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

contract TransmuterAddCollateralMWEURCTest is BaseTest {
    using stdJson for string;

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

        // address gnosisSafe = _chainToContract(chainId, ContractType.GovernorMultisig);
        // transmuter = ITransmuter(address(_getTransmuter(chainId, fiat)));
        // agToken = _getAgToken(chainId, fiat);

        address gnosisSafe = 0x7DF37fc774843b678f586D55483819605228a0ae;
        transmuter = ITransmuter(0xBA0e73218a80C3deC1213d64873aF83B02cE0455);
        agToken = IAgToken(address(transmuter.agToken()));

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

        uint256 newCollateralIndex = 1;
        collateralList = transmuter.getCollateralList();
        assertEq(agToken.isMinter(address(transmuter)), true);
        assertEq(collateralList.length, 2);
        assertEq(collateralList[newCollateralIndex], address(0xf24608E0CCb972b0b0f4A6446a0BBf58c701a026));

        // Check parameters are correct for the new collateral
        address newCollateral = collateralList[newCollateralIndex];
        {
            (
                Storage.OracleReadType oracleType,
                Storage.OracleReadType targetType,
                bytes memory oracleData,
                bytes memory targetData,
                bytes memory hyperparameters
            ) = transmuter.getOracle(newCollateral);

            bytes memory readData;
            {
                address oracle = 0xa7ea0d40C246b876F76713Ba9a9A95f3f18AB794;
                uint256 normalizationFactor = 1e18;
                readData = abi.encode(oracle, normalizationFactor);
            }
            assertEq(uint256(oracleType), uint256(Storage.OracleReadType.MORPHO_ORACLE));
            assertEq(uint256(targetType), uint256(Storage.OracleReadType.MAX));
            assertEq(oracleData, readData);
            assertEq(targetData, abi.encode(1008235463728948111));
            assertEq(hyperparameters, abi.encode(uint128(0), uint128(0.0005e18)));
        }

        {
            (uint64[] memory xFeeMint, int64[] memory yFeeMint) = transmuter.getCollateralMintFees(newCollateral);
            (uint64[] memory xFeeBurn, int64[] memory yFeeBurn) = transmuter.getCollateralBurnFees(newCollateral);

            assertEq(xFeeMint.length, 3);
            assertEq(yFeeMint.length, 3);
            assertEq(xFeeBurn.length, 3);
            assertEq(yFeeBurn.length, 3);

            assertEq(xFeeBurn[0], 1e9);
            assertEq(xFeeBurn[1], 0.21e9);
            assertEq(xFeeBurn[2], 0.20e9);
            assertEq(yFeeBurn[0], 0.005e9);
            assertEq(yFeeBurn[1], 0.005e9);
            assertEq(yFeeBurn[2], int64(uint64(MAX_BURN_FEE)));

            assertEq(xFeeMint[0], 0);
            assertEq(xFeeMint[1], 0.59e9);
            assertEq(xFeeMint[2], 0.60e9);
            assertEq(yFeeMint[0], 0.0005e9);
            assertEq(yFeeMint[1], 0.0005e9);
            assertEq(yFeeMint[2], int64(uint64(MAX_MINT_FEE)));
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

        {
            // Test oracle values returned
            uint256 value = IERC4626(newCollateral).convertToAssets(1 ether) * 1e12;
            (uint256 mint, uint256 burn, uint256 ratio, uint256 minRatio, uint256 redemption) = transmuter
                .getOracleValues(newCollateral);
            assertApproxEqAbs(mint, value, 0.01 ether);
            assertApproxEqAbs(burn, value, 0.01 ether);
            assertApproxEqAbs(ratio, BASE_18, 0.01 ether);
            assertApproxEqAbs(redemption, value,0.01 ether);
        }

        // Check quotes are working on the added collateral
        {
            // we can do some quoteIn and quoteOut
            uint256 mintedAmount = transmuter.quoteIn(1 ether, newCollateral, address(agToken));
            assertApproxEqAbs(mintedAmount, 1 ether, 0.01 ether);
            uint256 fromAmount = transmuter.quoteOut(1 ether, newCollateral, address(agToken));
            assertApproxEqAbs(fromAmount, 1 ether, 0.01 ether);
        }

        transmuter.quoteRedemptionCurve(BASE_18);
    }
}
