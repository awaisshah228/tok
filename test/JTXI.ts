/* tslint:disable */
/* eslint-disable */

import { expect } from "chai";
import { ethers,upgrades } from "hardhat";
import { Contract } from "ethers";
// type SignerWithAddress = Awaited<ReturnType<typeof ethers["getSigner"]>>;

// test suite
describe("Test deployment", function () {
  let token: any;

  this.beforeAll(async () => {
    const [owner, otherAccount] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("JTXI");
    token = await upgrades.deployProxy(Token)
  });
  it(" token  deployed",async function() {
    expect(token.address).not.to.be.null;
    expect(await token.name()).to.be.equal("JTXI");
    expect(await token.totalSupply()).to.be.equal(ethers.utils.parseEther("1000000000"));
    
  });
  it("upgrade proxy",async function() {
    const Token2= await ethers.getContractFactory("JTXV2");
    const token2= await upgrades.upgradeProxy(token.address,Token2)
    expect(await token2.version()).to.be.equal("v2");
    expect(await token2.totalSupply()).to.be.equal(ethers.utils.parseEther("1000000000"));

    
  });


  // test case
}); // end of describe
