// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapV1 {
    IERC20 public token;
    address public factory;

    constructor(address _token) {
        token = IERC20(_token);
        factory = msg.sender;
    }

    // Add liquidity (ETH + Token)
    function addLiquidity(uint256 tokenAmount) external payable {
        require(tokenAmount > 0 && msg.value > 0, "Invalid amounts");

        token.transferFrom(msg.sender, address(this), tokenAmount);
    }

    // Remove all liquidity (simplified version)
    function removeLiquidity() external {
        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethReserve = address(this).balance;

        token.transfer(msg.sender, tokenReserve);
        payable(msg.sender).transfer(ethReserve);
    }

    // Get output amount using constant product formula
    function getOutputAmount(uint256 inputAmount, uint256 inputReserve, uint256 outputReserve) public pure returns (uint256) {
        uint256 inputAmountWithFee = inputAmount * 997;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = inputReserve * 1000 + inputAmountWithFee;
        return numerator / denominator;
    }

    // ETH -> Token swap
    function ethToTokenSwap(uint256 minTokens) external payable {
        require(msg.value > 0, "Send ETH");

        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 tokensOut = getOutputAmount(msg.value, address(this).balance - msg.value, tokenReserve);

        require(tokensOut >= minTokens, "Slippage");

        token.transfer(msg.sender, tokensOut);
    }

    // Token -> ETH swap
    function tokenToEthSwap(uint256 tokenIn, uint256 minEth) external {
        require(tokenIn > 0, "Send tokens");

        uint256 tokenReserve = token.balanceOf(address(this));
        uint256 ethReserve = address(this).balance;

        uint256 ethOut = getOutputAmount(tokenIn, tokenReserve, ethReserve);

        require(ethOut >= minEth, "Slippage");

        token.transferFrom(msg.sender, address(this), tokenIn);
        payable(msg.sender).transfer(ethOut);
    }

    // Get token and ETH reserve
    function getReserves() external view returns (uint256 tokenReserve, uint256 ethReserve) {
        return (token.balanceOf(address(this)), address(this).balance);
    }
}

