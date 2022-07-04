const { run, network, ethers } = require("hardhat");

require("dotenv").config();

const verifyContract = async (address, args) => {
  await run("verify:verify", {
    address: address.toString(),
    constructorArguments: args,
  });
}

const deployContract = async (contractName, args) => {

  console.log(`⌛ Deploying ${contractName}...`);

  const consumerFactory = await ethers.getContractFactory(contractName);

  const contract = await consumerFactory.deploy(...args);
  await contract.deployed();

  await verifyContract(contract.address, args);

  console.log(`✅ Deployed ${contractName} to ${contract.address}`);
};

async function main() {
  const IS_DEV = network.name == "rinkeby";
  const LEAF_CONTRACT_ADDRESS = IS_DEV ? process.env.LEAF_RINKEBY : process.env.LEAF_MAINNET;

  await deployContract("LeafLongTermVesting", [LEAF_CONTRACT_ADDRESS]);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
