pragma solidity ^0.4.18;

contract Broadcast{
  address initiator;
  address participant;
  // Secret hash encrypted with participant's pubkey
  bytes32 secretHash;
  // Contract and contract transaction
  bytes32 contractCode;
  bytes32 contractTransaction;

  modifier onlyBy(address _account)
  {
    require(msg.sender == _account);
    _;
  }

  function Broadcast(address _initiator, address _participant)
    public
  {
    initiator = _initiator;
    participant = _participant;
  }

  struct SwapInfo {
    bytes32 _secretHash;
    bytes32 _contractCode;
    bytes32 _contractTransaction;
  }

  function pushSwapInfo(bytes32 _secretHash, bytes32 _contractCode,
                        bytes32 _contractTransaction)
    public
    onlyBy(initiator)
  {
    secretHash = _secretHash;
    contractCode = _contractCode;
    contractTransaction = _contractTransaction;
    participant.call.gas(0).value(0)(
      SwapInfo(secretHash, contractCode, contractTransaction)
    );
  }
}
