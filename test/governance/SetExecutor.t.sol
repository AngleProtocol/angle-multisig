// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { TimelockController } from "oz/governance/TimelockController.sol";
import "../../scripts/foundry/Constants.s.sol";

contract SetExecutorTest is BaseTest {
    using stdJson for string;

    function setUp() public override {
        super.setUp();
    }

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        address gnosisSafe = _chainToContract(chainId, ContractType.GuardianMultisig);

        vm.selectFork(forkIdentifier[chainId]);

        TimelockController timelock = TimelockController(payable(_chainToContract(chainId, ContractType.Timelock)));

        address to = json.readAddress("$.to");
        uint256 operation = json.readUint("$.operation");
        bytes memory payload = json.readBytes("$.data");
        bytes memory additionalData = json.readBytes("$.additionalData");

        // Verify that the call will succeed
        MockSafe mockSafe = new MockSafe();
        vm.etch(gnosisSafe, address(mockSafe).code);
        vm.prank(gnosisSafe);
        (bool success, ) = gnosisSafe.call(abi.encode(address(to), payload, operation, 1e6));
        if (!success) revert();

        assertEq(timelock.hasRole(timelock.EXECUTOR_ROLE(), address(0)), true);
    }
}
