// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TrungToken.sol";

contract SaleCampaign{ 
    TrungToken public token;
    address payable public owner;
    uint256 public startTime;
    uint256 public constant DURATION = 30 days;
    
    uint256 public tokensSold;
    uint256 public constant TOTAL_SALE_CAP = 5000 * 1e18; // 50% of total tokens
    uint256 public constant PRICE_PHASE1 = 5 ether;       // First 25% = 2500 tokens
    uint256 public constant PRICE_PHASE2 = 10 ether;      // Next 25% = 2500 tokens

    constructor(address tokenAddress, address spender) {
        token = TrungToken(tokenAddress);
        owner = payable(spender);
        startTime = block.timestamp;
    }

    function buyTokens(uint256 amount) external payable {
        require(block.timestamp <= startTime + DURATION, "Sale ended (time)");
        require(tokensSold + amount <= TOTAL_SALE_CAP, "Sale ended (cap)");

        uint256 cost = getTokenCost(amount);
        require(msg.value >= cost, "Insufficient ETH sent");

        tokensSold += amount;

        // Transfer tokens to buyer
        require(token.transfer(owner, amount), "Token transfer failed");

        // Refund excess ETH
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        // Forward ETH to owner
        owner.transfer(cost);
    }

    function getTokenCost(uint256 amount) public view returns (uint256) {
        require(amount > 0, "Amount must be > 0");

        uint256 phase1Remaining = 2500 * 1e18 > tokensSold
            ? (2500 * 1e18 - tokensSold)
            : 0;

        if (amount <= phase1Remaining) {
            return amount * PRICE_PHASE1;
        } else {
            uint256 phase1Amount = phase1Remaining;
            uint256 phase2Amount = amount - phase1Remaining;
            return phase1Amount * PRICE_PHASE1 + phase2Amount * PRICE_PHASE2;
        }
    }

}
