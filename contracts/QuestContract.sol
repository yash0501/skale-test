// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract QuestContract {
    address public owner;

    enum RewardDistributionType { SameAmount, SeparateAmount }

    struct Quest {
        string title;
        string description;
        uint256 startDate;
        uint256 endDate;
        RewardDistributionType rewardDistributionType;
        uint256 totalRewards;
        uint256[] rewardAmounts;
        uint256 totalParticipants;
        address[] participants;
        mapping(address => bool) enrolled;
        mapping(address => bool) tasksCompleted;
    }

    mapping(uint256 => Quest) public quests;
    uint256 public questCount;

    event QuestCreated(
        uint256 questId,
        string title,
        string description,
        uint256 startDate,
        uint256 endDate,
        RewardDistributionType rewardDistributionType,
        uint256 totalRewards,
        uint256[] rewardAmounts,
        uint256 totalParticipants
    );
    event UserEnrolled(uint256 questId, address user);
    event TaskCompleted(uint256 questId, address user);
    event PrizeDistributed(uint256 questId, address[] winners);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createQuest(
        string memory _title,
        string memory _description,
        uint256 _startDate,
        uint256 _endDate,
        RewardDistributionType _rewardDistributionType,
        uint256 _totalRewards,
        uint256[] memory _rewardAmounts,
        uint256 _totalParticipants
    ) external onlyOwner payable {
        require(_totalRewards > 0, "Total rewards should be greater than zero");
        require(_rewardAmounts.length == _totalRewards, "Invalid reward amounts");
        require(_totalParticipants > 0, "Total participants should be greater than zero");

        questCount++;

        Quest storage newQuest = quests[questCount];
        newQuest.title = _title;
        newQuest.description = _description;
        newQuest.startDate = _startDate;
        newQuest.endDate = _endDate;
        newQuest.rewardDistributionType = _rewardDistributionType;
        newQuest.totalRewards = _totalRewards;
        newQuest.rewardAmounts = _rewardAmounts;
        newQuest.totalParticipants = _totalParticipants;
        newQuest.participants = new address[](0);

        // Transfer reward amount to the contract
        for (uint256 i = 0; i < _totalRewards; i++) {
            require(
                address(this).balance >= _rewardAmounts[i],
                "Insufficient balance in the contract"
            );
            payable(owner).transfer(_rewardAmounts[i]);
        }

        emit QuestCreated(
            questCount,
            _title,
            _description,
            _startDate,
            _endDate,
            _rewardDistributionType,
            _totalRewards,
            _rewardAmounts,
            _totalParticipants
        );
    }

    function enrollInQuest(uint256 _questId) external payable {
        require(_questId > 0 && _questId <= questCount, "Invalid quest ID");
        Quest storage quest = quests[_questId];
        require(quest.enrolled[msg.sender] == false, "User already enrolled");
        // require(msg.value > 0, "Enrollment fee is required");

        require(quest.participants.length < quest.totalParticipants, "Quest is full");

        quest.participants.push(msg.sender);
        quest.enrolled[msg.sender] = true;

        emit UserEnrolled(_questId, msg.sender);
    }

    function completeTask(uint256 _questId) external {
        require(_questId > 0 && _questId <= questCount, "Invalid quest ID");
        Quest storage quest = quests[_questId];
        require(quest.enrolled[msg.sender] == true, "User not enrolled in the quest");
        require(quest.tasksCompleted[msg.sender] == false, "User has already completed the task");

        quest.tasksCompleted[msg.sender] = true;

        emit TaskCompleted(_questId, msg.sender);

        if (quest.participants.length == quest.totalParticipants) {
            distributePrizes(_questId);
        }
    }

    function distributePrizes(uint256 _questId) internal {
        Quest storage quest = quests[_questId];
        address[] memory winners = new address[](quest.totalParticipants);

        if (quest.rewardDistributionType == RewardDistributionType.SameAmount) {
            // Same amount for all winners
            uint256 totalPrize = quest.totalRewards * quest.rewardAmounts[0];
            require(address(this).balance >= totalPrize, "Insufficient funds for prize distribution");

            for (uint256 i = 0; i < quest.totalParticipants; i++) {
                winners[i] = quest.participants[i];
            }

            // Distribute prizes
            for (uint256 i = 0; i < winners.length; i++) {
                require(payable(winners[i]).send(quest.rewardAmounts[0]), "Prize distribution failed");
            }
        } else if (quest.rewardDistributionType == RewardDistributionType.SeparateAmount) {
            // Separate amount for each winner
            require(quest.totalRewards == quest.rewardAmounts.length, "Invalid reward amounts");

            for (uint256 i = 0; i < quest.totalParticipants; i++) {
                winners[i] = quest.participants[i % quest.totalRewards];
            }

            // Distribute prizes
            for (uint256 i = 0; i < winners.length; i++) {
                require(payable(winners[i]).send(quest.rewardAmounts[i % quest.totalRewards]), "Prize distribution failed");
            }
        }

        emit PrizeDistributed(_questId, winners);
    }
}
