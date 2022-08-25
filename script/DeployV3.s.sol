// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import "../src/SplitSwapV3Router.sol";

contract DeployV3Script is Script {
    function run() public {
        vm.startBroadcast();
        new SplitSwapV3Router(
            0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac,
            0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f,
            0xe18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303,
            0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f
        );
        vm.stopBroadcast();
    }
}
