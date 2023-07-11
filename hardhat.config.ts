/// ENVVAR
// - ENABLE_GAS_REPORT
// - CI
// - RUNS
import "dotenv/config";

import yargs from "yargs";
import { nodeUrl, accounts } from "./utils/network";
import { HardhatUserConfig } from "hardhat/config";

import "hardhat-contract-sizer";
import "hardhat-spdx-license-identifier";
import "hardhat-docgen";
import "hardhat-deploy";
import "hardhat-abi-exporter";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-truffle5";
import "@nomiclabs/hardhat-solhint";
import "@openzeppelin/hardhat-upgrades";
import "solidity-coverage";
import "@tenderly/hardhat-tenderly";
import "@typechain/hardhat";

const argv = yargs
  .env("")
  .boolean("ci")
  .number("runs")
  .boolean("fork")
  .boolean("disableAutoMining");

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1000000,
          },
          // debug: { revertStrings: 'strip' },
        },
      },
    ]
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      accounts: accounts("mainnet"),
      live: false,
      blockGasLimit: 125e5,
      initialBaseFeePerGas: 0,
      hardfork: "london",
      forking: {
        enabled: false,
        url: nodeUrl("fork"),
        // This is the last block before the deployer role is removed
        // blockNumber: 13473325,
      },

      chainId: 1337,
    },
    polygon: {
      url: nodeUrl("polygon"),
      accounts: accounts("polygon"),
      gas: "auto",
    },
    mainnet: {
      live: true,
      url: nodeUrl("mainnet"),
      accounts: accounts("mainnet"),
      gas: "auto",
      gasMultiplier: 1.3,
      chainId: 1,
    },
  },
  paths: {
    sources: "./contracts",
        tests: "./tests",

  },
  namedAccounts: {
    deployer: 0,
    guardian: 1,
    user: 2,
    slp: 3,
    ha: 4,
    keeper: 5,
    user2: 6,
    slp2: 7,
    ha2: 8,
    keeper2: 9,
  },
};

export default config;
