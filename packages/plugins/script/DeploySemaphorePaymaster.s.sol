// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';
import '../src/paymaster/SemaphorePaymaster.sol';
import {IEntryPoint} from 'account-abstraction/interfaces/IEntryPoint.sol';

contract MyScript is Script {
    address semaphore = 0x934DeFdBef580f0c2B381DBCbd47e4e2F4078B9C;
    address entryPoint = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    uint256 groupId = 1;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);
        new SemaphorePaymaster(IEntryPoint(entryPoint), semaphore, groupId);
        vm.stopBroadcast();
    }
}
