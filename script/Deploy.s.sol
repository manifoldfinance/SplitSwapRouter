// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SplitSwapRouter.sol";

contract DeployScript is Script {
    error UnknownChain();

    function getChainID() internal view returns (uint256 id) {
        assembly ("memory-safe") {
            id := chainid()
        }
    }

    function run() public {
        address wNative; // wrapped native coin (eg weth)
        address sushiFactory; // sushi factory address
        address backupFactory; // backup factory address
        bytes32 sushiFactoryHash; // sushi pair init code hash
        bytes32 backupFactoryHash; // backup pair init code hash

        uint256 chain = getChainID();

        if (chain == 1) {
            // eth mainnet
            wNative = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // weth
            sushiFactory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac; // sushiswap factory on eth mainnet
            backupFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // uniswap v2 factory
            sushiFactoryHash = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303; // sushi pair init code hash
            backupFactoryHash = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f; // uniswap v2 init pair code hash
        } else if (chain == 137) {
            // Polygon mainnet
            wNative = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // wmatic
            sushiFactory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4; // sushiswap factory on polygon mainnet
            backupFactory = 0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32; // quickswap factory
            sushiFactoryHash = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303; // sushi pair init code hash
            backupFactoryHash = 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f; // quickswap init pair code hash
        } else revert UnknownChain();

        vm.startBroadcast();
        new SplitSwapRouter{ salt: "Manifold" }(
            wNative,
            sushiFactory,
            backupFactory,
            sushiFactoryHash,
            backupFactoryHash
        );
        vm.stopBroadcast();
    }
}
