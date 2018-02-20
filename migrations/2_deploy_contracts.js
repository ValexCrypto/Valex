var SafeMath = artifacts.require("SafeMath.sol");
var ExchangeStructs = artifacts.require("ExchangeStructs.sol");
var Exchange = artifacts.require("Exchange.sol");

module.exports = function(deployer) {
  var difficulty = String("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
  deployer.deploy(SafeMath);
  deployer.deploy(ExchangeStructs);
  deployer.link(SafeMath, Exchange);
  deployer.link(ExchangeStructs, Exchange);
  deployer.deploy(Exchange, new web3.BigNumber("5e17"), new web3.BigNumber("5e16"),
                  100, 100, 100, difficulty.valueOf());
};
