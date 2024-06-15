// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {ITreasury} from "borrow/interfaces/ITreasury.sol";
import {IAgToken} from "borrow/interfaces/IAgToken.sol";
import {MultiSend} from "safe/libraries/MultiSend.sol";
import {Safe, Enum} from "safe/Safe.sol";
import {ITransmuter} from "transmuter/interfaces/ITransmuter.sol";
import "./Constants.s.sol";
import {IAngle} from "./Constants.s.sol";
import {CoreBorrow} from "borrow/coreBorrow/CoreBorrow.sol";
import {ProxyAdmin} from "oz/proxy/transparent/ProxyAdmin.sol";
import {CommonUtils} from "utils/src/CommonUtils.sol";
import { MockSafe } from "../../test/mock/MockSafe.sol";

/// @title Utils
/// @author Angle Labs, Inc.
contract Utils is Script, CommonUtils {
    bytes[] private calldatas;
    string private description;
    address[] private targets;
    uint256[] private values;
    uint256[] private chainIds;
    uint256[] private operations;
    address[] private safes;

    function setUp() public virtual {
        setUpForks();
    }

    function _serializeJson(
        uint256 chainId,
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        bytes memory additionalData
    ) internal {
        _serializeJson(chainId, to, value, data, operation, additionalData, address(0));
    }

    function _serializeJson(
        uint256 chainId,
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        bytes memory additionalData,
        address safe
    ) internal {
        string memory json = "";
        vm.serializeUint(json, "chainId", chainId);
        vm.serializeAddress(json, "to", to);
        vm.serializeUint(json, "value", value);
        vm.serializeUint(json, "operation", uint256(operation));
        vm.serializeBytes(json, "additionalData", additionalData);
        if (safe != address(0)) {
            vm.serializeAddress(json, "safe", safe);
        }
        string memory finalJson = vm.serializeBytes(json, "data", data);

        vm.writeJson(finalJson, "./scripts/foundry/transaction.json");
    }

    function _wrap(Transaction[] memory transactions, ContractType safeType, uint256 chainId, address chainSafe) internal returns (SafeTransaction[] memory) {
        // get all unique chainIds
        uint256[] memory targetedChainIds = new uint256[](transactions.length);
        uint256 targetedChainIdsLength = 0;
        for (uint256 i = 0; i < transactions.length; ++i) {
            bool found = false;
            for (uint256 j = 0; j < targetedChainIds.length; ++j) {
                if (targetedChainIds[j] == transactions[i].chainId) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                targetedChainIds[targetedChainIdsLength] = transactions[i].chainId;
                targetedChainIdsLength++;
            }
        }
        assembly ("memory-safe") {
            mstore(targetedChainIds, targetedChainIdsLength)
        }

        SafeTransaction[] memory multiSendTransactions = new SafeTransaction[](targetedChainIdsLength);
        for (uint256 i = 0; i < targetedChainIds.length; ++i) {
            bytes memory chainTransactions;
            uint256 totalValue;
            for (uint256 y = 0; y < transactions.length; ++y) {
                Transaction memory transaction = transactions[y];
                if (transaction.chainId == targetedChainIds[i]) {
                    totalValue += transaction.value;
                    bytes memory internalTx = abi.encodePacked(
                        uint8(transaction.operation), transaction.to, transaction.value, transaction.data.length, transaction.data
                    );
                    chainTransactions = abi.encodePacked(chainTransactions, internalTx);
                }
            }
            bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, chainTransactions);
            address multiSend = address(_chainToMultiSend(targetedChainIds[i]));
            address safe;
            if (chainId != 0 && targetedChainIds[i] == chainId) {
                safe = chainSafe;
            } else {
                safe = _chainToContract(targetedChainIds[i], safeType);
            }
            multiSendTransactions[i] = SafeTransaction(payloadMultiSend, multiSend, totalValue, targetedChainIds[i], uint256(Enum.Operation.DelegateCall), safe);
        }
        return multiSendTransactions;
    }

    function _wrap(Transaction[] memory transactions, ContractType safeType) internal returns (SafeTransaction[] memory) {
        return _wrap(transactions, safeType, 0, address(0));
    }


    function _serializeJson(
        SafeTransaction[] memory transactions
    ) internal {
        string memory json = "chain";
        string memory output;
        {
            string memory jsonTargets = "to";
            string memory targetsOutput;
            for (uint256 i; i < transactions.length; i++) {
                targetsOutput = vm.serializeAddress(jsonTargets, vm.toString(i), transactions[i].to);
            }
            vm.serializeString(json, "to", targetsOutput);
        }
        {
            string memory jsonValues = "value";
            string memory valuesOutput;
            for (uint256 i; i < transactions.length; i++) {
                valuesOutput = vm.serializeUint(jsonValues, vm.toString(i), transactions[i].value);
            }
            vm.serializeString(json, "value", valuesOutput);
        }
        {
            string memory jsonDatas = "data";
            string memory datasOutput;
            for (uint256 i; i < transactions.length; i++) {
                datasOutput = vm.serializeBytes(jsonDatas, vm.toString(i), transactions[i].data);
            }
            vm.serializeString(json, "data", datasOutput);
        }
        {
            string memory jsonChainIds = "chainId";
            string memory chainIdsOutput;
            for (uint256 i; i < transactions.length; i++) {
                chainIdsOutput = vm.serializeUint(jsonChainIds, vm.toString(i), transactions[i].chainId);
            }
            vm.serializeString(json, "chainId", chainIdsOutput);
        }
        {
            string memory jsonOperations = "operation";
            string memory operationsOutput;
            for (uint256 i; i < transactions.length; i++) {
                operationsOutput = vm.serializeUint(jsonOperations, vm.toString(i), transactions[i].operation);
            }
            output = vm.serializeString(json, "operation", operationsOutput);
        }
        {
            string memory jsonSafes = "safe";
            string memory safesOutput;
            for (uint256 i; i < transactions.length; i++) {
                safesOutput = vm.serializeAddress(jsonSafes, vm.toString(i), transactions[i].safe);
            }
            output = vm.serializeString(json, "safe", safesOutput);
        }

        vm.writeJson(output, "./scripts/foundry/transactions.json");
    }

    function _deserializeJson() internal returns(SafeTransaction[] memory) {
        string memory json = vm.readFile("./scripts/foundry/transactions.json");
        {
            string memory calldataKey = ".data";
            string[] memory keys = vm.parseJsonKeys(json, calldataKey);
            // Iterate over the encoded structs
            for (uint256 i = 0; i < keys.length; ++i) {
                string memory structKey = string.concat(calldataKey, ".", keys[i]);
                bytes memory encodedStruct = vm.parseJson(json, structKey);
                calldatas.push(abi.decode(encodedStruct, (bytes)));
            }
        }
        {
            string memory targetsKey = ".to";
            string[] memory keys = vm.parseJsonKeys(json, targetsKey);
            // Iterate over the encoded structs
            for (uint256 i = 0; i < keys.length; ++i) {
                string memory structKey = string.concat(targetsKey, ".", keys[i]);
                bytes memory encodedStruct = vm.parseJson(json, structKey);
                targets.push(abi.decode(encodedStruct, (address)));
            }
        }
        {
            string memory valuesKey = ".value";
            string[] memory keys = vm.parseJsonKeys(json, valuesKey);
            // Iterate over the encoded structs
            for (uint256 i = 0; i < keys.length; ++i) {
                string memory structKey = string.concat(valuesKey, ".", keys[i]);
                bytes memory encodedStruct = vm.parseJson(json, structKey);
                values.push(abi.decode(encodedStruct, (uint256)));
            }
        }
        {
            string memory chainIdsKey = ".chainId";
            string[] memory keys = vm.parseJsonKeys(json, chainIdsKey);
            // Iterate over the encoded structs
            for (uint256 i = 0; i < keys.length; ++i) {
                string memory structKey = string.concat(chainIdsKey, ".", keys[i]);
                bytes memory encodedStruct = vm.parseJson(json, structKey);
                chainIds.push(abi.decode(encodedStruct, (uint256)));
            }
        }
        {
            string memory operationsKey = ".operation";
            string[] memory keys = vm.parseJsonKeys(json, operationsKey);
            // Iterate over the encoded structs
            for (uint256 i = 0; i < keys.length; ++i) {
                string memory structKey = string.concat(operationsKey, ".", keys[i]);
                bytes memory encodedStruct = vm.parseJson(json, structKey);
                operations.push(abi.decode(encodedStruct, (uint256)));
            }
        }
        {
            string memory safesKey = ".safe";
            string[] memory keys = vm.parseJsonKeys(json, safesKey);
            // Iterate over the encoded structs
            for (uint256 i = 0; i < keys.length; ++i) {
                string memory structKey = string.concat(safesKey, ".", keys[i]);
                bytes memory encodedStruct = vm.parseJson(json, structKey);
                safes.push(abi.decode(encodedStruct, (address)));
            }
        }
        SafeTransaction[] memory transactions = new SafeTransaction[](calldatas.length);
        for (uint256 i = 0; i < calldatas.length; i++) {
            transactions[i] = SafeTransaction(calldatas[i], targets[i], values[i], chainIds[i], operations[i], safes[i]);
        }
        return transactions;
    }

    function _chainToMultiSend(uint256 chain) internal pure returns (MultiSend) {
        if (chain == CHAIN_ETHEREUM) return multiSendEthereum;
        else if (chain == CHAIN_POLYGON) return multiSendPolygon;
        else if (chain == CHAIN_ARBITRUM) return multiSendArbitrum;
        else if (chain == CHAIN_OPTIMISM) return multiSendOptimism;
        else if (chain == CHAIN_AVALANCHE) return multiSendAvalanche;
        else if (chain == CHAIN_GNOSIS) return multiSendGnosis;
        else if (chain == CHAIN_BNB) return multiSendBNB;
        else if (chain == CHAIN_POLYGONZKEVM) return multiSendPolygonZkEVM;
        else if (chain == CHAIN_BASE) return multiSendBase;
        else if (chain == CHAIN_CELO) return multiSendCelo;
        else if (chain == CHAIN_LINEA) return multiSendLinea;
        else if (chain == CHAIN_MANTLE) return multiSendMantle;
        else if (chain == CHAIN_MODE) return multiSendMode;
        else revert("chain not supported");
    }

    function implEURA(uint256 chain) public view returns (address) {
        if (chain == CHAIN_ARBITRUM) return address(0x1a23b27aC7775B6220dC4F816b5c6A629E371f19);
        else if (chain == CHAIN_AVALANCHE) return address(0xE9169817EdBFe5FCF629eD8b3C2a34E2a50ec84C);
        else if (chain == CHAIN_BASE) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else if (chain == CHAIN_BNB) return address(0xE9169817EdBFe5FCF629eD8b3C2a34E2a50ec84C);
        else if (chain == CHAIN_CELO) return address(0xA0E088Fb02A8d5a71d337B88B7629b0413f53de4);
        else if (chain == CHAIN_ETHEREUM) return address(0xc3ef7ed4F97450Ae8dA2473068375788BdeB5c5c);
        else if (chain == CHAIN_GNOSIS) return address(0xA0E088Fb02A8d5a71d337B88B7629b0413f53de4);
        else if (chain == CHAIN_LINEA) return address(0xc42b7A34Cb37eE450cc8059B10D839e4753229d5);
        else if (chain == CHAIN_OPTIMISM) return address(0x67AA77342bE08935380eBece796A0F4f19F16444);
        else if (chain == CHAIN_POLYGON) return address(0x09f143d3Af1Af9af6AB6BCe1B53fc5a8dc1baA79);
        else if (chain == CHAIN_POLYGONZKEVM) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else revert("chain not supported");
    }

    function implUSDA(uint256 chain) public view returns (address) {
        if (chain == CHAIN_ARBITRUM) return address(0x1a23b27aC7775B6220dC4F816b5c6A629E371f19);
        else if (chain == CHAIN_AVALANCHE) return address(0xE9169817EdBFe5FCF629eD8b3C2a34E2a50ec84C);
        else if (chain == CHAIN_BASE) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else if (chain == CHAIN_BNB) return address(0xE9169817EdBFe5FCF629eD8b3C2a34E2a50ec84C);
        else if (chain == CHAIN_CELO) return address(0xA0E088Fb02A8d5a71d337B88B7629b0413f53de4);
        else if (chain == CHAIN_ETHEREUM) return address(0x028e1f0DB25DAF4ce8C895215deAfbCE7A873b24);
        else if (chain == CHAIN_GNOSIS) return address(0xA0E088Fb02A8d5a71d337B88B7629b0413f53de4);
        else if (chain == CHAIN_LINEA) return address(0xc42b7A34Cb37eE450cc8059B10D839e4753229d5);
        else if (chain == CHAIN_OPTIMISM) return address(0x67AA77342bE08935380eBece796A0F4f19F16444);
        else if (chain == CHAIN_POLYGON) return address(0x04A7d169C5b14d2e29A3bA8b5071dDA5E365c199);
        else if (chain == CHAIN_POLYGONZKEVM) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else revert("chain not supported");
    }

    function implStakedStablecoin(uint256 chain) public view returns (address) {
        if (chain == CHAIN_ARBITRUM) return address(0xDAcf64fe735F5333474C9aE8000120002327a55A);
        else if (chain == CHAIN_AVALANCHE) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else if (chain == CHAIN_BASE) return address(0x1899D4cC1BFf96038f9E8f5ecc898c70E2ff72ee);
        else if (chain == CHAIN_BNB) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else if (chain == CHAIN_CELO) return address(0xc42b7A34Cb37eE450cc8059B10D839e4753229d5);
        else if (chain == CHAIN_ETHEREUM) return address(0x25B0a02C8050943483aE5d68165Ebcb47EB01148);
        else if (chain == CHAIN_GNOSIS) return address(0xc42b7A34Cb37eE450cc8059B10D839e4753229d5);
        else if (chain == CHAIN_LINEA) return address(0xE9169817EdBFe5FCF629eD8b3C2a34E2a50ec84C);
        else if (chain == CHAIN_OPTIMISM) return address(0xa25c30044142d2fA243E7Fd3a6a9713117b3c396);
        else if (chain == CHAIN_POLYGON) return address(0xA87D4F27F49D335ab1deEe6b9c43404414Bee214);
        else if (chain == CHAIN_POLYGONZKEVM) return address(0x1899D4cC1BFf96038f9E8f5ecc898c70E2ff72ee);
        else revert("chain not supported");
    }

    function _chainTo1InchAggregator(uint256 chain) internal pure returns (address) {
        if (
            chain == CHAIN_ETHEREUM ||
            chain == CHAIN_POLYGON ||
            chain == CHAIN_ARBITRUM ||
            chain == CHAIN_OPTIMISM ||
            chain == CHAIN_AVALANCHE ||
            chain == CHAIN_GNOSIS
        ) return 0x111111125421cA6dc452d289314280a0f8842A65;
        else revert("chain not supported");
    }

    function _getTransmuter(uint256 chainId, StablecoinType fiat) internal returns (ITransmuter transmuter) {
        if (fiat == StablecoinType.EUR)
            transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));
        if (fiat == StablecoinType.USD)
            transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgUSD));
    }

    function _getTreasury(uint256 chainId, StablecoinType fiat) internal returns (ITreasury treasury) {
        if (fiat == StablecoinType.EUR) treasury = ITreasury(_chainToContract(chainId, ContractType.TreasuryAgEUR));
        if (fiat == StablecoinType.USD) treasury = ITreasury(_chainToContract(chainId, ContractType.TreasuryAgUSD));
    }

    function _getAgToken(uint256 chainId, StablecoinType fiat) internal returns (IAgToken agToken) {
        if (fiat == StablecoinType.EUR) agToken = IAgToken(_chainToContract(chainId, ContractType.AgEUR));
        if (fiat == StablecoinType.USD) agToken = IAgToken(_chainToContract(chainId, ContractType.AgUSD));
    }
}
