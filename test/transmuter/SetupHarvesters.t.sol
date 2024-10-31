// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { BaseHarvester } from "transmuter/helpers/BaseHarvester.sol";
import { MultiBlockHarvester } from "transmuter/helpers/MultiBlockHarvester.sol";
import "../../scripts/foundry/Constants.s.sol";

contract SetupHarvestersTest is BaseTest {
    using stdJson for string;

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        address safe = json.readAddress("$.safe");
        vm.selectFork(forkIdentifier[chainId]);

        /** TODO  complete */
        address keeper = 0xa9bbbDDe822789F123667044443dc7001fb43C01;
        uint64 minExposureStable = 0e9;
        uint64 maxExposureStable = 1e9;
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

        {
            address multiBlockHarvesterUSD = 0x5BEdD878CBfaF4dc53EC272A291A6a4C2259369D;

            // USDM
            uint64 targetExposureUSDM = 0.50e9;

            assertEq(BaseHarvester(multiBlockHarvesterUSD).isTrusted(keeper), true);
            {
                (
                    address asset,
                    uint64 target,
                    uint64 maxExposure,
                    uint64 minExposure,
                    uint64 overrideExp
                ) = BaseHarvester(multiBlockHarvesterUSD).yieldBearingData(address(USDM));
                assertEq(asset, address(USDC));
                assertEq(target, targetExposureUSDM);
                assertEq(minExposure, minExposureStable);
                assertEq(maxExposure, maxExposureStable);
                assertEq(overrideExp, 2);
            }

            assertEq(
                MultiBlockHarvester(multiBlockHarvesterUSD).yieldBearingToDepositAddress(USDM),
                0x78A42Aa9b25Cd00823Ebb34DDDCF38224D99e0C8
            );
        }

        {
            address multiBlockHarvesterEUR = 0x0A10f87F55d89eb2a89c264ebE46C90785a10B77;

            // XEVT
            uint64 targetExposureXEVT = 0.125e9;

            assertEq(BaseHarvester(multiBlockHarvesterEUR).isTrusted(keeper), true);
            {
                (
                    address asset,
                    uint64 target,
                    uint64 maxExposure,
                    uint64 minExposure,
                    uint64 overrideExp
                ) = BaseHarvester(multiBlockHarvesterEUR).yieldBearingData(address(XEVT));
                assertEq(asset, address(EUROC));
                assertEq(target, targetExposureXEVT);
                assertEq(overrideExp, 2);
                assertEq(minExposure, minExposureStable);
                assertEq(maxExposure, maxExposureStable);
            }

            assertEq(MultiBlockHarvester(multiBlockHarvesterEUR).yieldBearingToDepositAddress(XEVT), XEVT);
        }

        {
            address genericHarvesterUSD = 0x54b96Fee8208Ea7aCe3d415e5c14798112909794;

            // steaksUSDC
            uint64 targetExposureSteakUSDC = 0.35e9;

            {
                (
                    address asset,
                    uint64 target,
                    uint64 maxExposure,
                    uint64 minExposure,
                    uint64 overrideExp
                ) = BaseHarvester(genericHarvesterUSD).yieldBearingData(address(STEAK_USDC));
                assertEq(asset, address(USDC));
                assertEq(target, targetExposureSteakUSDC);
                assertEq(overrideExp, 2);
                assertEq(minExposure, minExposureStable);
                assertEq(maxExposure, maxExposureStable);
            }
        }
    }
}
