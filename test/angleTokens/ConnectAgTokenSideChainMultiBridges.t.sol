// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import "../../scripts/foundry/Constants.s.sol";

contract ConnectAgTokenSideChainMultiBridgesTest is BaseTest {
    function testScript() external {
        (Transaction[] memory transactions) = _deserializeJson();

        for (uint256 i = 0; i < transactions.length; i++) {
            Transaction memory transaction = transactions[i];
            address to = transaction.to;
            uint256 operation = transaction.operation;
            bytes memory payload = transaction.data;
            uint256 chainId = transaction.chainId;

            address gnosisSafe = _chainToContract(chainId, ContractType.GuardianMultisig);

            vm.selectFork(forkIdentifier[chainId]);

            // Verify that the call will succeed
            MockSafe mockSafe = new MockSafe();
            vm.etch(gnosisSafe, address(mockSafe).code);
            vm.prank(gnosisSafe);
            (bool success, ) = gnosisSafe.call(abi.encode(address(to), payload, operation, 1e6));
            if (!success) revert();
        }
    }
}
