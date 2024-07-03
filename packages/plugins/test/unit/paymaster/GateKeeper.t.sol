// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import {TestHelper} from '../utils/TestHelper.sol';
import {PoapSemaphoreGatekeeper} from '../../../src/paymaster/Gatekeeper.sol';
import {ISemaphore} from '../../../src/paymaster/interfaces/ISemaphore.sol';

/* solhint-disable func-name-mixedcase */

contract GateKeeperTest is TestHelper {
    constructor() TestHelper() {}

    address semaphore = address(1);
    address poap = address(2);
    PoapSemaphoreGatekeeper public gateKeeper;

    ISemaphore.SemaphoreProof validProof =
        ISemaphore.SemaphoreProof(
            0,
            0,
            0,
            0,
            0,
            [uint(1), uint(2), uint(3), uint(4), uint(5), uint(6), uint(7), uint(8)]
        );

    function setUp() public {
        gateKeeper = new PoapSemaphoreGatekeeper(semaphore, poap, 12);
        bytes memory createGroupCall = abi.encodeWithSelector(
            bytes4(keccak256('createGroup(address)')),
            address(gateKeeper)
        );
        _mockAndExpect(semaphore, createGroupCall, abi.encode(100));
        gateKeeper.init();
    }

    function test_should_call_validate_if_verify() public {
        _mockAndExpect(
            semaphore,
            abi.encodeWithSelector(ISemaphore.verifyProof.selector, 100, validProof),
            abi.encode(true)
        );
        _mockAndExpect(
            semaphore,
            abi.encodeWithSelector(ISemaphore.validateProof.selector, 100, validProof),
            abi.encode()
        );
        assertTrue(gateKeeper.validate(validProof));
    }

    function test_should_not_validate_if_not_verify() public {
        _mockAndExpect(
            semaphore,
            abi.encodeWithSelector(ISemaphore.verifyProof.selector, 100, validProof),
            abi.encode(false)
        );
        assertFalse(gateKeeper.validate(validProof));
    }

    function _mockAndExpect(address _target, bytes memory _call, bytes memory _ret) internal {
        vm.mockCall(_target, _call, _ret);
        vm.expectCall(_target, _call);
    }
}
