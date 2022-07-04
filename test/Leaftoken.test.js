const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("LeafToken", function () {
  it("Should return the right amount of total supply", async function () {
    const LeafTokenContract = await ethers.getContractFactory("LeafToken");
    const leafToken = await LeafTokenContract.deploy();
    await leafToken.deployed();

    const totalSupply = await leafToken.totalSupply();
    const totalSupplyEth = ethers.utils.formatEther( totalSupply );
    expect(totalSupplyEth).to.equal('420000000000.0');
  });
});
