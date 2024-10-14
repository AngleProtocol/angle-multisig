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

contract TransmuterAddCollateralXEVTTest is BaseTest {
    using stdJson for string;

    uint256 constant BPS = 1e14;

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
        StablecoinType fiat = StablecoinType.EUR;
        // TODO END

        address gnosisSafe = _chainToContract(chainId, ContractType.GovernorMultisig);
        transmuter = ITransmuter(address(_getTransmuter(chainId, fiat)));
        agToken = _getAgToken(chainId, fiat);

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

        collateralList = transmuter.getCollateralList();
        assertEq(agToken.isMinter(address(transmuter)), true);
        assertEq(collateralList.length, 4);
        assertEq(collateralList[3], address(0x3Ee320c9F73a84D1717557af00695A34b26d1F1d));

        // Check parameters are correct for the new collateral
        uint256 newCollateralIndex = 3;
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
            assertEq(xFeeBurn.length, 3);
            assertEq(yFeeBurn.length, 3);

            assertEq(xFeeMint[0], 0);
            assertEq(xFeeMint[1], 0.19e9);
            assertEq(xFeeMint[2], 0.20e9);
            assertEq(xFeeBurn[0], 1e9);
            assertEq(xFeeBurn[1], 0.06e9);
            assertEq(xFeeBurn[2], 0.05e9);

            assertEq(yFeeBurn[0], 0.005e9);
            assertEq(yFeeBurn[1], 0.005e9);
            assertEq(yFeeBurn[2], 0.999e9);
            assertEq(yFeeMint[0], 0);
            assertEq(yFeeMint[1], 0);
            assertEq(yFeeMint[2], 100e9 - 1);
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
            // assertEq(mint, BASE_18);
            // assertEq(burn, BASE_18);
            // assertEq(ratio, BASE_18);
            // assertEq(redemption, BASE_18);
        }

        // Check quotes are working on the added collateral
        {
            // we ca do some quoteIn and quoteOut
            transmuter.quoteOut(BASE_18, newCollateral, address(agToken);
            transmuter.quoteIn(BASE_18, newCollateral, address(agToken)));
        }

        transmuter.quoteRedemptionCurve(BASE_18);
    }
}