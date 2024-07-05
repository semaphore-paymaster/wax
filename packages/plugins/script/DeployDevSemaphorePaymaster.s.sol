// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';
import '../src/paymaster/SemaphorePaymasterDev.sol';
import {IEntryPoint} from 'account-abstraction/interfaces/IEntryPoint.sol';

contract MyScript is Script {
    address semaphore = 0x42C0e6780B60E18E44B3AB031B216B6360009baB;
    address entryPoint = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    uint256 groupId = 3;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);
        new SemaphorePaymasterDev(IEntryPoint(entryPoint), semaphore, groupId);
        vm.stopBroadcast();
    }
}
