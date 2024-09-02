// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import "../../scripts/foundry/Constants.s.sol";

contract ActivateSavingsTest is BaseTest {
    using stdJson for string;

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        address safe = json.readAddress("$.safe");
        vm.selectFork(forkIdentifier[chainId]);

         /** TODO  complete */
        address stToken = 0x004626A008B1aCdC4c74ab51644093b155e59A23; // _chainToContract(chainId, ContractType.StEUR);
        address treasury = _chainToContract(chainId, ContractType.TreasuryAgEUR);
        address keeper = 0xa9bbbDDe822789F123667044443dc7001fb43C01;
        uint256 rate = 3022265993024575488;
        /** END  complete */

        address to = json.readAddress("$.to");
        // uint256 value = json.readUint("$.value");
        uint256 operation = json.readUint("$.operation");
        bytes memory payload = json.readBytes("$.data");

        // Verify that the call will succeed
        MockSafe mockSafe = new MockSafe();
        vm.etch(safe, address(mockSafe).code);
        vm.prank(safe);
        (bool success, ) = safe.call(abi.encode(address(to), payload, operation, 1e6));
        if (!success) revert();

        assertEq(ISavings(stToken).maxRate(), rate);
        address stablecoin = address(ITreasury(treasury).stablecoin());
        assertEq(IAgToken(stablecoin).isMinter(stToken), true);
        assertEq(ISavings(stToken).isTrustedUpdater(keeper), true);
    }
}
