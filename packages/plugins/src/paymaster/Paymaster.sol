// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IEntryPoint} from 'account-abstraction/interfaces/IEntryPoint.sol';

import {BasePaymaster} from 'account-abstraction/core/BasePaymaster.sol';
import {UserOperationLib} from 'account-abstraction/core/UserOperationLib.sol';
import 'account-abstraction/core/Helpers.sol';
import {PackedUserOperation} from 'account-abstraction/interfaces/PackedUserOperation.sol';
import {ISemaphore} from './interfaces/ISemaphore.sol';

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

        (uint48 validUntil, uint48 validAfter, bytes calldata signature) = parsePaymasterAndData(
            userOp.paymasterAndData
        );

        bool isValid = ISemaphore(_semaphore).verifyProof(_groupId, abi.decode(signature, (ISemaphore.SemaphoreProof)));

        if (isValid) {
            return ('', _packValidationData(true, validUntil, validAfter));
        }

        return ('', _packValidationData(false, validUntil, validAfter));
    }

    function parsePaymasterAndData(
        bytes calldata paymasterAndData
    ) public pure returns (uint48 validUntil, uint48 validAfter, bytes calldata signature) {
        (validUntil, validAfter) = abi.decode(paymasterAndData[VALID_TIMESTAMP_OFFSET:], (uint48, uint48));
        signature = paymasterAndData[SIGNATURE_OFFSET:];
    }
}
