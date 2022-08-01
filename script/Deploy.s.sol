// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import "../src/SplitOrderRouter.sol";

contract DeployScript is Script {
    function run() public {
        vm.startBroadcast();
        new SplitOrderRouter();
        vm.stopBroadcast();
    }
}
