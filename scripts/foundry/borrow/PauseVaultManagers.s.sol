// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { IVaultManagerFunctions } from "borrow/interfaces/IVaultManager.sol";
import { IERC721Metadata } from "oz/token/ERC721/extensions/IERC721Metadata.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, ITreasury, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

/** This script suppose that the state of all the vaultManager on the chain are identical (all paused or unpause) 
/** Otherwise behaviour is chaotic
*/
contract PauseVaultManagers is Utils {
    function run() external {
        bytes memory transactions;
        bytes memory additionalData;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        uint256 chainId = vm.envUint("CHAIN_ID");

        ITreasury treasury = _chainToTreasury(chainId);
        uint256 i;
        while (true) {
            try treasury.vaultManagerList(i) returns (address vault) {
                string memory name = IERC721Metadata(vault).name();
                console.log("Pausing %s", name);
                {
                    address to = vault;
                    bytes memory data = abi.encodeWithSelector(IVaultManagerFunctions.togglePause.selector);
                    additionalData = abi.encode(additionalData, data);
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
        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, additionalData);
    }
}
