// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {console} from "forge-std/console.sol";
import {NonblockingLzApp} from "angle-tokens/agToken/layerZero/utils/NonblockingLzApp.sol";
import "../Utils.s.sol";

contract ConnectAngleSideChainMultiBridge is Utils {
    Transaction[] public transactions;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_ID");

        /** TODO complete */
        bool mock = vm.envOr("MOCK", false);
        /** END  complete */

        string memory json = vm.readFile(JSON_ADDRESSES_PATH);
        address lzToken = vm.parseJsonAddress(json, ".lzAngle");

        (uint256[] memory chainIds, address[] memory contracts) = _getConnectedChains("ANGLE");

        if (!mock) {
            // Set trusted remote from current chain
            for (uint256 i = 0; i < contracts.length; i++) {
                if (chainIds[i] == chainId) {
                    continue;
                }

                {
                    bytes memory data = abi.encodeWithSelector(
                        NonblockingLzApp.setTrustedRemote.selector,
                        _getLZChainId(chainIds[i]),
                        abi.encodePacked(contracts[i], lzToken)
                    );
                    address to = lzToken;
                    transactions.push(Transaction(data, to, 0, chainId, uint256(Enum.Operation.Call)));
                }
            }
        }

        // Set trusted remote from all connected chains
        for (uint256 i = 0; i < contracts.length; i++) {
            if (chainIds[i] == chainId || chainIds[i] == CHAIN_ETHEREUM) {
                continue;
            }

            {
                bytes memory data = abi.encodeWithSelector(
                    NonblockingLzApp.setTrustedRemote.selector,
                    _getLZChainId(chainId),
                    abi.encodePacked(lzToken, contracts[i])
                );
                address to = contracts[i];
                transactions.push(Transaction(data, to, 0, chainIds[i], uint256(Enum.Operation.Call)));
            }
        }

        SafeTransaction[] memory multiSendTransactions;
        if (vm.keyExists(json, ".guardian")) {
            address guardian = vm.parseJsonAddress(json, ".guardian");
            multiSendTransactions = _wrap(transactions, ContractType.GuardianMultisig, chainId, guardian);
        } else {
            multiSendTransactions = _wrap(transactions, ContractType.GuardianMultisig);
        }
        _serializeJson(multiSendTransactions);
    }
}
