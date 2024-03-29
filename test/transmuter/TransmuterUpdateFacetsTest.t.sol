// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { TransmuterUtils, Utils } from "../../scripts/foundry/transmuter/updateFacets/TransmuterUtils.s.sol";
import "../../scripts/foundry/Constants.s.sol";
import { OldTransmuter } from "../../scripts/foundry/transmuter/updateFacets/TransmuterUpdateFacets.s.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { AggregatorV3Interface } from "transmuter/interfaces/external/chainlink/AggregatorV3Interface.sol";
import { BASE_8, MAX_MINT_FEE, MAX_BURN_FEE } from "transmuter/utils/Constants.sol";

contract TransmuterUpdateFacetsTest is BaseTest, TransmuterUtils {
    using stdJson for string;

    ITransmuter transmuter;

    // TODO COMPLETE
    bytes public oracleConfigDataEUROC =
        hex"0000000000000000000000004305fb66699c3b2702d4d05cf36551390a4c69c600000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000276fa85158bf14ede77087fe3ae472f66213f6ea2f5b411cb2de472794990fa5ca995d00bb36a63cef7fd2c287dc105fc8f3d93779f062f09551b0af3e81ec30b000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000001275000000000000000000000000000000000000000000000000000000000000127500000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000";
    bytes public oracleConfigDataBC3M =
        hex"00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e000000000000000000000000000000000000000000000000000000000000001200000000000000000000000000000000000000000000000000000000000000160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000006e27a25999b3c665e44d903b2139f5a4be2b6c260000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000003f4800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";
    bytes public oracleConfigDataBERNX =
        hex"00000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000120000000000000000000000000000000000000000000000000000000000000016000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000475855dae09af1e3f2d380d766b9e630926ad3ce0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000003f4800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000008";
    //

    function setUp() public override(Utils, BaseTest) {
        BaseTest.setUp();

        uint256 chainId = json.readUint("$.chainId");

        // special case as we rely on the fork state
        // vm.selectFork(forkIdentifier[CHAIN_FORK]);
        vm.selectFork(forkIdentifier[chainId]);

        vm.pauseGasMetering();

        // As there are calls to price feeds and there are delays to be respected we need to mock calls
        // to escape from `InvalidChainlinkRate()` error
        vm.mockCall(
            address(0x6E27A25999B3C665E44D903B2139F5a4Be2B6C26),
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(0), int256(11979000000), uint256(block.timestamp), uint256(block.timestamp), uint80(0))
        );

        address gnosisSafe = _chainToContract(chainId, ContractType.GovernorMultisig);

        transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));

        address to = json.readAddress("$.to");
        // uint256 value = json.readUint("$.value");
        uint256 operation = json.readUint("$.operation");
        bytes memory payload = json.readBytes("$.data");

        // Verify that the call will succeed
        MockSafe mockSafe = new MockSafe();
        vm.etch(gnosisSafe, address(mockSafe).code);
        vm.prank(gnosisSafe);
        (bool success, ) = gnosisSafe.call(abi.encode(address(to), payload, operation, 1e6));
        if (!success) revert();
    }

    function test_script() external {
        // Now test that everything is as expected
        uint256 chainId = CHAIN_SOURCE;
        transmuter = ITransmuter(payable(_chainToContract(chainId, ContractType.TransmuterAgEUR)));

        _testAccessControlManager();
        _testAgToken();
        _testGetCollateralList();
        _testGetCollateralInfo();
        _testGetOracleValues();
    }

    function _testAccessControlManager() internal {
        assertEq(address(transmuter.accessControlManager()), _chainToContract(CHAIN_SOURCE, ContractType.CoreBorrow));
    }

    function _testAgToken() internal {
        assertEq(address(transmuter.agToken()), _chainToContract(CHAIN_SOURCE, ContractType.AgEUR));
    }

    function _testGetCollateralList() internal {
        address[] memory collateralList = transmuter.getCollateralList();
        assertEq(collateralList.length, 3);
        assertEq(collateralList[0], address(EUROC));
        assertEq(collateralList[1], address(BC3M));
        assertEq(collateralList[2], address(BERNX));
    }

    function _testGetCollateralInfo() internal {
        {
            Storage.Collateral memory collatInfoEUROC = transmuter.getCollateralInfo(address(EUROC));
            assertEq(collatInfoEUROC.isManaged, 0);
            assertEq(collatInfoEUROC.isMintLive, 1);
            assertEq(collatInfoEUROC.isBurnLive, 1);
            assertEq(collatInfoEUROC.decimals, 6);
            assertEq(collatInfoEUROC.onlyWhitelisted, 0);
            assertApproxEqRel(collatInfoEUROC.normalizedStables, 9539025 * BASE_18, 100 * BPS);
            assertEq(collatInfoEUROC.whitelistData.length, 0);
            assertEq(collatInfoEUROC.managerData.subCollaterals.length, 0);
            assertEq(collatInfoEUROC.managerData.config.length, 0);
            {
                (
                    Storage.OracleReadType oracleType,
                    Storage.OracleReadType targetType,
                    bytes memory oracleData,
                    bytes memory targetData,
                    bytes memory hyperparams
                ) = abi.decode(
                        collatInfoEUROC.oracleConfig,
                        (Storage.OracleReadType, Storage.OracleReadType, bytes, bytes, bytes)
                    );
                assertEq(uint8(oracleType), uint8(8));
                assertEq(uint8(targetType), uint8(3));
                assertEq(oracleData, oracleConfigDataEUROC);
                assertEq(targetData, hex"");
                assertEq(hyperparams, abi.encode(USER_PROTECTION_EUROC, FIREWALL_BURN_RATIO_EUROC));
            }
            {
                assertEq(collatInfoEUROC.xFeeMint.length, 3);
                assertEq(collatInfoEUROC.yFeeMint.length, 3);
                assertEq(collatInfoEUROC.xFeeMint[0], 0);
                assertEq(collatInfoEUROC.yFeeMint[0], 0);
                assertEq(collatInfoEUROC.xFeeMint[1], uint64((69 * BASE_9) / 100));
                assertEq(collatInfoEUROC.yFeeMint[1], 0);
                assertEq(collatInfoEUROC.xFeeMint[2], uint64((70 * BASE_9) / 100));
                assertEq(collatInfoEUROC.yFeeMint[2], int64(uint64(MAX_MINT_FEE)));
            }
            {
                assertEq(collatInfoEUROC.xFeeBurn.length, 3);
                assertEq(collatInfoEUROC.yFeeBurn.length, 3);
                assertEq(collatInfoEUROC.xFeeBurn[0], 1000000000);
                assertEq(collatInfoEUROC.yFeeBurn[0], 0);
                assertEq(collatInfoEUROC.xFeeBurn[1], uint64((11 * BASE_9) / 100));
                assertEq(collatInfoEUROC.yFeeBurn[1], 0);
                assertEq(collatInfoEUROC.xFeeBurn[2], uint64((10 * BASE_9) / 100));
                assertEq(collatInfoEUROC.yFeeBurn[2], 999000000);
            }
        }

        {
            Storage.Collateral memory collatInfoBC3M = transmuter.getCollateralInfo(address(BC3M));
            assertEq(collatInfoBC3M.isManaged, 0);
            assertEq(collatInfoBC3M.isMintLive, 1);
            assertEq(collatInfoBC3M.isBurnLive, 1);
            assertEq(collatInfoBC3M.decimals, 18);
            assertEq(collatInfoBC3M.onlyWhitelisted, 1);
            assertApproxEqRel(collatInfoBC3M.normalizedStables, 6236650 * BASE_18, 100 * BPS);
            {
                (
                    Storage.OracleReadType oracleType,
                    Storage.OracleReadType targetType,
                    bytes memory oracleData,
                    bytes memory targetData,
                    bytes memory hyperparams
                ) = abi.decode(
                        collatInfoBC3M.oracleConfig,
                        (Storage.OracleReadType, Storage.OracleReadType, bytes, bytes, bytes)
                    );

                assertEq(uint8(oracleType), uint8(0));
                assertEq(uint8(targetType), uint8(9));
                assertEq(oracleData, oracleConfigDataBC3M);
                assertEq(hyperparams, abi.encode(USER_PROTECTION_BC3M, FIREWALL_BURN_RATIO_BC3M));

                uint256 maxValue = abi.decode(targetData, (uint256));
                assertApproxEqRel(maxValue, (1198 * BASE_18) / 10, 10 * BPS);
            }

            {
                (Storage.WhitelistType whitelist, bytes memory data) = abi.decode(
                    collatInfoBC3M.whitelistData,
                    (Storage.WhitelistType, bytes)
                );
                address keyringGuard = abi.decode(data, (address));
                assertEq(uint8(whitelist), uint8(Storage.WhitelistType.BACKED));
                assertEq(keyringGuard, 0x9391B14dB2d43687Ea1f6E546390ED4b20766c46);
            }
            assertEq(collatInfoBC3M.managerData.subCollaterals.length, 0);
            assertEq(collatInfoBC3M.managerData.config.length, 0);

            {
                assertEq(collatInfoBC3M.xFeeMint.length, 3);
                assertEq(collatInfoBC3M.yFeeMint.length, 3);
                assertEq(collatInfoBC3M.xFeeMint[0], 0);
                assertEq(collatInfoBC3M.yFeeMint[0], 0);
                assertEq(collatInfoBC3M.xFeeMint[1], uint64((49 * BASE_9) / 100));
                assertEq(collatInfoBC3M.yFeeMint[1], 0);
                assertEq(collatInfoBC3M.xFeeMint[2], uint64((50 * BASE_9) / 100));
                assertEq(collatInfoBC3M.yFeeMint[2], int64(uint64(MAX_MINT_FEE)));
            }
            {
                assertEq(collatInfoBC3M.xFeeBurn.length, 3);
                assertEq(collatInfoBC3M.yFeeBurn.length, 3);
                assertEq(collatInfoBC3M.xFeeBurn[0], 1000000000);
                assertEq(collatInfoBC3M.yFeeBurn[0], int64(uint64((50 * BASE_9) / 10000)));
                assertEq(collatInfoBC3M.xFeeBurn[1], uint64((26 * BASE_9) / 100));
                assertEq(collatInfoBC3M.yFeeBurn[1], int64(uint64((50 * BASE_9) / 10000)));
                assertEq(collatInfoBC3M.xFeeBurn[2], uint64((25 * BASE_9) / 100));
                assertEq(collatInfoBC3M.yFeeBurn[2], 999000000);
            }
        }

        {
            Storage.Collateral memory collatInfoBERNX = transmuter.getCollateralInfo(address(BERNX));
            assertEq(collatInfoBERNX.isManaged, 0);
            assertEq(collatInfoBERNX.isMintLive, 1);
            assertEq(collatInfoBERNX.isBurnLive, 1);
            assertEq(collatInfoBERNX.decimals, 18);
            assertEq(collatInfoBERNX.onlyWhitelisted, 1);
            assertEq(collatInfoBERNX.normalizedStables, 0);

            {
                (
                    Storage.OracleReadType oracleType,
                    Storage.OracleReadType targetType,
                    bytes memory oracleData,
                    bytes memory targetData,
                    bytes memory hyperparams
                ) = abi.decode(
                        collatInfoBERNX.oracleConfig,
                        (Storage.OracleReadType, Storage.OracleReadType, bytes, bytes, bytes)
                    );

                assertEq(uint8(oracleType), uint8(0));
                assertEq(uint8(targetType), uint8(9));
                assertEq(oracleData, oracleConfigDataBERNX);
                assertEq(hyperparams, abi.encode(USER_PROTECTION_BERNX, FIREWALL_BURN_RATIO_BERNX));

                uint256 maxValue = abi.decode(targetData, (uint256));

                assertApproxEqRel(maxValue, (523 * BASE_18) / 100, 10 * BPS);
            }

            {
                (Storage.WhitelistType whitelist, bytes memory data) = abi.decode(
                    collatInfoBERNX.whitelistData,
                    (Storage.WhitelistType, bytes)
                );
                address keyringGuard = abi.decode(data, (address));
                assertEq(uint8(whitelist), uint8(Storage.WhitelistType.BACKED));
                assertEq(keyringGuard, 0x9391B14dB2d43687Ea1f6E546390ED4b20766c46);
            }
            assertEq(collatInfoBERNX.managerData.subCollaterals.length, 0);
            assertEq(collatInfoBERNX.managerData.config.length, 0);

            {
                assertEq(collatInfoBERNX.xFeeMint.length, 3);
                assertEq(collatInfoBERNX.yFeeMint.length, 3);
                assertEq(collatInfoBERNX.xFeeMint[0], 0);
                assertEq(collatInfoBERNX.yFeeMint[0], 0);
                assertEq(collatInfoBERNX.xFeeMint[1], uint64((49 * BASE_9) / 100));
                assertEq(collatInfoBERNX.yFeeMint[1], 0);
                assertEq(collatInfoBERNX.xFeeMint[2], uint64((50 * BASE_9) / 100));
                assertEq(collatInfoBERNX.yFeeMint[2], int64(uint64(MAX_MINT_FEE)));
            }
            {
                assertEq(collatInfoBERNX.xFeeBurn.length, 3);
                assertEq(collatInfoBERNX.yFeeBurn.length, 3);
                assertEq(collatInfoBERNX.xFeeBurn[0], 1000000000);
                assertEq(collatInfoBERNX.yFeeBurn[0], int64(uint64((50 * BASE_9) / 10000)));
                assertEq(collatInfoBERNX.xFeeBurn[1], uint64((26 * BASE_9) / 100));
                assertEq(collatInfoBERNX.yFeeBurn[1], int64(uint64((50 * BASE_9) / 10000)));
                assertEq(collatInfoBERNX.xFeeBurn[2], uint64((25 * BASE_9) / 100));
                assertEq(collatInfoBERNX.yFeeBurn[2], 999000000);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                        ORACLE                                                      
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function _testGetOracleValues() internal {
        _checkOracleValues(address(EUROC), BASE_18, USER_PROTECTION_EUROC, FIREWALL_BURN_RATIO_EUROC);
        _checkOracleValues(address(BC3M), (11949 * BASE_18) / 100, USER_PROTECTION_BC3M, FIREWALL_BURN_RATIO_BC3M);
        _checkOracleValues(address(BERNX), (523 * BASE_18) / 100, USER_PROTECTION_BERNX, FIREWALL_BURN_RATIO_BERNX);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                        CHECKS                                                      
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function _checkOracleValues(
        address collateral,
        uint256 targetValue,
        uint128 userProtection,
        uint128 firewallBurn
    ) internal {
        (uint256 mint, uint256 burn, uint256 ratio, uint256 minRatio, uint256 redemption) = transmuter.getOracleValues(
            collateral
        );
        assertApproxEqRel(targetValue, redemption, 200 * BPS);

        if (
            targetValue * (BASE_18 - userProtection) < redemption * BASE_18 &&
            redemption * BASE_18 < targetValue * (BASE_18 + userProtection)
        ) assertEq(burn, targetValue);
        else assertEq(burn, redemption);

        if (
            targetValue * (BASE_18 - userProtection) < redemption * BASE_18 &&
            redemption * BASE_18 < targetValue * (BASE_18 + userProtection)
        ) {
            assertEq(mint, targetValue);
            assertEq(ratio, BASE_18);
        } else if (redemption * BASE_18 < targetValue * (BASE_18 - firewallBurn)) {
            assertEq(mint, redemption);
            assertEq(ratio, (redemption * BASE_18) / targetValue);
        } else {
            assertEq(mint, redemption);
            assertEq(ratio, BASE_18);
        }
    }
}
