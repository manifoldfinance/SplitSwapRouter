// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import "../src/SplitOrderV3Router.sol";

contract DeployV3Script is Script {
    function run() public {
        vm.startBroadcast();
        new SplitOrderV3Router();
        vm.stopBroadcast();
    }
}
