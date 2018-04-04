pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './ExchangeStructs.sol';
/// @title Exchange
/// @author Karim Helmy

// Primary contract: Describes functions of exchange
contract Exchange is ExchangeStructs {
  // TODO: Make all operations safe
  using SafeMath for uint;

  // SECTION: Declaring/initializing variables
  uint public PRECISION = 10 ** 18;

  // separate out the open balance (includes unclosed fees, gas fees),
  // which will be distributed between miners, the exchange, and traders,
  // from closed balance, which belongs to the exchange
  uint public openBalance = 0;

  Parameters public params;

  // separate chapters for different currency pairs
  // that's why they're 2D
  /*
  * Web3 can't properly handle structs.
  * Ethers.js can only handle them under experimental version.
  * Therefore, the old orderBook and adressBook pattern won't work.
  * ¯\_(ツ)_/¯
  */
  // separate chapters for different currency pairs
  // that's why they're 2D
  mapping (uint => bool[]) public buyBook;
  mapping (uint => uint[]) public volBook;
  mapping (uint => uint[]) public minVolBook;
  mapping (uint => uint[]) public limitBook;

  mapping (uint => address[]) public ethAddressBook;
  mapping (uint => bytes32[2][]) public firstAddressBook;
  mapping (uint => bytes32[2][]) public secondAddressBook;

  // Numbers of orders that have been closed are kept here
  uint[] numsCleared;

  address public owner = msg.sender;

  // SECTION: Permissions
  // Modified: http://solidity.readthedocs.io/en/v0.3.1/common-patterns.html
  modifier onlyBy(address _account)
  {
    require(msg.sender == _account);
    _;
  }

  function changeOwner(address _newOwner)
    public
    onlyBy(owner)
  {
    owner = _newOwner;
  }

  // SECTION: Constructor and helpers
  // Constructor for contract
  function Exchange(uint closureFee, uint cancelFee,
                    uint cleanSize, uint minerShare,
                    bytes32 difficulty)
    public
  {
    // Initialize parameters books
    setParams(closureFee, cancelFee,
              cleanSize, minerShare, difficulty);
    // Initialize order books
    addChapter(0);
    return;
  }

  /*
  * Initializes order book and address book for chapter
  * Only used in constructor
  * Pushes "genesis order" to chapter
  * ONLY USE FOR MOST RECENT CHAPTER + 1
  */
  function addChapter(uint chapter)
    public
    onlyBy(owner)
  {
    buyBook[chapter].push(false);
    volBook[chapter].push(0);
    minVolBook[chapter].push(0);
    limitBook[chapter].push(0);

    ethAddressBook[chapter].push(address(0));
    firstAddressBook[chapter].push([bytes32(0), bytes32(0)]);
    secondAddressBook[chapter].push([bytes32(0), bytes32(0)]);
    // Initialize numsCleared[chapter] as zero
    numsCleared.push(0);
  }

  // Init the params struct, which contains the bulk of exchange's parameters
  // Only used in constructor
  function setParams(uint closureFee, uint cancelFee,
                    uint cleanSize, uint minerShare,
                    bytes32 difficulty)
    internal
  {
    params.closureFee = closureFee;
    params.cancelFee = cancelFee;
    params.cleanSize = cleanSize;
    params.minerShare = minerShare;
    params.difficulty = difficulty;
  }

  // SECTION: Getters
  // Get chapter from order book
  function getOrderChapter(uint chapter)
    external
    view
    returns(bool[] buyChapter, uint[] volChapter,
            uint[] minVolChapter, uint[] limitChapter)
  {
    return(buyBook[chapter], volBook[chapter],
          minVolBook[chapter], limitBook[chapter]);
  }

  /*
  * Wish I could've bundled these.
  * For some reason, get a bug when firstAddressChapter and secondAddressChapter are together.
  * Suspect it has something to do with returning dynamic arrays of fixed size arrays
  */
  // Get chapter from ethAddressBook
  function getETHAddressChapter(uint chapter)
    external
    view
    returns(address[] ethAddressChapter)
  {
    return(ethAddressBook[chapter]);
  }

  // Get chapter from firstAddressBook
  function getFirstAddressChapter(uint chapter)
    external
    view
    returns(bytes32[2][] firstAddressChapter)
  {
    return(firstAddressBook[chapter]);
  }

  // Get chapter from secondAddressBook
  function getSecondAddressChapter(uint chapter)
    external
    view
    returns(bytes32[2][] secondAddressChapter)
  {
    return(secondAddressBook[chapter]);
  }

  // SECTION: Core functionality
  // Checks edge cases for match verification
  function checkMatchEdges(uint chapter, uint index1, uint index2)
    private
    view
    returns(bool passes)
  {
    // valid indices
    require(index1 < buyBook[chapter].length);
    require(index2 < buyBook[chapter].length);
    //One buy order and one sell order
    require(buyBook[chapter][index1] != buyBook[chapter][index2]);
    //Non-empty order
    require(volBook[chapter][index1] != 0);
    require(volBook[chapter][index2] != 0);
    // All edge cases work!
    return true;
  }

  // verifies that match is valid
  function calcRateAndVol(uint chapter, uint index1, uint index2)
    public
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
    if (buyBook[chapter][index1]) {
      buyIndex = index1;
      sellIndex = index2;
    } else{
      buyIndex = index2;
      sellIndex = index1;
    }
    // shorthand for buy and sell orders
    Order memory buyOrder = Order(true, volBook[chapter][buyIndex],
                                  minVolBook[chapter][buyIndex],
                                  limitBook[chapter][buyIndex]);
    Order memory sellOrder = Order(false, volBook[chapter][sellIndex],
                                  minVolBook[chapter][sellIndex],
                                  limitBook[chapter][sellIndex]);

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
    if (buyBook[chapter][index1]) {
      buyIndex = index1;
      sellIndex = index2;
    } else{
      buyIndex = index2;
      sellIndex = index1;
    }
    if (volBook[chapter][buyIndex] == ethVol) {
      numsCleared[chapter] += 1;
    }
    if (minVolBook[chapter][buyIndex] < ethVol) {
      minVolBook[chapter][buyIndex] = 0;
    } else{
      minVolBook[chapter][buyIndex] -= ethVol;
    }
    volBook[chapter][buyIndex] -= ethVol;
    if (volBook[chapter][sellIndex] == (ethVol * mimRate / PRECISION)) {
      numsCleared[chapter] += 1;
    }
    if (minVolBook[chapter][sellIndex] < (ethVol * mimRate / PRECISION)) {
      minVolBook[chapter][sellIndex] = 0;
    } else{
      minVolBook[chapter][sellIndex] -= (ethVol * mimRate / PRECISION);
    }
    volBook[chapter][sellIndex] -= ethVol * mimRate / PRECISION;
  }

  // Adds trade to log, for traders to note
  // http://solidity.readthedocs.io/en/latest/contracts.html?highlight=events#events
  function alertTraders(uint chapter, uint index1, uint index2, uint mimRate, uint ethVol)
    private
  {
    TradeInfo(
      ethAddressBook[chapter][index1], //ethAddress1,
      ethAddressBook[chapter][index2], //ethAddress2,
      firstAddressBook[chapter][index1], //firstAddress1,
      firstAddressBook[chapter][index2], //firstAddress2,
      secondAddressBook[chapter][index1], //otherAddress1,
      secondAddressBook[chapter][index2], // otherAddress2,
      mimRate,
      ethVol
      );
  }

  // Move balance from open to closed
  function clearBalance(uint ethVol, uint buyLimit)
    private
  {
    openBalance -= (params.closureFee * ethVol) / PRECISION;
    openBalance -= (params.closureFee * ethVol * buyLimit) / (PRECISION * PRECISION);
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
    for (uint i = 1; i < buyBook[chapter].length; i++) {
      if (volBook[chapter][i] == 0) {
        if (i < buyBook[chapter].length - 1) {
          buyBook[chapter][i] = buyBook[chapter][i+1];
          volBook[chapter][i] = volBook[chapter][i+1];
          minVolBook[chapter][i] = minVolBook[chapter][i+1];
          limitBook[chapter][i] = limitBook[chapter][i+1];

          ethAddressBook[chapter][i] = ethAddressBook[chapter][i+1];
          firstAddressBook[chapter][i] = firstAddressBook[chapter][i+1];
          secondAddressBook[chapter][i] = secondAddressBook[chapter][i+1];

          delete buyBook[chapter][i+1];
          delete volBook[chapter][i+1];
          delete minVolBook[chapter][i+1];
          delete limitBook[chapter][i+1];

          delete ethAddressBook[chapter][i+1];
          delete firstAddressBook[chapter][i+1];
          delete secondAddressBook[chapter][i+1];
        }
      }
    }
    buyBook[chapter].length = buyBook[chapter].length - numsCleared[chapter];
    volBook[chapter].length = volBook[chapter].length - numsCleared[chapter];
    minVolBook[chapter].length = minVolBook[chapter].length - numsCleared[chapter];
    limitBook[chapter].length = limitBook[chapter].length - numsCleared[chapter];

    ethAddressBook[chapter].length = ethAddressBook[chapter].length - numsCleared[chapter];
    firstAddressBook[chapter].length = firstAddressBook[chapter].length - numsCleared[chapter];
    secondAddressBook[chapter].length = secondAddressBook[chapter].length - numsCleared[chapter];

    numsCleared[chapter] = 0;
    return true;
  }

  // Checks if POW (nonce) is valid
  // Performs nonce verification (keccak256)
  // Helper for giveMatch
  function isValidPOW(address depositAddress, uint chapter, uint index1,
                      uint index2, uint nonce)
    private
    view
    returns(bool isValid)
  {
    if (params.difficulty < keccak256(depositAddress, chapter, index1, index2, nonce)) {
      return false;
    }
    return true;
  }

  // Function to pay the miner what's due
  function payMiner(address depositAddress, uint ethVol)
    private
  {
    // Calculate the miner's payment
    uint minerPayment = ((params.minerShare * params.closureFee * ethVol) /
                          (PRECISION * PRECISION));
    // Pay the miner
    depositAddress.transfer(minerPayment);
  }

  // Miners suggest matches with this function
  // Wrapper for calcRateAndVol and isValidPOW, performs other required functions
  function giveMatch(address depositAddress, uint chapter,
                    uint index1, uint index2, uint nonce)
    public
    returns(bool isValid)
  {
    // Validate nonce
    require(isValidPOW(depositAddress, chapter, index1, index2, nonce));
    var (mimRate, ethVol) = calcRateAndVol(chapter, index1, index2);
    require(ethVol > 0);
    // which order is buying and selling ETH?
    // buy-sell copy1
    uint buyIndex;
    uint sellIndex;
    if (buyBook[chapter][index1]) {
      buyIndex = index1;
      sellIndex = index2;
    } else{
      buyIndex = index2;
      sellIndex = index1;
    }
    payMiner(depositAddress, ethVol);
    clearBalance(ethVol, limitBook[chapter][buyIndex]);
    alertTraders(chapter, index1, index2, mimRate, ethVol);
    clearTrade(chapter, index1, index2, mimRate, ethVol);
    cleanChapter(chapter);
    return true;
  }

  // Allows traders to place orders
  function placeOrder(bool buyETH, uint volume, uint minVolume, uint limit,
                      address ethAddress, bytes32[2] firstAddress,
                      bytes32[2] otherAddress, uint chapter)
    public
    payable
    returns(bool accepted)
  {
    require(volume > 0);
    require(minVolume > 0);
    require(volume >= minVolume);
    require(limit > 0);
    // TODO: NEXT VERSION: Charge according to transaction vol with fixed fees for generic currencies
    // TODO: NEXT VERSION: Instant refunds (prototype code below)
    if (buyETH) {
      require(limit * msg.value >= volume * params.closureFee);
      openBalance += volume * params.closureFee * limit / (PRECISION * PRECISION);
      //msg.sender.transfer((limit * msg.value) - (volume * params.closureFee));
    } else{
      require(msg.value >= volume * params.closureFee / PRECISION);
      openBalance += volume * params.closureFee / PRECISION;
      //msg.sender.transfer(msg.value - (volume * params.closureFee / PRECISION));
    }
    require(buyBook[chapter].length > 0);

    buyBook[chapter].push(buyETH);
    volBook[chapter].push(volume);
    minVolBook[chapter].push(minVolume);
    limitBook[chapter].push(limit);

    ethAddressBook[chapter].push(ethAddress);
    firstAddressBook[chapter].push(firstAddress);
    secondAddressBook[chapter].push(otherAddress);
    return true;
  }

  // Allows traders to cancel orders
  function cancelOrder(uint chapter, uint index)
    public
    returns(bool accepted)
  {
    require(index < buyBook[chapter].length);
    // Can't cancel other people's orders
    require(msg.sender == ethAddressBook[chapter][index]);

    uint limit = limitBook[chapter][index];
    uint volume = volBook[chapter][index];

    // TODO: NEXT VERSION: Refund according to fixed fees for generic currencies
    // Refund according to ether transaction volume
    if (buyBook[chapter][index]) {
      msg.sender.transfer(volume * (params.closureFee - params.cancelFee) / limit);
    } else{
      msg.sender.transfer(volume * (params.closureFee - params.cancelFee) / limit);
    }
    delete buyBook[chapter][index];
    delete volBook[chapter][index];
    delete minVolBook[chapter][index];
    delete limitBook[chapter][index];

    delete ethAddressBook[chapter][index];
    delete firstAddressBook[chapter][index];
    delete secondAddressBook[chapter][index];

    numsCleared[chapter] += 1;
    cleanChapter(chapter);
    return true;
  }

  // TODO: Fixed fees per unit, rather than using dynamic exchange rate
  // Different fees for buy/sell
  // can be done with mapping (uint => mapping (bool => uint))
  // Allows us to use multiple currencies (not just Ether trading pairs)

  // TODO: NEXT VERSION: Add KYC whitelist
}
