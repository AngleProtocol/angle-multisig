// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { IVaultManagerFunctions } from "borrow/interfaces/IVaultManager.sol";
import { IERC721Metadata } from "oz/token/ERC721/extensions/IERC721Metadata.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract SetRateVaultManagerOptimism is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        uint256 i;

        while (true) {
            try treasuryOptimism.vaultManagerList(i) returns (address vault) {
                uint64 rate;
                // Non yield bearing vaults
                if (i==0 || i==1 || i==2|| i==3) rate = twoPoint5Rate;
                else rate = fourRate;
                string memory name = IERC721Metadata(vault).name();
                console.log("Setting rate %s", name);
                {
                    address to = vault;
                    bytes32 what = "IR";
                    bytes memory data = abi.encodeWithSelector(IVaultManagerGovernance.setUint64.selector,rate, what);
                    uint256 dataLength = data.length;
                    bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                    transactions = abi.encodePacked(transactions, internalTx);
                }
                i++;
            } catch {
                break;
            }
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        // Verify that the calls will succeed
        vm.startBroadcast(address(guardianOptimismSafe));
        address(multiSendOptimism).delegatecall(payloadMultiSend);
        vm.stopBroadcast();

        _serializeJson(CHAIN_OPTIMISM, address(multiSendOptimism), 0, payloadMultiSend, Enum.Operation.DelegateCall);
    }
}
