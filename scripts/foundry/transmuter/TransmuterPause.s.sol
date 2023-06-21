// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ProxyAdmin } from "oz/proxy/transparent/ProxyAdmin.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, ITransmuter, Utils } from "../Utils.s.sol";

contract PauseTransmuter is Utils {
    function run() external {
        // address[] memory collateralList = transmuter.getCollateralList();
        // bytes memory transactions;
        // uint8 isDelegateCall = 0;
        // address to = address(transmuter);
        // uint256 value = 0;
        // {
        //     bytes memory data = abi.encodeWithSelector(
        //         ITransmuter.togglePause.selector,
        //         address(0x0),
        //         Storage.ActionType.Redeem
        //     );
        //     uint256 dataLength = data.length;
        //     bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
        //     transactions = abi.encodePacked(transactions, internalTx);
        // }
        // for (uint256 i = 0; i < collateralList.length; i++) {
        //     address collateral = collateralList[i];
        //     console.log("Pausing %s", collateral);
        //     {
        //         bytes memory data = abi.encodeWithSelector(
        //             ITransmuter.togglePause.selector,
        //             collateral,
        //             Storage.ActionType.Mint
        //         );
        //         uint256 dataLength = data.length;
        //         bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
        //         transactions = abi.encodePacked(transactions, internalTx);
        //     }
        //     {
        //         bytes memory data = abi.encodeWithSelector(
        //             ITransmuter.togglePause.selector,
        //             collateral,
        //             Storage.ActionType.Burn
        //         );
        //         uint256 dataLength = data.length;
        //         bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
        //         transactions = abi.encodePacked(transactions, internalTx);
        //     }
        // }
        // bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        // // console.logBytes(payloadMultiSend);
        // _serializeJson(address(multiSendMainnet), 0, payloadMultiSend, Enum.Operation.Call);
    }
}
