pragma solidity ^0.4.16;

import 'zeppelin-solidity/contracts/math/SafeMath.sol';
import 'zeppelin-solidity/contracts/token/StandardToken.sol';
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

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract ValexToken is StandardToken, Exchange {
    using SafeMath for uint;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;

    string public name = "Valex Token";
    string public symbol = "VLX";
    uint8 public decimals = 18;

    uint256 public initialSupply = 10000 * (10 ** uint256(decimals));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
     // TODO: Make the constructor inherit from Exchange's
    function ValexToken() public {
      totalSupply = initialSupply;
      balances[msg.sender] = initialSupply;
    }

}
