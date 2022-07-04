const { run, ethers } = require("hardhat");

require("dotenv").config();

const verifyContract = async(contract, args) => {
  await new Promise((resolve) => {
    setTimeout(resolve, 5000);
  });

  try {
    await run("verify:verify", {
      address: contract.address,
      constructorArguments: args,
    });
  } catch (_) { }
}

const deployContract = async (contractName, args) => {
  console.log(`⌛ Deploying ${contractName}...`);

  const consumerFactory = await ethers.getContractFactory(contractName);
  const contract = await consumerFactory.deploy(...args);
  await contract.deployed();
  
  verifyContract(contract, args);

  console.log(`✅ Deployed ${contractName} to ${contract.address}`);
};

async function main() {
  await deployContract("LeafToken", []);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
