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
contract SplitSwapRouterInvestTest is DSTest {
    using stdStorage for StdStorage;
    StdStorage stdstore;
    Vm internal constant vm = Vm(HEVM_ADDRESS);
    SplitSwapRouter router;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address FOLD = 0xd084944d3c05CD115C09d072B9F44bA3E0E45921;
    IWETH weth = IWETH(WETH);
    ERC20 usdc = ERC20(USDC);
    ERC20 fold = ERC20(FOLD);
    IUniswapV2Router02 uniRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Router02 routerOld = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IUniswapV2Pair usdWeth = IUniswapV2Pair(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0);
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
    }

    receive() external payable {}

    function testInvest() external {
        uint256 amountIn = 140000000000000000000;
        uint256 blockNum = block.number;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = FOLD;
        address[] memory path2 = new address[](3);
        path2[0] = WETH;
        path2[1] = USDC;
        path2[2] = FOLD;
        uint256 partAmountIn = amountIn * 1500000 / 2500000;
        uint256[] memory amounts = router.swapExactETHForTokens{ value: partAmountIn  }(0, path, address(this), block.timestamp);
        uint256[] memory amounts1 = router.swapExactETHForTokens{ value: amountIn - partAmountIn  }(0, path2, address(this), block.timestamp);
        vm.roll(blockNum); // roll back state
        uint256[] memory amounts2 = routerOld.swapExactETHForTokens{ value: amountIn }(0, path, address(this), block.timestamp);
        assertGt((amounts[1] + amounts1[2]), amounts2[1]);
    }
}
