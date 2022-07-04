require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");
require("dotenv").config();
require("hardhat-deploy");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const mnemonic = process.env.MNEMONIC || "";
const infuraKey = process.env.INFURA_API_KEY || "";
const etherscanKey = process.env.ETHERSCAN_APIKEY || "";

const defaultConfig = {
  accounts: [mnemonic],
};

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: "byzantium",
      },
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${infuraKey}`,
      chainId: 1,
      ...defaultConfig,
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${infuraKey}`,
      chainId: 4,
      ...defaultConfig,
    },
  },
  etherscan: {
    apiKey: etherscanKey,
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  namedAccounts: {
    deployer: {
      default: 0, // here this will by default take the first account as deployer
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 3000000,
  },
};
