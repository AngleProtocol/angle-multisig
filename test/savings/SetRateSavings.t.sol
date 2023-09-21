// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { Utils } from "../Utils.s.sol";
import "../../scripts/foundry/Constants.s.sol";

contract SetRateSavings is Utils {
    using stdJson for string;

    function setUp() public override {
        super.setUp();
    }

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        (uint256 fork, address gnosisSafe) = chainId == 1
            ? (ethereumFork, address(guardianEthereumSafe))
            : chainId == 10
            ? (optimismFork, address(guardianOptimismSafe))
            : chainId == 137
            ? (polygonFork, address(guardianPolygonSafe))
            : chainId == 42161
            ? (arbitrumFork, address(guardianArbitrumSafe))
            : (avalancheFork, address(guardianAvalancheSafe));

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

        assertEq(uint256(ISavings(stEUR).rate()),fourRate);


    }
}
