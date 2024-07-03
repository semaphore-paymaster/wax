// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/paymaster/Gatekeeper.sol";

contract MyScript is Script {
    address semaphore = 0x42C0e6780B60E18E44B3AB031B216B6360009baB;
    address poap = 0x8c2DD6E3D63Dc5950D9B908374CD68D0d7160EcA;
    uint256 eventId = 12;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        PoapSemaphoreGatekeeper gp = new PoapSemaphoreGatekeeper(semaphore, poap, eventId);
        vm.stopBroadcast();
    }
}
