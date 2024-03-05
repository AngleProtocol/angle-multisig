// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { IVaultManagerFunctions } from "borrow/interfaces/IVaultManager.sol";
import { IERC721Metadata } from "oz/token/ERC721/extensions/IERC721Metadata.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract UpgradeAgTokenNameable is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        uint256 chainId = vm.envUint("CHAIN_ID");

        /** TODO  complete */
        address agToken = _chainToContract(chainId, ContractType.AgEUR);
        address agTokenImpl = address(0);
        string memory name = "EURA"; // Previously "AgEUR"
        string memory symbol = "EURA"; // Previously "AgEUR"
        /** END  complete */

        bytes memory nameAndSymbolData = abi.encodeWithSelector(INameable.setNameAndSymbol.selector, name, symbol);
        bytes memory data = abi.encodeWithSelector(ProxyAdmin.upgradeAndCall.selector, agToken, agTokenImpl, "");
        address to = _chainToContract(chainId, ContractType.ProxyAdmin);
        bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
        bytes memory nameAndSymbolTx = abi.encodePacked(isDelegateCall, agToken, value, nameAndSymbolData.length, nameAndSymbolData);
        transactions = abi.encodePacked(transactions, internalTx);
        transactions = abi.encodePacked(transactions, nameAndSymbolTx);

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        // Verify that the calls will succeed
        address multiSend = address(_chainToMultiSend(chainId));
        address guardian = address(_chainToContract(chainId, ContractType.GuardianMultisig));
        vm.startBroadcast(guardian);
        address(multiSend).delegatecall(payloadMultiSend);
        vm.stopBroadcast();
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, data);
    }
}