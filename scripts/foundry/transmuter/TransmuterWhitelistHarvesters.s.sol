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
                bytes memory data = abi.encodeWithSelector(ISettersGovernor.toggleTrusted.selector, 0x16CA2999e5f5e43aEc2e6c18896655b9B05a1560, TrustedType.Seller);
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
                bytes memory data = abi.encodeWithSelector(ISettersGovernor.toggleTrusted.selector, 0x54b96Fee8208Ea7aCe3d415e5c14798112909794, TrustedType.Seller);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(ISettersGovernor.toggleTrusted.selector, 0xf156D2F6726E3231dd94dD9CB2e86D9A85A38d18, TrustedType.Seller);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        _serializeJson(chainId, address(_chainToMultiSend(chainId)), uint256(0), payloadMultiSend, Enum.Operation.DelegateCall, hex"", safe);
    }
}
