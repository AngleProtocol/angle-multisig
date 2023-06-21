// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ITransmuter } from "transmuter/interfaces/ITransmuter.sol";
import { ProxyAdmin } from "oz/proxy/transparent/ProxyAdmin.sol";
import { Enum } from "safe/Safe.sol";
import { Utils } from "../Utils.s.sol";

contract PauseTransmuter is Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.deriveKey(vm.envString("MNEMONIC_MAINNET"), 0);
        vm.startBroadcast(deployerPrivateKey);

        bytes memory transactions;
        {
            uint8 isDelegateCall = 0;
            address to = address(0x5183f032bf42109cD370B9559FD22207e432301E);
            uint256 value = 0;
            bytes memory data = abi.encodeWithSelector(
                ProxyAdmin.upgrade.selector,
                0xf1dDcACA7D17f8030Ab2eb54f2D9811365EFe123,
                0x6cd24ac05103C2C911347a6D3628d64a9F07eAf5
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        {
            uint8 isDelegateCall = 0;
            address to = address(0xf1dDcACA7D17f8030Ab2eb54f2D9811365EFe123);
            uint256 value = 0;
            bytes memory data = hex"6147def20000000000000000000000000000000000000000000000000000000000000001";
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        // console.logBytes(payloadMultiSend);

        _serializeJson(address(governorMainnetSafe), 0, payloadMultiSend, Enum.Operation.Call);

        vm.stopBroadcast();
    }
}
