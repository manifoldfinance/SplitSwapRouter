/// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.13 <0.9.0;

import "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { DSTest } from "ds-test/test.sol";
import { SplitSwapRouter } from "../src/SplitSwapRouter.sol";
import { IUniswapV2Router02 } from "../src/interfaces/IUniswapV2Router.sol";
import { IUniswapV2Pair } from "../src/interfaces/IUniswapV2Pair.sol";
import { IWETH } from "../src/interfaces/IWETH.sol";
import { ERC20 } from "../src/ERC20.sol";

/// @title SplitSwapRouterTest
contract SplitSwapRouterVS1inchApiTest is DSTest {
    using stdStorage for StdStorage;
    StdStorage stdstore;
    Vm internal constant vm = Vm(HEVM_ADDRESS);
    SplitSwapRouter router;
    address ONEINCH = 0x1111111254fb6c44bAC0beD2854e76F90643097d;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    IWETH weth = IWETH(WETH);
    ERC20 usdc = ERC20(USDC);
    ERC20 dai = ERC20(DAI);
    uint256 margin = 9900; // margin ratio output diff, out of 10000 (e.g. 9860 == 1.4% off 1inch price)

    bytes DATA;
    uint256 amountIn;
    uint256 amountOut1Inch;
    address toTokenAddress;

    function writeTokenBalance(
        address who,
        address token,
        uint256 amt
    ) internal {
        stdstore.target(token).sig(ERC20(token).balanceOf.selector).with_key(who).checked_write(amt);
    }

    function setUp() public {
        string memory key = "data";
        DATA = vm.envBytes(key);
        key = "toTokenAddress";
        toTokenAddress = vm.envAddress(key);
        key = "amount_out";
        amountOut1Inch = vm.envUint(key);
        key = "amount";
        amountIn = vm.envUint(key);
    }

    receive() external payable {}

    // function testSwapExactETHForTokensApi() external {
    //     router = new SplitSwapRouter(
    //         address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
    //         address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
    //         address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
    //         bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
    //         bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
    //     );
    //     uint256 amountOutMin = 0;
    //     address[] memory path = new address[](2);
    //     path[0] = WETH;
    //     path[1] = toTokenAddress;

    //     address to = address(this);
    //     uint256 deadline = block.timestamp;
    //     uint256[] memory amounts = router.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, to, deadline);

    //     assertGe(amounts[amounts.length - 1], (amountOut1Inch * margin) / uint256(10000));
    // }

    function testSwapExactETHForTokensCall() external {
        router = new SplitSwapRouter(
            address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2), // WETH9
            address(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac), // Sushi factory
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f), // Uni V2 factory
            bytes32(0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303), // sushi pair code hash
            bytes32(0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f) // uni pair code hash
        );
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = toTokenAddress;

        address to = address(this);
        uint256 deadline = block.timestamp;

        uint256 blockNum = block.number;
        uint256[] memory amounts = router.swapExactETHForTokens{ value: amountIn }(amountOutMin, path, to, deadline);
        vm.roll(blockNum); // roll back state
        (bool success, bytes memory data) = ONEINCH.call{ value: amountIn }(DATA);
        if (!success) revert();
        (uint256 actual1InchOut, , ) = abi.decode(data, (uint256, uint256, uint256));
        assertGe(amounts[amounts.length - 1], (actual1InchOut * margin) / uint256(10000));
    }
}
