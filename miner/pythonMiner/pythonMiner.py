
STANDARD_TRADING_PAIR = 1
DIFFICULTY = 10000
MAX_NONCE = 100000000
DEPOSIT_ADDRESS = 42

#fields for an order
ORD_TYPE = 0
ORD_VOL = 1
ORD_MIN = 2
ORD_LIMIT = 3

def findNonce(addr, pair, buyInd, sellInd):
    for i in range(MAX_NONCE):
        if(hash(addr, pair, buyInd, sellInd) < DIFFICULTY):
            return i



while(1):
    orderBook = getOrderBook(STANDARD_TRADING_PAIR)
    highestBuy = 0
    buyInd = 0
    lowestSell = 0
    sellInd = 0
    quantity = 0
    for i in range(len(orderBook)):
        order = orderBook[i]
        if(order[ORD_TYPE]): #if true type is a buy
            if((highestBuy = 0) or (order[ORD_LIMIT] > highestBuy)):
                if(lowestSell = 0):
                    highestBuy = order[ORD_LIMIT]
                    buyInd = i
                else:
                    volume = min(order[ORD_VOL], orderBook[sellInd][ORD_VOL])
                    if((volume >= order[ORD_MIN]) and (volume > orderBook[sellInd][ORD_MIN])):
                        highestBuy = order[ORD_LIMIT]
                        buyInd = i
        else:   #order must by a sell
            if((lowestSell = 0) or (order[ORD_LIMIT] < lowestSell)):
                if(highestBuy = 0):
                    lowestSell = order[ORD_LIMIT]
                    sellInd = i
                else:
                    volume = min(order[ORD_VOL], orderBook[sellInd][ORD_VOL])
                    if((volume >= order[ORD_MIN]) and (volume > orderBook[buyInd][ORDER_MIN])):
                        lowestSell = order[ORD_LIMIT]
                        sellInd = i
    if(lowestSell < highestBuy):
        nonce = findNonce(DEPOSIT_ADDRESS, STANDARD_TRADING_PAIR, buyInd, sellInd)
        giveMatch(DEPOSIT_ADDRESS, STANDARD_TRADING_PAIR, buyInd, sellInd, nonce)
