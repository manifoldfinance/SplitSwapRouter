/// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

import { DSTest } from "../../lib/forge-std/lib/ds-test/src/test.sol";
import {SplitOrderRouter} from "../src/SplitOrderRouter.sol";
import { Vm } from "../../lib/forge-std/src/Vm.sol";
import { IUniswapV2Router02 } from "../src/interfaces/IUniswapV2Router.sol";
import { IUniswapV2Pair } from "../src/interfaces/IUniswapV2Pair.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {ERC20} from "../src/ERC20.sol";

/// @title SplitOrderRouterTest
contract SplitOrderRouterFuzzTest is DSTest {
    Vm internal constant vm = Vm(HEVM_ADDRESS);
    SplitOrderRouter router;
    // OpenMevLibrary lib;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IWETH weth = IWETH(WETH);
    ERC20 usdc = ERC20(USDC);
    ERC20 dai = ERC20(DAI);
    IUniswapV2Router02 routerOld = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IUniswapV2Pair usdWeth = IUniswapV2Pair(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0);
    IUniswapV2Pair daiWeth = IUniswapV2Pair(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f);
    IUniswapV2Pair daiUsdc = IUniswapV2Pair(0xAaF5110db6e744ff70fB339DE037B990A20bdace);
    uint256 minLiquidity = uint256(1000);

    function setUp() public {
        router = new SplitOrderRouter();
    }

    function testSwapExactTokensForTokens(uint256 amountIn) external {
        vm.assume(amountIn > 100000000000000000); // eth amount
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10);
        // uint256 amountIn = 1000000000000000000;
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        address to = address(this);
        uint256 deadline = block.timestamp;

        uint256[] memory amountsUSDC = routerOld.swapExactETHForTokens{ value: amountIn }(
            amountOutMin,
            path,
            to,
            deadline
        );
        path[0] = USDC;
        path[1] = DAI;
        usdc.approve(address(router), amountsUSDC[amountsUSDC.length - 1] / 2);
        usdc.approve(address(routerOld), amountsUSDC[amountsUSDC.length - 1] / 2);
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountsUSDC[amountsUSDC.length - 1]/2,
            amountOutMin,
            path,
            to,
            deadline
        );
        uint256[] memory amounts2 = routerOld.swapExactTokensForTokens(
            amountsUSDC[amountsUSDC.length - 1]/2,
            amountOutMin,
            path,
            to,
            deadline
        );

        assertGe(amounts[amounts.length - 1], amounts2[amounts2.length - 1] - amounts2[amounts2.length - 1] / 100);
    }
}
