// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import 'forge-std/Script.sol';
import '../src/paymaster/SponsorEverythingPaymaster.sol';
import {IEntryPoint} from 'account-abstraction/interfaces/IEntryPoint.sol';

contract MyScript is Script {
    address entryPoint = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    uint256 groupId = 0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint('PRIVATE_KEY');
        vm.startBroadcast(deployerPrivateKey);
        new SponsorEverythingPaymaster(IEntryPoint(entryPoint));
        vm.stopBroadcast();
    }
}
