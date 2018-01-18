var SafeMath = artifacts.require("SafeMath.sol");
var ExchangeStructs = artifacts.require("ExchangeStructs.sol");
var Exchange = artifacts.require("Exchange.sol");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.deploy(ExchangeStructs);
  deployer.link(SafeMath, Exchange);
  deployer.link(ExchangeStructs, Exchange);
  deployer.deploy(Exchange, 1, 1, 100, 100, 100);
};
