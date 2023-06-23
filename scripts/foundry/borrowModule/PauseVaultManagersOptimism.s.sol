// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { ITreasury } from "borrow/interfaces/ITreasury.sol";
import { VaultManager } from "borrow/vaultManager/VaultManager.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";

contract PauseVaultManagersOptimism is Utils {
    function run() external {
        address[] memory vaultManagerList = treasuryOptimism.getVaultManagerList();
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        for (uint256 i = 0; i < vaultManagerList.length; i++) {
            address vault = vaultManagerList[i];
            string memory name = VaultManager(vault).name();
            console.log("Pausing %s", name);
            {
                address to = vault;
                bytes memory data = abi.encodeWithSelector(VaultManager.togglePause.selector);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }
        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        // Verify that the calls will succeed
        vm.startBroadcast(address(guardianOptimismSafe));
        address(multiSendOptimism).call(payloadMultiSend);
        vm.stopBroadcast();

        _serializeJson(CHAIN_OPTIMISM, address(multiSendOptimism), 0, payloadMultiSend, Enum.Operation.DelegateCall);
    }
}
