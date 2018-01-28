pragma solidity ^0.4.18;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ExchangeStructs.sol";
import "../contracts/Exchange.sol";

contract TestExchange {
  Exchange exchange = Exchange(DeployedAddresses.Exchange());

  // Testing the setBooks() function
  function testSetBooks() public {
    // Test variables
    mapping (uint => ExchangeStructs.Order[]) expectedOrderBook;
    mapping (uint => ExchangeStructs.AddressInfo[]) expectedAddressBook;

    expectedOrderBook[0].push(ExchangeStructs.Order(false,0,0,0));
    expectedAddressBook[0].push(ExchangeStructs.AddressInfo(address(0),"",""));


    mapping (uint => ExchangeStructs.Order[]) orderBook = exchange.orderBook();
    mapping (uint => ExchangeStructs.AddressInfo[]) addressBook = exchange.addressBook();

    Assert.equal(orderBook, expectedOrderBook, "Order book should equal desired base state.");
    Assert.equal(addressBook, expectedAddressBook, "Address book should equal desired base state.");
  }
}
