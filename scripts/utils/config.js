const { ethers } = require("hardhat");
const { parseEther } = ethers.utils;

module.exports = async function loadConfig(){
  
  let deploymentConfig = {}

  const network = await ethers.provider.getNetwork();

  console.log("ChainID: "+network.chainId);
  console.log("Network Name: "+network.name);

  if(network.chainId == 1){
    // ETH Mainnet
  } 
  if(network.chainId == 4) {
    // ETH Rinkeby
    deploymentConfig.networkName = "rinkeby"
    deploymentConfig.addresses = {
      gyfiToken: "0x3028De1BA4692D1138D27DD91a3d65cD7D76b581"
    }
  } 
  if(network.chainId == 56) {
    // BSC Mainnet
  }
  if(network.chainId == 100) {
    // xDAI Chain
  }
  if(network.chainId == 31337) {
    // hardhat
  }

  //Deployment will always use most recently added crowdsale.
  if(deploymentConfig.networkName == "rinkeby") {
    deploymentConfig.crowdsales = [
      [
        2000, // rate
        "0x7f801888E6Dd283f53D34D6c46ae6Ef0d115884f", //wallet
        deploymentConfig.addresses.gyfiToken, //token
        "0x7f801888E6Dd283f53D34D6c46ae6Ef0d115884f", //tokenWallet,
        parseEther("20"), //cap
        "1619222400", //openingTime
        "1619481600", //closingTime
        parseEther("2") //perBeneficiaryCap
      ]
    ]
  }

  return deploymentConfig;
}