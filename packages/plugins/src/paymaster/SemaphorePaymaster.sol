// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IEntryPoint} from 'account-abstraction/interfaces/IEntryPoint.sol';
import {BasePaymaster} from 'account-abstraction/core/BasePaymaster.sol';
import {UserOperationLib} from 'account-abstraction/core/UserOperationLib.sol';
import 'account-abstraction/core/Helpers.sol';
import {PackedUserOperation} from 'account-abstraction/interfaces/PackedUserOperation.sol';
import {ISemaphore} from './interfaces/ISemaphore.sol';

/// @title A paymaster that pays for all semeaphore members.
contract SemaphorePaymaster is BasePaymaster {
    using UserOperationLib for PackedUserOperation;

    address private immutable _semaphore;
    uint256 private immutable _groupId;

    /**
     * Constructor.
     * @param _entryPoint - The entry point.
     * @param __semaphore - The semaphore contract address.
     * @param __groupId   - The semaphore group id.
     */
    constructor(IEntryPoint _entryPoint, address __semaphore, uint256 __groupId) BasePaymaster(_entryPoint) {
        _semaphore = __semaphore;
        _groupId = __groupId;
    }

    /**
     * Validate a user operation.
     * @param userOp         - The user operation.
     * @param requiredPreFund - The required pre-fund.
     */
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 requiredPreFund
    ) internal view override returns (bytes memory context, uint256 validationData) {
        ISemaphore.SemaphoreProof memory proof = abi.decode(
            userOp.paymasterAndData[PAYMASTER_DATA_OFFSET:],
            (ISemaphore.SemaphoreProof)
        );
        if (ISemaphore(_semaphore).verifyProof(_groupId, proof)) {
            return (abi.encode(proof), _packValidationData(false, 0, 0));
        }
        return ('', _packValidationData(true, 0, 0));
    }

    /**
     * Post operation.
     * @param context               - The context.
     * @param actualGasCost         - The actual gas cost.
     * @param actualUserOpFeePerGas - The actual user operation fee per gas.
     */
    function _postOp(
        PostOpMode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) internal override {
        // ISemaphore.SemaphoreProof memory proof = abi.decode(context, (ISemaphore.SemaphoreProof));
        // ISemaphore(_semaphore).validateProof(_groupId, proof);
    }
}
