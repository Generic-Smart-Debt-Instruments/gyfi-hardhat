const chai = require('chai');
const { solidity } = require("ethereum-waffle");
const { expect } = chai;
const { time } = require("@openzeppelin/test-helpers");
const { hre, ethers } = require('hardhat');
const { formatEther, formatUnits, parseEther, parseUnits } = ethers.utils;
chai.use(solidity);

const { toNum, toBN } = require("./utils");

describe("GYFICrowdsale", function() {
  let GyfiCrowdsale, GyfiToken;
  let gyfiCrowdsale, gyfiToken;
  let deployerAddress, treasuryAddress, gyfiWalletAddress;
  let network;
  before(async function() {
    await time.advanceBlock();
    now = await time.latest();

    const accounts = await ethers.getSigners();
    deployerAddress = accounts[0];
    treasuryAddress = accounts[1];
    gyfiWalletAddress = accounts[2];
    beneficiary = accounts[3];

    const GyfiToken = await ethers.getContractFactory("GYFIToken");
    gyfiToken = await upgrades.deployProxy(GyfiToken);
    await gyfiToken.deployed();

    GyfiCrowdsale = await ethers.getContractFactory("GYFICrowdsale");
    gyfiCrowdsale = await GyfiCrowdsale.deploy(
        2000, //rate, in GYFI units per wei
        treasuryAddress.address, // address to receive the assets
        gyfiToken.address, // token address IERC20 token,
        gyfiWalletAddress.address, // address to send the gyfi from
        parseEther("200"), // total cap
        now.toNumber()+time.duration.hours(1).toNumber(), // start timestamp
        now.toNumber()+time.duration.hours(3).toNumber(), // end timestamp
        parseEther("1")  // beneficiary cap
      );
    await gyfiCrowdsale.deployed();
    
    await gyfiToken.transfer(gyfiWalletAddress.address, parseEther("400000"));
    const gyfiTokenWithProjectDevSigner = gyfiToken.connect(gyfiWalletAddress);
    await gyfiTokenWithProjectDevSigner.approve(gyfiCrowdsale.address, parseEther("400000"));

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
      ).to.be.revertedWith("TimedCrowdsale: not open");
    });
    it("Should revert when amount is over beneficiary cap", async function() {
      await expect(
        beneficiary.sendTransaction({
          to: gyfiCrowdsale.address,
          value: parseEther("1.1")
        })
      ).to.be.revertedWith("GYFICrowdsale: Contribution above cap.");;
    });
    it("Should revert if not whitelisted", async function() {
      await time.increase(
        time.duration.hours(2)
      );
      await time.advanceBlock();
      await expect(
        beneficiary.sendTransaction({
          to: gyfiCrowdsale.address,
          value: parseEther("0.5")
        })
      ).to.be.revertedWith("WhitelistCrowdsale: beneficiary doesn't have the Whitelisted role");;
    });
    it("Should transfer tokens from gyfiWallet to beneficiary on success", async function() {
      await gyfiCrowdsale.addWhitelisted(beneficiary.address);
      await beneficiary.sendTransaction({
        to: gyfiCrowdsale.address,
        value: parseEther("0.5")
      })
      const beneficiaryTokens = await gyfiToken.balanceOf(beneficiary.address);
      const gyfiWalletTokens = await gyfiToken.balanceOf(gyfiWalletAddress.address);
      expect(beneficiaryTokens).to.equal(parseEther("1000"));
      expect(gyfiWalletTokens).to.equal(parseEther("399000"));
    });
    it("Should revert when amount from all attempts summed is over beneficiary cap", async function() {
      await expect(
        beneficiary.sendTransaction({
          to: gyfiCrowdsale.address,
          value: parseEther("0.6")
        })
      ).to.be.revertedWith("GYFICrowdsale: Contribution above cap.");;
    });
    it("Should revert when after time end", async function() {
      await time.increase(
        time.duration.hours(2)
      );
      await time.advanceBlock();
      await expect(
        beneficiary.sendTransaction({
          to: gyfiCrowdsale.address,
          value: parseEther("0.5")
        })
      ).to.be.revertedWith("TimedCrowdsale: not open");
    });
  });
});
