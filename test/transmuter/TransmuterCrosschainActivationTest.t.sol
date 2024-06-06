// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import "../../scripts/foundry/Constants.s.sol";
import "transmuter/transmuter/Storage.sol" as Storage;

interface ITransmuterExtended is ITransmuter {
    function getStablecoinCap(address collateral) external view returns (uint256);
}

contract TransmuterCrosschainActivationTest is BaseTest {
    using stdJson for string;

    ITransmuterExtended public transmuter;
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
        uint256 newCap = 2_000_000 ether;
        address receiver = 0xa9bbbDDe822789F123667044443dc7001fb43C01;
        uint256 amount = 100_000 ether;
        // TODO END

        address gnosisSafe = _chainToContract(chainId, ContractType.GovernorMultisig);
        transmuter = ITransmuterExtended(address(_getTransmuter(chainId, fiat)));
        agToken = _getAgToken(chainId, fiat);
        // There should only be one collateral
        collateralList = transmuter.getCollateralList();

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

        assertEq(agToken.isMinter(address(transmuter)), true);
        assertEq(collateralList.length, 1);
        for (uint256 i = 0; i < collateralList.length; i++) {
            assertEq(transmuter.getStablecoinCap(collateralList[i]), newCap);
        }

        // // No minter role
        // if (chainId == CHAIN_BASE) {
        //     assertGe(agToken.balanceOf(receiver), amount);
        // }

        // we ca do some quoteIn and quoteOut
        transmuter.quoteOut(BASE_18, address(collateralList[0]), address(agToken));
        transmuter.quoteIn(10 ** 6, address(collateralList[0]), address(agToken));
        // burn
        transmuter.quoteIn(BASE_18, address(agToken), address(collateralList[0]));
        transmuter.quoteOut(10 ** 6, address(agToken), address(collateralList[0]));

        // quoteRedeem To check if it is the right implementation
        transmuter.quoteRedemptionCurve(BASE_18);
    }
}
