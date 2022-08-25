/// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

import { DSTest } from "../../lib/forge-std/lib/ds-test/src/test.sol";
import { SplitSwapV3Router } from "../src/SplitSwapV3Router.sol";
import { Vm } from "../../lib/forge-std/src/Vm.sol";
import { IUniswapV2Router02 } from "../src/interfaces/IUniswapV2Router.sol";
import { IUniswapV2Pair } from "../src/interfaces/IUniswapV2Pair.sol";
import { IWETH } from "../src/interfaces/IWETH.sol";
import { ERC20 } from "../src/ERC20.sol";

/// @title SplitSwapV3RouterTest
contract SplitSwapV3RouterFuzzTest is DSTest {
    Vm internal constant vm = Vm(HEVM_ADDRESS);
    SplitSwapV3Router router;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address GAMES = 0x005998df532dE1820119e3ebD50FC90A4e8E8080; // fee on transfer token
    IWETH weth = IWETH(WETH);
    ERC20 usdc = ERC20(USDC);
    ERC20 dai = ERC20(DAI);
    ERC20 games = ERC20(GAMES);
    IUniswapV2Router02 uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 routerOld = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IUniswapV2Pair usdWeth = IUniswapV2Pair(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0);
    IUniswapV2Pair daiWeth = IUniswapV2Pair(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f);
    IUniswapV2Pair daiUsdc = IUniswapV2Pair(0xAaF5110db6e744ff70fB339DE037B990A20bdace);
    uint256 minLiquidity = uint256(1000);

    function setUp() public {
        router = new SplitSwapV3Router(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
            bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
        );
    }

    receive() external payable {}

    function testQuote(
        uint112 amountA,
        uint112 reserveA,
        uint112 reserveB
    ) external {
        vm.assume(amountA > 1000);
        vm.assume(reserveA > 1000);
        vm.assume(reserveB > reserveA);
        assertGe(router.quote(amountA, reserveA, reserveB), routerOld.quote(amountA, reserveA, reserveB));
    }

    function testGetAmountOut(
        uint112 amountIn,
        uint112 reserveIn,
        uint112 reserveOut
    ) external {
        vm.assume(amountIn > 1000);
        vm.assume(reserveIn > 1000);
        vm.assume(reserveOut > reserveIn);
        assertGe(
            router.getAmountOut(amountIn, reserveIn, reserveOut),
            routerOld.getAmountOut(amountIn, reserveIn, reserveOut)
        );
    }

    function testGetAmountIn(
        uint112 amountOut,
        uint112 reserveIn,
        uint112 reserveOut
    ) external {
        vm.assume(amountOut > 1000);
        vm.assume(reserveIn > 1000);
        vm.assume(reserveOut > reserveIn);
        vm.assume(reserveOut > amountOut);
        assertLe(
            router.getAmountIn(amountOut, reserveIn, reserveOut),
            routerOld.getAmountIn(amountOut, reserveIn, reserveOut)
        );
    }

    function testGetAmountsOut(uint112 amountIn) external {
        vm.assume(amountIn > 1000000000000);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);
        uint256[] memory amounts2 = routerOld.getAmountsOut(amountIn, path);
        assertGe(amounts[1], amounts2[1]);
    }

    function testGetAmountsIn(uint112 amountOut) external {
        vm.assume(amountOut > 1000000);
        (uint112 reserveUsdc, , ) = usdWeth.getReserves();
        vm.assume(amountOut < reserveUsdc); // max USDC reserve
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        uint256[] memory amounts = router.getAmountsIn(amountOut, path);
        uint256[] memory amounts2 = routerOld.getAmountsIn(amountOut, path);
        assertLe(amounts[0], amounts2[0]);
    }

    function testSwapExactETHForTokens(uint256 amountIn) external {
        vm.assume(amountIn > 1000000000000);
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10); // max USDC reserve
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256[] memory amounts = router.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, to, deadline);
        uint256[] memory amounts2 = routerOld.swapExactETHForTokens{ value: amountIn }(
            amountOutMin,
            path,
            to,
            deadline
        );
        assertGe(amounts[amounts.length - 1], amounts2[amounts2.length - 1]);
    }

    function testSwapETHForExactTokens(uint256 amountIn) external {
        vm.assume(amountIn > 10000000000000000);
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10); // max USDC reserve
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256[] memory amounts = router.swapETHForExactTokens{ value: amountIn }(
            (routerOld.getAmountsOut(amountIn, path)[1] * 4) / 5,
            path,
            to,
            deadline
        );
        uint256[] memory amounts2 = routerOld.swapETHForExactTokens{ value: amountIn }(
            (routerOld.getAmountsOut(amountIn, path)[1] * 4) / 5,
            path,
            to,
            deadline
        );
        assertLe(amounts[0], amounts2[0] + amounts2[0] / 1000);
    }

    function testSwapExactTokensForETH(uint256 amountIn) external {
        vm.assume(amountIn > 1000000000000);
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10); // max USDC reserve
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256[] memory amountsUSDC = router.swapExactETHForTokens{ value: amountIn }(
            amountOutMin,
            path,
            to,
            deadline
        );
        uint256[] memory amountsUSDC2 = routerOld.swapExactETHForTokens{ value: 2 * amountIn }(
            amountOutMin,
            path,
            to,
            deadline
        );
        path[0] = USDC;
        path[1] = WETH;
        uint256 totalUSDC = amountsUSDC2[amountsUSDC2.length - 1] + amountsUSDC[amountsUSDC.length - 1];
        usdc.approve(address(router), totalUSDC / 2);
        usdc.approve(address(routerOld), totalUSDC / 2);
        uint256[] memory amounts = router.swapExactTokensForETH(totalUSDC / 2, amountOutMin, path, to, deadline);
        uint256[] memory amounts2 = routerOld.swapExactTokensForETH(totalUSDC / 2, amountOutMin, path, to, deadline);

        assertGe(amounts[amounts.length - 1], amounts2[amounts2.length - 1]);
    }

    function testSwapTokensForExactETH(uint256 amountIn) external {
        vm.assume(amountIn > 1000000000000000);
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10); // max USDC reserve
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256[] memory amountsUSDC = router.swapExactETHForTokens{ value: amountIn }(
            amountOutMin,
            path,
            to,
            deadline
        );
        uint256[] memory amountsUSDC2 = routerOld.swapExactETHForTokens{ value: amountIn }(
            amountOutMin,
            path,
            to,
            deadline
        );
        path[0] = USDC;
        path[1] = WETH;
        uint256 totalUSDC = amountsUSDC2[amountsUSDC2.length - 1] + amountsUSDC[amountsUSDC.length - 1];
        usdc.approve(address(router), totalUSDC / 2);
        usdc.approve(address(routerOld), totalUSDC / 2);
        uint256[] memory amounts = router.swapTokensForExactETH(
            (routerOld.getAmountsOut(totalUSDC / 2, path)[1] * 4) / 5,
            totalUSDC / 2,
            path,
            to,
            deadline
        );
        uint256[] memory amounts2 = routerOld.swapTokensForExactETH(
            (routerOld.getAmountsOut(totalUSDC / 2, path)[1] * 4) / 5,
            totalUSDC / 2,
            path,
            to,
            deadline
        );

        assertLe(amounts[0], amounts2[0] + amounts2[0] / 1000);
    }

    function testSwapExactTokensForTokens(uint256 amountIn) external {
        vm.assume(amountIn > 100000000000000000); // eth amount
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10);
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
            amountsUSDC[amountsUSDC.length - 1] / 2,
            amountOutMin,
            path,
            to,
            deadline
        );
        uint256[] memory amounts2 = routerOld.swapExactTokensForTokens(
            amountsUSDC[amountsUSDC.length - 1] / 2,
            amountOutMin,
            path,
            to,
            deadline
        );

        assertGe(amounts[amounts.length - 1], amounts2[amounts2.length - 1]);
    }

    function testSwapTokensForExactTokens(uint256 amountIn) external {
        vm.assume(amountIn > 1000000000000000);
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10);
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256[] memory amountsUSDC = router.swapExactETHForTokens{ value: amountIn }(
            amountOutMin,
            path,
            to,
            deadline
        );
        uint256[] memory amountsUSDC2 = routerOld.swapExactETHForTokens{ value: amountIn }(
            amountOutMin,
            path,
            to,
            deadline
        );
        path[0] = USDC;
        path[1] = DAI;
        uint256 totalUSDC = amountsUSDC2[amountsUSDC2.length - 1] + amountsUSDC[amountsUSDC.length - 1];
        usdc.approve(address(router), totalUSDC / 2);
        usdc.approve(address(routerOld), totalUSDC / 2);
        uint256[] memory amounts = router.swapTokensForExactTokens(
            (routerOld.getAmountsOut(totalUSDC / 2, path)[1] * 4) / 5,
            totalUSDC / 2,
            path,
            to,
            deadline
        );
        uint256[] memory amounts2 = routerOld.swapTokensForExactTokens(
            (routerOld.getAmountsOut(totalUSDC / 2, path)[1] * 4) / 5,
            totalUSDC / 2,
            path,
            to,
            deadline
        );

        assertLe(amounts[0], amounts2[0] + amounts2[0] / 1000);
    }

    function testSwapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountIn) external {
        vm.assume(amountIn > 1000000000000000);
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10); // max USDC reserve
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = GAMES;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256 balanceBefore = games.balanceOf(address(this));
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountIn }(amountOutMin, path, to, deadline);
        uint256 balanceMid = games.balanceOf(address(this));
        uniRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountIn }(
            amountOutMin,
            path,
            to,
            deadline
        );
        assertGe(balanceMid - balanceBefore, games.balanceOf(address(this)) - balanceMid);
    }

    function testSwapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn) external {
        vm.assume(amountIn > 1000000000000000);
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10); // max USDC reserve
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = GAMES;

        address to = address(this);
        uint256 deadline = block.timestamp;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountIn }(amountOutMin, path, to, deadline);
        uniRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountIn }(
            amountOutMin,
            path,
            to,
            deadline
        );
        path[0] = GAMES;
        path[1] = WETH;
        uint256 bal = games.balanceOf(address(this)) / 2;
        games.approve(address(router), bal);
        games.approve(address(uniRouter), bal);
        uint256 balanceBefore = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(bal, amountOutMin, path, to, deadline);
        uint256 balanceMid = address(this).balance;
        uniRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(bal, amountOutMin, path, to, deadline);

        assertGe(balanceMid - balanceBefore, address(this).balance - balanceMid);
    }

    function testSwapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn) external {
        vm.assume(amountIn > 1000000000000000);
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10); // max USDC reserve
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = GAMES;

        address to = address(this);
        uint256 deadline = block.timestamp;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountIn }(amountOutMin, path, to, deadline);
        uniRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountIn }(
            amountOutMin,
            path,
            to,
            deadline
        );
        path[0] = GAMES;
        path[1] = WETH;
        uint256 bal = games.balanceOf(address(this)) / 2;
        games.approve(address(router), bal);
        games.approve(address(uniRouter), bal);
        uint256 balanceBefore = ERC20(WETH).balanceOf(address(this));
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(bal, amountOutMin, path, to, deadline);
        uint256 balanceMid = ERC20(WETH).balanceOf(address(this));
        uniRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(bal, amountOutMin, path, to, deadline);

        assertGe(balanceMid - balanceBefore, ERC20(WETH).balanceOf(address(this)) - balanceMid);
    }

    function testLiquidityEth(uint256 amountIn) external {
        vm.assume(amountIn > 1000000000000);
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        uint256[] memory amounts = router.swapExactETHForTokens{ value: 2 * amountIn }(
            0,
            path,
            address(this),
            block.timestamp
        );
        usdc.approve(address(router), amounts[amounts.length - 1] / 2);
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = router.addLiquidityETH{
            value: (amountIn * 10) / 11
        }(USDC, amounts[amounts.length - 1] / 2, 0, amountIn / 2, address(this), block.timestamp);
        usdc.approve(address(routerOld), amounts[amounts.length - 1] / 2);
        (uint256 amountToken2, uint256 amountETH2, uint256 liquidity2) = routerOld.addLiquidityETH{
            value: (amountIn * 10) / 11
        }(USDC, amounts[amounts.length - 1] / 2, 0, amountIn / 2, address(this), block.timestamp);
        assertGe(amountToken, amountToken2);
        assertGe(amountETH, amountETH2);
        assertGe(liquidity, liquidity2);

        usdWeth.approve(address(routerOld), liquidity2);
        (amountToken2, amountETH2) = routerOld.removeLiquidityETH(
            USDC,
            liquidity2,
            0,
            0,
            address(this),
            block.timestamp
        );
        usdWeth.approve(address(router), liquidity);
        (amountToken, amountETH) = router.removeLiquidityETH(USDC, liquidity, 0, 0, address(this), block.timestamp);

        assertGe(amountToken, amountToken2);
        assertGe(amountETH, amountETH2);
    }

    function testLiquidityTokens(uint256 amountIn) external {
        vm.assume(amountIn > 1000000000000);
        vm.assume(amountIn < address(this).balance / 4);
        (, uint112 reserveWeth, ) = usdWeth.getReserves();
        vm.assume(amountIn < reserveWeth / 10);
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        uint256[] memory amountsUSDC = router.swapExactETHForTokens{ value: 2 * amountIn }(
            0,
            path,
            address(this),
            block.timestamp
        );
        path[0] = WETH;
        path[1] = DAI;
        uint256[] memory amountsDAI = router.swapExactETHForTokens{ value: 2 * amountIn }(
            0,
            path,
            address(this),
            block.timestamp
        );
        usdc.approve(address(router), amountsUSDC[amountsUSDC.length - 1] / 2);
        dai.approve(address(router), amountsDAI[amountsDAI.length - 1] / 2);
        (uint256 amountToken, uint256 amountETH, uint256 liquidity) = router.addLiquidity(
            DAI,
            USDC,
            amountsDAI[amountsDAI.length - 1] / 2,
            amountsUSDC[amountsUSDC.length - 1] / 2,
            0,
            0,
            address(this),
            block.timestamp
        );
        usdc.approve(address(routerOld), amountsUSDC[amountsUSDC.length - 1] / 2);
        dai.approve(address(routerOld), amountsDAI[amountsDAI.length - 1] / 2);
        (uint256 amountToken2, uint256 amountETH2, uint256 liquidity2) = routerOld.addLiquidity(
            DAI,
            USDC,
            amountsDAI[amountsDAI.length - 1] / 2,
            amountsUSDC[amountsUSDC.length - 1] / 2,
            0,
            0,
            address(this),
            block.timestamp
        );
        assertGe(amountToken, amountToken2);
        assertGe(amountETH, amountETH2);
        assertGe(liquidity, liquidity2);

        daiUsdc.approve(address(routerOld), liquidity2);
        (amountToken2, amountETH2) = routerOld.removeLiquidity(
            DAI,
            USDC,
            liquidity2,
            0,
            0,
            address(this),
            block.timestamp
        );
        daiUsdc.approve(address(router), liquidity);
        (amountToken, amountETH) = router.removeLiquidity(DAI, USDC, liquidity, 0, 0, address(this), block.timestamp);

        assertGe(amountToken, amountToken2);
        assertGe(amountETH, amountETH2);
    }
}
