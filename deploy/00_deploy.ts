import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

interface Custom extends HardhatRuntimeEnvironment {
  [prop: string]: any;
}

const func: DeployFunction = async function (hre: Custom) {
  // const signers = await ethers.getSigners();

  const { getNamedAccounts, deployments } = hre;
  const { deploy, run } = deployments;
  const { deployer } = await getNamedAccounts();

  let token;
  const Token = await ethers.getContractFactory("JTXI");
  token = await upgrades.deployProxy(Token);

  console.log(token.address);

  // console.log(deployments)
  // const signers = await ethers.getSigners();

  // const {getNamedAccounts , deployments, network } = hre
  // const { deploy, run } = deployments
  // const { deployer } = await getNamedAccounts()

  // await upgrades.deployProxy(Foo, { executor: deployments.executor })

  // await deploy('JTXI', {
  //     from: deployer,
  //     proxy: true
  //   });

  // await deploy("UniswapV2Factory", {
  //     from: deployer,
  //     args: [],
  //     log: true,

  //   })
};
export default func;
