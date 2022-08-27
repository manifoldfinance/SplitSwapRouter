/// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

import { DSTest } from "../../lib/forge-std/lib/ds-test/src/test.sol";
import { SplitSwapV3Router } from "../src/SplitSwapV3Router.sol";
import { Vm } from "../../lib/forge-std/src/Vm.sol";
import "../../lib/forge-std/src/Test.sol";
import { IUniswapV2Router02 } from "../src/interfaces/IUniswapV2Router.sol";
import { IUniswapV2Pair } from "../src/interfaces/IUniswapV2Pair.sol";
import { IWETH } from "../src/interfaces/IWETH.sol";
import { ERC20 } from "../src/ERC20.sol";

/// @title SplitSwapV3RouterTest
contract SplitSwapV3RouterVS1inchTest is DSTest {
    using stdStorage for StdStorage;
    StdStorage stdstore;
    Vm internal constant vm = Vm(HEVM_ADDRESS);
    uint256 forkId1;
    uint256 forkId2;
    uint256 forkId3;
    uint256 forkId4;
    uint256 forkId5;
    uint256 forkId6;
    SplitSwapV3Router router;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address renBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
    IWETH weth = IWETH(WETH);
    ERC20 usdc = ERC20(USDC);
    ERC20 dai = ERC20(DAI);
    IUniswapV2Pair usdWeth = IUniswapV2Pair(0x397FF1542f962076d0BFE58eA045FfA2d347ACa0);
    IUniswapV2Pair daiWeth = IUniswapV2Pair(0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f);
    IUniswapV2Pair daiUsdc = IUniswapV2Pair(0xAaF5110db6e744ff70fB339DE037B990A20bdace);
    uint256 minLiquidity = uint256(1000);
    uint256 margin = 9900; // margin ratio output diff, out of 10000 (e.g. 9860 == 1.4% off 1inch price)

    function writeTokenBalance(
        address who,
        address token,
        uint256 amt
    ) internal {
        stdstore.target(token).sig(ERC20(token).balanceOf.selector).with_key(who).checked_write(amt);
    }

    function setUp() public {
        string memory key = "ETH_RPC_URL";
        string memory rpcUrl = vm.envString(key);
        forkId1 = vm.createFork(rpcUrl, 15347843);
        forkId2 = vm.createFork(rpcUrl, 15408222);
        forkId3 = vm.createFork(rpcUrl, 15409161);
        forkId4 = vm.createFork(rpcUrl, 15409149);
        forkId5 = vm.createFork(rpcUrl, 15396936);
        forkId6 = vm.createFork(rpcUrl, 15414959);
    }

    receive() external payable {}

    /// @dev Beat https://etherscan.io/tx/0x3e506fb505c538805752e419356c3a6ce8b05a29d34ca563c95e894fda75bf80
    function testSwapExactETHForTokens1() external {
        vm.selectFork(forkId1);
        router = new SplitSwapV3Router(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
            bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
        );
        uint256 amountIn = 449000000000000000000;
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256[] memory amounts = router.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, to, deadline);

        assertGe(amounts[amounts.length - 1], (850817000000 * margin) / uint256(10000));
    }

    /// @dev Beat https://etherscan.io/tx/0x36eeb2248b7fc1f95bfbbf3be467ac70018a7c53120e3ec4da716707e08c01f0
    function testSwapExactETHForTokens2() external {
        vm.selectFork(forkId2);
        router = new SplitSwapV3Router(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
            bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
        );
        uint256 amountIn = 797000000000000000000;
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = WBTC;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256[] memory amounts = router.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, to, deadline);

        assertGe(amounts[amounts.length - 1], 6172958744);
    }

    /// @dev Beat https://etherscan.io/tx/0xa9d979dc02f5a5293431d015e0eb6c9eea963dbe4a00cccd556d703eb3b91bb1
    function testSwapExactETHForTokens3() external {
        vm.selectFork(forkId3);
        router = new SplitSwapV3Router(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
            bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
        );
        uint256 amountIn = 100000000000000000000;
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256[] memory amounts = router.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, to, deadline);
        uint256 target = (uint256(170278029811506367525806) * uint256(margin)) / uint256(10000);
        assertGe(amounts[amounts.length - 1], target);
    }

    /// @dev Beat https://etherscan.io/tx/0xf2c30b239cd6f77427b2998b930eff3c0eb4bb50a92f7993d379484161c89480
    function testSwapExactETHForTokens4() external {
        vm.selectFork(forkId4);
        router = new SplitSwapV3Router(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
            bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
        );
        uint256 amountIn = 123000000000000000000;
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDT;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256[] memory amounts = router.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, to, deadline);

        assertGe(amounts[amounts.length - 1], ((uint256(209720659556) * margin) / uint256(10000)));
    }

    /// @dev Beat https://etherscan.io/tx/0xd851a00e54dace8f77cd7e6f25c28818177ac3e1f5a3b18795a9c747723cb7a9
    function testSwapExactTokensForETH5() external {
        vm.selectFork(forkId5);
        router = new SplitSwapV3Router(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
            bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
        );
        writeTokenBalance(address(this), MKR, 10 * 1e18);
        uint256 amountIn = 2771813428670135738;
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = MKR;
        path[1] = WETH;

        address to = address(this);
        uint256 deadline = block.timestamp;
        ERC20(MKR).approve(address(router), amountIn);
        uint256[] memory amounts = router.swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);

        assertGe(amounts[amounts.length - 1], ((uint256(1454367631491887808) * margin) / uint256(10000)));
    }

    /// @dev Beat https://etherscan.io/tx/0x8ff0ece45991c4fca8df6aba595af3390d4830b3d99f613ddef4f143b4abca52
    function testSwapExactETHForTokens6() external {
        vm.selectFork(forkId6);
        router = new SplitSwapV3Router(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
            bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
        );
        uint256 amountIn = 65000000000000000000;
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = USDC;

        address to = address(this);
        uint256 deadline = block.timestamp;
        uint256[] memory amounts = router.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, to, deadline);

        assertGe(amounts[amounts.length - 1], ((uint256(107326648907) * margin) / uint256(10000)));
    }

}
