/*
* Based on these initial values (found in 2_deploy_contracts.js):
* var difficulty = String("0x341f85f5eca6304166fcfb6f591d49f6019f23fa39be0615e6417da06bf747ce");
* deployer.deploy(Exchange, new web3.BigNumber("1e18"), new web3.BigNumber("5e17"),
*                100, 100, 100, difficulty.valueOf());
*/

var SafeMath = artifacts.require("SafeMath.sol");
var ExchangeStructs = artifacts.require("ExchangeStructs.sol");
var Exchange = artifacts.require("Exchange.sol");

contract("Exchange", function() {
  // SECTION: Test initial values
  // First, test PRECISION
  it("should have precision of 10 ** 18", async function() {
    let exchange = await Exchange.deployed();
    let precision = await exchange.PRECISION();
    let expectedPrecision = new web3.BigNumber("1e18");

    assert.equal(precision.toString(10) === expectedPrecision.toString(10),
                  true, "precision should be equal to 10 ** 18");
  });

  // Test params initial values
  it("should have correct initial parameters", async function() {
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

  // Test exBalances initial values
  it("should have correct initial open and closed balances", async function() {
    let exchange = await Exchange.deployed();
    let exBalances = await exchange.exBalances();

    let openBalance = exBalances[0];
    let closedBalance = exBalances[1];

    let bigZero = new web3.BigNumber("0");

    assert.equal(openBalance.toString(10) === bigZero.toString(10),
                  true, "open balance should be equal to 0");
    assert.equal(closedBalance.toString(10) === bigZero.toString(10),
                  true, "closed balance should be equal to 0");
  });

  // Test order book initial values
  it("should have correct initial order book", async function() {
    let exchange = await Exchange.deployed();
    let orderChapter0 = await exchange.getOrderChapter(0);

    let expectedOrderChapter0 = [[false], [new web3.BigNumber("0")],
                                  [new web3.BigNumber("0")], [new web3.BigNumber("0")]];

    assert.equal(JSON.stringify(orderChapter0) === JSON.stringify(expectedOrderChapter0),
                  true, "order chapter 0 should contain genesis order");
  });

  // Test address book initial values
  it("should have correct initial address book", async function() {
    let exchange = await Exchange.deployed();
    let ethAddressChapter0 = await exchange.getETHAddressChapter(0);
    let firstAddressChapter0 = await exchange.getFirstAddressChapter(0);
    let secondAddressChapter0 = await exchange.getSecondAddressChapter(0);

    assert.equal(web3.toDecimal(ethAddressChapter0[0]) == 0,
                  true, "address chapter 0 should contain genesis order ETH address");
    assert.equal(web3.toDecimal(firstAddressChapter0[0][0]) == 0,
                  true, "address chapter 0 should contain genesis order first address");
    assert.equal(web3.toDecimal(firstAddressChapter0[0][1]) == 0,
                  true, "address chapter 0 should contain genesis order first address");
    assert.equal(web3.toDecimal(secondAddressChapter0[0][0]) == 0,
                  true, "address chapter 0 should contain genesis order second address");
    assert.equal(web3.toDecimal(secondAddressChapter0[0][1]) == 0,
                  true, "address chapter 0 should contain genesis order second address");
  });

  // SECTION: Test dynamic values
  // TODO: Test placing orders
  // TODO: SUBGOAL: Test exBalances
  // TODO: Test making matches
  // TODO: Test trade logging

})
