// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/MultiSplit.sol";

contract DeployMultiScript is Script {
    error UnknownChain();

    function getChainID() internal view returns (uint256 id) {
        assembly ("memory-safe") {
            id := chainid()
        }
    }

    function run() public {
        address router; // split swap router address
        uint256 chain = getChainID();

        if (chain == 1) {
            // eth mainnet
            router = 0x77337dEEA78720542f0A1325394Def165918D562; // split swap router
        } else revert UnknownChain();

        vm.startBroadcast();
        new MultiSplit{ salt: "Manifold" }(router);
        vm.stopBroadcast();
    }
}
