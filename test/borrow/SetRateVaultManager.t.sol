// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { Utils } from "../Utils.s.sol";
import "../../scripts/foundry/Constants.s.sol";

contract SetRateVaultManagers is Utils {
    using stdJson for string;

    function setUp() public override {
        super.setUp();
    }

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        (uint256 fork, address gnosisSafe) = _chainToForkAndSafe(chainId);

        vm.selectFork(fork);

        address to = json.readAddress("$.to");
        uint256 operation = json.readUint("$.operation");
        bytes memory payload = json.readBytes("$.data");

        // Verify that the call will succeed
        MockSafe mockSafe = new MockSafe();
        vm.etch(gnosisSafe, address(mockSafe).code);
        vm.prank(gnosisSafe);
        (bool success, ) = gnosisSafe.call(abi.encode(address(to), payload, operation, 1e6));
        if (!success) revert();

        /** TODO modify */
        assertEq(uint256(IVaultManagerGovernance(0x9FFC8A23eafc25635DAe822eA9c4fF440226a001).interestRate()), fourRate);
        assertEq(
            uint256(IVaultManagerGovernance(0x8E2277929B2D849c0c344043D9B9507982e6aDd0).interestRate()),
            twoPoint5Rate
        );
    }
}
