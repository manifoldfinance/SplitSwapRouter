// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SplitSwapRouterLite.sol";

contract DeployLiteScript is Script {
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
            // Ethereum mainnet
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
        } else if (chain == 250) {
            // Fantom mainnet
            wNative = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; // wftm
            sushiFactory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4; // sushiswap factory on fantom mainnet
            backupFactory = 0x152eE697f2E276fA89E96742e9bB9aB1F2E61bE3; // spookyswap factory
            sushiFactoryHash = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303; // sushi pair init code hash
            backupFactoryHash = 0xcdf2deca40a0bd56de8e3ce5c7df6727e5b1bf2ac96f283fa9c4b3e6b42ea9d2; // spookyswap init pair code hash
        } else if (chain == 43114) {
            // Avalanche mainnet
            wNative = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // wavax
            sushiFactory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4; // sushiswap factory on avalanche mainnet
            backupFactory = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10; // traderjoe factory
            sushiFactoryHash = 0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303; // sushi pair init code hash
            backupFactoryHash = 0x0bbca9af0511ad1a1da383135cf3a8d2ac620e549ef9f6ae3a4c33c2fed0af91; // traderjoe init pair code hash
        } else revert UnknownChain();

        vm.startBroadcast();
        new SplitSwapRouterLite{ salt: "Manifold" }(
            wNative,
            sushiFactory,
            backupFactory,
            sushiFactoryHash,
            backupFactoryHash
        );
        vm.stopBroadcast();
    }
}
