/*
* Based on:
* var difficulty = String("0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747ce");
* deployer.deploy(Exchange, new web3.BigNumber("1e18"), new web3.BigNumber("5e17"),
*                100, 100, 100, difficulty.valueOf());
*/

var ethers = require("ethers");
var utils = ethers.utils;

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

  // Test params initial values
  it("should have correct initial params", async function() {
    let exchange = await Exchange.deployed();
    let params = await exchange.params();

    let closureFee = params[0];
    let cancelFee = params[1];
    let cleanSize = params[2];
    let minerShare = params[3];
    let distBalance = params[4];
    let difficulty = params[5];

    let expectedClosureFee = new web3.BigNumber("1e18");
    let expectedCancelFee = new web3.BigNumber("5e17");
    let expectedCleanSize = new web3.BigNumber("100");
    let expectedMinerShare = new web3.BigNumber("100");
    let expectedDistBalance = new web3.BigNumber("100");
    let expectedDifficulty = "0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747ce";

    assert.equal(closureFee.toString(10) === expectedClosureFee.toString(10),
                  true, "closure fee should equal expected closure fee");
    assert.equal(cancelFee.toString(10) === expectedCancelFee.toString(10),
                  true, "cancel fee should equal expected cancel fee");
    assert.equal(cleanSize.toString(10) === expectedCleanSize.toString(10),
                  true, "clean size should equal expected clean size");
    assert.equal(minerShare.toString(10) === expectedMinerShare.toString(10),
                  true, "miner share should equal expected miner share");
    assert.equal(distBalance.toString(10) === expectedDistBalance.toString(10),
                  true, "distribution balance should equal expected distribution balance");
    assert.equal(difficulty === expectedDifficulty,
                  true, "difficulty should equal expected difficulty");
  });

  // TODO: Test orderBook initial values
  it("should have correct initial orderBook", async function() {
    // let exchange = await Exchange.deployed();
    // let orderChapter0 = await exchange.getOrderChapter(0);

    // console.log(orderChapter0);

    // let expectedPrecision = new web3.BigNumber("1e18");
    // assert.equal(precision.toString(10) === expectedPrecision.toString(10),
    //              true, "precision should be equal to 10 ** 18");
  });

  // TODO: Test addressBook initial values
  // TODO: Test exBalances initial values
  // TODO: Test placing orders
  // TODO: SUBGOAL: Test exBalances
  // TODO: Test making matches
  // TODO: Test trade logging

})
