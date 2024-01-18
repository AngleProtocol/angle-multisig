// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { IDistributionCreator } from "../../scripts/foundry/merkl/SetMinAmountsRewardToken.s.sol";
import "../../scripts/foundry/Constants.s.sol";

contract SetMinAmountsRewardTokenTest is BaseTest {
    using stdJson for string;

    function setUp() public override {
        super.setUp();
    }

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        address gnosisSafe = _chainToContract(chainId, ContractType.GuardianMultisig);

        vm.selectFork(forkIdentifier[chainId]);

        IDistributionCreator distributionCreator = IDistributionCreator(
            _chainToContract(chainId, ContractType.DistributionCreator)
        );

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

        /** Automatically detect what are the params set from your script */
        additionalData = slice(additionalData, 4, additionalData.length - 4);
        (address[] memory tokens, uint256[] memory amounts) = abi.decode(additionalData, (address[], uint256[]));

        for (uint256 i = 0; i < tokens.length; i++) {
            console.log(amounts[i], tokens[i]);
            assertEq(uint256(distributionCreator.rewardTokenMinAmounts(tokens[i])), amounts[i]);
        }
    }
}
