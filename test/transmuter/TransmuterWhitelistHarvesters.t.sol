// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import "../../scripts/foundry/Constants.s.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import "transmuter/utils/Errors.sol" as Errors;
import { ITransmuter, ISettersGovernor, ISettersGuardian, ISwapper, IGetters } from "transmuter/interfaces/ITransmuter.sol";
import { MAX_MINT_FEE, MAX_BURN_FEE } from "transmuter/utils/Constants.sol";
import { IERC20 } from "oz/token/ERC20/IERC20.sol";

contract TransmuterWhitelistHarvestersTest is BaseTest {
    using stdJson for string;

    ITransmuter public transmuter;

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        address gnosisSafe = json.readAddress("$.safe");
        vm.selectFork(forkIdentifier[chainId]);

        address to = json.readAddress("$.to");
        // uint256 value = json.readUint("$.value");
        uint256 operation = json.readUint("$.operation");
        bytes memory payload = json.readBytes("$.data");

        // Verify that the call will succeed
        MockSafe mockSafe = new MockSafe();
        vm.etch(gnosisSafe, address(mockSafe).code);
        vm.prank(gnosisSafe);
        (bool success, ) = gnosisSafe.call(abi.encode(address(to), payload, operation, 1e7));
        if (!success) revert();

        {
            transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));
            assertEq(IGetters(address(transmuter)).isTrustedSeller(address(0x0A10f87F55d89eb2a89c264ebE46C90785a10B77)), true);
        }
        {
            transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgUSD));
            assertEq(IGetters(address(transmuter)).isTrustedSeller(address(0x54b96Fee8208Ea7aCe3d415e5c14798112909794)), true);
            assertEq(IGetters(address(transmuter)).isTrustedSeller(address(0x5BEdD878CBfaF4dc53EC272A291A6a4C2259369D)), true);
        }
    }
}
