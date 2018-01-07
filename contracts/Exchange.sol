pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';

/// @title Exchange
/// @author Karim Helmy

// Primary contract: Describes functions of exchange
contract Exchange {
  // TODO: Make all operations safe
  using SafeMath for uint;
  // fee parameters and such
  struct Parameters{
    //wei per eth
    // closure fee paid up front, refunded - withdrawal fee if cancelled
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

  Parameters public params;
  Balances public exBalances;

  // separate chapters for different currency pairs
  // that's why they're 2D mappings
  mapping (uint => Order[]) public orderBook;
  // Order[][] public orderBook;
  mapping (uint => AddressInfo[]) private addressBook;
  // AddressInfo[][] private addressBook;
  // Numbers of orders that have been closed are kept here
  uint[] numsCleared;

  // Constructor for contract
  function Exchange(uint closureFeePerUnit, uint cancelFeePerUnit,
                    uint margin0, uint margin1, uint cleanSize,
                    uint minershare0, uint minerShare1, uint distBalance)
    public
  {
    // Initialize parameters books
    setParams(closureFeePerUnit, cancelFeePerUnit,
              margin0, margin1, cleanSize, minershare0, minerShare1, distBalance);
    // Initialize order books
    setBooks();
    // Initialize numsCleared[0] as zero
    numsCleared.push(0);
    return;
  }

  // TODO: If necessary, implement, otherwise delete
  // Initializes orderBook and addressBook
  // Only used in constructor
  function setBooks()
    private
    // TODO: Make impure when finished
    // pure to avoid warning, but in final version will not be
    pure
    returns(bool passes)
  {
    return true;
  }
  // Init the params struct, which contains the bulk of exchange's parameters
  // Only used in constructor
  function setParams(uint closureFeePerUnit, uint cancelFeePerUnit,
                    uint margin0, uint margin1, uint cleanSize,
                    uint minerShare0, uint minerShare1, uint distBalance)
    private
    returns(bool passes)
  {
    params.closureFeePerUnit = closureFeePerUnit;
    params.cancelFeePerUnit = cancelFeePerUnit;
    params.margin[0] = margin0;
    params.margin[1] = margin1;
    params.cleanSize = cleanSize;
    params.minerShare[0] = minerShare0;
    params.minerShare[1] = minerShare1;
    params.distBalance = distBalance;
    return true;
  }

  // Checks edge cases for match verification
  function checkMatchEdges(uint chapter, uint index1, uint index2)
    private
    view
    returns(bool passes)
  {
    // valid indices
    require(index1 < orderBook[chapter].length);
    require(index2 < orderBook[chapter].length);
    //One buy order and one sell order
    require(orderBook[chapter][index1].buyETH != orderBook[chapter][index2].buyETH);
    //Non-empty order
    require(orderBook[chapter][index1].volume != 0);
    require(orderBook[chapter][index2].volume != 0);
    // All edge cases work!
    return true;
  }

  // verifies that match is valid
  function isValidMatch(uint chapter, uint index1, uint index2)
    private
    view
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
    if (orderBook[chapter][index1].buyETH){
      buyIndex = index1;
      sellIndex = index2;
    }
    else{
      buyIndex = index2;
      sellIndex = index1;
    }
    // shorthand for buy and sell orders
    Order memory buyOrder = orderBook[chapter][buyIndex];
    Order memory sellOrder = orderBook[chapter][sellIndex];

    // Non-contradictory limits
    // (non-negative trade surplus)
    // TODO: DEBUGGING: verify that these are the correct equations
    if (buyOrder.limit[0] * sellOrder.limit[1] <
        buyOrder.limit[1] * sellOrder.limit[0]){
      return false;
    }

    // Meet in middle rate
    // mimRate copy2
    uint[2] memory mimRate;
    mimRate[1] = buyOrder.limit[0] * sellOrder.limit[1] * 2;
    mimRate[0] = (buyOrder.limit[1] * sellOrder.limit[0]) + (buyOrder.limit[0] * sellOrder.limit[1]);

    // Volumes comparable
    // TODO: DEBUGGING: verify that these are the correct equations
    if (buyOrder.volume * mimRate[0] > sellOrder.volume * mimRate[1]){
      if (buyOrder.volume * params.margin[0] * mimRate[0] > sellOrder.volume * params.margin[1] * mimRate[1]){
        return false;
      }
    }
    if (sellOrder.volume * mimRate[1] > buyOrder.volume * mimRate[0] ){
      if (sellOrder.volume * params.margin[0] * mimRate[0] > buyOrder.volume * params.margin[1] * mimRate[1] ){
        return false;
      }
    }
    return true;
  }

  // Clears closed trade, reenters into order book if incomplete
  function clearTrade(uint chapter, uint index1, uint index2, uint[2] volumes)
    private
    returns(bool passed)
  {
    if (orderBook[chapter][index1].volume == volumes[0]){
      delete orderBook[chapter][index1].volume;
      numsCleared[chapter] += 1;
    }
    else{
      orderBook[chapter][index1].volume = (orderBook[chapter][index1].volume -
                                                volumes[0]);
    }
    if (orderBook[chapter][index2].volume == volumes[1]){
      delete orderBook[chapter][index2].volume;
      numsCleared[chapter] += 1;
    }
    else{
      orderBook[chapter][index2].volume = (orderBook[chapter][index2].volume -
                                                volumes[1]);
    }
    return true;
  }

  // Adds trade to log, for traders to note
  // http://solidity.readthedocs.io/en/latest/contracts.html?highlight=events#events
  function alertTraders(uint chapter, uint index1, uint index2, uint[2] volumes)
    private
    returns(bool passed)
  {
    uint ethVol;
    uint otherVol;
    if (orderBook[chapter][index1].buyETH){
      ethVol = volumes[0];
      otherVol = volumes[1];
    }
    else{
      ethVol = volumes[0];
      otherVol = volumes[1];
    }
    TradeInfo(
      addressBook[chapter][index1].ethAddress, //ethAddress1,
      addressBook[chapter][index2].ethAddress, //ethAddress2,
      addressBook[chapter][index1].firstAddress, //firstAddress1,
      addressBook[chapter][index2].firstAddress, //firstAddress2,
      addressBook[chapter][index1].otherAddress, //otherAddress1,
      addressBook[chapter][index2].otherAddress, // otherAddress2,
      ethVol,
      otherVol
      );
    return true;
  }

  // Calculates exchange volumes for trade using limits (meet in middle)
  // Ether volume is always first
  function getVolumes(uint chapter, uint index1, uint index2)
    private
    view
    returns(uint[2] volumes)
  {
    // which order is buying and selling ETH?
    // buy-sell copy1
    // a little different from the other version
    uint buyIndex;
    uint sellIndex;
    bool index1ETH;
    if (orderBook[chapter][index1].buyETH){
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
    Order storage buyOrder = orderBook[chapter][buyIndex];
    Order storage sellOrder = orderBook[chapter][sellIndex];
    // TODO: FINISH FUNCTION
    // Meet in middle rate
    // mimRate copy2
    uint[2] memory mimRate;
    mimRate[1] = buyOrder.limit[0] * sellOrder.limit[1] * 2;
    mimRate[0] = (buyOrder.limit[1] * sellOrder.limit[0]) + (buyOrder.limit[0] * sellOrder.limit[1]);
    if (((sellOrder.volume * mimRate[1]) / mimRate[0]) <= buyOrder.volume){
      volumes[0] = sellOrder.volume;
      volumes[1] = ((buyOrder.volume * mimRate[0]) / mimRate[1]);
    }
    else{
      volumes[0] = ((buyOrder.volume * mimRate[0]) / mimRate[1]);
      volumes[1] = buyOrder.volume;
    }
    return volumes;
  }

  // TODO: Implement
  // Distributes dividends when balance is of sufficient size
  function distDividends()
    private
    returns(bool passes)
  {
    exBalances.closedBalance = 0;
    return true;
  }

  // Move balance from open to closed
  // Eliminate minerPayment from either balance
  function clearBalance(uint minerPayment, uint[2] volumes)
    private
    returns(bool passed)
  {
    exBalances.openBalance = (exBalances.openBalance -
                                  (params.closureFeePerUnit * volumes[0]));
    exBalances.closedBalance = (exBalances.closedBalance -
                                  minerPayment +
                                  (params.closureFeePerUnit * volumes[0]));
    if (exBalances.closedBalance >= params.distBalance){
      distDividends();
    }
    return true;
  }

  // Clean chapter (called when size reaches size to clean)
  function cleanChapter(uint chapter)
    private
    returns(bool cleaned)
  {
    // Clean chapter only if size is appropriate
    if (numsCleared[chapter] < params.cleanSize){
      return false;
    }
    // For all orders
    // If it's a cleared order:
    // Replace it with the next one, and clear the next one
    for (uint i = 0; i < orderBook[chapter].length; i++){
      if (orderBook[chapter][i].volume == 0){
        if (i < orderBook[chapter].length - 1){
          orderBook[chapter][i] = orderBook[chapter][i+1];
          delete orderBook[chapter][i+1];
        }
      }
    }
    orderBook[chapter].length = orderBook[chapter].length - numsCleared[chapter];
    numsCleared[chapter] = 0;
    return true;
  }

  // Checks if POW (nonce) is valid
  // Performs nonce verification (keccak256)
  // Helper for giveMatch
  function isValidPOW(address msgSender, uint chapter, uint index1,
                  uint index2, bytes32 nonce, uint hashVal)
    private
    pure
    returns(bool isValid)
  {
    if (nonce != keccak256(msgSender,
                          (chapter + 110) % 1000,
                          (index1 + 110) % 1000,
                          (index2 + 110) % 1000,
                          (hashVal + 110) % 1000)){
      return false;
    }
    return true;
  }

  // Miners suggest matches with this function
  // Wrapper for isValidMatch and isValidPOW, performs other required functions
  function giveMatch(uint chapter, uint index1, uint index2,
                  bytes32 nonce, uint hashVal)
    public
    payable
    returns(bool isValid)
  {
    // Validate that nonce is equivalent
    // modulo so that cost is constant
    // + 110 so that it's always 3 digits
    // storing all values is impractical
    // hashVal adds security if trade volume is small
    // Helper for giveMatch
    if (! isValidMatch(chapter, index1, index2) ||
        ! isValidPOW(msg.sender, chapter, index1, index2, nonce, hashVal)){
      return false;
    }
    uint[2] memory volumes = getVolumes(chapter, index1, index2);
    // calculate the miner's payment
    uint minerPayment = ((params.minerShare[0] * params.closureFeePerUnit * volumes[0]) /
                          params.minerShare[1]);
    msg.sender.transfer(minerPayment);
    clearBalance(minerPayment, volumes);
    alertTraders(chapter, index1, index2, volumes);
    clearTrade(chapter, index1, index2, volumes);
    cleanChapter(chapter);
    return true;
  }

  // Allows traders to place orders
  function placeOrder(bool buyETH, uint volume, uint limit0, uint limit1,
                      address ethAddress, string firstAddress,
                      string otherAddress, uint chapter)
    public
    payable
    returns(bool accepted)
  {
    require(volume > 0);
    require(limit0 > 0 && limit1 > 0);
    // Charge according to ether transaction vol
    if (buyETH){
      require((limit1 * volume * msg.value) > limit0 * params.closureFeePerUnit);
    }
    else{
      require((limit0 * volume * msg.value) > limit1 * params.closureFeePerUnit);
    }
    uint[2] memory limit;
    limit[0] = limit0;
    limit[1] = limit1;
    orderBook[chapter].push(Order(buyETH, volume, limit));
    addressBook[chapter].push(AddressInfo(ethAddress, firstAddress, otherAddress));
    return true;
  }

  // Allows traders to cancel orders
  function cancelOrder(uint chapter, uint index)
    public
    returns(bool accepted)
  {
    //TODO: Account for gas price (maybe, if necessary)
    // Valid indices
    // require(chapter < orderBook.length);
    require(index < orderBook[chapter].length);
    // Can't cancel other people's orders
    require(msg.sender == addressBook[chapter][index].ethAddress);
    // uint volume = orderBook[chapter][index].volume;
    uint limit;
    // Refund according to ether transaction vol
    if (orderBook[chapter][index].buyETH){
      limit = orderBook[chapter][index].limit[0];
    }
    else{
      limit = orderBook[chapter][index].limit[1];
    }
    uint cancelPayment = limit * (params.closureFeePerUnit - params.cancelFeePerUnit);
    msg.sender.transfer(cancelPayment);
    // Update exBalances
    exBalances.openBalance = (exBalances.openBalance -
                                (limit * params.closureFeePerUnit));
    exBalances.closedBalance = (exBalances.closedBalance +
                                  (limit * params.cancelFeePerUnit));
    delete orderBook[chapter][index];
    delete addressBook[chapter][index];
    numsCleared[chapter] += 1;
    cleanChapter(chapter);
    return true;
  }
}
