
#Interface for miners

# this is the interface that python based miners use to interact with the
# contracts.

from enum import Enum
class TradingPair(Enum):
    NONE = 0
    ETH_BTC = 1


# trading_pair is the TradingPair to get the order book of
def getOrderBook(trading_pair):
    # returns a list (ordered by time)
    # of lists of fixed size, with members:
    #    buy_alpha (bool) is true if the order is a buy order (in alpha)
    #    volume (integer) is the volume in alpha (times 10^18)
    #    min_volume (integer) is the minimum volume in alpha (times 10^18)
    #    limit is the limit price for the sale in (alpha / beta times 10^18)

# order_number is the order number to get the address of
def getAddressEntry(order_number):
    # returns a list with members:
    #    eth_address (string) is the etheruem address for the transaction
    #    alpha_address (string) is the address in alpha
    #    bravo_address (string) is the address in bravo

# deposit_address is the miner address to give the payout to
# trading_pair is the TradingPair to give the match for
# buy_index is the index of the order book entry of the buyer
# sell_index is the index of the order book entry of the seller
# nonce is the cryptographic nonce used to
def giveMatch(deposit_address, trading_pair, buy_index, sell_index, nonce):
