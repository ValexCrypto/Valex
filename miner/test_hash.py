
HASH_MAX = (2 ** 256 - 1)

# Dummy hash function based on mersenne primes
# to be replaced with actual hash function

def minerHash(addr, pair, buyInd, sellInd, nonce):
    comp1 = addr * ((2 ** 107) - 1)
    comp2 = pair * ((2 ** 61) - 1)
    comp3 = buyInd * ((2 ** 127) - 1)
    comp4 = sellInd * ((2 ** 521) - 1)
    comp5 = nonce * ((2 ** 607) - 1)
    ret = (comp1 + comp2 + comp3 + comp4 + comp5) % HASH_MAX
    print("miner hash returned " + str(ret))
    return ret

