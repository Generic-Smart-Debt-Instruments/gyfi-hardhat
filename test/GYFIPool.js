const chai = require("chai");
const { solidity, deployContract } = require("ethereum-waffle");
const { expect } = chai;
const { time } = require("@openzeppelin/test-helpers");
const { hre, ethers } = require("hardhat");
const { formatEther, formatUnits, parseEther, parseUnits } = ethers.utils;
const { BigNumber } = require("ethers");
chai.use(solidity);

const { toNum, toBN } = require("./utils");

describe("GYFIPool", function () {
  let chainId, gsdiId;
  let gyfiToken, dai, gyfiPool, gyfiStrategy, gauc, gsdiNFT, gsdiWallet;
  let deployer, feeRecipient, user, executor, havester, borrower;
  const havesterRole =
    "0x3fc733b4d20d27a28452ddf0e9351aced28242fe03389a653cdb783955316b9b";

  before(async function () {
    await time.advanceBlock();

    const accounts = await ethers.getSigners();
    deployer = accounts[0];
    feeRecipient = accounts[1];
    user = accounts[2];
    executor = accounts[3];
    havester = accounts[4];
    borrower = accounts[5];

    const GyfiToken = await ethers.getContractFactory("GYFIToken");
    gyfiToken = await upgrades.deployProxy(GyfiToken);
    await gyfiToken.deployed();

    const MockERC20Factory = await ethers.getContractFactory("MockERC20");
    dai = await MockERC20Factory.deploy();
    await dai.deployed();

    const network = await ethers.provider.getNetwork();
    chainId = BigNumber.from(network.chainId);
    gsdiId = chainId.mul(BigNumber.from(2).pow(160));

    const gsdiNFTFactory = await ethers.getContractFactory("GSDINFT");
    gsdiNFT = await upgrades.deployProxy(gsdiNFTFactory, [chainId]);
    await gsdiNFT.deployed();

    await gsdiNFT.setTreasury(gsdiNFT.address);

    const gsdiWalletFactory = await ethers.getContractFactory("GSDIWallet");
    gsdiWallet = await upgrades.deployProxy(gsdiWalletFactory, [
      gsdiNFT.address,
      executor.address,
    ]);
    await gsdiWallet.deployed();

    const GAUCFactory = await ethers.getContractFactory("GAUC");
    gauc = await GAUCFactory.deploy(dai.address, gsdiNFT.address);
    await gauc.deployed();

    const GyfiPool = await ethers.getContractFactory("GYFIPool");
    gyfiPool = await GyfiPool.deploy();
    await gyfiPool.deployed();

    const GyfiStrategy = await ethers.getContractFactory("StrategyManual");
    gyfiStrategy = await GyfiStrategy.deploy(
      gyfiPool.address,
      dai.address,
      gauc.address,
      gsdiNFT.address,
      feeRecipient.address
    );
    await gyfiStrategy.deployed();

    await gyfiStrategy.grantRole(havesterRole, havester.address);

    await gyfiPool.initialize(gyfiStrategy.address, "GYFI Pool", "lpGyfi");

    await gyfiToken.transfer(gyfiStrategy.address, parseEther("400000"));
  });

  it("Preapre", async function () {
    await gyfiToken.approve(gauc.address, "1000000000");
    await gauc.createERC20Auction(
      gyfiToken.address,
      "1000000000",
      borrower.address,
      (await time.latest()).toNumber() + 1000,
      "100000000",
      "10000000",
      (await time.latest()).toNumber() + 2000,
      "50000000"
    );

    await dai.approve(deployer.address, "100000000000");
    await dai.transfer(gyfiStrategy.address, "100000000000");

    await gyfiStrategy.connect(havester).bid(0, "100000000");

    await time.increase(time.duration.seconds(1000));
    await time.advanceBlock();

    await gyfiStrategy.connect(havester).claim(0);

    await time.increase(time.duration.seconds(10000));
    await time.advanceBlock();

    await gyfiStrategy.connect(havester).seize(gsdiId);

    await gyfiStrategy.connect(havester).processCover(gsdiId);

    await dai.approve(deployer.address, "100000000000");
    await dai.transfer(user.address, "100000000000");
    await dai.connect(user).approve(gyfiStrategy.address, "100000000000");
  });

  it("GYFIPool mint", async function () {
    const lpBalanceBefore = await gyfiPool.callStatic.balanceOf(user.address);
    expect(lpBalanceBefore).to.be.equal("0");
    const daiBalanceBefore = await dai.callStatic.balanceOf(user.address);
    expect(daiBalanceBefore).to.be.equal("100000000000");

    await gyfiPool.connect(user).mint("100000000");

    const lpBalanceAfter = await gyfiPool.callStatic.balanceOf(user.address);
    expect(lpBalanceAfter).to.be.equal("100000000");
    const daiBalanceAfter = await dai.callStatic.balanceOf(user.address);
    expect(daiBalanceAfter).to.be.lt(daiBalanceBefore);
  });

  it("GYFIPool snapshot", async function () {
    await gyfiPool.snapshot();
    await gyfiPool.connect(user).mint("100000000");
    await gyfiPool.snapshot();

    expect(await gyfiPool.balanceOfAt(user.address, 1)).to.be.equal(
      "100000000"
    );

    expect(await gyfiPool.balanceOfAt(user.address, 2)).to.be.equal(
      "200000000"
    );

    expect(await gyfiPool.totalSupplyAt(1)).to.be.equal("100000000");

    expect(await gyfiPool.totalSupplyAt(2)).to.be.equal("200000000");
  });

  it("GYFIPool burn", async function () {
    const lpBalanceBefore = await gyfiPool.callStatic.balanceOf(user.address);
    expect(lpBalanceBefore).to.be.equal("200000000");
    const daiBalanceBefore = await dai.callStatic.balanceOf(user.address);

    await gyfiPool.connect(user).burn("100000000");

    const lpBalanceAfter = await gyfiPool.callStatic.balanceOf(user.address);
    expect(lpBalanceAfter).to.be.equal("100000000");
    const daiBalanceAfter = await dai.callStatic.balanceOf(user.address);
    expect(daiBalanceAfter).to.be.gt(daiBalanceBefore);
  });
});
