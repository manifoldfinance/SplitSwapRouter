/// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

import "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { DSTest } from "ds-test/test.sol";
import { MultiSplit } from "../src/MultiSplit.sol";
import { SplitSwapRouter } from "../src/SplitSwapRouter.sol";
import { IUniswapV2Router02 } from "../src/interfaces/IUniswapV2Router.sol";
import { IUniswapV2Pair } from "../src/interfaces/IUniswapV2Pair.sol";
import { IWETH } from "../src/interfaces/IWETH.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

/// @title MultiSplitTest
contract MultiSplitFuzzTest is DSTest {
    using stdStorage for StdStorage;
    StdStorage stdstore;
    Vm internal constant vm = Vm(HEVM_ADDRESS);
    SplitSwapRouter router;
    MultiSplit multi;
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
        router = new SplitSwapRouter(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
            bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
        );
        multi = new MultiSplit(address(router));
    }

    function writeTokenBalance(
        address who,
        address token,
        uint256 amt
    ) internal {
        stdstore.target(token).sig(ERC20(token).balanceOf.selector).with_key(who).checked_write(amt);
    }

    receive() external payable {}

    fallback() external payable {}

    function testSwapExactETHForTokens() external {
        // vm.assume(amountIn > 1000000000000);
        // vm.assume(amountIn < address(this).balance / 4);
        // (, uint112 reserveWeth, ) = usdWeth.getReserves();
        // vm.assume(amountIn < reserveWeth / 10); // max USDC reserve
        uint256 amountIn = 200000000000000000000;
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        address[] memory path2 = new address[](3);
        path2[0] = WETH;
        path2[1] = DAI;
        path2[2] = USDC;
        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256 bal = usdc.balanceOf(address(this));
        bytes memory data = abi.encodeWithSignature(
            "swapExactETHForTokens(uint256,address[],address,uint256)",
            amountOutMin,
            path,
            to,
            deadline
        );
        bytes memory data2 = abi.encodeWithSignature(
            "swapExactETHForTokens(uint256,address[],address,uint256)",
            amountOutMin,
            path2,
            to,
            deadline
        );
        // router.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, to, deadline);
        multi.multiSplit{ value: 2 * amountIn }(
            abi.encodePacked(amountIn, data.length, data, amountIn, data2.length, data2)
        );

        assertGt(usdc.balanceOf(address(this)), bal);
        // assertGt(usdc.balanceOf(address(multi)), bal);
    }

    function testSwapExactTokensForTokens() external {
        // vm.assume(amountIn > 1000000000000);
        // vm.assume(amountIn < address(this).balance / 4);
        // (, uint112 reserveWeth, ) = usdWeth.getReserves();
        // vm.assume(amountIn < reserveWeth / 10); // max USDC reserve

        uint256 amountIn = 200000000000000000000;
        writeTokenBalance(address(this), WETH, amountIn * 4);
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        address[] memory path2 = new address[](3);
        path2[0] = WETH;
        path2[1] = DAI;
        path2[2] = USDC;
        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256 bal = usdc.balanceOf(address(this));
        ERC20(WETH).transfer(address(multi), amountIn * 2);
        bytes memory data = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
        bytes memory data2 = abi.encodeWithSignature(
            "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
            amountIn,
            amountOutMin,
            path2,
            to,
            deadline
        );
        // router.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, to, deadline);
        multi.multiSplit(abi.encodePacked(uint256(0), data.length, data, uint256(0), data2.length, data2));

        assertGt(usdc.balanceOf(address(this)), bal);
        // assertGt(usdc.balanceOf(address(multi)), bal);
    }
}
