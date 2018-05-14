from test_hash import minerHash

#testing nterface for miners

TEST_DIFFICULTY = 2 ** 254

from enum import Enum
class TradingPair(Enum):
    NONE = 0
    ETH_BTC = 1

order_book = [[True, 10000000, 0, 1000000000000000000],
            [False, 10000000, 0, 1000000000000000000],
            [True, 1000000, 0, 1000000000000000050],
            [True, 1000000, 0, 900000000000000000],
            [False, 100000, 0, 1000000000000000045],
            [False, 1000000, 0, 909000000000000000]]

address_book = [["0x1234", "0x3211", "0x134389"],
                ["0x1254334", "0x33141", "0x1342389"],
                ["0x123434", "0x32341", "0x134289"],
                ["0x12324", "0x321491", "0x13423489"],
                ["0x12364", "0x390141", "0x1242389"],
                ["0x14234", "0x35141", "0x1345389"]]


def getOrderBook(trading_pair):
    global order_book
    return order_book

def getAddressEntry(order_number):
    global address_book
    return address_book[order_number]

def giveMatch(deposit_address, trading_pair, buy_index, sell_index, nonce):
    global order_book
    if(buy_index == sell_index):
        print("Buy and sell index the same")
        return
    if(buy_index < 0 or 6 < buy_index):
        print("Buy index out of bounds")
        return
    if(sell_index < 0 or 6 < sell_index):
        print("Buy index out of bounds")
        return
    if(not order_book[buy_index][0]):
        print("Buy index not a buy")
        return
    if(order_book[sell_index][0]):
        print("Sell index not a sell")
        return
    if(order_book[sell_index][3] > order_book[buy_index][3]):
        print("Orders not compatable")
        return
    if(minerHash(deposit_address, trading_pair, buy_index, sell_index, nonce) > TEST_DIFFICULTY):
        print("Nonce does not meet difficulty")
        return

    print("Order made")
    if(order_book[sell_index][1] == order_book[buy_index][1]):
        print("order amount " + str(order_book[sell_index][1]))

    if(order_book[sell_index][1] > order_book[buy_index][1]):
        print("order amount " + str(order_book[buy_index][1]))
        order_book = order_book + [[False, order_book[sell_index][1] - order_book[buy_index][1], 0, order_book[sell_index][1]]]

    if(order_book[sell_index][1] < order_book[buy_index][1]):
        print("order amount " + str(order_book[sell_index][1]))
        order_book = order_book + [[True, order_book[buy_index][1] - order_book[sell_index][1], 0, order_book[buy_index][1]]]

    order_book[sell_index][0] = False
    order_book[sell_index][1] = 0
    order_book[sell_index][2] = 0
    order_book[sell_index][3] = 0
    order_book[buy_index][0] = False
    order_book[buy_index][1] = 0
    order_book[buy_index][2] = 0
    order_book[buy_index][3] = 0
