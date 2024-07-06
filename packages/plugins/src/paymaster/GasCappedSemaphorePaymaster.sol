// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IEntryPoint} from 'account-abstraction/interfaces/IEntryPoint.sol';
import {BasePaymaster} from 'account-abstraction/core/BasePaymaster.sol';
import {UserOperationLib} from 'account-abstraction/core/UserOperationLib.sol';
import {PackedUserOperation} from 'account-abstraction/interfaces/PackedUserOperation.sol';
import {ISemaphore} from './interfaces/ISemaphore.sol';
import 'account-abstraction/core/Helpers.sol';

/// @title A paymaster that pays for all semeaphore members up to a predefined amount of gas the predefined interval.
contract GasCappedSemaphorePaymaster is BasePaymaster {
    using UserOperationLib for PackedUserOperation;

    /// @notice The semaphore contract address.
    /// @dev membership mamangement of the semaphore group is done externally.
    address public immutable semaphore;

    /// @notice The semaphore group id.
    uint256 public immutable groupId;

    /// @notice The gas cap per user in each interval.
    uint256 public immutable gasCapPerUser;

    /// @notice The gas refill interval. In each interval, the gas cap is reset.
    /// @notice The interval is global for all users.
    /// @dev The gas refill interval is in seconds.
    uint256 public immutable gasRefillInterval;

    /// @notice The start timestamp of the first interval.
    uint256 public immutable gasRefillIntervalStart;

    /// @notice The current interval number. This could potentially be different than the actual interval number.
    /// @dev The interval number is `(block.timestamp - gasRefillIntervalStart) / gasRefillInterval`.
    /// @dev The value is used in the _validatePaymasterUserOp function to check if the has not run out of gas
    /// @dev Since we can't access `block.timestamp` in _validatePaymasterUserOp, we need to cache it here
    uint256 public intervalNumber;

    /// @notice The gas used by each user in each interval.
    /// @dev The mapping is `intervalNumber => nullifier => gasUsed`.
    /// @dev semaphore nullifier can be used to identify the user in each interval.
    mapping(uint256 => mapping(uint256 => uint256)) gasUsed;

    /**
     * Constructor.
     * @param _entryPoint - The entry point.
     * @param _semaphore - The semaphore contract address.
     * @param _groupId   - The semaphore group id.
     * @param _gasCapPerUser - The gas cap per user in each interval.
     * @param _gasRefillInterval - The gas refill interval.
     * @param _gasRefillIntervalStart - The start timestamp of the first interval.
     */
    constructor(
        IEntryPoint _entryPoint,
        address _semaphore,
        uint256 _groupId,
        uint256 _gasCapPerUser,
        uint256 _gasRefillInterval,
        uint256 _gasRefillIntervalStart
    ) BasePaymaster(_entryPoint) {
        semaphore = _semaphore;
        groupId = _groupId;
        gasCapPerUser = _gasCapPerUser;
        gasRefillInterval = _gasRefillInterval;
        gasRefillIntervalStart = _gasRefillIntervalStart;
    }

    /**
     * Validate a user operation.
     * @param userOp         - The user operation.
     * @param requiredPreFund - The required pre-fund.
     * @return context        - abi encoded proof nullifier which will be used as identifier in post operation.
     */
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 requiredPreFund
    ) internal view override returns (bytes memory context, uint256 validationData) {
        (uint48 validUntil, uint48 validAfter, bytes memory signature) = parsePaymasterAndData(userOp.paymasterAndData);
        ISemaphore.SemaphoreProof memory proof = abi.decode(signature, (ISemaphore.SemaphoreProof));

        /// @notice message is always 0 for this paymaster.
        proof.message = 0;

        /// @notice scope should be the current interval number.
        proof.scope = intervalNumber;

        uint256 gasUsedByUser = gasUsed[intervalNumber][proof.nullifier];

        /// @notice If the user has used all the gas in the current interval, the user operation is invalid.
        if (gasUsedByUser + requiredPreFund > gasCapPerUser) {
            return ('', _packValidationData(true, validUntil, validAfter));
        }

        if (ISemaphore(semaphore).verifyProof(groupId, proof)) {
            return (abi.encode(proof.nullifier), _packValidationData(false, validUntil, validAfter));
        }

        return ('', _packValidationData(true, validUntil, validAfter));
    }

    /**
     * Post operation.
     * @param context               - expected to be abi encoded proof nullifier
     * @param actualGasCost         - The actual gas cost.
     */
    function _postOp(PostOpMode, bytes calldata context, uint256 actualGasCost, uint256) internal override {
        uint256 nullifier = abi.decode(context, (uint256));
        gasUsed[intervalNumber][nullifier] += actualGasCost;
    }

    /**
     * Parse the paymaster and data.
     * @param paymasterAndData - The paymaster and data.
     * @return validUntil - The valid until.
     * @return validAfter  - The valid after.
     * @return signature   - The signature.
     */
    function parsePaymasterAndData(
        bytes calldata paymasterAndData
    ) internal pure returns (uint48 validUntil, uint48 validAfter, bytes memory signature) {
        (, validUntil, validAfter, signature) = abi.decode(paymasterAndData, (address, uint48, uint48, bytes));
    }
}
