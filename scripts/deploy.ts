import { ethers, upgrades } from "hardhat";

async function main() {
 

  
  
  const Token = await ethers.getContractFactory("JTXV2");
  const token = await upgrades.deployProxy(Token)
  console.log(` deployed to ${token.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
