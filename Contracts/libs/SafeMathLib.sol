pragma solidity ^0.4.17;

// from:
// https://github.com/aragon/zeppelin-solidity/blob/master/contracts/SafeMathLib.sol

library SafeMathLib {
  function times(uint a, uint b) pure public returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) pure public returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) pure public returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}
