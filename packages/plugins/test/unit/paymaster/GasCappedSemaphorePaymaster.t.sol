// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import {TestHelper} from '../utils/TestHelper.sol';
import {GasCappedSemaphorePaymaster} from '../../../src/paymaster/GasCappedSemaphorePaymaster.sol';
import {ISemaphore} from '../../../src/paymaster/interfaces/ISemaphore.sol';
import {IEntryPoint} from 'account-abstraction/interfaces/IEntryPoint.sol';
import {PackedUserOperation} from 'account-abstraction/interfaces/PackedUserOperation.sol';
import 'account-abstraction/core/Helpers.sol';
import 'account-abstraction/interfaces/IPaymaster.sol';

/* solhint-disable func-name-mixedcase */

contract GasCappedSemaphorePaymasterWrapper is GasCappedSemaphorePaymaster {
    constructor(
        IEntryPoint _entryPoint,
        address __semaphore,
        uint256 __groupId,
        uint256 __gasCapPerUser,
        uint256 __gasRefillInterval,
        uint256 __gasRefillIntervalStart
    )
        GasCappedSemaphorePaymaster(
            _entryPoint,
            __semaphore,
            __groupId,
            __gasCapPerUser,
            __gasRefillInterval,
            __gasRefillIntervalStart
        )
    {}

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
    uint256 gasCapPerUser = 500;
    uint256 gasRefillInterval = 100; // seconds
    uint256 gasRefillIntervalStart = block.timestamp;

    GasCappedSemaphorePaymasterWrapper public paymaster;

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
        paymaster = new GasCappedSemaphorePaymasterWrapper(
            IEntryPoint(entryPoint),
            semaphore,
            groupId,
            gasCapPerUser,
            gasRefillInterval,
            gasRefillIntervalStart
        );
    }

    function test_valid_proof_within_cap() public {
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
        assertEq(context, abi.encode(proof.nullifier));
    }

    function test_valid_proof_exceed_cap() public {
        PackedUserOperation memory userOp = buildUserOp();
        bytes memory signature = abi.encode(proof);

        bytes memory paymasterAndData = abi.encode(address(paymaster), uint48(10), uint48(20), signature);
        userOp.paymasterAndData = paymasterAndData;

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        (bytes memory context, uint256 validationData) = paymaster.performValidatePaymasterUserOp(userOp, 0, 600);
        uint256 exptectedValidationData = _packValidationData(true, 10, 20);
        assertEq(validationData, exptectedValidationData);
        assertEq(context, '');
    }

    function test_valid_proof_cap_after_interval() public {
        // first uses 500 gas in interval 1 and 500 gas in interval 2

        PackedUserOperation memory userOp = buildUserOp();
        userOp.paymasterAndData = abi.encode(address(paymaster), uint48(10), uint48(20), abi.encode(proof));

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        _mockAndExpect(
            semaphore,
            abi.encodeWithSelector(ISemaphore.verifyProof.selector, groupId, proof),
            abi.encode(true)
        );
        (bytes memory context, uint256 validationData) = paymaster.performValidatePaymasterUserOp(userOp, 0, 500);
        uint256 exptectedValidationData = _packValidationData(false, 10, 20);
        paymaster.performPostOp(IPaymaster.PostOpMode.opSucceeded, context, 500, 0);
        assertEq(validationData, exptectedValidationData);
        assertEq(context, abi.encode(proof.nullifier));

        // forward time to next interval
        vm.warp(gasRefillIntervalStart + gasRefillInterval + 1);
        proof.nullifier = 1;
        userOp.paymasterAndData = abi.encode(address(paymaster), uint48(10), uint48(20), abi.encode(proof));
        userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        _mockAndExpect(
            semaphore,
            abi.encodeWithSelector(ISemaphore.verifyProof.selector, groupId, proof),
            abi.encode(true)
        );
        (context, validationData) = paymaster.performValidatePaymasterUserOp(userOp, 0, 500);
        exptectedValidationData = _packValidationData(false, 10, 20);
        paymaster.performPostOp(IPaymaster.PostOpMode.opSucceeded, context, 500, 0);
        assertEq(validationData, exptectedValidationData);
        assertEq(context, abi.encode(proof.nullifier));
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

    function test_postOp() public {}

    function _mockAndExpect(address _target, bytes memory _call, bytes memory _ret) internal {
        vm.mockCall(_target, _call, _ret);
        vm.expectCall(_target, _call);
    }
}
