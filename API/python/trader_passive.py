### Trader's passive functions

def setUpBroadcast(w3):
    broadcastFile = "./build/contracts/Broadcast.json"
    broadcastABI = open(broadcastFile, "r").read()
    Broadcast = w3.eth.contract(abi = exchangeABI)
    return Broadcast

def connectToBroadcast(Broadcast, broadcastAddress):
    broadcast = Broadcast(address = broadcastAddress)
    return broadcast

def pushSwapInfo(broadcast, encSecretHash, contractCode, contractTransaction):
    broadcast.pushSwapInfo(encSecretHash, contractCode, contractTransaction)
    return
