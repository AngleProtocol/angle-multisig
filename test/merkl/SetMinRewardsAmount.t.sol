// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { Utils } from "../Utils.s.sol";
import { IDistributionCreator } from "../../scripts/foundry/merkl/SetMinAmountsRewardToken.s.sol";
import "../../scripts/foundry/Constants.s.sol";

contract SetMinRewardsAmount is Utils {
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

        // TODO complete for the tokens
        uint256 CHAIN = 0;
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        tokens[0] = address(0);
        amounts[0] = 0;
        // end TODO

        for (uint256 i = 0; i < tokens.length; i++)
            console.log(
                tokens[i],
                uint256(IDistributionCreator(distributionCreator).rewardTokenMinAmounts(tokens[i])),
                amounts[i]
            );
    }
}
