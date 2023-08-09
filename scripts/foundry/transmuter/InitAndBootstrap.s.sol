// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ISettersGuardian } from "transmuter/interfaces/ISetters.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";
import { Treasury } from "borrow/treasury/Treasury.sol";
import { IERC20 } from "oz/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "oz/token/ERC20/extensions/IERC20Metadata.sol";

contract InitAndBootstrap is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;
        address to;
        {
            to = EUROC;
            bytes memory data = abi.encodeWithSelector(
                IERC20.transfer.selector,
                address(transmuter),
                9_500_000 * 10 ** IERC20Metadata(to).decimals()
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // {
        //     to = BC3M;
        //     bytes memory data = abi.encodeWithSelector(
        //         IERC20.transfer.selector,
        //         address(transmuter),
        //         4_500_000 * 10 ** IERC20Metadata(to).decimals()
        //     );
        //     uint256 dataLength = data.length;
        //     bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
        //     transactions = abi.encodePacked(transactions, internalTx);
        // }

        // add transmuter as `agEUR` minter
        {
            to = address(treasuryEthereum);
            bytes memory data = abi.encodeWithSelector(Treasury.addMinter.selector, address(transmuter));
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        // console.logBytes(payloadMultiSend);
        _serializeJson(CHAIN_ETHEREUM, address(multiSendEthereum), 0, payloadMultiSend, Enum.Operation.DelegateCall);
    }
}
