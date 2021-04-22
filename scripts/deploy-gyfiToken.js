const { BigNumber } = require("ethers")
const { ethers, upgrades } = require("hardhat")

async function main() {

    const GYFIToken = await ethers.getContractFactory("GYFIToken");

    console.log("Starting deployments...")

    const gyfiToken = await upgrades.deployProxy(GYFIToken, [])
    await gyfiToken.deployed()
    console.log("GYFIToken deployed to:", gyfiToken.address)
  }
  
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    });
  