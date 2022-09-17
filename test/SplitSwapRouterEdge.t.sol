/// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

import "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { DSTest } from "ds-test/test.sol";
import { SplitSwapRouter } from "../src/SplitSwapRouter.sol";
import { IUniswapV2Router02 } from "../src/interfaces/IUniswapV2Router.sol";
import { IUniswapV2Factory } from "../src/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "../src/interfaces/IUniswapV2Pair.sol";
import { IWETH } from "../src/interfaces/IWETH.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

/// @title SplitSwapRouterTest
contract SplitSwapRouterEdgeTest is DSTest {
    using stdStorage for StdStorage;
    StdStorage stdstore;
    Vm internal constant vm = Vm(HEVM_ADDRESS);
    SplitSwapRouter router;
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
    uint256 maxSwaps = uint256(12);
    mapping(address => bool) internal tokenBlacklist;

    function setUp() public {
        router = new SplitSwapRouter(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
            bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
        );
        tokenBlacklist[0xD46bA6D942050d489DBd938a2C909A5d5039A161] = true; // AMPL swap issues
    }

    function writeTokenBalance(
        address who,
        address token,
        uint256 amt
    ) internal {
        stdstore.target(token).sig(ERC20(token).balanceOf.selector).with_key(who).checked_write(amt);
    }

    receive() external payable {}

    function testSwapExpired() public {
        uint256 amountIn = 1000000000000000000;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        vm.expectRevert(abi.encodeWithSignature("Expired()"));
        router.swapExactETHForTokens{ value: amountIn }(0, path, address(this), 1);
    }

    function testSwapInsufficientOutputAmount() public {
        uint256 amountIn = 1000000000000000000;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        vm.expectRevert(abi.encodeWithSignature("InsufficientOutputAmount()"));
        router.swapExactETHForTokens{ value: amountIn }(10000000000000000, path, address(this), block.timestamp);
    }

    function testSwapZeroAmount() public {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;
        vm.expectRevert(abi.encodeWithSignature("ZeroAmount()"));
        router.swapExactETHForTokens{ value: 0 }(0, path, address(this), block.timestamp);
    }

    function testSwapInvalidPath() public {
        uint256 amountIn = 1000000000000000000;
        address[] memory path = new address[](1);
        path[0] = WETH;
        vm.expectRevert(abi.encodeWithSignature("InvalidPath()"));
        router.swapExactETHForTokens{ value: amountIn }(0, path, address(this), block.timestamp);
    }

    function testSwapIdenticalAddresses() public {
        uint256 amountIn = 1000000000000000000;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = WETH;
        vm.expectRevert(abi.encodeWithSignature("IdenticalAddresses()"));
        router.swapExactETHForTokens{ value: amountIn }(0, path, address(this), block.timestamp);
    }

    function testSwapZeroAddress() public {
        uint256 amountIn = 1000000000000000000;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = 0x0000000000000000000000000000000000000000;
        vm.expectRevert(abi.encodeWithSignature("ZeroAddress()"));
        router.swapExactETHForTokens{ value: amountIn }(0, path, address(this), block.timestamp);
    }

    function testAllPairs() external {
        address sushiFactory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;
        uint256 allPairsCount = IUniswapV2Factory(sushiFactory).allPairsLength();
        uint256 swapCount = 0;
        uint256 amountIn = 1000000000000000000;
        address to = 0xA3A771A7c4AFA7f0a3f88Cc6512542241851C926;
        uint256 deadline = block.timestamp;
        for (uint256 i = 0; i < allPairsCount - 1; i++) {
            address pair = IUniswapV2Factory(sushiFactory).allPairs(i);
            (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair).getReserves();
            if (reserve0 > minLiquidity && reserve1 > minLiquidity) {
                address token0 = IUniswapV2Pair(pair).token0();
                address token1 = IUniswapV2Pair(pair).token1();
                if (tokenBlacklist[token0] || tokenBlacklist[token1]) continue;
                if (token0 == WETH) {
                    if (reserve0 < 3000000000000000000) continue;
                    address[] memory path = new address[](2);
                    path[0] = token0;
                    path[1] = token1;
                    emit log_address(token1);
                    try router.swapExactETHForTokens{ value: amountIn }(0, path, to, deadline) returns (
                        uint256[] memory amounts
                    ) {
                        assertGt(amounts[1], 0);
                    } catch {
                        // assume rebase or fee on transfer
                        IUniswapV2Pair(pair).sync();
                        uint256 balBefore = ERC20(token1).balanceOf(address(this));
                        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountIn }(
                            0,
                            path,
                            to,
                            deadline
                        );
                        assertGt(ERC20(token1).balanceOf(address(this)) - balBefore, 0);
                    }
                } else if (token1 == WETH) {
                    if (reserve1 < 3000000000000000000) continue;
                    address[] memory path = new address[](2);
                    path[0] = token1;
                    path[1] = token0;
                    emit log_address(token0);
                    try router.swapExactETHForTokens{ value: amountIn }(0, path, to, deadline) returns (
                        uint256[] memory amounts
                    ) {
                        assertGt(amounts[1], 0);
                    } catch {
                        // assume rebase or fee on transfer
                        IUniswapV2Pair(pair).sync();
                        uint256 balBefore = ERC20(token0).balanceOf(address(this));
                        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amountIn }(
                            0,
                            path,
                            to,
                            deadline
                        );
                        assertGt(ERC20(token0).balanceOf(address(this)) - balBefore, 0);
                    }
                } else {
                    address[] memory path = new address[](2);
                    path[0] = token0;
                    path[1] = token1;
                    writeTokenBalance(address(this), token0, amountIn);
                    ERC20(token0).approve(address(router), amountIn);
                    try router.swapExactTokensForTokens(amountIn, 0, path, to, deadline) returns (
                        uint256[] memory amounts
                    ) {
                        assertGt(amounts[1], 0);
                    } catch {
                        // assume rebase or fee on transfer
                        IUniswapV2Pair(pair).sync();
                        uint256 balBefore = ERC20(token1).balanceOf(address(this));
                        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(amountIn, 0, path, to, deadline);
                        assertGt(ERC20(token1).balanceOf(address(this)) - balBefore, 0);
                    }
                }
            }
            swapCount = swapCount + 1;
            if (swapCount >= maxSwaps) break;
        }
    }
}
