// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import {TestHelper} from '../utils/TestHelper.sol';
import {SemaphorePaymaster} from '../../../src/paymaster/SemaphorePaymaster.sol';
import {ISemaphore} from '../../../src/paymaster/interfaces/ISemaphore.sol';
import {IPoap} from '../../../src/paymaster/interfaces/IPoap.sol';
import {IEntryPoint} from 'account-abstraction/interfaces/IEntryPoint.sol';
import {PackedUserOperation} from 'account-abstraction/interfaces/PackedUserOperation.sol';
import 'account-abstraction/core/Helpers.sol';
import 'account-abstraction/interfaces/IPaymaster.sol';

/* solhint-disable func-name-mixedcase */

contract SemaphorePaymasterWrapper is SemaphorePaymaster {
    constructor(
        IEntryPoint _entryPoint,
        address __semaphore,
        uint256 __groupId
    ) SemaphorePaymaster(_entryPoint, __semaphore, __groupId) {}

    function performValidatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 requiredPreFund
    ) public view returns (bytes memory context, uint256 validationData) {
        return _validatePaymasterUserOp(userOp, userOpHash, requiredPreFund);
    }

    function performPostOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) public {
        _postOp(mode, context, actualGasCost, actualUserOpFeePerGas);
    }
}

contract SemaphorePaymasterTest is TestHelper {
    constructor() TestHelper() {}

    uint256 eventId = 12;
    uint256 groupId = 100;
    address semaphore = address(1);

    SemaphorePaymasterWrapper public paymaster;

    ISemaphore.SemaphoreProof proof =
        ISemaphore.SemaphoreProof(
            0,
            0,
            0,
            0,
            0,
            [uint(1), uint(2), uint(3), uint(4), uint(5), uint(6), uint(7), uint(8)]
        );

    function setUp() public {
        paymaster = new SemaphorePaymasterWrapper(IEntryPoint(entryPoint), semaphore, groupId);
    }

    function test_valid_proof() public {
        PackedUserOperation memory userOp = buildUserOp();
        bytes memory signature = abi.encode(proof);

        bytes memory paymasterAndData = abi.encode(address(paymaster), uint48(10), uint48(20), signature);
        userOp.paymasterAndData = paymasterAndData;

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        _mockAndExpect(
            semaphore,
            abi.encodeWithSelector(ISemaphore.verifyProof.selector, groupId, proof),
            abi.encode(true)
        );
        (bytes memory context, uint256 validationData) = paymaster.performValidatePaymasterUserOp(userOp, 0, 0);
        uint256 exptectedValidationData = _packValidationData(false, 10, 20);
        assertEq(validationData, exptectedValidationData);
        assertEq(context, signature);
    }

    function test_invalid_proof() public {
        PackedUserOperation memory userOp = buildUserOp();
        bytes memory signature = abi.encode(proof);

        bytes memory paymasterAndData = abi.encode(address(paymaster), uint48(10), uint48(20), signature);
        userOp.paymasterAndData = paymasterAndData;

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        _mockAndExpect(
            semaphore,
            abi.encodeWithSelector(ISemaphore.verifyProof.selector, groupId, proof),
            abi.encode(false)
        );
        (bytes memory context, uint256 validationData) = paymaster.performValidatePaymasterUserOp(userOp, 0, 0);
        uint256 exptectedValidationData = _packValidationData(true, 10, 20);
        assertEq(validationData, exptectedValidationData);
        assertEq(context, '');
    }

    function test_postOp() public {
        bytes memory signature = abi.encode(proof);
        bytes memory context = signature;
        _mockAndExpect(
            semaphore,
            abi.encodeWithSelector(ISemaphore.validateProof.selector, groupId, proof),
            abi.encode()
        );
        paymaster.performPostOp(IPaymaster.PostOpMode.opSucceeded, context, 0, 0);
    }

    function _mockAndExpect(address _target, bytes memory _call, bytes memory _ret) internal {
        vm.mockCall(_target, _call, _ret);
        vm.expectCall(_target, _call);
    }
}
