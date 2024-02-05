var SimpleStorage = artifacts.require("Storage");

module.exports = function (deployer) {
  // deployment steps
  deployer.deploy(SimpleStorage);
};
