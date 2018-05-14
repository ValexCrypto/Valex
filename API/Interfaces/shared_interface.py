### Interface for shared properties of miners and traders
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
