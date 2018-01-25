pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './ExchangeStructs.sol';
/// @title Exchange
/// @author Karim Helmy

// Primary contract: Describes functions of exchange
contract Exchange is ExchangeStructs {
  // TODO: Make all operations safe
  using SafeMath for uint;

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
                    uint cleanSize, uint minerShare, uint distBalance)
    public
  {
    // Initialize parameters books
    setParams(closureFeePerUnit, cancelFeePerUnit,
              cleanSize, minerShare, distBalance);
    // Initialize order books
    setBooks();
    // Initialize numsCleared[0] as zero
    numsCleared.push(0);
    return;
  }

  // Initializes orderBook and addressBook
  // Only used in constructor
  function setBooks()
    private
    returns(bool passes)
  {
    orderBook[0].push(Order(false,0,0,0));
    addressBook[0].push(AddressInfo(address(0),"",""));
    return true;
  }

  // Init the params struct, which contains the bulk of exchange's parameters
  // Only used in constructor
  function setParams(uint closureFeePerUnit, uint cancelFeePerUnit,
                    uint cleanSize, uint minerShare, uint distBalance)
    internal
  {
    params.closureFeePerUnit = closureFeePerUnit;
    params.cancelFeePerUnit = cancelFeePerUnit;
    params.cleanSize = cleanSize;
    params.minerShare = minerShare;
    params.distBalance = distBalance;
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
  function calcRateAndVol(uint chapter, uint index1, uint index2)
    private
    view
    returns (uint mimRate, uint ethVol)
  {
    // check edge cases
    if (! checkMatchEdges(chapter, index1, index2)) {
      return (0,0);
    }
    // which order is buying and selling ETH?
    // buy-sell copy1
    uint buyIndex;
    uint sellIndex;
    if (orderBook[chapter][index1].buyETH) {
      buyIndex = index1;
      sellIndex = index2;
    } else{
      buyIndex = index2;
      sellIndex = index1;
    }
    // shorthand for buy and sell orders
    Order memory buyOrder = orderBook[chapter][buyIndex];
    Order memory sellOrder = orderBook[chapter][sellIndex];

    // Non-contradictory limits
    if (buyOrder.limit < sellOrder.limit) {
      return (0, 0);
    }
    // Meet in middle rate
    // mimRate
    mimRate = (buyOrder.limit + sellOrder.limit) / 2;
    // Volumes comparable
    if (buyOrder.volume * PRECISION > sellOrder.volume * mimRate) {
      if (buyOrder.minVolume * PRECISION > sellOrder.volume * mimRate) {
        return (0, 0);
      }
      return (mimRate, sellOrder.volume * mimRate);
    }
    if (sellOrder.volume * mimRate > buyOrder.volume * PRECISION ) {
      if (sellOrder.minVolume * mimRate > buyOrder.volume * PRECISION) {
        return (0, 0);
      }
    }
    return (mimRate, buyOrder.volume);
  }

  // Clears closed trade, reenters into order book if incomplete
  function clearTrade(uint chapter, uint index1, uint index2,
                      uint mimRate, uint ethVol)
    private
  {
    // which order is buying and selling ETH?
    // buy-sell copy1
    uint buyIndex;
    uint sellIndex;
    if (orderBook[chapter][index1].buyETH) {
      buyIndex = index1;
      sellIndex = index2;
    } else{
      buyIndex = index2;
      sellIndex = index1;
    }
    if (orderBook[chapter][buyIndex].volume == ethVol) {
      numsCleared[chapter] += 1;
    }
    if (orderBook[chapter][buyIndex].minVolume < ethVol) {
      orderBook[chapter][buyIndex].minVolume = 0;
    } else{
      orderBook[chapter][buyIndex].minVolume -= ethVol;
    }
    orderBook[chapter][buyIndex].volume -= ethVol;
    if (orderBook[chapter][sellIndex].volume == (ethVol * mimRate / PRECISION)) {
      numsCleared[chapter] += 1;
    }
    if (orderBook[chapter][sellIndex].minVolume < (ethVol * mimRate / PRECISION)) {
      orderBook[chapter][sellIndex].minVolume = 0;
    } else{
      orderBook[chapter][sellIndex].minVolume -= (ethVol * mimRate / PRECISION);
    }
    orderBook[chapter][sellIndex].volume -= ethVol * mimRate / PRECISION;
  }

  // Adds trade to log, for traders to note
  // http://solidity.readthedocs.io/en/latest/contracts.html?highlight=events#events
  function alertTraders(uint chapter, uint index1, uint index2, uint mimRate, uint ethVol)
    private
  {
    TradeInfo(
      addressBook[chapter][index1].ethAddress, //ethAddress1,
      addressBook[chapter][index2].ethAddress, //ethAddress2,
      addressBook[chapter][index1].firstAddress, //firstAddress1,
      addressBook[chapter][index2].firstAddress, //firstAddress2,
      addressBook[chapter][index1].otherAddress, //otherAddress1,
      addressBook[chapter][index2].otherAddress, // otherAddress2,
      mimRate,
      ethVol
      );
  }

  // Clears exBalances.closedBalance
  // ValexToken ovverride distributes dividends when balance is of sufficient size
  function distDividends()
    internal
  {
    exBalances.closedBalance = 0;
  }

  // Move balance from open to closed
  // Eliminate minerPayment from either balance
  function clearBalance(uint minerPayment, uint ethVol)
    private
  {
    exBalances.openBalance = (exBalances.openBalance -
                                  (params.closureFeePerUnit * ethVol));
    exBalances.closedBalance = (exBalances.closedBalance -
                                  minerPayment +
                                  (params.closureFeePerUnit * ethVol));
    if (exBalances.closedBalance >= params.distBalance) {
      distDividends();
    }
  }

  // Clean chapter (called when size reaches size to clean)
  function cleanChapter(uint chapter)
    private
    returns(bool cleaned)
  {
    // Clean chapter only if size is appropriate
    if (numsCleared[chapter] < params.cleanSize) {
      return false;
    }
    // For all orders
    // If it's a cleared order:
    // Replace it with the next one, and clear the next one
    for (uint i = 1; i < orderBook[chapter].length; i++) {
      if (orderBook[chapter][i].volume == 0) {
        if (i < orderBook[chapter].length - 1) {
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
    if (nonce != keccak256(msgSender, chapter, index1, index2, hashVal)) {
      return false;
    }
    return true;
  }

  // Miners suggest matches with this function
  // Wrapper for calcRateAndVol and isValidPOW, performs other required functions
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
    if (! isValidPOW(msg.sender, chapter, index1, index2, nonce, hashVal)) {
      return false;
    }
    var (mimRate, ethVol) = calcRateAndVol(chapter, index1, index2);
    if (ethVol == 0) {
      return false;
    }
    // calculate the miner's payment
    uint minerPayment = ((params.minerShare * params.closureFeePerUnit * ethVol) /
                          PRECISION);
    msg.sender.transfer(minerPayment);
    clearBalance(minerPayment, ethVol);
    alertTraders(chapter, index1, index2, mimRate, ethVol);
    clearTrade(chapter, index1, index2, mimRate, ethVol);
    cleanChapter(chapter);
    return true;
  }

  // Allows traders to place orders
  function placeOrder(bool buyETH, uint volume, uint minVolume, uint limit,
                      address ethAddress, string firstAddress,
                      string otherAddress, uint chapter)
    public
    payable
    returns(bool accepted)
  {
    require(volume > 0);
    require(minVolume > 0);
    require(volume >= minVolume);
    require(limit > 0);
    // TODO: NEXT VERSION: Charge according to transaction vol for generic currencies
    // Use market rate
    if (buyETH) {
      require(limit * msg.value >= volume * params.closureFeePerUnit);
    } else{
      require(msg.value >= volume * params.closureFeePerUnit);
    }
    require(orderBook[chapter].length > 0);
    orderBook[chapter].push(Order(buyETH, volume, minVolume, limit));
    addressBook[chapter].push(AddressInfo(ethAddress, firstAddress, otherAddress));
    return true;
  }

  // Allows traders to cancel orders
  function cancelOrder(uint chapter, uint index)
    public
    returns(bool accepted)
  {
    require(index < orderBook[chapter].length);
    // Can't cancel other people's orders
    require(msg.sender == addressBook[chapter][index].ethAddress);
    // uint volume = orderBook[chapter][index].volume;
    uint limit = orderBook[chapter][index].limit;
    uint volume = orderBook[chapter][index].volume;
    // TODO: NEXT VERSION: Refund according to transaction vol for generic currencies
    // Use market rate
    // Refund according to ether transaction volume
    if (orderBook[chapter][index].buyETH) {
      msg.sender.transfer(volume * (params.closureFeePerUnit - params.cancelFeePerUnit) / limit);
    } else{
      msg.sender.transfer(volume * (params.closureFeePerUnit - params.cancelFeePerUnit) / limit);
    }
    delete orderBook[chapter][index];
    delete addressBook[chapter][index];
    numsCleared[chapter] += 1;
    cleanChapter(chapter);
    return true;
  }
}
