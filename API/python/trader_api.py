import secrets
import time
import hashlib
import subprocess

from shared import *
from shared_local import *
from trader_active import *
from web3 import eth, Web3
from decimal import *

def placeOrder(buyAlpha, volume, minVolume, limit, ethAddress, firstAddress,
                otherAddress, trading_pair,
                alpha_acc, alpha_pass, beta_acc, beta_pass):
    placeOrder_back(exchange, buyAlpha, volume, minVolume, limit,
                    ethAddress, firstAddress, otherAddress, trading_pair)
    filled = False
    while not filled:
        time.sleep(5)
        filled, tradeInfoRaw = checkMessage(exchangeAddress, ethAddress)
    tradeInfo = processInfo(tradeInfoRaw)
    if buyAlpha: return initiatorSequence(ethAddress, tradeInfo, otherAddress,
                                            alpha_acc, alpha_pass, beta_acc,
                                            beta_pass)
    else: return participantSequence(ethAddress, tradeInfo, firstAddress,
                                        alpha_acc, alpha_pass, beta_acc,
                                        beta_pass)
    return

def initiatorSequence(ethAddress, tradeInfo, otherAddress, alpha_acc, alpha_pass,
                        beta_acc, beta_pass):
    sec_key = hex(secrets.randbelow(rand_cap))
    sec_hash = hashlib.sha256(bytes(sec_key, "utf8")).hexdigest()
    counterEthAddress = tradeInfo[0]
    initInfo = initiateAlpha(trading_pair, tradeInfo, sec_hash,
                                alpha_acc, alpha_pass)
    # Message the participant with secretHash, alphaContractTX
    web3.eth.sendTransaction({to: tradeInfo[0], value: 1,
                                data: initInfo[0] + " " + initInfo[1]})
    contInfoRaw = awaitMessage(counterEthAddress, ethAddress)
    contInfo = processInfo(contInfoRaw)
    if not initiateBeta(trading_pair, tradeInfo, sec_key, contInfo,
                        otherAddress, beta_acc, beta_pass):
        return False
    # Message the participant with secret
    web3.eth.sendTransaction({to: tradeInfo[0], value: 1,
                                data: sec_key})
    return True

def participantSequence(ethAddress, tradeInfo, firstAddress,
                        alpha_acc, alpha_pass, beta_acc, beta_pass):
    counterEthAddress = tradeInfo[0]
    initInfoRaw = awaitMessage(counterEthAddress, ethAddress)
    initInfo = processInfo(initInfoRaw)
    contInfo = participateBeta(trading_pair, tradeInfo, initInfo,
                                beta_acc, beta_pass)
    if not contInfo:
        return False
    # Message the initiator with betaContractCode, betaContractTX
    web3.eth.sendTransaction({to: tradeInfo[0], value: 1,
                                data: contInfo[0] + " " + contInfo[1]})
    sec_key_raw = awaitMessage(counterEthAddress, ethAddress)
    sec_key = processInfo(sec_key_raw)[0]
    return participateAlpha(trading_pair, tradeInfo, initInfo,
                            sec_key, firstAddress, alpha_acc, alpha_pass)

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

# Post transaction with the required atomic info to alpha blockchain
def initiateAlpha(trading_pair, tradeInfo, sec_hash,
                    alpha_acc, alpha_pass):
    alpha_currency = tp_mappings[trading_pair][0]
    cmd = []
    # Default refundTime is 48 hours (60 * 60 * 48)
    refundTime = 60 * 60 * 48
    vol = calcSwapVol(tradeInfo, alpha_currency, True)
    if alpha_currency == Currencies.ETH:
        cmd = "ethatomicswap initiate " + refundTime + " " + sec_hash +
                " " + tradeInfo[1]
    else:
        return False
    initInfo_raw = subprocess.check_output(cmd).decode("utf8")
    # Extract relevant init info, return
    initInfo = [sec_hash, initInfoRaw.split()[4]]
    return initInfo

# Run audit sequence
def passesAudit(currency, expected_vol, contractCode, contractTX, myAddress,
                sec_hash):
    if currency == Currencies.ETH:
        # TODO: Find a way to audit ETH
        return True
    else:
        if currency == Currencies.BTC:
            prefix = "btcatomicswap"
        elif currency == Currencies.BCH:
            prefix = "bchatomicswap"
        elif currency == Currencies.LTC:
            prefix = "ltcatomicswap"
        cmd = " auditcontract " + contractCode + " " + contractTX
        auditInfo_raw = subprocess.check_output(prefix + cmd).decode("utf8")
        # Clean and extract auditInfo_raw to get auditInfo
        auditInfo = [Decimal(auditInfo_raw.split()[5]),
                        auditInfo_raw.split()[9],
                        auditInfo_raw.split()[12]]
        if (auditInfo[0] == expected_vol) and ((auditInfo[1] == myAddress) and
            (auditInfo[2] == sec_hash)):
            return True
    return False

# Redeem transaction on beta blockchain
def initiateBeta(trading_pair, tradeInfo, sec_key, contInfo, otherAddress,
                    beta_acc, beta_pass):
    beta_currency = tp_mappings[trading_pair][1]
    vol = calcSwapVol(tradeInfo, beta_currency, False)
    if not passesAudit(beta_currency, vol, contInfo[0], contInfo[1],
                        otherAddress, sec_hash):
        return False
    if beta_currency == Currencies.BTC:
        prefix = "btcatomicswap"
    elif beta_currency == Currencies.BCH:
        prefix = "bchatomicswap"
    elif beta_currency == Currencies.LTC:
        prefix = "ltcatomicswap"
    else:
        return False
    cmd = " redeem --rpcuser=" + beta_acc + " rpcpass=" +
            beta_pass + " " + contInfo[0] + " " + contInfo[1] + " " +
            sec_key
    subprocess.check_output(prefix + cmd)
    return True

# Redeem transaction on alpha blockchain
def participateAlpha(trading_pair, tradeInfo, initInfo, sec_key,
                        alpha_acc, alpha_pass):
    alpha_currency = tp_mappings[trading_pair][0]
    if alpha_currency == Currencies.ETH:
        cmd = "ethatomicswap redeem " + sec_key + " " + initInfo[0]
    else:
        return False
    return True

# Post transaction with the required atomic info to beta blockchain
def participateBeta(trading_pair, tradeInfo, initInfo, firstAddress,
                    beta_acc, beta_pass):
    alpha_currency = tp_mappings[trading_pair][0]
    beta_currency = tp_mappings[trading_pair][1]
    vol = calcSwapVol(tradeInfo, beta_currency, False)
    alphaVol = calcSwapVol(tradeInfo, alpha_currency, True)
    sec_hash = initInfo[0]
    if not passesAudit(alpha_currency, alphaVol, None, initInfo[1],
                        firstAddress, sec_hash):
        return False
    if beta_currency == Currencies.BTC:
        prefix = "btcatomicswap"
    elif beta_currency == Currencies.BCH:
        prefix = "bchatomicswap"
    elif beta_currency == Currencies.LTC:
        prefix = "ltcatomicswap"
    else:
        return False
    cmd = " participate --rpcuser=" + beta_acc +
            " --rpcpass=" + beta_pass + " " + tradeInfo[2] + " " + vol +
            " " + sec_hash
    contInfo_raw = subprocess.check_output(prefix + cmd).decode("utf8")
    # Extract relevant cont info, return
    contInfo = [contInfo_raw.split()[14], contInfo_raw.split()[17]]
    return contInfo
