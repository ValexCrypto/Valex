import secrets
import time
import hashlib
import subprocess

from shared import *
from shared_local import *
from trader_active import *
from web3 import eth, Web3
from decimal import *

# struct TradeInfo {
# address counterEthAddress;
# bytes32 counterFirstAddress;
# bytes32 counterSecondAddress;
# // alpha volume and rate of exchange
# uint mimRate;
# uint alphaVol;
# }

def placeOrder(buyAlpha, volume, minVolume, limit, ethAddress, firstAddress,
                otherAddress, trading_pair,
                alpha_addr, alpha_pass, beta_addr, beta_pass):
    placeOrder_back(exchange, buyAlpha, volume, minVolume, limit,
                    ethAddress, firstAddress, otherAddress, trading_pair)
    filled = False
    while not filled:
        time.sleep(5)
        filled, tradeInfoRaw = checkMessage(exchangeAddress, ethAddress)
    tradeInfo = processInfo(tradeInfoRaw)
    if buyAlpha: return initiatorSequence(ethAddress, tradeInfo,
                                            alpha_addr, alpha_pass, beta_addr,
                                            beta_pass)
    else: return participantSequence(ethAddress, tradeInfo,
                                        alpha_addr, alpha_pass, beta_addr,
                                        beta_pass)
    return

def initiatorSequence(ethAddress, tradeInfo, alpha_addr, alpha_pass,
                        beta_addr, beta_pass):
    sec_key = hex(secrets.randbelow(rand_cap))
    sec_hash = hashlib.sha256(bytes(sec_key, "utf8"))
    counterEthAddress = tradeInfo[0]
    initInfo = initiateAlpha(ethAddress, trading_pair, tradeInfo, sec_hash,
                                alpha_addr, alpha_pass)
    contInfoRaw = awaitMessage(counterEthAddress, ethAddress)
    contInfo = processInfo(messageInfoRaw)
    # TODO: message the participant with secretHash, alphaContractCode, alphaContractTX
    initiateBeta(ethAddress, trading_pair, tradeInfo, initInfo, contInfo,
                    beta_addr, beta_pass)
    # TODO: message the participant with secret
    return

def participantSequence(ethAddress, tradeInfo, alpha_addr, alpha_pass,
                        beta_addr, beta_pass):
    counterEthAddress = tradeInfo[0]
    initInfoRaw = awaitMessage(counterEthAddress, ethAddress)
    initInfo = processInfo(messageInfoRaw)
    contInfo = participateBeta(ethAddress, trading_pair, tradeInfo, messageInfo,
                                beta_addr, beta_pass)
    # TODO: message the initiator with betaContractCode, betaContractTX
    secretRaw = awaitMessage(counterEthAddress, ethAddress)
    secret = processInfo(messageInfoRaw)[0]
    participateAlpha(ethAddress, trading_pair, tradeInfo, messageInfo, secret,
                        alpha_addr, alpha_pass)
    return

def checkMessage(fromAddress, toAddress):
    block = eth.getBlock("latest")
    if block.transactions == None: return (False, None)
    for t in block.transactions:
        if (t.from == fromAddress) and (t.to == toAddress):
            return (True, t.input)
    return (False, None)

def awaitMessage(fromAddress, toAddress):
    contacted = False
    while not contacted:
        time.sleep(5)
        contacted, messageInfoRaw = checkMessage(counterEthAddress, ethAddress)
    return messageInfoRaw

# Parse Ethereum message data into list of elements
# TODO: Make sure this works
def processInfo(rawInfo):
    return Web3.toBytes(rawInfo).decode("utf8").split(" ")

# Puts volume in appropriate units, with appropriate precision
def calcSwapVol(tradeInfo, currency, alpha):
    alphaVol_raw =  (Decimal(tradeInfo[4]) / Decimal(EXCHANGE_PRECISION))
    if alpha:
        alphaVol = alphaVol_raw - (alphaVol_raw % (1 / Decimal(precisions[currency])))
        return alphaVol
    betaVol_raw = alphaVol_raw * (Decimal(tradeInfo[3]) / Decimal(EXCHANGE_PRECISION))
    betaVol = betaVol_raw - (betaVol_raw % (1 / Decimal(precisions[currency])))
    return betaVol

# TODO: Post transaction with the required atomic info to alpha blockchain
def initiateAlpha(ethAddress, trading_pair, tradeInfo, sec_hash,
                    alpha_addr, alpha_pass):
    alpha_currency = tp_mappings[trading_pair][0]
    messageInfo = None
    cmd = []
    # Default refundTime is 48 hours (60 * 60 * 48)
    refundTime = 60 * 60 * 48
    vol = calcSwapVol(tradeInfo, alpha_currency, True)
    if alpha_currency = Currencies.ETH:
        cmd = ["ethatomicswap initiate " + refundTime + " " + sec_hash +
                " " + tradeInfo[1], alpha_pass, "y"]
    else:
        return False
    messageInfo_raw = subprocess.check_output(cmd)
    # TODO: Extract relevant message info, return
    return messageInfo

# TODO: Redeem transaction on beta blockchain
def initiateBeta(ethAddress, trading_pair, tradeInfo, messageInfo,
                    beta_addr, beta_pass):
    beta_currency = tp_mappings[trading_pair][1]
    # messageInfo = None
    cmd = []
    if beta_currency = Currencies.BTC:
        #cmd =
        pass
    elif beta_currency = Currencies.BCH:
        pass
    elif beta_currency = Currencies.LTC:
        pass
    else:
        return False
    subprocess.check_output(cmd)
    return True

# TODO: Redeem transaction on alpha blockchain
def participateAlpha(ethAddress, trading_pair, tradeInfo, messageInfo,
                        alpha_addr, alpha_pass):
    alpha_currency = tp_mappings[trading_pair][0]
    if alpha_currency = Currencies.ETH:
        #cmd =
        pass
    else:
        return False
    return True

# TODO: Post transaction with the required atomic info to beta blockchain
def participateBeta(ethAddress, trading_pair, tradeInfo, messageInfo,
                    beta_addr, beta_pass):
    beta_currency = tp_mappings[trading_pair][1]
    if beta_currency = Currencies.BTC:
        #cmd =
        pass
    elif beta_currency = Currencies.BCH:
        pass
    elif beta_currency = Currencies.LTC:
        pass
    else:
        return False
    return True
