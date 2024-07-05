
// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./Ownable.sol";

contract Arbitrage is Ownable {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 public uniswap;
    IUniswapV2Router02 public sushiswap;
    uint public slippageTolerance;
    IERC20 public wbtcContract;
    IERC20 public usdtContract;

    constructor(
        address _uniswap,
        address _sushiswap,
        uint _slippageTolerance,
        address _wbtcContract,
        address _usdtContract
    ) {
        uniswap = IUniswapV2Router02(_uniswap);
        sushiswap = IUniswapV2Router02(_sushiswap);
        slippageTolerance = _slippageTolerance;
        wbtcContract = IERC20(_wbtcContract);
        usdtContract = IERC20(_usdtContract);
        
       
        usdtContract.safeApprove(_uniswap, type(uint256).max);
        usdtContract.safeApprove(_sushiswap, type(uint256).max);
        wbtcContract.safeApprove(_uniswap, type(uint256).max);
        wbtcContract.safeApprove(_sushiswap, type(uint256).max);
    }

    function setSlippageTolerance(uint _slippageTolerance) external onlyOwner {
        slippageTolerance = _slippageTolerance;
    }

    function approveAndPerformArbitrage(
        uint usdtAmount,
        uint wbtcAmount,
        address[] calldata path1,
        address[] calldata path2
    ) external {
       
        performArbitrage(usdtAmount, wbtcAmount, path1, path2);
    }

    function performArbitrage(
        uint usdtAmount,
        uint wbtcAmount,
        address[] calldata path1,
        address[] calldata path2
    ) public onlyOwner {
        usdtContract.safeTransferFrom(msg.sender, address(this), usdtAmount);
        wbtcContract.safeTransferFrom(msg.sender, address(this), wbtcAmount);
        uint deadline = block.timestamp + 1; 

        uint[] memory usdtAmounts = uniswap.getAmountsOut(usdtAmount, path1);
        uint usdtOutAmount = usdtAmounts[usdtAmounts.length - 1];

        uint[] memory wbtcAmounts = uniswap.getAmountsOut(wbtcAmount, path1);
        uint wbtcOutAmount = wbtcAmounts[wbtcAmounts.length - 1];

        usdtAmounts = sushiswap.getAmountsIn(usdtOutAmount, path2);
        uint usdtInAmount = usdtAmounts[0];

        wbtcAmounts = sushiswap.getAmountsIn(wbtcOutAmount, path2);
        uint wbtcInAmount = wbtcAmounts[0];

        require(usdtInAmount <= usdtAmount * (10000 + slippageTolerance) / 10000, "Arbitrage not profitable");
        require(wbtcInAmount <= wbtcAmount * (10000 + slippageTolerance) / 10000, "Arbitrage not profitable");

       
        uniswap.swapExactTokensForTokens(usdtAmount, usdtOutAmount, path1, address(this), deadline);
        uniswap.swapExactTokensForTokens(wbtcAmount, wbtcOutAmount, path1, address(this), deadline);

        
        uint newUsdtAmount = IERC20(path1[path1.length - 1]).balanceOf(address(this));
        uint newWbtcAmount = IERC20(path2[path2.length - 1]).balanceOf(address(this));

        
        sushiswap.swapExactTokensForTokens(newUsdtAmount, usdtInAmount, path2, address(this), deadline);
        sushiswap.swapExactTokensForTokens(newWbtcAmount, wbtcInAmount, path2, address(this), deadline);
    }

    function withdrawToken(address token) external onlyOwner {
        uint balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        IERC20(token).safeTransfer(owner(), balance);
    }

    function emergencyWithdrawToken(address token) external onlyOwner {
        uint balance = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner(), balance);
    }
}
