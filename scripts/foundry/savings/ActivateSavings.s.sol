// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { OFTCore } from "angle-tokens/agToken/layerZero/utils/OFTCore.sol";
import { NonblockingLzApp } from "angle-tokens/agToken/layerZero/utils/NonblockingLzApp.sol";
import { AgTokenSideChainMultiBridge } from "angle-tokens/agToken/AgTokenSideChainMultiBridge.sol";
import "../Utils.s.sol";

contract ActivateSavings is Utils {
    function run() external {
        bytes memory transactions;
        uint256 chainId = vm.envUint("CHAIN_ID");
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        /** TODO complete */
        address stToken = _chainToContract(chainId, ContractType.StEUR);
        address treasury = _chainToContract(chainId, ContractType.TreasuryAgEUR);
        address keeper = 0xa9bbbDDe822789F123667044443dc7001fb43C01;
        uint256 rate = 3022265993024575488;
        /** END  complete */

        {
            bytes memory data = abi.encodeWithSelector(
                ITreasury.addMinter.selector,
                stToken
            );
            address to = treasury;
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }
        {
            bytes memory data = abi.encodeWithSelector(
                ISavings.setMaxRate.selector,
                rate
            );
            address to = stToken;
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }
        {
            bytes memory data = abi.encodeWithSelector(
                ISavings.toggleTrusted.selector,
                keeper
            );
            address to = stToken;
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        // Verify that the calls will succeed
        address multiSend = address(_chainToMultiSend(chainId));
        address safe = address(_chainToContract(chainId, ContractType.GovernorMultisig));
        vm.startBroadcast(safe);
        address(multiSend).delegatecall(payloadMultiSend);
        vm.stopBroadcast();
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, new bytes(0), safe);
    }
}
