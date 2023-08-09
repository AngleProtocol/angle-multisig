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
        (uint256 fork, address gnosisSafe) = chainId == 1
            ? (ethereumFork, address(governorEthereumSafe))
            : chainId == 10
            ? (optimismFork, address(governorOptimismSafe))
            : chainId == 137
            ? (polygonFork, address(governorPolygonSafe))
            : chainId == 42161
            ? (arbitrumFork, address(governorArbitrumSafe))
            : (avalancheFork, address(governorAvalancheSafe));

        vm.selectFork(fork);

        address to = json.readAddress("$.to");
        uint256 value = json.readUint("$.value");
        uint256 operation = json.readUint("$.operation");
        bytes memory payload = json.readBytes("$.data");

        // Verify that the call will succeed
        MockSafe mockSafe = new MockSafe();
        vm.etch(gnosisSafe, address(mockSafe).code);
        vm.prank(gnosisSafe);
        (bool success, ) = gnosisSafe.call(abi.encode(address(to), payload, operation, 1e6));
        if (!success) revert();

        assertEq(IERC20(EUROC).balanceOf(address(transmuter)), 9_500_000 * 10 ** 6);
        // assertEq(IERC20(BC3M).balanceOf(address(transmuter)), 4_500_000 * BASE_18);
        assertEq(transmuter.isPaused(address(EUROC), Storage.ActionType.Mint), false);
        assertEq(transmuter.isPaused(address(EUROC), Storage.ActionType.Burn), false);
        assertEq(transmuter.isPaused(address(BC3M), Storage.ActionType.Mint), false);
        assertEq(transmuter.isPaused(address(BC3M), Storage.ActionType.Burn), false);
        assertEq(transmuter.isPaused(address(0), Storage.ActionType.Redeem), false);

        // we ca do some quoteIn and quoteOut
        transmuter.quoteOut(BASE_18, address(EUROC), address(agEUREthereum));
        transmuter.quoteIn(10 ** 6, address(EUROC), address(agEUREthereum));
        // transmuter.quoteOut(BASE_18, address(BC3M), address(agEUREthereum));
        // transmuter.quoteIn(BASE_18, address(BC3M), address(agEUREthereum));
        // burn
        transmuter.quoteIn(BASE_18, address(agEUREthereum), address(EUROC));
        transmuter.quoteOut(10 ** 6, address(agEUREthereum), address(EUROC));
        // transmuter.quoteIn(BASE_18, address(agEUREthereum), address(BC3M));
        // transmuter.quoteOut(BASE_18, address(agEUREthereum), address(BC3M));
    }
}
