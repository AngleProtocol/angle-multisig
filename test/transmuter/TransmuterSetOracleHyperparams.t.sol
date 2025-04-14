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

contract TransmuterSetOracleHyperparamsTest is BaseTest {
    using stdJson for string;

    address collateral = 0x60a3E35Cc302bFA44Cb288Bc5a4F316Fdb1adb42;

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
        // address gnosisSafe = 0x7DF37fc774843b678f586D55483819605228a0ae;
        // transmuter = ITransmuter(0xBA0e73218a80C3deC1213d64873aF83B02cE0455);

        agToken = _getAgToken(chainId, fiat);
        // agToken = IAgToken(0xA61BeB4A3d02decb01039e378237032B351125B4);

        assertEq(transmuter.isTrustedSeller(0xa9bbbDDe822789F123667044443dc7001fb43C01), false);

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

        (
            Storage.OracleReadType oracleType,
            Storage.OracleReadType targetType,
            bytes memory oracleData,
            bytes memory targetData,
            bytes memory hyperparameters
        ) = transmuter.getOracle(collateral);

        assertEq(uint256(oracleType), uint256(Storage.OracleReadType.PYTH));
        assertEq(uint256(targetType), uint256(Storage.OracleReadType.STABLE));
        assertEq(
            oracleData,
            hex"0000000000000000000000008250f4af4b972684f7b336503e2d6dfedeb1487a00000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000276fa85158bf14ede77087fe3ae472f66213f6ea2f5b411cb2de472794990fa5ca995d00bb36a63cef7fd2c287dc105fc8f3d93779f062f09551b0af3e81ec30b000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000001275000000000000000000000000000000000000000000000000000000000000127500000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000"
        );
        assertEq(targetData.length, 0);
        assertEq(hyperparameters, abi.encode(uint128(1000000000000000), uint128(0)));

        assertEq(transmuter.isTrustedSeller(0xa9bbbDDe822789F123667044443dc7001fb43C01), true);
    }
}
