// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ISettersGuardian } from "transmuter/interfaces/ISetters.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract PauseTransmuter is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        address to = address(transmuter);
        uint256 value = 0;

        uint256 chainId = vm.envUint("CHAIN_ID");

        /** TODO  complete */
        uint64[] memory xFee = new uint64[](2);
        int64[] memory yFee = new int64[](2);

        xFee[0] = 0;
        xFee[1] = uint64(BASE_9);
        yFee[0] = 0;
        yFee[1] = 0;
        /** END  complete */

        bytes memory data = abi.encodeWithSelector(ISettersGuardian.setRedemptionCurveParams.selector, xFee, yFee);
        uint256 dataLength = data.length;
        bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
        transactions = abi.encodePacked(transactions, internalTx);

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        // console.logBytes(payloadMultiSend);
        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, hex"");
    }
}
