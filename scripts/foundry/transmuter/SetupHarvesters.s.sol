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
        address multiBlockHarvesterUSD = 0x5BEdD878CBfaF4dc53EC272A291A6a4C2259369D;
        address multiBlockHarvesterEUR = 0x0A10f87F55d89eb2a89c264ebE46C90785a10B77;
        address keeper = 0xa9bbbDDe822789F123667044443dc7001fb43C01;
        address depositAddressUSDM = 0x78A42Aa9b25Cd00823Ebb34DDDCF38224D99e0C8;
        uint64 targetExposureSteakUSDC = 0.35e9;
        uint64 targetExposureUSDM = 0.50e9;
        uint64 targetExposureXEVT = 0.125e9;
        /** END  complete */

        bytes memory transactions;
        uint8 isDelegateCall = 0;
        address to = address(transmuter);
        uint256 value = 0;

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

        // set yield bearing to deposit address
        {
            bytes memory data = abi.encodeWithSelector(IHarvester.setYieldBearingToDepositAddress.selector, XEVT, XEVT);

            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        {
            bytes memory data = abi.encodeWithSelector(
                IHarvester.setYieldBearingToDepositAddress.selector,
                USDM,
                depositAddressUSDM
            );

            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // Set target exposures
        {
            bytes memory data = abi.encodeWithSelector(
                BaseHarvester.setYieldBearingAssetData.selector,
                STEAK_USDC,
                USDC,
                targetExposureSteakUSDC,
                0,
                0,
                0
            );
            address to = genericHarvesterUSD;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }
        {
            bytes memory data = abi.encodeWithSelector(
                BaseHarvester.setYieldBearingAssetData.selector,
                USDM,
                USDC,
                targetExposureUSDM,
                0,
                0,
                0
            );
            address to = multiBlockHarvesterUSD;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }
        {
            bytes memory data = abi.encodeWithSelector(
                BaseHarvester.setYieldBearingAssetData.selector,
                XEVT,
                EUROC,
                targetExposureXEVT,
                0,
                0,
                0
            );
            address to = multiBlockHarvesterEUR;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(
            chainId,
            multiSend,
            uint256(0),
            payloadMultiSend,
            Enum.Operation.DelegateCall,
            hex"",
            _chainToContract(chainId, ContractType.GuardianMultisig)
        );
    }
}
