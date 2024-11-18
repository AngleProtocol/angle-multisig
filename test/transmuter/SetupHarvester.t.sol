// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { BaseHarvester } from "transmuter/helpers/BaseHarvester.sol";
import { IGetters } from "transmuter/interfaces/IGetters.sol";
import { MultiBlockHarvester } from "transmuter/helpers/MultiBlockHarvester.sol";
import "../../scripts/foundry/Constants.s.sol";

contract SetupHarvesterTest is BaseTest {
    using stdJson for string;

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        address safe = json.readAddress("$.safe");
        vm.selectFork(forkIdentifier[chainId]);

        /** TODO  complete */
        address harvester = 0x0A10f87F55d89eb2a89c264ebE46C90785a10B77;
        address keeper = 0xa9bbbDDe822789F123667044443dc7001fb43C01;
        uint64 targetExposure = 0.35e9;
        address asset = EUROC;
        address yieldBearingAsset = XEVT;
        bool isGenericHarvester = false;
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

        if (!isGenericHarvester) {
            assertEq(BaseHarvester(harvester).isTrusted(keeper), true);

            assertEq(
                MultiBlockHarvester(harvester).yieldBearingToDepositAddress(USDM),
                0x78A42Aa9b25Cd00823Ebb34DDDCF38224D99e0C8
            );
        }

        {
            address transmuter = _chainToContract(chainId, ContractType.TransmuterAgEUR);
            assertEq(IGetters(transmuter).isTrusted(harvester), true);
        }

        {
            (
                address _asset,
                uint64 target,
                uint64 maxExposure,
                uint64 minExposure,
                uint64 overrideExp
            ) = BaseHarvester(harvester).yieldBearingData(yieldBearingAsset);
            assertEq(_asset, asset);
            assertEq(target, targetExposure);
        }


    }
}
