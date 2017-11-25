pragma solidity ^0.4.17;

import './Swap.sol';
import '../libs/SafeMathLib.sol';

/// @title Exchange
/// @Author khelmy

contract Exchange {
  using SafeMathLib for uint;
  // TODO: figure out how gas refunds should work
  // fee parameters and such
  struct Parameters{
    //wei per eth
    // closure fee paid up front, refunded - withdrawal fee if cancelled
    uint closureFeePerUnit;
    uint withdrawalFeePerUnit;
    // fixed gas fee (Everything should run in O(1) time)
    // valuated in gas (so remember to multiply by tx.gasprice)
    uint gasFee;
    // Order margin for error (match), expressed as margin[0] units/margin[1] units
    uint[2] margin;
    // Size at which we should clean an order book
    uint cleanSize;
    // Proportion of fees that miners get
    uint[2] minerShare;
  }

  // stores active balances
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
    string otherAddress;
  }

  event TradeInfo{
    address ethAddress;
    string otherAddress;
    // ether / other volumes
    uint ethVol;
    uint otherVol;
  }

  Parameters params;
  Balances private balances;

  // separate chapters for different currency pairs
  // that's why they're 2D
  Order[][] orderbook;
  AddressInfo[][] private addressBook;

  // Checks edge cases for match verification
  function checkMatchEdges(uint chapter, uint index1, uint index2)
    private
    returns(bool passes)
  {
    // valid chapter
    if (chapter >= this.orderBook.length){
      return false;
    }
    // valid indices
    if ((index1 >= this.orderBook[chapter].length) ||
          (index2 >= this.orderBook[chapter].length)){
      return false;
    }
    //One buy order and one sell order
    if (this.orderBook[chapter][index1].buyETH == this.orderBook[chapter][index2].buyETH){
      return false;
    }
    if ((this.orderBook[chapter][index1].volume == 0 ) ||
          (this.orderBook[chapter][index2].volume == 0)){
      return false;
    }
    return true;
  }

  // verifies that match is valid
  function isValidMatch(uint chapter, uint index1, uint index2)
    private
    returns(bool isValid)
  {
    // check edge cases
    if (! checkMatchEdges(chapter, index1, index2)){
      return false;
    }
    // which order is buying and selling ETH?
    // buy-sell copy1
    uint buyIndex;
    uint sellIndex;
    if (this.orderBook[chapter][index1].buyETH){
      buyIndex = index1;
      sellIndex = index2;
    }
    else{
      buyIndex = index2;
      sellIndex = index1;
    }
    // shorthand for buy and sell orders
    Order buyOrder = this.orderBook[chapter][buyIndex];
    Order sellOrder = this.orderbook[chapter][sellIndex];

    // Non-contradictory limits
    // (non-negative trade surplus)
    // TODO: DEBUGGING: verify that these are the correct equations
    if (buyOrder.limit[0] * sellOrder.limit[1] <
        buyOrder.limit[1] * sellOrder.limit[0]){
      return false;
    }

    // Meet in middle rate
    uint[2] mimRate;
    mimRate[1] = buyOrder.limit[0] * sellOrder.limit[1] * 2;
    mimRate[0] = (buyOrder.limit[1] * sellOrder.limit[0]) + (buyOrder.limit[0] * sellOrder.limit[1]);

    // Volumes comparable
    // TODO: DEBUGGING: verify that these are the correct equations
    if (buyOrder.volume * mimRate[0] > sellOrder.volume * mimRate[1]){
      if (buyOrder.volume * margin[0] * mimRate[0] > sellOrder.volume * margin[1] * mimRate[1]){
        return false;
      }
    }
    if (sellOrder.volume * mimRate[1] > buyOrder.volume * mimRate[0] ){
      if (sellOrder.volume * margin[0] * mimRate[0] > buyOrder.volume * margin[1] * mimRate[1] ){
        return false;
      }
    }
    return true;
  }

  // Clears closed trade, reenters into order book if incomplete
  function clearTrade(uint chapter, uint index1, uint index2, uint[3] volumes)
    private
  {
    if (this.orderBook[chapter][index1].volume == volumes[0]){
      delete this.orderBook[chapter][index1].volume;
    }
    else{
      this.orderBook[chapter][index1].volume = (this.orderBook[chapter][index1].volume -
                                                volumes[0]);
    }
    if (this.orderBook[chapter][index2].volume == volumes[1]){
      delete this.orderBook[chapter][index2].volume;
    }
    else{
      this.orderBook[chapter][index2].volume = (this.orderBook[chapter][index2].volume -
                                                volumes[1]);
    }
    return;
  }

  // Adds trade to log, for traders to note
  // http://solidity.readthedocs.io/en/latest/contracts.html?highlight=events#events
  function alertTraders(uint chapter, uint index1, uint index2, uint[3] volumes)
    private
  {
    address ethAddress;
    string otherAddress;
    uint ethVol;
    uint otherVol;
    if (volumes[3] == 0){
      ethAddress = this.addressBook[chapter][index1].ethAddress;
      otherAddress = this.addressBook[chapter][index2].ethAddress;
      ethVol = 0;
      otherVol = 1;
    }
    else{
      ethAddress = this.addressBook[chapter][index2].ethAddress;
      otherAddress = this.addressBook[chapter][index1].ethAddress;
      ethVol = 1;
      otherVol = 0;
    }
    TradeInfo(
      ethAddress,
      otherAddress,
      ethVol,
      otherVol
      );
    return;
  }

  // Calculates "exchange rate" for trade using limits (meet in middle)
  // third element is which of first 2 is the ETH volume
  function getVolumes(uint chapter, uint index1, uint index2)
    private
    returns(uint[3] volumes)
  {
    // which order is buying and selling ETH?
    // buy-sell copy1
    // a little different from the other version
    uint buyIndex;
    uint sellIndex;
    if (this.orderBook[chapter][index1].buyETH){
      buyIndex = index1;
      sellIndex = index2;
      volumes[3] = 0;
    }
    else{
      buyIndex = index2;
      sellIndex = index1;
      volumes[3] = 1;
    }
    // shorthand for buy and sell orders
    Order buyOrder = this.orderBook[chapter][buyIndex];
    Order sellOrder = this.orderbook[chapter][sellIndex];
    // TODO: FINISH FUNCTION
    return volumes;
  }

  // Move balance from open to closed
  // Eliminate minerPayment from either balance
  function clearBalance(uint minerPayment, uint[3] volumes)
    private
  {
    this.balances.openBalance = (this.balances.openBalance -
                                  (closureFeePerUnit * volumes[volumes[2]]));
    this.balances.closedBalance = (this.balances.closedBalance -
                                  minerPayment +
                                  (closureFeePerUnit * volumes[volumes[2]]));
    return;
  }

  // Miners suggest matches with this function
  function match(uint chapter, uint index1, uint index2)
    public
    payable
    returns(bool isValid)
  {
    require(msg.value >= this.params.gasFee * tx.gasprice);
    if (! isValidMatch(chapter, index1, index2)){
      return false;
    }
    uint[3] volumes = getVolumes(chapter, index1, index2);
    // calculate the miner's payment
    uint minerPayment = ((this.params.minerShare[0] * closureFeePerUnit * volumes[volumes[2]]) /
                          this.params.minerShare[1]);
    msg.sender.transfer(minerPayment);
    clearBalance(minerPayment, volumes);
    alertTraders(chapter, index1, index2, volumes);
    clearTrade(chapter, index1, index2, volumes);
    return true;
  }

  // deploy a new swap contract (not functional)
  function newSwap()
    private
    returns(address newContract)
  {
    Swap s = new Swap();
    return s;
  }
}
