# Valex
Valex: A Decentralized Cryptocurrency Exchange

https://valex.io

Current version of Exchange contract can be found on Rinkeby at: `0x609780719a2774DD754a58ba06094bFbA3F5F0A7`

## Instructions for running locally:

Open a terminal window in the Valex folder. Run:

```
ganache-cli
```

Open another window. Run:

```
truffle migrate
```

## Instructions for running on Rinkeby:


Modify `truffle.js` to include your testnet address (after `from:`) instead of the default address.

Open a terminal window in the Valex folder. Run:

```
geth --rinkeby --rpc --rpcapi db,eth,net,web3,personal --unlock="[your testnet address]"
```
You will be prompted to give your password for the account. Type it in and hit enter.

Open another window. Run:
```
truffle migrate --network rinkeby --reset
```
