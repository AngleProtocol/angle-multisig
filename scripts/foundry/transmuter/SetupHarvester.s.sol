// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { IVaultManagerFunctions } from "borrow/interfaces/IVaultManager.sol";
import { IERC721Metadata } from "oz/token/ERC721/extensions/IERC721Metadata.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import { BaseHarvester, YieldBearingParams } from "transmuter/helpers/BaseHarvester.sol";
import { ISettersGuardian, ISettersGovernor } from "transmuter/interfaces/ITransmuter.sol";
import { TrustedType } from "transmuter/transmuter/Storage.sol";
import { MultiBlockHarvester } from "transmuter/helpers/MultiBlockHarvester.sol";
import "../Constants.s.sol";

contract SetupHarvester is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        uint256 chainId = vm.envUint("CHAIN_ID");

        /** TODO  complete */
        address harvester = 0x0A10f87F55d89eb2a89c264ebE46C90785a10B77;
        uint64 targetExposure = 0.35e9;
        address asset = EUROC;
        address yieldBearingAsset = XEVT;
        bool isGenericHarvester = false;
        /** END  complete */

        // Add harvester to trusted
        {
            address transmuter = _chainToContract(chainId, ContractType.TransmuterAgEUR);
            bytes memory data = abi.encodeWithSelector(ISettersGovernor.toggleTrusted.selector, harvester);
            address to = transmuter;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // Add keeper to trusted
        if (!isGenericHarvester) {
            address keeper = 0xa9bbbDDe822789F123667044443dc7001fb43C01;
            {
                bytes memory data = abi.encodeWithSelector(BaseHarvester.toggleTrusted.selector, keeper, TrustedType.Updater);
                address to = harvester;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        // set yield bearing to deposit address
        if (!isGenericHarvester) {
            address depositAddress = 0x78A42Aa9b25Cd00823Ebb34DDDCF38224D99e0C8;

            bytes memory data = abi.encodeWithSelector(
                MultiBlockHarvester.setYieldBearingToDepositAddress.selector,
                yieldBearingAsset,
                depositAddress
            );
            address to = harvester;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // Set target exposures
        {
            bytes memory data = abi.encodeWithSelector(
                BaseHarvester.setYieldBearingAssetData.selector,
                yieldBearingAsset,
                asset,
                targetExposure,
                0,
                0,
                0
            );
            address to = harvester;
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
            _chainToContract(chainId, ContractType.GovernorMultisig)
        );
    }
}
