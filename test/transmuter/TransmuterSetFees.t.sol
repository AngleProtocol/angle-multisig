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
import { IERC4626 } from "oz/token/ERC20/extensions/ERC4626.sol";
import { BaseHarvester } from "transmuter/helpers/BaseHarvester.sol";

contract TransmuterSetFeesTest is BaseTest {
    using stdJson for string;

    ITransmuter public transmuter;
    IAgToken public agToken;

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        address safe = json.readAddress("$.safe");
        vm.selectFork(forkIdentifier[chainId]);


        transmuter = transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));
        agToken = IAgToken(address(transmuter.agToken()));

        address to = json.readAddress("$.to");
        // uint256 value = json.readUint("$.value");
        uint256 operation = json.readUint("$.operation");
        bytes memory payload = json.readBytes("$.data");

        // Verify that the call will succeed
        MockSafe mockSafe = new MockSafe();
        vm.etch(safe, address(mockSafe).code);
        vm.prank(safe);
        (bool success, ) = safe.call(abi.encode(address(to), payload, operation, 1e7));
        if (!success) revert();

        address collateral = 0x3Ee320c9F73a84D1717557af00695A34b26d1F1d;
        {
            (uint64[] memory xFeeBurn, int64[] memory yFeeBurn) = transmuter.getCollateralBurnFees(collateral);

            assertEq(xFeeBurn.length, 1);
            assertEq(yFeeBurn.length, 1);

            assertEq(xFeeBurn[0], 1e9);
            assertEq(yFeeBurn[0], 0);
        }

        // Check quotes are working on the added collateral
        {
            // we ca do some quoteIn and quoteOut
            transmuter.quoteOut(BASE_18, collateral, address(agToken));
            transmuter.quoteIn(BASE_18, collateral, address(agToken));
        }

        transmuter.quoteRedemptionCurve(BASE_18);

        {
            BaseHarvester harvester = BaseHarvester(0x0A10f87F55d89eb2a89c264ebE46C90785a10B77);
            (, uint64 target,,,) = harvester.yieldBearingData(collateral);
            assertEq(target, 0);
        }
    }
}
