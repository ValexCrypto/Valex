pragma solidity ^0.4.17;

import '../libs/SafeMathLib.sol';

/// @title Exchange
/// @Author khelmy

contract Exchange {
  using SafeMathLib for uint;
  // fee parameters and such
  struct Parameters{
    //wei per eth
    // closure fee paid up front, refunded - withdrawal fee if cancelled
    uint closureFeePerUnit;
    uint cancelFeePerUnit;
    // fixed gas fee (Everything should run in O(1) time)
    // valuated in gas (so remember to multiply by tx.gasprice)
    uint gasFee;
    // default gas value
    uint gasDef;
    // Order margin for error (match), expressed as margin[0] units/margin[1] units
    uint[2] margin;
    // Size of numsCleared at which we should clean an order book
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

  event TradeInfo(
    address ethAddress,
    string otherAddress,
    // ether / other volumes
    uint ethVol,
    uint otherVol
  );

  Parameters params;
  Balances private balances;

  // separate chapters for different currency pairs
  // that's why they're 2D
  Order[][] orderBook;
  AddressInfo[][] private addressBook;
  // Orders that have been closed are kept here
  uint[] numsCleared;

  // Checks edge cases for match verification
  function checkMatchEdges(uint chapter, uint index1, uint index2)
    private
    returns(bool passes)
  {
    // valid chapter
    require(chapter < this.orderBook.length);
    // valid indices
    require(index1 < this.orderBook[chapter].length);
    require(index2 < this.orderBook[chapter].length);
    //One buy order and one sell order
    require(this.orderBook[chapter][index1].buyETH != this.orderBook[chapter][index2].buyETH);
    //Non-empty order
    require(this.orderBook[chapter][index1].volume != 0);
    require(this.orderBook[chapter][index2].volume != 0);
    // All edge cases work!
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
    Order sellOrder = this.orderBook[chapter][sellIndex];

    // Non-contradictory limits
    // (non-negative trade surplus)
    // TODO: DEBUGGING: verify that these are the correct equations
    if (buyOrder.limit[0] * sellOrder.limit[1] <
        buyOrder.limit[1] * sellOrder.limit[0]){
      return false;
    }

    // Meet in middle rate
    // mimRate copy2
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
  function clearTrade(uint chapter, uint index1, uint index2, uint[2] volumes)
    private
  {
    if (this.orderBook[chapter][index1].volume == volumes[0]){
      delete this.orderBook[chapter][index1].volume;
      this.numsCleared[chapter] += 1;
    }
    else{
      this.orderBook[chapter][index1].volume = (this.orderBook[chapter][index1].volume -
                                                volumes[0]);
    }
    if (this.orderBook[chapter][index2].volume == volumes[1]){
      delete this.orderBook[chapter][index2].volume;
      this.numsCleared[chapter] += 1;
    }
    else{
      this.orderBook[chapter][index2].volume = (this.orderBook[chapter][index2].volume -
                                                volumes[1]);
    }
    return;
  }

  // Adds trade to log, for traders to note
  // http://solidity.readthedocs.io/en/latest/contracts.html?highlight=events#events
  function alertTraders(uint chapter, uint index1, uint index2, uint[2] volumes)
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

  // Calculates exchange volumes for trade using limits (meet in middle)
  // Ether volume is always first
  function getVolumes(uint chapter, uint index1, uint index2)
    private
    returns(uint[2] volumes)
  {
    // which order is buying and selling ETH?
    // buy-sell copy1
    // a little different from the other version
    uint buyIndex;
    uint sellIndex;
    bool index1ETH;
    if (this.orderBook[chapter][index1].buyETH){
      buyIndex = index1;
      sellIndex = index2;
      index1ETH = false;
    }
    else{
      buyIndex = index2;
      sellIndex = index1;
      index1ETH = true;
    }
    // shorthand for buy and sell orders
    Order buyOrder = this.orderBook[chapter][buyIndex];
    Order sellOrder = this.orderBook[chapter][sellIndex];
    // TODO: FINISH FUNCTION
    // Meet in middle rate
    // mimRate copy2
    uint[2] mimRate;
    mimRate[1] = buyOrder.limit[0] * sellOrder.limit[1] * 2;
    mimRate[0] = (buyOrder.limit[1] * sellOrder.limit[0]) + (buyOrder.limit[0] * sellOrder.limit[1]);
    if (((sellOrder.volume * mimRate[1]) / mimRate[0]) <= buyOrder.volume){
      volumes[0] = sellOrder;
      volumes[1] = ((buyOrder.volume * mimRate[0]) / mimRate[1]);
    }
    else{
      volumes[0] = ((buyOrder.volume * mimRate[0]) / mimRate[1]);
      volumes[1] = buyOrder;
    }
    return volumes;
  }

  // Move balance from open to closed
  // Eliminate minerPayment from either balance
  function clearBalance(uint minerPayment, uint[2] volumes)
    private
  {
    this.balances.openBalance = (this.balances.openBalance -
                                  (closureFeePerUnit * volumes[0]));
    this.balances.closedBalance = (this.balances.closedBalance -
                                  minerPayment +
                                  (closureFeePerUnit * volumes[0]));
    return;
  }

  // Clean chapter (called when size reaches size to clean)
  function cleanChapter(uint chapter)
    private
  {
    // Clean chapter only if size is appropriate
    if (this.numsCleared[chapter] < this.params.cleanSize){
      return;
    }
    // For all orders
    // If it's a cleared order:
    // Replace it with the next one, and clear the next one
    for (uint i = 0; i < this.orderBook[chapter].length; i++){
      if (this.orderBook[chapter][i].volume == 0){
        if (i < this.orderBook[chapter].length - 1){
          this.orderBook[chapter][i] = this.orderBook[chapter][i+1];
          delete this.orderBook[chapter][i+1];
        }
      }
    }
    this.orderBook[chapter].length = this.orderBook[chapter].length - this.numsCleared[chapter];
  }

  // Miners suggest matches with this function
  // Performs nonce verification (keccak256)
  // Wrapper for isValidMatch, performs other required functions
  function getMatch(uint chapter, uint index1, uint index2,
                  bytes32 nonce, uint hashVal)
    public
    payable
    returns(bool isValid)
  {
    require(msg.value >= this.params.gasFee * tx.gasprice);
    // Validate that nonce is equivalent
    // modulo so that cost is constant
    // + 110 so that it's always 3 digits
    // storing all values is impractical
    // hashVal adds security if trade volume is small
    if (nonce != keccak256(msg.sender,
                          (hashVal + 110) % 1000,
                          (chapter + 110) % 1000,
                          (index1 + 110) % 1000,
                          (index2 + 110) % 1000)){
      return false;
    }
    if (! isValidMatch(chapter, index1, index2)){
      return false;
    }
    uint[2] volumes = getVolumes(chapter, index1, index2);
    // calculate the miner's payment
    uint minerPayment = ((this.params.minerShare[0] * closureFeePerUnit * volumes[0]) /
                          this.params.minerShare[1]);
    msg.sender.transfer(minerPayment);
    clearBalance(minerPayment, volumes);
    alertTraders(chapter, index1, index2, volumes);
    clearTrade(chapter, index1, index2, volumes);
    cleanChapter(chapter);
    return true;
  }

  // Allows traders to place orders
  function placeOrder(bool buyETH, uint volume, uint limit0, uint limit1,
                      address ethAddress, string otherAddress, uint chapter)
    public
    payable
    returns(bool accepted)
  {
    require(volume > 0);
    require(limit0 > 0 && limit1 > 0);
    // for accounting
    // TODO: Not sure if this is necessary
    require(tx.gasprice == this.params.gasDef);
    // Charge according to ether transaction vol
    if (buyETH){
      require((limit1 * volume * msg.value) > limit0 * this.params.closureFeePerUnit);
    }
    else{
      require((limit0 * volume * msg.value) > limit1 * this.params.closureFeePerUnit);
    }
    uint[2] limit;
    limit[0] = limit0;
    limit[1] = limit1;
    this.orderBook[chapter].push(Order(buyETH, volume, limit));
    this.addressBook[chapter].push(AddressInfo(ethAddress, otherAddress));
    return true;
  }

  // Allows traders to cancel orders
  function cancelOrder(uint chapter, uint index)
    public
    returns(bool accepted)
  {
    //TODO: Account for gas price (maybe, if necessary)
    // Valid indices
    require(chapter < this.orderBook.length);
    require(index < this.orderBook[chapter].length);
    // Can't cancel other people's orders
    require(msg.sender == this.addressBook[chapter][index].ethAddress);
    uint volume = this.orderBook[chapter][index].volume;
    uint limit;
    // Refund according to ether transaction vol
    if (this.orderBook[chapter][index].buyETH){
      limit = limit[0];
    }
    else{
      limit = limit[1];
    }
    uint cancelPayment = limit * (this.params.closureFeePerUnit - this.params.cancelFeePerUnit);
    msg.sender.transfer(cancelPayment);
    // Update balances
    this.balances.openBalance = (this.balances.openBalance -
                                (limit * this.params.closureFeePerUnit));
    this.balances.closedBalance = (this.balances.closedBalance +
                                  (limit * this.params.cancelFeePerUnit));
    delete this.orderBook[chapter][index];
    delete this.addressBook[chapter][index];
    this.numsCleared[chapter] += 1;
    cleanChapter(chapter);
    return true;
  }
}
