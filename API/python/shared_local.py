## Global variables
# For local setup (with ganache-cli -m)
from shared import *

w3 = setUpW3(Network.LOCAL)
Exchange = setUpExchange(w3)
exchangeAddress = "0x56f7dc1cc938d6d6575b68d70d381f9c28c8c7b7"
exchange = connectToExchange(Exchange, exchangeAddress)

rand_cap = int(1e18)
