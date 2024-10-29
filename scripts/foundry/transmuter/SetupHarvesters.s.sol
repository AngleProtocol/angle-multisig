// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { IVaultManagerFunctions } from "borrow/interfaces/IVaultManager.sol";
import { IERC721Metadata } from "oz/token/ERC721/extensions/IERC721Metadata.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import { BaseHarvester } from "transmuter/helpers/BaseHarvester.sol";
import "../Constants.s.sol";

contract SetupHarvestersScript is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        uint256 chainId = vm.envUint("CHAIN_ID");

        /** TODO  complete */
        address genericHarvesterUSD = 0x54b96Fee8208Ea7aCe3d415e5c14798112909794;
        address multiBlockHarvesterUSD = 0x51401aD6023755237ffb0EF0c9bD1379355f6a7b;
        address multiBlockHarvesterEUR = 0x27042f1B94e4F56d00c1aD21F4Ee66816587989b;
        address keeper = 0xa9bbbDDe822789F123667044443dc7001fb43C01;
        /** END  complete */

        // Add keeper to trusted
        {
            bytes memory data = abi.encodeWithSelector(BaseHarvester.toggleTrusted.selector, keeper);
            address to = multiBlockHarvesterUSD;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }
        {
            bytes memory data = abi.encodeWithSelector(BaseHarvester.toggleTrusted.selector, keeper);
            address to = multiBlockHarvesterEUR;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // Set target exposures
        {
            bytes memory data = abi.encodeWithSelector(BaseHarvester.setYieldBearingAssetData.selector, STEAK_USDC, USDC, 0.13e9, 0, 0, 0);
            address to = genericHarvesterUSD;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }
        {
            bytes memory data = abi.encodeWithSelector(BaseHarvester.setYieldBearingAssetData.selector, USDM, USDC, 0.125e9, 0, 0, 0);
            address to = multiBlockHarvesterUSD;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }
        {
            bytes memory data = abi.encodeWithSelector(BaseHarvester.setYieldBearingAssetData.selector, XEVT, EUROC, 0.125e9, 0, 0, 0);
            address to = multiBlockHarvesterEUR;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(chainId, multiSend, uint256(0), payloadMultiSend, Enum.Operation.DelegateCall, hex"", _chainToContract(chainId, ContractType.GuardianMultisig));
    }
}