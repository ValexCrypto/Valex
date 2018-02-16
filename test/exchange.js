/*
* Based on:
* var difficulty = String("0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747ce");
* deployer.deploy(Exchange, new web3.BigNumber("1e18"), new web3.BigNumber("5e17"),
*                100, 100, 100, difficulty.valueOf());
*/

var SafeMath = artifacts.require("SafeMath.sol");
var ExchangeStructs = artifacts.require("ExchangeStructs.sol");
var Exchange = artifacts.require("Exchange.sol");

contract("Exchange", function() {
  // First, test PRECISION
  it("should have precision of 10 ** 18", async function() {
    let exchange = await Exchange.deployed();
    let precision = await exchange.PRECISION();
    let expectedPrecision = new web3.BigNumber("1e18");
    assert.equal(precision.toString(10) === expectedPrecision.toString(10),
                  true, "precision should be equal to 10 ** 18");
  });
  // TODO: Test params
  it("should have correct initial values for params", async function() {
    let exchange = await Exchange.deployed();
    let params = await exchange.params();

    let closureFee= params[0];
    let cancelFee = params[1];
    // Size of numsCleared at which we should clean an order book
    let cleanSize = params[2];
    // Proportion of fees that miners get (divided by precision)
    let minerShare = params[3];
    // closedBalance at which we distribute dividends
    let distBalance = params[4];
    // For nonce-finding
    let difficulty = params[5];

    let expectedClosureFee = new web3.BigNumber("1e18");
    let expectedCancelFee = new web3.BigNumber("5e17");
    // Size of numsCleared at which we should clean an order book
    let expectedCleanSize;
    // Proportion of fees that miners get (divided by precision)
    let minerShare;
    // closedBalance at which we distribute dividends
    let distBalance;
    // For nonce-finding
    let difficulty; */
    console.log(params);
  });


  // TODO: Test orderBook
  // TODO: Test addressBook
  // TODO: Test placing orders
  // TODO: Test making matches
  // TODO: Test trade logging
  // TODO: Test exBalances
})
