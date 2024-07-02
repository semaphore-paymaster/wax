// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {TestHelper} from "../utils/TestHelper.sol";
import {PoapSemaphoreGatekeeper} from "../../../src/paymaster/Gatekeeper.sol";
import {ISemaphore} from "../../../src/paymaster/interfaces/ISemaphore.sol";

/* solhint-disable func-name-mixedcase */

contract GateKeeperTest is TestHelper {
    constructor() TestHelper() {}

    address semaphore = address(1);
    address poap = address(2);
    PoapSemaphoreGatekeeper public gateKeeper;

    function setUp() public {
        gateKeeper = new PoapSemaphoreGatekeeper(semaphore, poap, 12);
        bytes memory createGroupCall = abi.encodeWithSelector(
            bytes4(keccak256("createGroup(address)")),
            address(gateKeeper)
        );
        _mockAndExpect(semaphore, createGroupCall, abi.encode(100));
        gateKeeper.init();
    }

    function test_validate() public {}

    function _mockAndExpect(
        address _target,
        bytes memory _call,
        bytes memory _ret
    ) internal {
        vm.mockCall(_target, _call, _ret);
        vm.expectCall(_target, _call);
    }
}
