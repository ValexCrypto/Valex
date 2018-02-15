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
  // TODO: Test orderBook
  // TODO: Test addressBook
  // TODO: Test placing orders
  // TODO: Test making matches
  // TODO: Test trade logging
  // TODO: Test exBalances
})
