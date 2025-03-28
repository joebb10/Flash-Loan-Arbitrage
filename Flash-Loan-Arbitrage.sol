// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "https://github.com/aave/aave-v3-core/blob/master/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import "https://github.com/aave/aave-v3-core/blob/master/contracts/interfaces/IPoolAddressesProvider.sol";
import "https://github.com/aave/aave-v3-core/blob/master/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract SimpleFlashLoan is FlashLoanSimpleReceiverBase {
    address payable owner;
    IUniswapV2Router public uniswapRouter;
    address public uniswapRouterAddress;

    constructor(address _addressProvider, address _uniswapRouterAddress)
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
    {
        uniswapRouterAddress = _uniswapRouterAddress;
        uniswapRouter = IUniswapV2Router(_uniswapRouterAddress);
    }

    function fn_RequestFlashLoan(address _token, uint256 _amount) public {
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;

        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );
    }

    function  executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    )  external override returns (bool) {
        

        
        address weth = 0x52D800ca262522580CeBAD275395ca6e7598C014; 
        path[0] = asset;
        path[1] = weth;
        
        uint256 deadline = block.timestamp + 15; 

   
        IERC20(asset).approve(uniswapRouterAddress, amount);
        
        
        uniswapRouter.swapExactTokensForTokens(amount, 0, path, address(this), deadline);
        
        uint256 totalAmount = amount + premium;
        
      
        
       
        IERC20(asset).approve(address(POOL), totalAmount);

        return true;
    }

    receive() external payable {}
}
