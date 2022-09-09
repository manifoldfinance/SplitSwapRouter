// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/SplitSwapRouterLite.sol";

contract DeployLiteScript is Script {
    function run() public {
        vm.startBroadcast();
        new SplitSwapRouterLite();
        vm.stopBroadcast();
    }
}
