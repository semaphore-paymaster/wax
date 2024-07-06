// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import {IEntryPoint} from 'account-abstraction/interfaces/IEntryPoint.sol';
import {BasePaymaster} from 'account-abstraction/core/BasePaymaster.sol';
import {UserOperationLib} from 'account-abstraction/core/UserOperationLib.sol';
import 'account-abstraction/core/Helpers.sol';
import {PackedUserOperation} from 'account-abstraction/interfaces/PackedUserOperation.sol';
import {ISemaphore} from './interfaces/ISemaphore.sol';
import 'forge-std/console.sol';

/// @title A paymaster that pays for all semeaphore members.
contract SemaphorePaymasterDev is BasePaymaster {
    using UserOperationLib for PackedUserOperation;

    address public _semaphore;
    uint256 public _groupId;

    uint256 private constant VALID_TIMESTAMP_OFFSET = 84;
    uint256 private constant SIGNATURE_OFFSET = VALID_TIMESTAMP_OFFSET + 64;

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

    event Log(bytes data);

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
        // (uint48 validUntil, uint48 validAfter, bytes memory signature) = parsePaymasterAndData(userOp.paymasterAndData);
        // ISemaphore.SemaphoreProof memory proof = abi.decode(signature, (ISemaphore.SemaphoreProof));
        // bytes memory data = userOp.paymasterAndData[232 / 2:(232 + 832) / 2];
        ISemaphore.SemaphoreProof memory proof = abi.decode(userOp.paymasterAndData[52:], (ISemaphore.SemaphoreProof));
        console.logBytes(userOp.paymasterAndData);
        if (ISemaphore(_semaphore).verifyProof(_groupId, proof)) {
            return (abi.encode(proof), _packValidationData(false, 0, 0));
        }
        // return ('', _packValidationData(true, 0, 0));
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
        emit Log(context);
        // must nullifie the semaphore proof. But we don't do that for ease of demonstration.
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
        // validUntil = uint48(bytes6(paymasterAndData[20:26]));
        // validAfter = uint48(bytes6(paymasterAndData[26:32]));
        signature = paymasterAndData[116:];
        // (validUntil, validAfter) = abi.decode(paymasterAndData[VALID_TIMESTAMP_OFFSET:], (uint48, uint48));
        // signature = paymasterAndData[SIGNATURE_OFFSET:];
    }

    // setters

    function setSemaphore(address __semaphore) external {
        _semaphore = __semaphore;
    }

    function setGroupId(uint256 __groupId) external {
        _groupId = __groupId;
    }
}
