// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IEntryPoint} from 'account-abstraction/interfaces/IEntryPoint.sol';

import {BasePaymaster} from 'account-abstraction/core/BasePaymaster.sol';
import {UserOperationLib} from 'account-abstraction/core/UserOperationLib.sol';
import 'account-abstraction/core/Helpers.sol';
import {PackedUserOperation} from 'account-abstraction/interfaces/PackedUserOperation.sol';
import {ISemaphore} from './interfaces/ISemaphore.sol';
import 'forge-std/console.sol';

/**
 * A paymaster that pays for all semeaphore members.
 */
contract SemaphorePaymaster is BasePaymaster {
    using UserOperationLib for PackedUserOperation;

    address private immutable _semaphore;
    uint256 private immutable _groupId;
    uint256 private constant VALID_TIMESTAMP_OFFSET = PAYMASTER_DATA_OFFSET;
    uint256 private constant SIGNATURE_OFFSET = VALID_TIMESTAMP_OFFSET + 64;

    constructor(IEntryPoint _entryPoint, address __semaphore, uint256 __groupId) BasePaymaster(_entryPoint) {
        _semaphore = __semaphore;
        _groupId = __groupId;
    }

    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 requiredPreFund
    ) internal view override returns (bytes memory context, uint256 validationData) {
        (requiredPreFund);
        (uint48 validUntil, uint48 validAfter, bytes memory signature) = parsePaymasterAndData(userOp.paymasterAndData);
        // ISemaphore.SemaphoreProof memory proof = abi.decode(signature, (ISemaphore.SemaphoreProof));
        // if (ISemaphore(_semaphore).verifyProof(_groupId, proof)) {
        //     return (signature, _packValidationData(false, validUntil, validAfter));
        // }
        // return ('', _packValidationData(true, validUntil, validAfter));
    }

    function _postOp(
        PostOpMode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) internal override {
        ISemaphore.SemaphoreProof memory proof = abi.decode(context, (ISemaphore.SemaphoreProof));
        ISemaphore(_semaphore).validateProof(_groupId, proof);
    }

    function parsePaymasterAndData(
        bytes calldata paymasterAndData
    ) public view returns (uint48 validUntil, uint48 validAfter, bytes memory signature) {
        paymasterAndData[VALID_TIMESTAMP_OFFSET:];
        // console.log(VALID_TIMESTAMP_OFFSET);
        (validUntil, validAfter, signature) = abi.decode(paymasterAndData, (uint48, uint48, bytes));
        // signature = paymasterAndData[SIGNATURE_OFFSET:];
    }
}
