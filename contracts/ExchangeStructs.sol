pragma solidity ^0.4.18;

contract ExchangeStructs{
  // fee parameters and such
  struct Parameters{
    // closure fee paid up front, refunded - cancel fee if cancelled
    uint closureFeePerUnit;
    uint cancelFeePerUnit;
    // Order margin for error (match), expressed as margin[0] units/margin[1] units
    uint[2] margin;
    // Size of numsCleared at which we should clean an order book
    uint cleanSize;
    // Proportion of fees that miners get
    uint[2] minerShare;
    // closedBalance at which we distribute dividends
    uint distBalance;
  }

  // stores active exBalances
  struct Balances{
    // separate out the open balance (includes unclosed fees, gas fees),
    // which will be distributed between miners, the exchange, and traders,
    // from closed balance, which belongs to the exchange
    uint openBalance;
    uint closedBalance;
  }

  // stores order info (public information)
  struct Order{
    // false for buy ETH, true for sell ETH
    bool buyETH;
    uint volume;
    // buy : sell ratio
    uint[2] limit;
  }

  // stores address info on people placing orders (private information)
  struct AddressInfo{
    address ethAddress;
    string firstAddress;
    string otherAddress;
  }

  event TradeInfo(
    address ethAddress1,
    address ethAddress2,
    string firstAddress1,
    string firstAddress2,
    string otherAddress1,
    string otherAddress2,
    // ether / other volumes
    uint ethVol,
    uint otherVol
  );
}
