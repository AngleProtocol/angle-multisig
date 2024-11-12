// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { TrustedType } from "transmuter/transmuter/Storage.sol";
import { ITransmuter, ISettersGovernor, ISettersGuardian, ISwapper} from "transmuter/interfaces/ITransmuter.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract TransmuterWhitelistHarvesters is Utils {
    function run() external {
        uint256 chainId = vm.envUint("CHAIN_ID");

        address safe = _chainToContract(chainId, ContractType.GovernorMultisig);
        bytes memory transactions;

        {
            ITransmuter transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));
            address to = address(transmuter);
            uint8 isDelegateCall = 0;
            {
                bytes memory data = abi.encodeWithSelector(ISettersGovernor.toggleTrusted.selector, 0x0A10f87F55d89eb2a89c264ebE46C90785a10B77, TrustedType.Updater);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }
        {
            ITransmuter transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgUSD));
            address to = address(transmuter);
            uint8 isDelegateCall = 0;
            {
                bytes memory data = abi.encodeWithSelector(ISettersGovernor.toggleTrusted.selector, 0x54b96Fee8208Ea7aCe3d415e5c14798112909794, TrustedType.Updater);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(ISettersGovernor.toggleTrusted.selector, 0x5BEdD878CBfaF4dc53EC272A291A6a4C2259369D, TrustedType.Updater);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        _serializeJson(chainId, address(_chainToMultiSend(chainId)), uint256(0), payloadMultiSend, Enum.Operation.DelegateCall, hex"", safe);
    }
}