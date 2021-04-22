require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-web3"); //For openzeppelin
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("solidity-coverage");

const loadJsonFile = require("load-json-file");
const keys = loadJsonFile.sync("./keys.json");

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {},
    ropsten: {
      url: `https://ropsten.infura.io/v3/${keys.infuraKey}`,
      accounts: [keys.privateKey],
      gasMultiplier: 1.1,
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${keys.infuraKey}`,
      accounts: [keys.privateKey],
      gasMultiplier: 1.1,
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${keys.infuraKey}`,
      accounts: [keys.privateKey],
      gasMultiplier: 1.1,
    },
    xdai: {
      url: `https://rpc.xdaichain.com`,
      accounts: [keys.privateKey],
      gasMultiplier: 1.1,
    },
    bsc: {
      url: `https://bsc-dataseed.binance.org`,
      accounts: [keys.privateKey],
      gasMultiplier: 1.1,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.3",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.4.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 20000,
  },
  etherscan: {
    apiKey: "DUMQWHVAG4IXE2287UAKE3ZD144YJSZSTI",
  },
};
