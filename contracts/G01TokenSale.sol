// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract G01TokenSale is ReentrancyGuard {
    IERC20 public token;
    address payable public wallet;
    uint256 public maxTokens;
    uint256 public firstTierLimit;
    uint256 public tokensSold;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public constant FIRST_TIER_PRICE = 5 ether;
    uint256 public constant SECOND_TIER_PRICE = 10 ether;

    event TokensPurchased(address indexed buyer, uint256 amount, uint256 ethSpent);

    constructor(address _token, address payable _wallet, uint256 _maxTokens) {
        token = IERC20(_token);
        wallet = _wallet;
        maxTokens = _maxTokens;
        firstTierLimit = _maxTokens / 2; // 25% của tổng cung
        tokensSold = 0;
        startTime = block.timestamp;
        endTime = startTime + 30 days;
    }

    function buyTokens(uint256 amount) external payable nonReentrant {
        require(block.timestamp <= endTime, "Sale ended");
        require(tokensSold + amount <= maxTokens, "Not enough tokens left");

        uint256 price = tokensSold < firstTierLimit ? FIRST_TIER_PRICE : SECOND_TIER_PRICE;
        uint256 cost = amount * price;
        require(msg.value >= cost, "Insufficient ETH");

        tokensSold += amount;
        token.transfer(msg.sender, amount);
        wallet.transfer(cost);

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost); // Hoàn tiền thừa
        }

        emit TokensPurchased(msg.sender, amount, cost);
    }

    function isSaleActive() external view returns (bool) {
        return block.timestamp <= endTime && tokensSold < maxTokens;
    }
}