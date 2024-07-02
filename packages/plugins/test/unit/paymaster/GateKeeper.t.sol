// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import {TestHelper} from "../utils/TestHelper.sol";
import {PoapSemaphoreGatekeeper} from "../../../src/paymaster/Gatekeeper.sol";

/* solhint-disable func-name-mixedcase */

contract GateKeeperTest is TestHelper {
    constructor() TestHelper() {}

    PoapSemaphoreGatekeeper public gateKeeper;

    function setUp() public {
        gateKeeper = new PoapSemaphoreGatekeeper(address(0), address(0), 12);
    }
}
