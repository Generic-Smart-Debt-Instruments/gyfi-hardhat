const chai = require('chai');
const { solidity } = require("ethereum-waffle");
const { expect } = chai;
const { ether, time } = require("@openzeppelin/test-helpers");
const { hre, ethers } = require('hardhat');
chai.use(solidity);

describe("GYFICrowdsale", function() {
  let GyfiCrowdsale;
  let gyfiCrowdsale;
  let deployerAddress, treasuryAddress, gyfiWalletAddress;
  let network;
  before(async function() {
    network = await ethers.provider.getNetwork();
    now = await time.advanceBlock();
    now = await time.latest();

    console.log("chain id:", network.chainId);
    const accounts = await ethers.getSigners();
    deployerAddress = accounts[0];
    treasuryAddress = accounts[1];
    gyfiWalletAddress = accounts[2];
    GyfiCrowdsale = await ethers.getContractFactory("GYFICrowdsale");
    gyfiCrowdsale = await GyfiCrowdsale.deploy(
        2000, //rate, in GYFI units per wei
        treasuryAddress.address, // address to receive the assets
        deployerAddress.address, // token address IERC20 token,
        gyfiWalletAddress.address, // address to send the gyfi from
        ether("200").toString(), // total cap
        now.toNumber()+3600, // start timestamp
        now.toNumber()+7200, // end timestamp
        ether("1").toString()  // beneficiary cap
      );
    await gyfiCrowdsale.deployed();
  })
  it("Should set rate to 2000", async function() {
    const rate = await gyfiCrowdsale.rate();
    expect(rate.toNumber()).to.equal(2000)
  });
});
