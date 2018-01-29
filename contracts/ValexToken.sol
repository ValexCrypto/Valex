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
    mapping (uint => uint) distBalanceFreqs;

    // Thresholds to be met for each parameter adjustment
    // TODO: add initialization for thresholds
    // TODO: add meta-voting for thresholds (will always require 51%)
    Parameters public thresholds;

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     * @dev Initializes token to have same parameters as exchange
     */
    function ValexToken(uint closureFeePerUnit, uint cancelFeePerUnit,
                      uint cleanSize, uint minershare, uint distBalance)
      Exchange(closureFeePerUnit, cancelFeePerUnit,
              cleanSize, minershare, distBalance)
      public
    {
      totalSupply_ = initialSupply;
      balances[msg.sender] = initialSupply;
    }

    // Distributes dividends when balance is of sufficient size
    function distDividends()
      internal
    {
      //TODO: Implement distribution
      Exchange.distDividends();
    }

    // TODO: Implement voting/parameter modification
    // Vote for a closure fee
    // Adjust closure fee if threshold met
    // voting copy3
    function voteClosureFee(uint desiredParam)
      public
    {
      require(balances[msg.sender] > 0);
      require(desiredParam > 0);
      if (voteBook[msg.sender].closureFeePerUnit > 0){
        closureFeeFreqs[voteBook[msg.sender].closureFeePerUnit] -= balances[msg.sender];
      }
      voteBook[msg.sender].closureFeePerUnit = desiredParam;
      closureFeeFreqs[desiredParam] += balances[msg.sender];
      if (closureFeeFreqs[desiredParam] > thresholds.closureFeePerUnit){
        params.closureFeePerUnit = desiredParam;
      }
    }

    // TODO: Implement adding/removing chapters

}
