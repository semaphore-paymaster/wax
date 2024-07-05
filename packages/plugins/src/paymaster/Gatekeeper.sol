pragma solidity >=0.8.4 <0.9.0;

import './interfaces/ISemaphore.sol';
import './interfaces/IPoap.sol';

contract PoapSemaphoreGatekeeper {
    address public immutable _semaphore;
    address public immutable _poap;
    uint256 public immutable _eventId;
    uint256 public _groupId;

    error InvalidToken();

    constructor(address __semaphore) {
        _semaphore = __semaphore;
        // _poap = __poap;
        // _eventId = __eventId;
    }

    function init() external {
        // for development purposes
        _groupId = ISemaphore(_semaphore).createGroup(address(this));
    }

    function validate(ISemaphore.SemaphoreProof calldata proof) external returns (bool) {
        if (ISemaphore(_semaphore).verifyProof(_groupId, proof)) {
            ISemaphore(_semaphore).validateProof(_groupId, proof);
            return true;
        }
        return false;
    }

    function enter(uint256 _tokenIndex, uint256 _identityCommitment) external {
        // (, uint256 eventId) = IPoap(_poap).tokenDetailsOfOwnerByIndex(msg.sender, _tokenIndex);
        // if (eventId != _eventId) revert InvalidToken();
        ISemaphore(_semaphore).addMember(_groupId, _identityCommitment);
    }
}
