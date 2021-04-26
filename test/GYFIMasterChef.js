const chai = require("chai");
const { solidity } = require("ethereum-waffle");
const { expect } = chai;
const { time } = require("@openzeppelin/test-helpers");
const { ethers } = require("hardhat");
const { parseEther, formatEther, parseUnits } = ethers.utils;

chai.use(solidity);

const { toNum } = require("./utils");

describe("GYFIMasterChef", function () {
  before(async function () {
    await time.advanceBlock();
    now = await time.latest();

    const accounts = await ethers.getSigners();
    this.admin = accounts[0];
    this.user = accounts[1];
    this.dev = accounts[2];

    const GyfiToken = await ethers.getContractFactory("GYFIToken");
    this.gyfiToken = await upgrades.deployProxy(GyfiToken);
    await this.gyfiToken.deployed();

    const MockToken = await ethers.getContractFactory("MockToken");
    this.mockToken = await MockToken.deploy("MockToken", "MT");
    this.mockToken1 = await MockToken.deploy("MockToken1", "MT1");
    await this.mockToken.deployed();
    await this.mockToken1.deployed();

    const GyfiMasterChef = await ethers.getContractFactory("GYFIMasterChef");
    this.gyfiPerBlock = parseEther("100");
    this.accGyfiPrecision = parseUnits("1", "szabo"); // 1e12
    this.gyfiMasterChef = await GyfiMasterChef.deploy(
      this.gyfiToken.address,
      this.user.address,
      this.gyfiPerBlock,
      25,
      1
    );
    await this.gyfiMasterChef.deployed();

    await this.mockToken1.approve(
      this.gyfiMasterChef.address,
      parseEther("400000")
    );

    await this.mockToken.transfer(
      this.gyfiMasterChef.address,
      parseEther("300000")
    );

    await this.gyfiToken.transfer(
      this.gyfiMasterChef.address,
      parseEther("40000")
    );
  });

  it("Should set gyfi token address", async function () {
    const gyfi = await this.gyfiMasterChef.gyfi();
    expect(gyfi).to.equal(this.gyfiToken.address);
  });

  it("Should set dev address", async function () {
    const devaddr = await this.gyfiMasterChef.devaddr();
    expect(devaddr).to.equal(this.user.address);
  });

  it("Should set gyfi per block", async function () {
    const gyfiPerBlock = await this.gyfiMasterChef.gyfiPerBlock();
    expect(gyfiPerBlock).to.equal(this.gyfiPerBlock);
  });

  it("Can create a new reward pool", async function () {
    await this.gyfiMasterChef.add(1, this.mockToken.address, true);
    const poolLength = await this.gyfiMasterChef.poolLength();
    expect(toNum(poolLength)).to.equal(1);

    const poolInfo = await this.gyfiMasterChef.poolInfo(0);
    expect(poolInfo.token).to.equal(this.mockToken.address);
    expect(toNum(poolInfo.allocPoint)).to.equal(1);
  });

  it("Can deposit tokens to farm GYFI", async function () {
    await expect(this.gyfiMasterChef.deposit(0, parseEther("200"))).to.be
      .reverted;
    await time.advanceBlock();

    await expect(
      this.gyfiMasterChef.deposit(0, parseEther("200"))
    ).to.be.revertedWith("ERC20: transfer amount exceeds allowance");
    await this.mockToken.approve(
      this.gyfiMasterChef.address,
      parseEther("400000")
    );

    await expect(this.gyfiMasterChef.deposit(0, parseEther("200")))
      .to.emit(this.gyfiMasterChef, "Deposit")
      .withArgs(this.admin.address, 0, parseEther("200"));
    const balance = await this.mockToken.balanceOf(this.gyfiMasterChef.address);
    const beforeGyfi = await this.gyfiToken.balanceOf(this.admin.address);
    expect(balance).to.equal(parseEther("300200"));

    const poolInfo = await this.gyfiMasterChef.poolInfo(0);
    const userInfo = await this.gyfiMasterChef.userInfo(0, this.admin.address);
    const totalAllocPoint = await this.gyfiMasterChef.totalAllocPoint();
    const gyfiReward = this.gyfiPerBlock
      .mul(poolInfo.allocPoint)
      .div(totalAllocPoint);
    const accGyfiPerShare = gyfiReward
      .mul(this.accGyfiPrecision)
      .div(parseEther("300000"));
    const rewardDebt = parseEther("200")
      .mul(accGyfiPerShare)
      .div(this.accGyfiPrecision);

    expect(poolInfo.accGyfiPerShare).to.equal(accGyfiPerShare);
    expect(userInfo.rewardDebt).to.equal(rewardDebt);

    const afterGyfi = await this.gyfiToken.balanceOf(this.admin.address);
    const pendingGyfi = userInfo.amount
      .mul(poolInfo.accGyfiPerShare)
      .div(this.accGyfiPrecision)
      .sub(userInfo.rewardDebt);
    expect(afterGyfi.sub(beforeGyfi)).to.equal(pendingGyfi);
  });

  it("Can get amount of GYFI pending", async function () {
    const gyfiReward = this.gyfiPerBlock.mul(2).div(2);
    await time.advanceBlock();

    const poolInfo = await this.gyfiMasterChef.poolInfo(0);
    const rewardDebt = parseEther("200")
      .mul(poolInfo.accGyfiPerShare)
      .div(this.accGyfiPrecision);
    const balance = await this.mockToken.balanceOf(this.gyfiMasterChef.address);
    const newAccGyfiPerShare = gyfiReward
      .mul(this.accGyfiPrecision)
      .div(balance);
    const expected = parseEther("200")
      .mul(poolInfo.accGyfiPerShare.add(newAccGyfiPerShare))
      .div(this.accGyfiPrecision)
      .sub(rewardDebt);
    const pendingGyfi = await this.gyfiMasterChef.pendingGyfi(
      0,
      this.admin.address
    );
    expect(pendingGyfi).to.equal(expected);
  });

  it("Can withdraw tokens from the pool", async function () {
    await expect(
      this.gyfiMasterChef.withdraw(0, parseEther("300"))
    ).to.be.revertedWith("withdraw: not good");
    await time.advanceBlock();
    const beforeGyfi = await this.gyfiToken.balanceOf(this.admin.address);
    const beforeToken = await this.mockToken.balanceOf(this.admin.address);
    const amount = parseEther("50");
    const pending = await this.gyfiMasterChef.pendingGyfi(
      0,
      this.admin.address
    );
    await this.gyfiMasterChef.withdraw(0, amount);
    const afterGyfi = await this.gyfiToken.balanceOf(this.admin.address);
    const afterToken = await this.mockToken.balanceOf(this.admin.address);
    const userInfo = await this.gyfiMasterChef.userInfo(0, this.admin.address);
    expect(afterGyfi.sub(beforeGyfi)).to.equal(pending);
    expect(afterToken.sub(beforeToken)).to.equal(amount);
    expect(userInfo.amount).to.equal(parseEther("150"));
  });

  it("Can withdraw deposited tokens without earning any GYFI rewards", async function () {
    const userInfo = await this.gyfiMasterChef.userInfo(0, this.admin.address);
    const before = await this.mockToken.balanceOf(this.admin.address);
    await expect(this.gyfiMasterChef.emergencyWithdraw(0))
      .to.emit(this.gyfiMasterChef, "EmergencyWithdraw")
      .withArgs(this.admin.address, 0, userInfo.amount);
    const after = await this.mockToken.balanceOf(this.admin.address);
    const updatedUserInfo = await this.gyfiMasterChef.userInfo(
      0,
      this.admin.address
    );
    expect(after.sub(before)).to.equal(userInfo.amount);
    expect(updatedUserInfo.amount).to.equal(0);
    expect(updatedUserInfo.rewardDebt).to.equal(0);
  });

  it("Should update the rewards for one pool", async function () {
    // await expect(this.gyfiMasterChef.updatePool(0)).to.be.reverted;

    const beforeBlock = await time.latestBlock();
    const before = await this.gyfiMasterChef.poolInfo(0);
    const beforeDev = await this.gyfiToken.balanceOf(this.user.address);
    const gyfiReward = this.gyfiPerBlock.mul(2).div(2);
    expect(toNum(beforeBlock)).to.above(toNum(before.lastRewardBlock));

    await this.gyfiMasterChef.updatePool(0);
    const balance = await this.mockToken.balanceOf(this.gyfiMasterChef.address);
    const expected = before.accGyfiPerShare.add(
      gyfiReward.mul(this.accGyfiPrecision).div(balance)
    );
    const after = await this.gyfiMasterChef.poolInfo(0);
    const afterDev = await this.gyfiToken.balanceOf(this.user.address);
    const afterBlock = await time.latestBlock();
    expect(toNum(afterBlock)).to.equal(toNum(after.lastRewardBlock));
    expect(afterDev.sub(beforeDev)).to.equal(gyfiReward);
    expect(after.accGyfiPerShare).to.equal(expected);
  });

  it("Should update the rewards for all pools", async function () {
    await this.gyfiMasterChef.add(2, this.mockToken1.address, true);
    await time.advanceBlock();
    const before = await this.gyfiMasterChef.poolInfo(1);
    const beforeBlock = await time.latestBlock();
    expect(toNum(beforeBlock)).to.above(toNum(before.lastRewardBlock));
    await this.gyfiMasterChef.massUpdatePools();

    const expected = before.accGyfiPerShare;
    const after = await this.gyfiMasterChef.poolInfo(1);
    const afterBlock = await time.latestBlock();
    expect(toNum(afterBlock)).to.equal(toNum(after.lastRewardBlock));
    expect(after.accGyfiPerShare).to.equal(expected);
  });

  it("Can set the allocation point for the pool", async function () {
    const before = await this.gyfiMasterChef.poolInfo(0);
    await this.gyfiMasterChef.set(0, 2, true);
    const after = await this.gyfiMasterChef.poolInfo(0);
    expect(toNum(before.allocPoint)).to.equal(1);
    expect(toNum(after.allocPoint)).to.equal(2);

    const block = await time.latestBlock();
    const updated = await this.gyfiMasterChef.poolInfo(0);
    expect(toNum(updated.lastRewardBlock)).to.equal(toNum(block));
  });

  it("Can change dev", async function () {
    const before = await this.gyfiMasterChef.devaddr();
    await expect(this.gyfiMasterChef.dev(this.dev.address)).to.be.revertedWith(
      "dev: wut?"
    );
    await this.gyfiMasterChef.connect(this.user).dev(this.dev.address);
    const after = await this.gyfiMasterChef.devaddr();
    expect(before).to.equal(this.user.address);
    expect(after).to.equal(this.dev.address);
  });
});
