var SafeMath = artifacts.require("SafeMath.sol");
var ExchangeStructs = artifacts.require("ExchangeStructs.sol");
var Exchange = artifacts.require("Exchange.sol");

module.exports = function(deployer) {
  var difficulty = String("0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747ce");
  deployer.deploy(SafeMath);
  deployer.deploy(ExchangeStructs);
  deployer.link(SafeMath, Exchange);
  deployer.link(ExchangeStructs, Exchange);
  deployer.deploy(Exchange, 1, 1, 100, 100, 100,
                  difficulty.valueOf());
};
