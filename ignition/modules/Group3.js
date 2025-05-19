const { ethers } = require("hardhat");

async function main() {
  // Deploy GroupXToken (not Group3Token)
  const totalSupply = ethers.parseEther("1000");
  const Token = await ethers.getContractFactory("GroupXToken");
  const token = await Token.deploy(totalSupply);
  await token.waitForDeployment();
  console.log("GroupXToken deployed to:", await token.getAddress());

  // Deploy TokenSale
  const Sale = await ethers.getContractFactory("TokenSale");
  const sale = await Sale.deploy(await token.getAddress());
  await sale.waitForDeployment();
  console.log("TokenSale deployed to:", await sale.getAddress());

  // Transfer 50% of tokens to the sale contract
  const maxSale = ethers.parseEther("500");
  const tx = await token.transfer(await sale.getAddress(), maxSale);
  await tx.wait();
  console.log("Transferred", maxSale.toString(), "tokens to sale contract");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});