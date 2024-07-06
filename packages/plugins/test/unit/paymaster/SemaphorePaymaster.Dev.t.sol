// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import 'forge-std/Test.sol';
import 'forge-std/console.sol';
import {TestHelper} from '../utils/TestHelper.sol';
import {SemaphorePaymasterDev} from '../../../src/paymaster/SemaphorePaymasterDev.sol';
import {ISemaphore} from '../../../src/paymaster/interfaces/ISemaphore.sol';
import {IPoap} from '../../../src/paymaster/interfaces/IPoap.sol';
import {IEntryPoint} from 'account-abstraction/interfaces/IEntryPoint.sol';
import {PackedUserOperation} from 'account-abstraction/interfaces/PackedUserOperation.sol';
import 'account-abstraction/core/Helpers.sol';
import 'account-abstraction/interfaces/IPaymaster.sol';

/* solhint-disable func-name-mixedcase */

contract SemaphorePaymasterWrapper is SemaphorePaymasterDev {
    constructor(
        IEntryPoint _entryPoint,
        address __semaphore,
        uint256 __groupId
    ) SemaphorePaymasterDev(_entryPoint, __semaphore, __groupId) {}

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

    function test_decode() public {
        PackedUserOperation memory userOp = buildUserOp();

        bytes
            memory paymasterAndData = '0x000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000001d406ac093a0eaf39e5018fcaecc13fffa8732517c700000000000000000000000000003bf6000000000000000000000000000021ce00000000000000000000000000000000000000000000000000000000000000031de297c34acccf52ccc8df601a716f029cfaffe7e0381a1f03a98688245de4db14f788df88ecace682c395c0b2d693328ca4b3e262de14c5690a9f1f2b6c4c350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021f447c9e416786f1e5abcd2a027e40a208622239ca1826f890c29e1622e1dd8241ad838d4c206d67f0f1fa8e6daeaa190b4d6bd23ea592a00580fae6156ff341d032edab17b7321b09d5bf6e248d64760181ceb6daa0f44afec1b700e246fb31c2b9824b0bed191e63dbf4909f14ed2e8564f17abff6a59bcb05a0639017ad525d908fca4eeefb153808bad7885088c7a46125d6fb78bcddb3423c75e29b5a50f7a8bdc7736bca0a0502524b2882e86a51a8b2ea28c089c9a8d7ef65d4abca12e6973cf662e58e430019e6dceed284944f1e895d2c1ebd45f4a5e1743a05e421cc0d817cd8a9bb65f7df77b40d4434d065b4988b859c7aaa42808e2e42598d3000000000000000000000000';
        userOp.paymasterAndData = paymasterAndData;

        console.log(paymasterAndData.length);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        // _mockAndExpect(
        //     semaphore,
        //     abi.encodeWithSelector(ISemaphore.verifyProof.selector, groupId, proof),
        //     abi.encode(true)
        // );
        (bytes memory context, uint256 validationData) = paymaster.performValidatePaymasterUserOp(userOp, 0, 0);
        console.logBytes(context);
        // uint256 exptectedValidationData = _packValidationData(false, 10, 20);
        // assertEq(validationData, exptectedValidationData);
        // assertEq(context, signature);
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
