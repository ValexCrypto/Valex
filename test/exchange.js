/*
* Based on these initial values (found in 2_deploy_contracts.js):
* var difficulty = String("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
* deployer.deploy(Exchange, new web3.BigNumber("5e17"), new web3.BigNumber("5e16"),
*                 100, 100, 100, difficulty.valueOf());
*/

var SafeMath = artifacts.require("SafeMath.sol");
var ExchangeStructs = artifacts.require("ExchangeStructs.sol");
var Exchange = artifacts.require("Exchange.sol");

contract("Exchange", function(accounts) {
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

    let expectedClosureFee = new web3.BigNumber("5e17");
    let expectedCancelFee = new web3.BigNumber("5e16");
    let expectedCleanSize = new web3.BigNumber("100");
    let expectedMinerShare = new web3.BigNumber("100");
    let expectedDistBalance = new web3.BigNumber("100");
    let expectedDifficulty = "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

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

  // Test openBalance initial value
  it("should have correct initial open balance", async function() {
    let exchange = await Exchange.deployed();
    let openBalance = await exchange.openBalance();

    let bigZero = new web3.BigNumber("0");

    assert.equal(openBalance.toString(10) === bigZero.toString(10),
                  true, "open balance should be equal to 0");
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
  // Test placing orders
  it("should place orders properly", async function() {
    let exchange = await Exchange.deployed();
    // Orders need to be padded.
    let postOrder = await exchange.placeOrder(true, "1e18", "9e17",
                                              "1e18", 11,
                                              ["0x" + "0".repeat(61) + "100",
                                                "0x" + "0".repeat(62) + "30"],
                                              ["0x" + "0".repeat(61) + "100",
                                                "0x" + "0".repeat(62) + "50"], 0,
                                              {value: "3e18", from: accounts[0]});

    let ethAddressChapter0 = await exchange.getETHAddressChapter(0);
    let firstAddressChapter0 = await exchange.getFirstAddressChapter(0);
    let secondAddressChapter0 = await exchange.getSecondAddressChapter(0);

    let orderChapter0 = await exchange.getOrderChapter(0);
    // This is the expectation for the chapter after the new order is put in
    let expectedOrderChapter0 = [[false, true],
                                  [new web3.BigNumber("0"), new web3.BigNumber("1e18")],
                                  [new web3.BigNumber("0"), new web3.BigNumber("9e17")],
                                  [new web3.BigNumber("0"), new web3.BigNumber("1e18")]];

    // Was the order placed?
    assert.equal(JSON.stringify(orderChapter0) === JSON.stringify(expectedOrderChapter0),
                  true, "order chapter 0 should contain genesis order");

    // Run previous tests to make sure genesis order wasn't messed up
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

    // All address information on new order correct?
    assert.equal(web3.toDecimal(ethAddressChapter0[1]) == 11,
                  true, "address chapter 0 should contain new order ETH address");
    assert.equal(firstAddressChapter0[1][0] === "0x" + "0".repeat(61) + "100",
                  true, "address chapter 0 should contain new order first address");
    assert.equal(firstAddressChapter0[1][1] == "0x" + "0".repeat(62) + "30",
                  true, "address chapter 0 should contain new order first address");
    assert.equal(secondAddressChapter0[1][0] === "0x" + "0".repeat(61) + "100",
                  true, "address chapter 0 should contain new order second address");
    assert.equal(secondAddressChapter0[1][1] == "0x" + "0".repeat(62) + "50",
                  true, "address chapter 0 should contain new order second address");
  });

  // Test placing orders
  // SUBGOAL: Test balances
  it("should update balances after ordering", async function() {
    let exchange = await Exchange.deployed();

    let openBalance = await exchange.openBalance();
    let totalBalance = await web3.eth.getBalance(exchange.address);

    assert.equal(new web3.BigNumber("3e18").toString(10) === openBalance.toString(10),
                  true, "open balance should equal message value of order placed");
    assert.equal(totalBalance.toString(10) === openBalance.toString(10),
                  true, "total balance should equal open balance");
  });

  // TODO: Test making matches
  it("should make matches properly", async function() {
    let exchange = await Exchange.deployed();
    // Orders need to be padded.
    let postOrder = await exchange.placeOrder(false, "1e18", "9e17",
                                              "1e18", 11,
                                              ["0x" + "0".repeat(61) + "100",
                                                "0x" + "0".repeat(62) + "30"],
                                              ["0x" + "0".repeat(61) + "100",
                                                "0x" + "0".repeat(62) + "50"], 0,
                                              {value: "3e18", from: accounts[0]});

    let postMatch = await exchange.giveMatch(accounts[1], 0, 1, 2, 0);

    let orderChapter0 = await exchange.getOrderChapter(0);

    // Change this
    let expectedOrderChapter0 = [[false, true, false],
                                  [new web3.BigNumber("0"), new web3.BigNumber("0"),
                                    new web3.BigNumber("0")],
                                  [new web3.BigNumber("0"), new web3.BigNumber("0"),
                                    new web3.BigNumber("0")],
                                  [new web3.BigNumber("0"), new web3.BigNumber("1e18"),
                                    new web3.BigNumber("1e18")]];

    assert.equal(JSON.stringify(orderChapter0) === JSON.stringify(expectedOrderChapter0),
                  true, "order chapter 0 should contain genesis order and empty orders");
  });

  // TODO: SUBGOAL: Test balances
  // TODO: SUBGOAL: Test chapter cleaning when necessary
  // TODO: More rigorous order-placing testing
  // TODO: More rigorous match-proposing testing
  // TODO: Test trade logging

})
