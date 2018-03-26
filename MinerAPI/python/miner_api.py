### Miner API for local use
from enum import Enum
from web3 import Web3, HTTPProvider, TestRPCProvider

w3 =  Web3(Web3.HTTPProvider("http://127.0.0.1:8545"))

class TradingPair(Enum):
    NONE = 0
    ETH_BTC = 1

# exchangeAddress is the address of the exchange
def connectToExchange(exchangeAddress):
    # Connects to exchange contract
    return


# trading_pair is the TradingPair to get the order book of
def getOrderBook(trading_pair):
    # returns a list (ordered by time)
    # of lists of fixed size, with members:
    #    buy_alpha (bool) is true if the order is a buy order (in alpha)
    #    volume (integer) is the volume in alpha (times 10^18)
    #    min_volume (integer) is the minimum volume in alpha (times 10^18)
    #    limit is the limit price for the sale in (alpha / beta times 10^18)
    return

# order_number is the order number to get the address of
def getAddressEntry(order_number):
    # returns a list with members:
    #    eth_address (string) is the etheruem address for the transaction
    #    alpha_address (string) is the address in alpha
    #    beta_address (string) is the address in beta
    return

# deposit_address is the miner address to give the payout to
# trading_pair is the TradingPair to give the match for
# buy_index is the index of the order book entry of the buyer
# sell_index is the index of the order book entry of the seller
# nonce is the cryptographic nonce used for difficulty
def giveMatch(deposit_address, trading_pair, buy_index, sell_index, nonce):
    return
