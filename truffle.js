// modified from: https://blog.abuiles.com/blog/2017/07/09/deploying-truffle-contracts-to-rinkeby/
// use: geth --rinkeby --rpc --rpcapi db,eth,net,web3,personal --unlock="0x82A88F3edc91324e9Ba52d5231873361d2aE6bb9"
// change the address to whatever your testnet address is

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    rinkeby: {
      host: "localhost", // Connect to geth on the specified
      port: 8545,
      from: "0x82A88F3edc91324e9Ba52d5231873361d2aE6bb9", // default address to use for any transaction Truffle makes during migrations
      network_id: 4,
      gas: 4612388 // Gas limit used for deploys
    }
  }
};
