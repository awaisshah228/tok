import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import { BigNumber, utils } from "ethers";
import "hardhat-deploy";
import "hardhat-gas-reporter"
import "@openzeppelin/hardhat-upgrades"


import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.9",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      accounts: {
        count: 100,
        accountsBalance: BigNumber.from(10).pow(25).toString(),
      },
      hardfork: "berlin", // kcc
      chainId: 1337,
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts:
      process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      // gasPrice: 20000000000,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    }
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    owner: {
      default: 1,
    },
  },
  gasReporter: {
     enabled:true
  }
};

export default config;



// Implementation 0x5c8E96e23CeDD453E88Dd51B2E78748F42379bDC already verified.
// Verifying proxy: 0x5e86592fA035B64468eE955dBAD716b4D1CD34Dc
// Contract at 0x5e86592fA035B64468eE955dBAD716b4D1CD34Dc already verified.
// Linking proxy 0x5e86592fA035B64468eE955dBAD716b4D1CD34Dc with implementation
// Successfully linked proxy to implementation.
// Verifying proxy admin: 0x99E45662C66E27124623d079a5F11Fc56fb3d1Fa
// Contract at 0x99E45662C66E27124623d079a5F11Fc56fb3d1Fa already verified.