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
    bool traderKYC;
    bool minerKYC;
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

  struct TradeInfo {
    address counterEthAddress;
    bytes32 counterFirstAddress;
    bytes32 counterSecondAddress;
    // alpha volume and rate of exchange
    uint mimRate;
    uint alphaVol;
    address broadcastAddress;
  }
}
