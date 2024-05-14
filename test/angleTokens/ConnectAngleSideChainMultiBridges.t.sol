// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { console } from "forge-std/console.sol";
import { NonblockingLzApp } from "angle-tokens/agToken/layerZero/utils/NonblockingLzApp.sol";
import { IERC20 } from "oz/token/ERC20/IERC20.sol";
import "../../scripts/foundry/Constants.s.sol";

contract ConnectAngleSideChainMultiBridgesTest is BaseTest {
    function testScript() external {
        (Transaction[] memory transactions) = _deserializeJson();

        for (uint256 i = 0; i < transactions.length; i++) {
            Transaction memory transaction = transactions[i];
            address to = transaction.to;
            uint256 operation = transaction.operation;
            bytes memory payload = transaction.data;
            uint256 chainId = transaction.chainId;

            address gnosisSafe = _chainToContract(chainId, ContractType.GuardianMultisig);

            vm.selectFork(forkIdentifier[chainId]);

            // Verify that the call will succeed
            MockSafe mockSafe = new MockSafe();
            vm.etch(gnosisSafe, address(mockSafe).code);
            vm.prank(gnosisSafe);
            (bool success, ) = gnosisSafe.call(abi.encode(address(to), payload, operation, 1e6));
            if (!success) revert();
        }

        uint256 chainId = vm.envUint("CHAIN_ID");
        string memory json = vm.readFile(JSON_ADDRESSES_PATH);
        address lzToken = vm.parseJsonAddress(json, ".lzAngle");
        address angle = vm.parseJsonAddress(json, ".angle");

        (uint256[] memory chainIds, address[] memory contracts) = _getConnectedChains("ANGLE");
        for (uint256 i = 0; i < contracts.length; i++) {
            if (chainIds[i] == chainId || chainIds[i] == CHAIN_ETHEREUM) {
                continue;
            }

            vm.selectFork(forkIdentifier[chainIds[i]]);
            uint256 amount = 1e18;
            address receiver = vm.addr(1);
            bytes memory payload = abi.encode(abi.encodePacked(receiver), amount);

            hoax(address(_lzEndPoint(chainIds[i])));
            NonblockingLzApp(contracts[i]).lzReceive(
                _getLZChainId(chainId),
                abi.encodePacked(lzToken, contracts[i]),
                0,
                payload
            );

            address token = _chainToContract(chainIds[i], ContractType.Angle);
            assertEq(IERC20(token).balanceOf(receiver), amount);
        }

        vm.selectFork(forkIdentifier[chainId]);
        for (uint256 i = 0; i < contracts.length; i++) {
            if (chainIds[i] == chainId) {
                continue;
            }

            uint256 amount = 1e18;
            address receiver = vm.addr(1);
            bytes memory payload = abi.encode(abi.encodePacked(receiver), amount);

            hoax(address(_lzEndPoint(chainId)));
            NonblockingLzApp(lzToken).lzReceive(
                _getLZChainId(chainIds[i]),
                abi.encodePacked(contracts[i], lzToken),
                0,
                payload
            );

            assertEq(IERC20(angle).balanceOf(receiver), amount);
        }
    }
}