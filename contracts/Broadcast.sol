pragma solidity ^0.4.18;

contract Broadcast{
  address initiator;
  address participant;
  // Secret hash encrypted with participant's pubkey
  bytes32 encSecretHash;
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
    bytes32 _encSecretHash;
    bytes32 _contractCode;
    bytes32 _contractTransaction;
  }

  function pushSwapInfo(bytes32 _encSecretHash, bytes32 _contractCode,
                        bytes32 _contractTransaction)
    public
    onlyBy(initiator)
  {
    encSecretHash = _encSecretHash;
    contractCode = _contractCode;
    contractTransaction = _contractTransaction;
    participant.call.gas(0).value(0)(
      SwapInfo(encSecretHash, contractCode, contractTransaction)
    );
  }
}
