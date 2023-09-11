// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { IVaultManagerFunctions } from "borrow/interfaces/IVaultManager.sol";
import { IERC721Metadata } from "oz/token/ERC721/extensions/IERC721Metadata.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract SavingsSetRateEthereum is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        uint208 rate = uint208(uint256(fourRate));
        bytes memory data = abi.encodeWithSelector(ISavings.setRate.selector,rate);
        uint256 dataLength = data.length;
        address to=stEUR;
        bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
        transactions = abi.encodePacked(transactions, internalTx);

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        // Verify that the calls will succeed
        vm.startBroadcast(address(guardianEthereumSafe));
        address(multiSendEthereum).delegatecall(payloadMultiSend);
        vm.stopBroadcast();

        _serializeJson(CHAIN_ETHEREUM, address(multiSendEthereum), 0, payloadMultiSend, Enum.Operation.DelegateCall);
    }
}
