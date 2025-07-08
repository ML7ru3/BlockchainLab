const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("Deploying contracts with:", deployer.address);

    // ✅ Deploy token
    const Token = await ethers.getContractFactory("TrungToken");
    const token = await Token.deploy();
    await token.waitForDeployment(); // ✅ Wait for deployment confirmation

    console.log("Token deployed to:", await token.getAddress());

    // ✅ Deploy SaleCampaign
    const TokenSale = await ethers.getContractFactory("SaleCampaign");
    const sale = await TokenSale.deploy(await token.getAddress(), "0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199");// 19th account
    await sale.waitForDeployment();

    console.log("TokenSale deployed to:", await sale.getAddress());

    const amount = ethers.parseUnits("2", 18); // 2 tokens
    const cost = await sale.getTokenCost(amount);
    console.log("Here's how much it costs:", cost );
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
