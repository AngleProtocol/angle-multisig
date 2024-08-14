// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { IDistribution } from "../../scripts/foundry/merkl/ResolveDispute.s.sol";
import "../../scripts/foundry/Constants.s.sol";

contract ResolveDisputeTest is BaseTest {
    using stdJson for string;

    function setUp() public override {
        super.setUp();
    }

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        address gnosisSafe = _chainToContract(chainId, ContractType.AngleLabsMultisig);

        vm.selectFork(forkIdentifier[chainId]);

        IDistribution distributor = IDistribution(_chainToContract(chainId, ContractType.Distributor));
        IAgToken agEUR = IAgToken(_chainToContract(chainId, ContractType.AgEUR));

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

        assertEq(distributor.disputer(), address(0));
        assertGe(agEUR.balanceOf(0xF4c94b2FdC2efA4ad4b831f312E7eF74890705DA), 100 ether);
    }
}
