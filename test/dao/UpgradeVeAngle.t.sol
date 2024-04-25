// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../scripts/foundry/Constants.s.sol";

contract UpgradeVeAngleTest is BaseTest {
    using stdJson for string;

    function setUp() public override {
        super.setUp();
    }

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        address gnosisSafe = address(_chainToContract(chainId, ContractType.GovernorMultisig));

        vm.selectFork(forkIdentifier[chainId]);

        IVeAngle veANGLE = IVeAngle(_chainToContract(chainId, ContractType.veANGLE));

        address to = json.readAddress("$.to");
        // uint256 value = json.readUint("$.value");
        uint256 operation = json.readUint("$.operation");
        bytes memory payload = json.readBytes("$.data");

        // Verify that the call will succeed
        MockSafe mockSafe = new MockSafe();
        vm.etch(gnosisSafe, address(mockSafe).code);
        vm.prank(gnosisSafe);
        (bool success, ) = gnosisSafe.call(abi.encode(address(to), payload, operation, 1e6));
        if (!success) revert();

        // Verify that emergency withdrawal can be enabled
        assertEq(veANGLE.emergency_withdrawal(), false);
        vm.prank(veANGLE.admin());
        veANGLE.set_emergency_withdrawal();
        assertEq(veANGLE.emergency_withdrawal(), true);
    }
}
