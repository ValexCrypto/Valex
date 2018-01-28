pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';

/**
 * @title ValexToken
 */
contract ValexToken is MintableToken {

  string public constant name = "Valex Token"; // solium-disable-line uppercase
  string public constant symbol = "VLX"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase

}
