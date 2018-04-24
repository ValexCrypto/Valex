pragma solidity ^0.4.18;

contract ExchangeStructs{
  // fee parameters and such
  struct Parameters {
    // Size of numsCleared at which we should clean an order book
    uint cleanSize;
    // Proportion of fees that miners get (divided by precision)
    uint minerShare;
    // For nonce-finding
    bytes32 difficulty;
  }

  // stores order info (public information)
  struct Order {
    // false for buy ETH, true for sell ETH
    bool buyETH;
    // Trade volume requested
    uint volume;
    // Minimum acceptable volume
    // If equal to volume, is all or nothing
    uint minVolume;
    // WRT 10^-18 * currency A (wei/btc)
    uint limit;
  }

  // stores address info on people placing orders (private information)
  struct AddressInfo {
    address ethAddress;
    bytes32[2] firstAddress;
    bytes32[2] otherAddress;
  }

  event TradeInfo(
    address ethAddress1,
    address ethAddress2,
    bytes32[2] firstAddress1,
    bytes32[2] firstAddress2,
    bytes32[2] otherAddress1,
    bytes32[2] otherAddress2,
    // ether / other volumes
    uint mimRate,
    uint ethVol
  );
}
