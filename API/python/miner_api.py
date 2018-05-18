### Miner API
from shared import *

# order_number is the order number to get the address of
def getAddressEntry(exchange, trading_pair, order_number):
    # returns a list with members:
    #    eth_address (string) is the ethereum address for the transaction
    #    alpha_address (string) is the address in alpha
    #    beta_address (string) is the address in beta
    return

# deposit_address is the miner address to give the payout to
# trading_pair is the TradingPair to give the match for
# buy_index is the index of the order book entry of the buyer
# sell_index is the index of the order book entry of the seller
# nonce is the cryptographic nonce used for difficulty
def giveMatch(exchange, deposit_address, trading_pair, buy_index,
                sell_index, nonce):
    return
