const { BigNumber } = require("ethers");
const { ethers, upgrades } = require("hardhat");
const loadConfig = require("./utils/config.js");

async function main() {

    const deploymentConfig = await loadConfig();

    const GYFICrowdsale = await ethers.getContractFactory("GYFICrowdsale");

    console.log("Starting deployments...");

    const saleArray = deploymentConfig.crowdsales[deploymentConfig.crowdsales.length-1];
    const gyfiTokenAddress = saleArray[3];
    const saleCap = saleArray[4];

    const gyfiCrowdsale = await GYFICrowdsale.deploy(...saleArray);
    await gyfiCrowdsale.deployed();
    console.log("GYFICrowdsale deployed to:", gyfiCrowdsale.address);
    
    
    // approves the crowdsale for deployer. Only works if the deployer is also the crowdsale tokenwallet.
    console.log("approving deployer")
    const gyfiToken = await ethers.getContractAt("IERC20", gyfiTokenAddress);
    await gyfiToken.approve(gyfiCrowdsale.address,saleCap);
    console.log("Approve tx sent.");

  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  