// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { IVaultManagerFunctions } from "borrow/interfaces/IVaultManager.sol";
import { IERC721Metadata } from "oz/token/ERC721/extensions/IERC721Metadata.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import { SavingsNameable } from "transmuter/savings/nameable/SavingsNameable.sol";
import "../Constants.s.sol";

contract UpgradeSavingsNameable is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        uint256 chainId = vm.envUint("CHAIN_ID");
        address stEUR = _chainToContract(chainId, ContractType.StEUR);

        /** TODO  complete */
        address savingsImpl = address(0);
        /** END  complete */

        bytes memory nameAndSymbolData = abi.encodeWithSelector(SavingsNameable.setNameAndSymbol.selector, "Staked EURA", "stEURA");
        bytes memory data = abi.encodeWithSelector(ProxyAdmin.upgradeAndCall.selector, 0, savingsImpl, _chainToContract(chainId, ContractType.StEUR), nameAndSymbolData);
        uint256 dataLength = data.length;
        address to = _chainToContract(chainId, ContractType.ProxyAdmin);
        bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
        transactions = abi.encodePacked(transactions, internalTx);

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
