pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
import './Exchange.sol';


/// @title ValexPreferred
/// @author Karim Helmy

// Parts sourced from https://github.com/bokkypoobah/Tokens/blob/master/contracts/FixedSupplyToken.sol

// ----------------------------------------------------------------------------
// 'VLP' 'Valex Preferred Token' token contract
//
// Symbol      : VLP
// Name        : Valex Preferred Token
// Total supply: 1,000,000.000000000000000000
// Decimals    : 18
//
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract ValexPreferredToken is StandardToken, Exchange {
    using SafeMath for uint;

    string public name = "Valex Preferred Token";
    string public symbol = "VLP";
    uint8 public decimals = 18;

    uint256 public initialSupply = 10000 * (10 ** uint256(decimals));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     * @dev Initializes token to have same parameters as exchange
     */
    function ValexPreferred(uint closureFeePerUnit, uint cancelFeePerUnit,
                      uint cleanSize, uint minershare, uint distBalance)
      Exchange(closureFeePerUnit, cancelFeePerUnit,
              cleanSize, minershare, distBalance)
      public
    {
      totalSupply = initialSupply;
      balances[msg.sender] = initialSupply;
    }

    // Distributes dividends when balance is of sufficient size
    function distDividends()
      internal
    {
      //TODO: Implement distribution
      Exchange.distDividends();
    }

    //TODO: Implement voting/parameter modification

}
