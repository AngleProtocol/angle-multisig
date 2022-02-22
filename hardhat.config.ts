/// ENVVAR
// - ENABLE_GAS_REPORT
// - CI
// - RUNS
import "dotenv/config";

import yargs from "yargs";
import { nodeUrl, accounts } from "./utils/network";
import { HardhatUserConfig, subtask } from "hardhat/config";
import { TASK_COMPILE_GET_COMPILATION_TASKS } from "hardhat/builtin-tasks/task-names";
// import { TASK_TYPECHAIN_GENERATE_TYPES } from '@typechain/hardhat/dist/constants';
import path from "path";
import fse from "fs-extra";

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
    ],
    overrides: {
      "contracts/stableMaster/StableMasterFront.sol": {
        version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 830,
          },
        },
      },
      "contracts/perpetualManager/PerpetualManagerFront.sol": {
        version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 283,
          },
        },
      },
      "contracts/mock/PerpetualManagerFrontUpgrade.sol": {
        version: "0.8.7",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },
    },
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
    kovan: {
      live: false,
      url: nodeUrl("kovan"),
      accounts: accounts("kovan"),
      gas: 12e6,
      gasPrice: 1e9,
      chainId: 42,
    },
    rinkeby: {
      live: true,
      url: nodeUrl("rinkeby"),
      accounts: accounts("rinkeby"),
      gas: "auto",
      // gasPrice: 12e8,
      chainId: 4,
    },
    mumbai: {
      url: nodeUrl("mumbai"),
      accounts: accounts("mumbai"),
      gas: "auto",
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
    angleTestNet: {
      url: nodeUrl("angle"),
      accounts: accounts("angle"),
      gas: 12e6,
      gasPrice: 5e9,
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
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
  mocha: {
    timeout: 100000,
    retries: 10,
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: false,
    disambiguatePaths: false,
  },
  spdxLicenseIdentifier: {
    overwrite: true,
    runOnCompile: false,
  },
  docgen: {
    path: "./docs",
    clear: true,
    runOnCompile: false,
  },
  abiExporter: {
    path: "./export/abi",
    clear: true,
    flat: true,
    spacing: 2,
  },
  tenderly: {
    project: process.env.TENDERLY_PROJECT || "",
    username: process.env.TENDERLY_USERNAME || "",
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
};

export default config;
