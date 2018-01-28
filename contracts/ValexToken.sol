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

contract ValexToken is Exchange, MintableToken {
    using SafeMath for uint;

    string public name = "Valex Token";
    string public symbol = "VLX";
    uint8 public decimals = 18;

    // uint256 public initialSupply = 10000 * (10 ** uint256(decimals));

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

    //TODO: Implement voting/parameter modification

}
