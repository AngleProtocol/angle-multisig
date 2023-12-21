// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { Utils } from "../Utils.s.sol";
import "../../scripts/foundry/Constants.s.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { IERC20 } from "oz/token/ERC20/IERC20.sol";

contract InitAndBoostrapTest is Utils {
    using stdJson for string;

    function setUp() public override {
        super.setUp();
    }

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        uint256 fork = _chainToFork(chainId);
        address gnosisSafe = _chainToContract(chainId, ContractType.GuardianMultisig);
        address agEUR = _chainToContract(chainId, ContractType.AgEUR);
        vm.selectFork(fork);

        ITransmuter transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));
        IAgToken agToken = IAgToken(_chainToContract(chainId, ContractType.AgEUR));

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

        assertEq(IERC20(EUROC).balanceOf(address(transmuter)), 9_500_000 * 10 ** 6);
        assertEq(IERC20(BC3M).balanceOf(address(transmuter)), 38446 * BASE_18);
        assertEq(transmuter.isPaused(address(EUROC), Storage.ActionType.Mint), false);
        assertEq(transmuter.isPaused(address(EUROC), Storage.ActionType.Burn), false);
        assertEq(transmuter.isPaused(address(BC3M), Storage.ActionType.Mint), false);
        assertEq(transmuter.isPaused(address(BC3M), Storage.ActionType.Burn), false);
        assertEq(transmuter.isPaused(address(0), Storage.ActionType.Redeem), false);

        // we ca do some quoteIn and quoteOut
        transmuter.quoteOut(BASE_18, address(EUROC), address(agEUR));
        transmuter.quoteIn(10 ** 6, address(EUROC), address(agEUR));
        transmuter.quoteOut(BASE_18, address(BC3M), address(agEUR));
        transmuter.quoteIn(BASE_18, address(BC3M), address(agEUR));
        // burn
        transmuter.quoteIn(BASE_18, address(agEUR), address(EUROC));
        transmuter.quoteOut(10 ** 6, address(agEUR), address(EUROC));
        transmuter.quoteIn(BASE_18, address(agEUR), address(BC3M));
        transmuter.quoteOut(BASE_18, address(agEUR), address(BC3M));

        // quoteRedeem To check if it is the right implementation
        transmuter.quoteRedemptionCurve(BASE_18);
    }
}
