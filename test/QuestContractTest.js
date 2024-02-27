const chai = require("chai").default;

const QuestContract = artifacts.require("QuestContract");

contract("QuestContract", (accounts) => {
  let questContract;

  const owner = accounts[0];
  const participant1 = accounts[1];
  const participant2 = accounts[2];

  beforeEach(async () => {
    questContract = await QuestContract.new({
      from: owner,
      value: web3.utils.toWei("1", "ether"),
    });
  });

  it("should create a quest", async () => {
    const result = await questContract.createQuest(
      "Test Quest",
      "Description of the quest",
      Math.floor(Date.now() / 1000) + 3600, // Start date 1 hour from now
      Math.floor(Date.now() / 1000) + 7200, // End date 2 hours from now
      0, // SameAmount reward distribution type
      1, // Total rewards
      [10], // Reward amounts
      2 // Total participants
    );

    assert.equal(
      result.logs[0].event,
      "QuestCreated",
      "QuestCreated event not emitted"
    );
  });

  it("should enroll participants in a quest", async () => {
    await questContract.createQuest(
      "Test Quest",
      "Description of the quest",
      Math.floor(Date.now() / 1000) + 3600, // Start date 1 hour from now
      Math.floor(Date.now() / 1000) + 7200, // End date 2 hours from now
      0, // SameAmount reward distribution type
      1, // Total rewards
      [10], // Reward amounts
      2 // Total participants
    );

    await questContract.enrollInQuest(1, { from: participant1, value: 1 });
    await questContract.enrollInQuest(1, { from: participant2, value: 1 });

    const quest = await questContract.quests(1);
    assert.equal(
      quest.totalParticipants,
      2,
      "Participants not enrolled successfully"
    );
  });

  it("should complete tasks and distribute prizes", async () => {
    await questContract.createQuest(
      "Test Quest",
      "Description of the quest",
      Math.floor(Date.now() / 1000) + 3600, // Start date 1 hour from now
      Math.floor(Date.now() / 1000) + 7200, // End date 2 hours from now
      0, // SameAmount reward distribution type
      1, // Total rewards
      [10], // Reward amounts
      2 // Total participants
    );

    await questContract.enrollInQuest(1, { from: participant1, value: 1 });
    await questContract.enrollInQuest(1, { from: participant2, value: 1 });

    await questContract.completeTask(1, { from: participant1 });
    await questContract.completeTask(1, { from: participant2 });

    const quest = await questContract.quests(1);
    assert.equal(
      quest.tasksCompleted[participant1],
      true,
      "Task not completed for participant1"
    );
    assert.equal(
      quest.tasksCompleted[participant2],
      true,
      "Task not completed for participant2"
    );

    const result = await questContract.distributePrizes(1);
    assert.equal(
      result.logs[0].event,
      "PrizeDistributed",
      "PrizeDistributed event not emitted"
    );
  });
});
