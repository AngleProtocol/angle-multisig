// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { ERC20 } from "oz/token/ERC20/ERC20.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";

contract SendTokens is Utils {
    function run() external {
        bytes memory transactions;

        uint8 isDelegateCall = 0;
        address to = address(0x912CE59144191C1204E64559FE8253a0e49E6548);
        uint256 value = 0;
        bytes memory data = abi.encodeWithSelector(
            ERC20.transfer.selector,
            1 * BASE_18,
            0xfdA462548Ce04282f4B6D6619823a7C64Fdc0185
        );
        uint256 dataLength = data.length;
        bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
        transactions = abi.encodePacked(transactions, internalTx);

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        // console.logBytes(payloadMultiSend);
        _serializeJson(address(multiSendArbitrum), 0, payloadMultiSend, Enum.Operation.Call);
    }
}
