pragma solidity 0.8.23;

import "./interfaces/ISemaphore.sol";

contract PoapSemaphoreGatekeeper {
    address private immutable _semaphore;
    address private immutable _poap;
    uint256 private immutable _groupId;
    uint256 private immutable _eventId;

    error InvalidToken();

    constructor(address __semaphore) {
        semaphore = __semaphore;
        _groupId = ISemaphore(semaphore).createGroup(address(this));
    }

    function validate(ISemaphore.SemaphoreProof calldata proof) returns (bool) {
        if (ISemaphore(semaphore).verify(_groupId, proof)) {
            ISemaphore(semaphore).validate(_groupId, proof);
            return true;
        }
        return false;
    }

    function enter(uint256 _tokenIndex, uint256 _identityCommitment) {
        (uint256 tokenId, uint256 eventId) = IPoap(poap)
            .tokenDetailsOfOwnerByIndex(msg.sender, _tokenIndex);
        if (eventId != _eventId) revert InvalidToken();
        ISemaphore(semaphore).addMember(_groupId, _identityCommitment);
    }
}
