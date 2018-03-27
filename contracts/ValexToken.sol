pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import './Exchange.sol';


/// @title ValexToken
/// @author Karim Helmy

// Parts sourced from https://github.com/bokkypoobah/Tokens/blob/master/contracts/FixedSupplyToken.sol

// ----------------------------------------------------------------------------
// 'VLX' 'Valex Token' token contract
//
// Symbol      : VLX
// Name        : Valex Token
// Total supply: 1,000,000.000000000000000000
// Decimals    : 18
//
// ----------------------------------------------------------------------------

contract ValexToken is Exchange, StandardToken {
    using SafeMath for uint;

    string public name = "Valex Token";
    string public symbol = "VLX";
    uint8 public decimals = 18;

    uint256 public initialSupply = 10000 * (10 ** uint256(decimals));

    // Voting mappings
    // Holds what every address has voted for
    mapping (address => Parameters) voteBook;
    // Hold frequencies of what addresses have voted for (in coin-votes)
    mapping (uint => uint) closureFeeFreqs;
    mapping (uint => uint) cancelFeeFreqs;
    mapping (uint => uint) cleanSizeFreqs;
    mapping (uint => uint) minerShareFreqs;

    // Threshold to be met for each parameter adjustment
    uint256 public threshold = (initialSupply / 100) * 51;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
      BasicToken.transfer(_to, _value);
      closureFeeFreqs[voteBook[msg.sender].closureFee] -= _value;
      cancelFeeFreqs[voteBook[msg.sender].cancelFee] -= _value;
      cleanSizeFreqs[voteBook[msg.sender].cleanSize] -= _value;
      minerShareFreqs[voteBook[msg.sender].minerShare] -= _value;
      return true;
    }

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
      StandardToken.transferFrom(_from, _to, _value);
      closureFeeFreqs[voteBook[_from].closureFee] -= _value;
      cancelFeeFreqs[voteBook[_from].cancelFee] -= _value;
      cleanSizeFreqs[voteBook[_from].cleanSize] -= _value;
      minerShareFreqs[voteBook[_from].minerShare] -= _value;
      return true;
    }

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     * @dev Initializes token to have same parameters as exchange
     */
    function ValexToken(uint closureFee, uint cancelFee,
                      uint cleanSize, uint minershare,
                      bytes32 difficulty)
      Exchange(closureFee, cancelFee,
              cleanSize, minershare, difficulty)
      public
    {
      totalSupply_ = initialSupply;
      balances[msg.sender] = initialSupply;
    }

    // Distributes dividends when balance is of sufficient size
    function distDividends()
      internal
    {
      // TODO: Implement distribution
      Exchange.distDividends();
    }

    // Voting functions for various parameters
    // Solidity doesn't allow any meaningful abstraction
    // Adjust relevant parameter if threshold met

    // voting copy3
    function voteClosureFee(uint desiredParam)
      public
    {
      require(balances[msg.sender] > 0);
      require(desiredParam > 0);
      if (voteBook[msg.sender].closureFee > 0){
        closureFeeFreqs[voteBook[msg.sender].closureFee] -= balances[msg.sender];
      }
      voteBook[msg.sender].closureFee = desiredParam;
      closureFeeFreqs[desiredParam] += balances[msg.sender];
      if (closureFeeFreqs[desiredParam] > threshold){
        params.closureFee = desiredParam;
      }
    }

    // voting copy3
    function voteCancelFee(uint desiredParam)
      public
    {
      require(balances[msg.sender] > 0);
      require(desiredParam > 0);
      if (voteBook[msg.sender].cancelFee > 0){
        cancelFeeFreqs[voteBook[msg.sender].cancelFee] -= balances[msg.sender];
      }
      voteBook[msg.sender].cancelFee = desiredParam;
      cancelFeeFreqs[desiredParam] += balances[msg.sender];
      if (cancelFeeFreqs[desiredParam] > threshold){
        params.cancelFee = desiredParam;
      }
    }

    // voting copy3
    function voteCleanSize(uint desiredParam)
      public
    {
      require(balances[msg.sender] > 0);
      require(desiredParam > 0);
      if (voteBook[msg.sender].cleanSize > 0){
        cleanSizeFreqs[voteBook[msg.sender].cleanSize] -= balances[msg.sender];
      }
      voteBook[msg.sender].cleanSize = desiredParam;
      cleanSizeFreqs[desiredParam] += balances[msg.sender];
      if (cleanSizeFreqs[desiredParam] > threshold){
        params.cleanSize = desiredParam;
      }
    }

    // voting copy3
    function voteMinerShare(uint desiredParam)
      public
    {
      require(balances[msg.sender] > 0);
      require(desiredParam > 0);
      if (voteBook[msg.sender].minerShare > 0){
        minerShareFreqs[voteBook[msg.sender].minerShare] -= balances[msg.sender];
      }
      voteBook[msg.sender].minerShare = desiredParam;
      minerShareFreqs[desiredParam] += balances[msg.sender];
      if (minerShareFreqs[desiredParam] > threshold){
        params.minerShare = desiredParam;
      }
    }

    // TODO: Implement adding/removing chapters

    // TODO: NEXT VERSION: Add vote transferring

}
