/// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

import { DSTest } from "../../lib/forge-std/lib/ds-test/src/test.sol";
import { SplitOrderV3Router } from "../src/SplitOrderV3Router.sol";
import { Vm } from "../../lib/forge-std/src/Vm.sol";
import { IUniswapV2Router02 } from "../src/interfaces/IUniswapV2Router.sol";
import { IUniswapV2Pair } from "../src/interfaces/IUniswapV2Pair.sol";
import { IWETH } from "../src/interfaces/IWETH.sol";
import { ERC20 } from "../src/ERC20.sol";

/// @title SplitOrderV3RouterTest
contract SplitOrderV3RouterVS1inchTest is DSTest {
    Vm internal constant vm = Vm(HEVM_ADDRESS);
    SplitOrderV3Router router;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    IWETH weth = IWETH(WETH);
    ERC20 usdc = ERC20(USDC);
    ERC20 dai = ERC20(DAI);
    IUniswapV2Pair usdWeth = IUniswapV2Pair(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0);
    IUniswapV2Pair daiWeth = IUniswapV2Pair(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f);
    IUniswapV2Pair daiUsdc = IUniswapV2Pair(0xAaF5110db6e744ff70fB339DE037B990A20bdace);
    uint256 minLiquidity = uint256(1000);

    function setUp() public {
        router = new SplitOrderV3Router(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
            bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
        );
    }

    receive() external payable {}


    function testSwapExactETHForTokens() external {
        uint256 amountIn = 449000000000000000000;
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256[] memory amounts = router.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, to, deadline);

        assertGe(amounts[amounts.length - 1], 850817000000);
    }
}
