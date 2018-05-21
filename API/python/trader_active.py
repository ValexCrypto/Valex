### Trader active API
from shared import *

# buyAlpha is if the order is buying the alpha currency in the pair
# volume is the volume of the order
# minVolume is the minimum acceptable volume to trade
# limit is the order's limit (per 10^18 of alpha currency)
# ethAddress is your ETH address
# firstAddress is your address on alpha chain
# otherAddress is your address on beta chain
# trading_pair is the trading pair
def placeOrder_back(exchange, buyAlpha, volume, minVolume, limit,
                  ethAddress, firstAddress, otherAddress, trading_pair):
    exchange.placeOrder(buyAlpha, volume, minVolume, limit, ethAddress,
                        firstAddress, otherAddress, trading_pair)
    return

# buyAlpha is if the order is buying the alpha currency in the pair
# volume is the volume of the order
# ethAddress is your ETH address
# firstAddress is your address on alpha chain
# otherAddress is your address on beta chain
# trading_pair is the trading pair
# index is the index of the order you would like to match with
# nonce is the cryptographic nonce used for difficulty
def placeTakeOrder_back(exchange, buyAlpha, volume, ethAddress, firstAddress,
                    otherAddress, trading_pair, index, nonce):
    exchange.placeTakeOrder(buyAlpha, volume, ethAddress, firstAddress,
                            otherAddress, trading_pair, index, nonce)
    return
