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

contract TransmuterRevokeAddCollateralTest is BaseTest {
    using stdJson for string;

    uint256 constant BPS = 1e14;
    address collateralRevoked = BC3M;
    ITransmuter public transmuter;
    IAgToken public agToken;
    address[] public collateralList;

    function setUp() public override {
        super.setUp();
    }

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        vm.selectFork(forkIdentifier[chainId]);

        // TODO
        StablecoinType fiat = StablecoinType.USD;
        // TODO END

        address gnosisSafe = _chainToContract(chainId, ContractType.GovernorMultisig);
        transmuter = ITransmuter(address(_getTransmuter(chainId, fiat)));
        agToken = _getAgToken(chainId, fiat);
        collateralList = transmuter.getCollateralList();

        address to = json.readAddress("$.to");
        // uint256 value = json.readUint("$.value");
        uint256 operation = json.readUint("$.operation");
        bytes memory payload = json.readBytes("$.data");

        // We fake a USDA balance (we need to send it to the governance multisig)
        deal(address(agToken), address(gnosisSafe), 2_000_000 * BASE_18);

        // Verify that the call will succeed
        MockSafe mockSafe = new MockSafe();
        vm.etch(gnosisSafe, address(mockSafe).code);
        vm.prank(gnosisSafe);
        (bool success, ) = gnosisSafe.call(abi.encode(address(to), payload, operation, 1e6));
        if (!success) revert();

        assertEq(agToken.isMinter(address(transmuter)), true);
        assertEq(collateralList.length, 3);
        // USDC
        assertEq(collateralList[0], address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
        assertEq(collateralList[1], address(0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C));
        assertEq(collateralList[2], address(0xBEEF01735c132Ada46AA9aA4c54623cAA92A64CB));

        // Check parameters are correct for the new collateral
        uint256 newCollateralIndex = 1;
        address newCollateral = collateralList[newCollateralIndex];
        {
            (
                Storage.OracleReadType oracleType,
                Storage.OracleReadType targetType,
                bytes memory oracleData,
                bytes memory targetData,
                bytes memory hyperparameters
            ) = transmuter.getOracle(newCollateral);
            assertEq(uint256(oracleType), uint256(Storage.OracleReadType.NO_ORACLE));
            assertEq(uint256(targetType), uint256(Storage.OracleReadType.STABLE));
            assertEq(oracleData.length, 0);
            assertEq(targetData.length, 0);
            assertEq(hyperparameters, abi.encode(uint128(0), uint128(50 * BPS)));
        }

        {
            (uint64[] memory xFeeMint, int64[] memory yFeeMint) = transmuter.getCollateralMintFees(newCollateral);
            (uint64[] memory xFeeBurn, int64[] memory yFeeBurn) = transmuter.getCollateralBurnFees(newCollateral);

            assertEq(xFeeMint.length, 3);
            assertEq(yFeeMint.length, 3);
            assertEq(xFeeMint[0], 0);
            assertEq(yFeeMint[0], 0);
            assertEq(xFeeMint[1], uint64((49 * BASE_9) / 100));
            assertEq(yFeeMint[1], 0);
            assertEq(xFeeMint[2], uint64((50 * BASE_9) / 100));
            assertEq(yFeeMint[2], int64(uint64(MAX_MINT_FEE)));

            assertEq(xFeeBurn.length, 3);
            assertEq(yFeeBurn.length, 3);
            assertEq(xFeeBurn[0], 1000000000);
            assertEq(yFeeBurn[0], int64(uint64((50 * BASE_9) / 10000)));
            assertEq(xFeeBurn[1], uint64((26 * BASE_9) / 100));
            assertEq(yFeeBurn[1], int64(uint64((50 * BASE_9) / 10000)));
            assertEq(xFeeBurn[2], uint64((25 * BASE_9) / 100));
            assertEq(yFeeBurn[2], 999000000);
        }

        // Check storage revoke collat
        {
            Storage.Collateral memory collatInfo = transmuter.getCollateralInfo(address(collateralRevoked));
            assertEq(collatInfo.isManaged, 0);
            assertEq(collatInfo.isMintLive, 1);
            assertEq(collatInfo.isBurnLive, 1);
            assertEq(collatInfo.decimals, 18);
            assertEq(collatInfo.onlyWhitelisted, 0);
            assertEq(collatInfo.normalizedStables, 0);
            assertEq(collatInfo.managerData.subCollaterals.length, 0);
            assertEq(collatInfo.managerData.config.length, 0);
        }

        // Check storage new collat
        {
            Storage.Collateral memory collatInfo = transmuter.getCollateralInfo(newCollateral);
            assertEq(collatInfo.isManaged, 0);
            assertEq(collatInfo.isMintLive, 1);
            assertEq(collatInfo.isBurnLive, 1);
            assertEq(collatInfo.decimals, 18);
            assertEq(collatInfo.onlyWhitelisted, 0);
            assertEq(collatInfo.normalizedStables, 0);
            assertEq(collatInfo.managerData.subCollaterals.length, 0);
            assertEq(collatInfo.managerData.config.length, 0);
        }

        // Test oracle values returned
        {
            (uint256 mint, uint256 burn, uint256 ratio, uint256 minRatio, uint256 redemption) = transmuter
                .getOracleValues(newCollateral);
            assertEq(mint, BASE_18);
            assertEq(burn, BASE_18);
            assertEq(ratio, BASE_18);
            assertEq(redemption, BASE_18);
        }

        // Check reverting quotes on old collateral
        {
            vm.expectRevert(Errors.InvalidSwap.selector);
            transmuter.quoteOut(BASE_18, collateralRevoked, address(agToken));
            vm.expectRevert(Errors.InvalidSwap.selector);
            transmuter.quoteIn(BASE_18, collateralRevoked, address(agToken));
            // burn
            vm.expectRevert(Errors.InvalidSwap.selector);
            transmuter.quoteIn(BASE_18, address(agToken), collateralRevoked);
            vm.expectRevert(Errors.InvalidSwap.selector);
            transmuter.quoteOut(BASE_18, address(agToken), collateralRevoked);
        }

        // Check quotes are working on the added collateral
        {
            // we ca do some quoteIn and quoteOut
            assertEq(BASE_18, transmuter.quoteOut(BASE_18, newCollateral, address(agToken)));
            assertEq(BASE_18, transmuter.quoteIn(BASE_18, newCollateral, address(agToken)));
            // burn
            assertEq(BASE_18, transmuter.quoteIn(BASE_18, address(agToken), newCollateral));
            assertEq(BASE_18, transmuter.quoteOut(BASE_18, address(agToken), newCollateral));
        }

        transmuter.quoteRedemptionCurve(BASE_18);
    }
}
