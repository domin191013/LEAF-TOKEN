const { run, network, ethers } = require("hardhat");

let leafContract;
let vestingContract;
let presaleContract;

const deployContract = async (contractName, args) => {

    console.log(`⌛ Deploying ${contractName}...`);

    const consumerFactory = await ethers.getContractFactory(contractName);

    const contract = await consumerFactory.deploy(...args);
    await contract.deployed();

    console.log(`✅ Deployed ${contractName} to ${contract.address}`);
    return contract;
};

const displayOwnerBalance = async (owner) => {
    console.log('');
    let ownerBalance = await leafContract.balanceOf(owner.address);
    console.log(`Owner have ${ownerBalance} leaf tokens`);
}

const sendTokenToPresaleContract = async (amount) => {
    // Deposit function testing
    console.log('');
    console.log('---------Sending token to presale contract---------');
    await leafContract.transfer(presaleContract.address, amount);
    let presaleBalance = await presaleContract.getLeafTokenBalance();
    console.log(`Presale contract have ${presaleBalance} leaf tokens`);
}

const buyToken = async (owner, valueInEther) => {
    await owner.sendTransaction({
        to: presaleContract.address,
        value: ethers.utils.parseEther(valueInEther),
    });
}

const lockMoney = async (amount) => {
    console.log('');
    console.log('Lock money himself');
    await leafContract['transferAndCall(address,uint256)'](vestingContract.address, amount);
}

const lockToOther = async (secAccount, amount) => {
    console.log('');
    console.log('Lock to other address');

    const abi = ethers.utils.defaultAbiCoder;
    const params = abi.encode(
        ["address[]", "uint256[]"], // encode as address array
        [[secAccount.address], [amount]]); // array to encode

    await leafContract['transferAndCall(address,uint256,bytes)'](
        vestingContract.address,
        amount,
        params);
}

const displayVesting = async () => {
    console.log('');
    console.log('---------Checking on vesting contract---------');
    let vestedLength = await vestingContract.getVestorsLength();
    console.log(`Total vested count: ${vestedLength}`);

    for (let i = 0; i < vestedLength; i++) {
        const address = await vestingContract.vestors(i);
        console.log(`Vested Address is ${address}`);
    }

    await vestingContract.getVestingInfos(0, vestedLength);
}

const main = async () => {
    const [owner, secAccount] = await ethers.getSigners();

    leafContract = await deployContract("LeafToken", []);
    vestingContract = await deployContract("LeafLongTermVesting", [leafContract.address]);
    presaleContract = await deployContract("LeafPresale", [leafContract.address, vestingContract.address, 0, 10e10]);

    const totalTokenAmount = 1000;

    await displayOwnerBalance(owner);

    await sendTokenToPresaleContract(10e11);
    await buyToken(owner, "0.0000000000000001");
    await displayOwnerBalance(owner);

    console.log('');

    await sendTokenToPresaleContract(10e11);
    await buyToken(owner, "0.0000000000000001");
    await displayOwnerBalance(owner);

    // Lock function testing
    await lockMoney(totalTokenAmount);
    await displayOwnerBalance(owner);

    await lockToOther(secAccount, totalTokenAmount);
    await displayOwnerBalance(owner);

    // Getting vested lists on vesting contract
    await displayVesting();
}

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
}

runMain();