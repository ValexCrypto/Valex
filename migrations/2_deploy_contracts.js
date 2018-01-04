var SafeMath = artifacts.require("SafeMath.sol");
var Exchange = artifacts.require("Exchange.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, Exchange);
  deployer.deploy(Exchange, 1, 1, 1, 2, 100, 1, 2, 100);
};
