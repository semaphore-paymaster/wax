pragma solidity 0.8.23;
import {ISemaphore} from "./ISemaphore.sol";

interface ISemaphoreGateKeeper {
    function validate(ISemaphore.SemaphoreProof calldata proof) external returns (bool);
}
