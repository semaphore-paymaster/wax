pragma solidity ^0.8.0;

interface IPoap {
    function tokenDetailsOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256 tokenId, uint256 eventId);
}
