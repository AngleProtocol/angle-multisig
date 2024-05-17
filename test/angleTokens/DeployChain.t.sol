// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { BaseTest } from "../BaseTest.t.sol";
import { console } from "forge-std/console.sol";
import "../../scripts/foundry/Constants.s.sol";

contract DeployChainTest is BaseTest {
    function testScript() external {
       uint256 chainId = vm.envUint("CHAIN_ID");

        string memory json = vm.readFile(JSON_ADDRESSES_PATH);
        CoreBorrow coreBorrow = CoreBorrow(payable(vm.parseJsonAddress(json, ".coreBorrow")));
        address governor = vm.parseJsonAddress(json, ".governor");
        address guardian = vm.parseJsonAddress(json, ".guardian");

        vm.selectFork(forkIdentifier[chainId]);
        assertTrue(coreBorrow.isGovernor(governor));
        assertTrue(coreBorrow.isGovernorOrGuardian(guardian));
    }
}
