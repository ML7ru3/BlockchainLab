// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Group3Token.sol";

contract TokenSale {
    GroupXToken public token;
    address payable public owner;
    uint256 public saleStart;
    uint256 public tokensSold;
    uint256 public constant TOTAL_SUPPLY = 1000 * 10 ** 18;
    uint256 public constant MAX_SALE = TOTAL_SUPPLY / 2; // 50%
    uint256 public constant FIRST_TIER_LIMIT = TOTAL_SUPPLY / 4; // 25%
    
    constructor(address tokenAddress) {
        token = GroupXToken(tokenAddress);
        owner = payable(msg.sender);
        saleStart = block.timestamp;
    }

    function buyTokens(uint256 tokenAmount) public payable {
        require(block.timestamp <= saleStart + 30 days, "Sale ended");
        require(tokensSold + tokenAmount <= MAX_SALE, "Exceeds sale cap");

        uint256 cost;
        if (tokensSold < FIRST_TIER_LIMIT) {
            uint256 firstTierLeft = FIRST_TIER_LIMIT - tokensSold;
            if (tokenAmount <= firstTierLeft) {
                cost = (tokenAmount / 1 ether) * 5 ether;
            } else {
                cost = ((firstTierLeft / 1 ether) * 5 ether) + (((tokenAmount - firstTierLeft) / 1 ether) * 10 ether);
            }
        } else {
            cost = (tokenAmount / 1 ether) * 10 ether;
        }

        require(msg.value == cost, "Incorrect ETH amount");

        tokensSold += tokenAmount;
        token.transfer(msg.sender, tokenAmount);
        owner.transfer(msg.value);
    }

    function endSale() public {
        require(msg.sender == owner, "Only owner can end");
        require(block.timestamp > saleStart + 30 days, "Sale not ended");

        uint256 remaining = token.balanceOf(address(this));
        if (remaining > 0) {
            token.transfer(owner, remaining);
        }
    }
}

