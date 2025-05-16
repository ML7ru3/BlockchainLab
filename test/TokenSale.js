const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Token Sale Campaign", function () {
  let token, sale, owner, buyer1, buyer2;
  let totalSupply, firstTierLimit, maxSale;

  beforeEach(async function () {
    [owner, buyer1, buyer2] = await ethers.getSigners();

    // Use top-level parseEther (ethers v6)
    totalSupply = ethers.parseEther("1000");
    firstTierLimit = ethers.parseEther("250"); // 25%
    maxSale = ethers.parseEther("500");        // 50%

    const TokenFactory = await ethers.getContractFactory("GroupXToken");
    token = await TokenFactory.deploy(totalSupply);
    await token.waitForDeployment();

    const SaleFactory = await ethers.getContractFactory("TokenSale");
    sale = await SaleFactory.deploy(await token.getAddress());
    await sale.waitForDeployment();

    await token.transfer(await sale.getAddress(), maxSale);
  });

  it("Should allow buying tokens at 5 ETH each for first 25%", async function () {
    const amount = ethers.parseEther("100");
    const cost = ethers.parseEther("500");

    await expect(() =>
      sale.connect(buyer1).buyTokens(amount, { value: cost })
    ).to.changeEtherBalances([buyer1, owner], [-cost, cost]);

    expect(await token.balanceOf(buyer1.address)).to.equal(amount);
  });

  it("Should correctly handle price tier change after 25%", async function () {
    const amountFirst = ethers.parseEther("250");
    const amountSecond = ethers.parseEther("100");
    const costFirst = ethers.parseEther("1250");
    const costSecond = ethers.parseEther("1000");

    await sale.connect(buyer1).buyTokens(amountFirst, { value: costFirst });
    await sale.connect(buyer2).buyTokens(amountSecond, { value: costSecond });

    expect(await token.balanceOf(buyer2.address)).to.equal(amountSecond);
  });

  it("Should reject purchases beyond 50% supply", async function () {
    const amount = ethers.parseEther("600");
    const cost = ethers.parseEther("5000");

    await expect(
      sale.connect(buyer1).buyTokens(amount, { value: cost })
    ).to.be.revertedWith("Exceeds sale cap");
  });

  it("Should stop sale after 30 days", async function () {
    await ethers.provider.send("evm_increaseTime", [31 * 24 * 60 * 60]);
    await ethers.provider.send("evm_mine");

    const amount = ethers.parseEther("10");
    const cost = ethers.parseEther("50");

    await expect(
      sale.connect(buyer1).buyTokens(amount, { value: cost })
    ).to.be.revertedWith("Sale ended");
  });

  it("Should allow owner to reclaim unsold tokens after 30 days", async function () {
    await ethers.provider.send("evm_increaseTime", [31 * 24 * 60 * 60]);
    await ethers.provider.send("evm_mine");

    const before = await token.balanceOf(owner.address);
    await sale.endSale();
    const after = await token.balanceOf(owner.address);

    expect(after - before).to.equal(maxSale);
  });
});

