// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { NonblockingLzApp } from "angle-tokens/agToken/layerZero/utils/NonblockingLzApp.sol";
import { OFTCore } from "lz/token/oft/v1/OFTCore.sol";
import { AgTokenSideChainMultiBridge } from "borrow/agToken/AgTokenSideChainMultiBridge.sol";
import "../Utils.s.sol";

contract ConnectAgTokenSideChainMultiBridge is Utils {
    Transaction[] public transactions;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_ID");

        /** TODO complete */
        string memory stableName = vm.envString("STABLE_NAME");
        bool mock = vm.envOr("MOCK", false);
        /** END  complete */

        string memory json = vm.readFile(JSON_ADDRESSES_PATH);
        address token = vm.parseJsonAddress(json, ".agToken");
        address lzToken = vm.parseJsonAddress(json, ".lzAgToken");

        (uint256[] memory chainIds, address[] memory contracts) = _getConnectedChains(stableName);
        if (!mock) {
            {
                uint256 totalLimit = vm.envUint("TOTAL_LIMIT");
                uint256 hourlyLimit = vm.envUint("HOURLY_LIMIT");
                {
                    bytes memory data = abi.encodeWithSelector(
                        AgTokenSideChainMultiBridge.addBridgeToken.selector,
                        lzToken,
                        totalLimit,
                        hourlyLimit,
                        0,
                        false
                    );
                    address to = token;
                    transactions.push(Transaction(data, to, 0, chainId, uint256(Enum.Operation.Call)));
                }
            }

            {
                uint256 chainTotalHourlyLimit = vm.envUint("CHAIN_TOTAL_HOURLY_LIMIT");
                {
                    bytes memory data = abi.encodeWithSelector(
                        AgTokenSideChainMultiBridge.setChainTotalHourlyLimit.selector,
                        chainTotalHourlyLimit
                    );
                    address to = lzToken;
                    transactions.push(Transaction(data, to, 0, chainId, uint256(Enum.Operation.Call)));
                }
            }

            {
                bytes memory data = abi.encodeWithSelector(OFTCore.setUseCustomAdapterParams.selector, 1);
                address to = lzToken;
                transactions.push(Transaction(data, to, 0, chainId, uint256(Enum.Operation.Call)));
            }

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
            if (chainIds[i] == chainId) {
                continue;
            }

            {
                bytes memory data =  abi.encodeWithSelector(
                    NonblockingLzApp.setTrustedRemote.selector,
                    _getLZChainId(chainId),
                    abi.encodePacked(lzToken, contracts[i])
                );
                address to = contracts[i];
                transactions.push(Transaction(data, to, 0, chainIds[i], uint256(Enum.Operation.Call)));
            }
        }

        Transaction[] memory multiSendTransactions = _wrap(transactions);
        _serializeJson(multiSendTransactions);
    }
}
