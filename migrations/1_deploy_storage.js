// var SimpleStorage = artifacts.require("Storage");

// module.exports = function (deployer) {
//   // deployment steps
//   deployer.deploy(SimpleStorage);
// };

var QuestContract = artifacts.require("QuestContract");

module.exports = function (deployer) {
  deployer.deploy(QuestContract);
};
