const chai = require('chai');
const { solidity } = require("ethereum-waffle");
const { expect } = chai;
const { time } = require("@openzeppelin/test-helpers");
const { hre, ethers } = require('hardhat');
const { formatEther, formatUnits, parseEther, parseUnits } = ethers.utils;
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
    beneficiary = accounts[3];
    GyfiCrowdsale = await ethers.getContractFactory("GYFICrowdsale");
    gyfiCrowdsale = await GyfiCrowdsale.deploy(
        2000, //rate, in GYFI units per wei
        treasuryAddress.address, // address to receive the assets
        deployerAddress.address, // token address IERC20 token,
        gyfiWalletAddress.address, // address to send the gyfi from
        parseEther("200"), // total cap
        now.toNumber()+3600, // start timestamp
        now.toNumber()+7200, // end timestamp
        parseEther("1")  // beneficiary cap
      );
    await gyfiCrowdsale.deployed();
  });
  it("Should set rate to 2000", async function() {
    const rate = await gyfiCrowdsale.rate();
    expect(rate.toNumber()).to.equal(2000)
  });
  it("Should set cap to 200 ether", async function() {
    const cap = await gyfiCrowdsale.cap();
    expect(cap).to.equal(parseEther("200"))
  });
  it("Should set beneficiary cap to 1 ether", async function() {
    const cap = await gyfiCrowdsale.perBeneficiaryCap();
    expect(cap).to.equal(parseEther("1"))
  });
  describe("receive fallback", function() {
    it("Should revert when now is before start timestamp", async function() {
      await expect(
        beneficiary.sendTransaction({
          to: gyfiCrowdsale.address,
          value: parseEther("1")
        })
      ).to.be.reverted;
    });
  });
});
