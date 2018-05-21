import secrets
import time
import hashlib

from shared import *
from shared_local import *
from trader_active import *
from trader_passive import *
from web3 import eth, Web3

# struct TradeInfo {
# address counterEthAddress;
# bytes32 counterFirstAddress;
# bytes32 counterSecondAddress;
# // alpha volume and rate of exchange
# uint mimRate;
# uint alphaVol;
# }

#  struct SwapInfo {
#     bytes32 _secretHash;
#     bytes32 _contractCode;
#     bytes32 _contractTransaction;
#  }

def placeOrder(buyAlpha, volume, minVolume, limit, ethAddress, firstAddress,
                otherAddress, trading_pair):
    placeOrder_back(exchange, buyAlpha, volume, minVolume, limit,
                    ethAddress, firstAddress, otherAddress, trading_pair)
    filled = False
    while not filled:
        time.sleep(5)
        filled, tradeInfoRaw = checkMessage(exchangeAddress, ethAddress)
    tradeInfo = processInfo(tradeInfoRaw)
    if buyAlpha: return initiatorSequence(ethAddress, tradeInfo)
    else: return participantSequence(ethAddress, tradeInfo)
    return

def initiatorSequence(ethAddress, tradeInfo):
    sec_key = hex(secrets.randbelow(rand_cap))
    sec_hash = hashlib.sha256(bytes(sec_key, "utf8"))
    initiateAlpha(ethAddress, trading_pair, tradeInfo)
    counterEthAddress = tradeInfo[0]
    messageInfo = initiateAlpha(ethAddress, trading_pair, tradeInfo)
    # TODO: message the participant with secretHash, contractCode, contract
    initiateBeta(ethAddress, trading_pair, tradeInfo, messageInfo)
    return

def participantSequence(ethAddress, tradeInfo):
    counterEthAddress = tradeInfo[0]
    contacted = False
    while not contacted:
        time.sleep(5)
        contacted, messageInfoRaw = checkMessage(counterEthAddress, ethAddress)
    messageInfo = processInfo(messageInfoRaw)
    participateBeta(ethAddress, trading_pair, tradeInfo, messageInfo)
    participateAlpha(ethAddress, trading_pair, tradeInfo, messageInfo)
    return

def checkMessage(fromAddress, toAddress):
    block = eth.getBlock("latest")
    if block.transactions == None: return (False, None)
    for t in block.transactions:
        if (t.from == fromAddress) and (t.to == toAddress):
            return (True, t.input)
    return (False, None)

# TODO: Parse Ethereum message data into list of elements
def processInfo(rawInfo):
    return Web3.toBytes(rawInfo).decode("utf8").split(" ")

# TODO: Post transaction with the required atomic info to alpha blockchain
def initiateAlpha(ethAddress, trading_pair, tradeInfo):
    messageInfo = None
    return messageInfo

# TODO: Redeem transaction on beta blockchain
def initiateBeta(ethAddress, trading_pair, tradeInfo, messageInfo):
    return

# TODO: Redeem transaction on alpha blockchain
def participateAlpha(ethAddress, trading_pair, tradeInfo, messageInfo):
    return

# TODO: Post transaction with the required atomic info to beta blockchain
def participateBeta(ethAddress, trading_pair, tradeInfo, messageInfo):
    return
