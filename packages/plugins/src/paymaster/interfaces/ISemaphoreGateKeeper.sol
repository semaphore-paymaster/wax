pragma solidity >=0.8.4 <0.9.0;
import {ISemaphore} from './ISemaphore.sol';

interface ISemaphoreGateKeeper {
    function validate(ISemaphore.SemaphoreProof calldata proof) external returns (bool);
    function enter(uint256 _tokenIndex, uint256 _identityCommitment) external;
    function semaphore() external view returns (address);
    function poap() external view returns (address);
    function eventId() external view returns (uint256);
}
