// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { IAgToken } from "borrow/interfaces/IAgToken.sol";
import { MultiSend } from "safe/libraries/MultiSend.sol";
import { Safe, Enum } from "safe/Safe.sol";
import { ITransmuter } from "transmuter/interfaces/ITransmuter.sol";
import "./Constants.s.sol";
import { IAngle } from "./Constants.s.sol";
import { CoreBorrow } from "borrow/coreBorrow/CoreBorrow.sol";
import { ProxyAdmin } from "oz/proxy/transparent/ProxyAdmin.sol";
import { CommonUtils } from "utils/src/CommonUtils.sol";
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

    struct Args {
        uint256 totalValue;
        uint256[] targetedChainIds;
        bytes chainTransactions;
        uint256 currentChain;
        address chainSafe;
        ContractType safeType;
        uint256 chainId;
    }

    function _createMultiSendTransaction(Args memory args) internal returns (SafeTransaction memory) {
        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, args.chainTransactions);
        address multiSend = address(_chainToMultiSend(args.targetedChainIds[args.currentChain]));
        address safe;
        if (args.chainId != 0 && args.targetedChainIds[args.currentChain] == args.chainId) {
            safe = args.chainSafe;
        } else {
            safe = _chainToContract(args.targetedChainIds[args.currentChain], args.safeType);
        }
        return
            SafeTransaction(
                payloadMultiSend,
                multiSend,
                args.totalValue,
                args.targetedChainIds[args.currentChain],
                uint256(Enum.Operation.DelegateCall),
                safe
            );
    }

    function _wrap(
        Transaction[] memory transactions,
        ContractType safeType,
        uint256 chainId,
        address chainSafe
    ) internal returns (MultiSendTransactions[] memory) {
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
        MultiSendTransactions[] memory multiSendTransactions = new MultiSendTransactions[](targetedChainIdsLength);
        for (uint256 i = 0; i < targetedChainIds.length; ++i) {
            bytes memory chainTransactions;
            SafeTransaction[] memory internalTransactions = new SafeTransaction[](transactions.length);
            uint256 count;
            uint256 totalValue;
            for (uint256 y = 0; y < transactions.length; ++y) {
                Transaction memory transaction = transactions[y];
                if (transaction.chainId == targetedChainIds[i]) {
                    totalValue += transaction.value;
                    bytes memory internalTx = abi.encodePacked(
                        uint8(transaction.operation),
                        transaction.to,
                        transaction.value,
                        transaction.data.length,
                        transaction.data
                    );
                    chainTransactions = abi.encodePacked(chainTransactions, internalTx);
                    internalTransactions[count++] = SafeTransaction(
                        transaction.data,
                        transaction.to,
                        transaction.value,
                        transaction.chainId,
                        transaction.operation,
                        chainSafe
                    );
                }
            }
            assembly ("memory-safe") {
                mstore(internalTransactions, count)
            }
            multiSendTransactions[i].transaction = _createMultiSendTransaction(
                Args(totalValue, targetedChainIds, chainTransactions, i, chainSafe, safeType, chainId)
            );
            multiSendTransactions[i].internalTransactions = internalTransactions;
        }
        return multiSendTransactions;
    }

    function _wrap(
        Transaction[] memory transactions,
        ContractType safeType
    ) internal returns (MultiSendTransactions[] memory) {
        return _wrap(transactions, safeType, 0, address(0));
    }

    function _serializeJson(MultiSendTransactions[] memory transactions) internal {
        string memory txJson = "chain";
        string memory json = "";
        string memory output;
        {
            string memory jsonTargets = "to";
            string memory targetsOutput;
            for (uint256 i; i < transactions.length; i++) {
                targetsOutput = vm.serializeAddress(jsonTargets, vm.toString(i), transactions[i].transaction.to);
            }
            vm.serializeString(txJson, "to", targetsOutput);
        }
        {
            string memory jsonValues = "value";
            string memory valuesOutput;
            for (uint256 i; i < transactions.length; i++) {
                valuesOutput = vm.serializeUint(jsonValues, vm.toString(i), transactions[i].transaction.value);
            }
            vm.serializeString(txJson, "value", valuesOutput);
        }
        {
            string memory jsonDatas = "data";
            string memory datasOutput;
            for (uint256 i; i < transactions.length; i++) {
                datasOutput = vm.serializeBytes(jsonDatas, vm.toString(i), transactions[i].transaction.data);
            }
            vm.serializeString(txJson, "data", datasOutput);
        }
        {
            string memory jsonChainIds = "chainId";
            string memory chainIdsOutput;
            for (uint256 i; i < transactions.length; i++) {
                chainIdsOutput = vm.serializeUint(jsonChainIds, vm.toString(i), transactions[i].transaction.chainId);
            }
            vm.serializeString(txJson, "chainId", chainIdsOutput);
        }
        {
            string memory jsonOperations = "operation";
            string memory operationsOutput;
            for (uint256 i; i < transactions.length; i++) {
                operationsOutput = vm.serializeUint(
                    jsonOperations,
                    vm.toString(i),
                    transactions[i].transaction.operation
                );
            }
            vm.serializeString(txJson, "operation", operationsOutput);
        }
        {
            string memory jsonSafes = "safe";
            string memory safesOutput;
            for (uint256 i; i < transactions.length; i++) {
                safesOutput = vm.serializeAddress(jsonSafes, vm.toString(i), transactions[i].transaction.safe);
            }
            output = vm.serializeString(txJson, "safe", safesOutput);
        }

        // internal txs
        string memory internalTxJson = "internal";
        string memory internalOutput;
        for (uint256 i; i < transactions.length; i++) {
            string memory jsonChain = string.concat("chain", ".", vm.toString(i));
            string memory chainOutput;
            {
                vm.serializeUint(jsonChain, "chainId", transactions[i].transaction.chainId);
            }
            {
                vm.serializeAddress(jsonChain, "safe", transactions[i].transaction.safe);
            }
            {
                string memory jsonTargets = string.concat("to", ".", vm.toString(i));
                string memory targetsOutput;
                for (uint256 j; j < transactions[i].internalTransactions.length; j++) {
                    targetsOutput = vm.serializeAddress(
                        jsonTargets,
                        vm.toString(j),
                        transactions[i].internalTransactions[j].to
                    );
                }
                chainOutput = vm.serializeString(jsonChain, "to", targetsOutput);
            }
            {
                string memory jsonValues = string.concat("value", ".", vm.toString(i));
                string memory valuesOutput;
                for (uint256 j; j < transactions[i].internalTransactions.length; j++) {
                    valuesOutput = vm.serializeUint(
                        jsonValues,
                        vm.toString(j),
                        transactions[i].internalTransactions[j].value
                    );
                }
                chainOutput = vm.serializeString(jsonChain, "value", valuesOutput);
            }
            {
                string memory jsonDatas = string.concat("data", ".", vm.toString(i));
                string memory datasOutput;
                for (uint256 j; j < transactions[i].internalTransactions.length; j++) {
                    datasOutput = vm.serializeBytes(
                        jsonDatas,
                        vm.toString(j),
                        transactions[i].internalTransactions[j].data
                    );
                }
                chainOutput = vm.serializeString(jsonChain, "data", datasOutput);
            }
            {
                string memory jsonOperations = string.concat("operation", ".", vm.toString(i));
                string memory operationsOutput;
                for (uint256 j; j < transactions[i].internalTransactions.length; j++) {
                    operationsOutput = vm.serializeUint(
                        jsonOperations,
                        vm.toString(j),
                        transactions[i].internalTransactions[j].operation
                    );
                }
                chainOutput = vm.serializeString(jsonChain, "operation", operationsOutput);
            }
            internalOutput = vm.serializeString(internalTxJson, vm.toString(i), chainOutput);
        }

        vm.serializeString(json, "internalTransactions", internalOutput);
        string memory transactionOutput = vm.serializeString(json, "transaction", output);
        vm.writeJson(transactionOutput, "./scripts/foundry/transactions.json");
    }

    function _deserializeJson() internal returns (SafeTransaction[] memory) {
        string memory json = vm.readFile("./scripts/foundry/transactions.json");
        {
            string memory calldataKey = ".transaction.data";
            string[] memory keys = vm.parseJsonKeys(json, calldataKey);
            // Iterate over the encoded structs
            for (uint256 i = 0; i < keys.length; ++i) {
                string memory structKey = string.concat(calldataKey, ".", keys[i]);
                bytes memory encodedStruct = vm.parseJson(json, structKey);
                calldatas.push(abi.decode(encodedStruct, (bytes)));
            }
        }
        {
            string memory targetsKey = ".transaction.to";
            string[] memory keys = vm.parseJsonKeys(json, targetsKey);
            // Iterate over the encoded structs
            for (uint256 i = 0; i < keys.length; ++i) {
                string memory structKey = string.concat(targetsKey, ".", keys[i]);
                bytes memory encodedStruct = vm.parseJson(json, structKey);
                targets.push(abi.decode(encodedStruct, (address)));
            }
        }
        {
            string memory valuesKey = ".transaction.value";
            string[] memory keys = vm.parseJsonKeys(json, valuesKey);
            // Iterate over the encoded structs
            for (uint256 i = 0; i < keys.length; ++i) {
                string memory structKey = string.concat(valuesKey, ".", keys[i]);
                bytes memory encodedStruct = vm.parseJson(json, structKey);
                values.push(abi.decode(encodedStruct, (uint256)));
            }
        }
        {
            string memory chainIdsKey = ".transaction.chainId";
            string[] memory keys = vm.parseJsonKeys(json, chainIdsKey);
            // Iterate over the encoded structs
            for (uint256 i = 0; i < keys.length; ++i) {
                string memory structKey = string.concat(chainIdsKey, ".", keys[i]);
                bytes memory encodedStruct = vm.parseJson(json, structKey);
                chainIds.push(abi.decode(encodedStruct, (uint256)));
            }
        }
        {
            string memory operationsKey = ".transaction.operation";
            string[] memory keys = vm.parseJsonKeys(json, operationsKey);
            // Iterate over the encoded structs
            for (uint256 i = 0; i < keys.length; ++i) {
                string memory structKey = string.concat(operationsKey, ".", keys[i]);
                bytes memory encodedStruct = vm.parseJson(json, structKey);
                operations.push(abi.decode(encodedStruct, (uint256)));
            }
        }
        {
            string memory safesKey = ".transaction.safe";
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
            transactions[i] = SafeTransaction(
                calldatas[i],
                targets[i],
                values[i],
                chainIds[i],
                operations[i],
                safes[i]
            );
        }
        return transactions;
    }

    function _chainToMultiSend(uint256 chain) internal pure returns (MultiSend) {
        if (chain == Constants.CHAIN_ETHEREUM) return multiSendEthereum;
        else if (chain == Constants.CHAIN_POLYGON) return multiSendPolygon;
        else if (chain == Constants.CHAIN_ARBITRUM) return multiSendArbitrum;
        else if (chain == Constants.CHAIN_OPTIMISM) return multiSendOptimism;
        else if (chain == Constants.CHAIN_AVALANCHE) return multiSendAvalanche;
        else if (chain == Constants.CHAIN_GNOSIS) return multiSendGnosis;
        else if (chain == Constants.CHAIN_BNB) return multiSendBNB;
        else if (chain == Constants.CHAIN_POLYGONZKEVM) return multiSendPolygonZkEVM;
        else if (chain == Constants.CHAIN_BASE) return multiSendBase;
        else if (chain == Constants.CHAIN_CELO) return multiSendCelo;
        else if (chain == Constants.CHAIN_LINEA) return multiSendLinea;
        else if (chain == Constants.CHAIN_MANTLE) return multiSendMantle;
        else if (chain == Constants.CHAIN_MODE) return multiSendMode;
        else if (chain == Constants.CHAIN_BLAST) return multiSendBlast;
        else if (chain == Constants.CHAIN_XLAYER) return multiSendXLayer;
        else revert("chain not supported");
    }

    function implEURA(uint256 chain) public view returns (address) {
        if (chain == Constants.CHAIN_ARBITRUM) return address(0x1a23b27aC7775B6220dC4F816b5c6A629E371f19);
        else if (chain == Constants.CHAIN_AVALANCHE) return address(0xE9169817EdBFe5FCF629eD8b3C2a34E2a50ec84C);
        else if (chain == Constants.CHAIN_BASE) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else if (chain == Constants.CHAIN_BNB) return address(0xE9169817EdBFe5FCF629eD8b3C2a34E2a50ec84C);
        else if (chain == Constants.CHAIN_CELO) return address(0xA0E088Fb02A8d5a71d337B88B7629b0413f53de4);
        else if (chain == Constants.CHAIN_ETHEREUM) return address(0xc3ef7ed4F97450Ae8dA2473068375788BdeB5c5c);
        else if (chain == Constants.CHAIN_GNOSIS) return address(0xA0E088Fb02A8d5a71d337B88B7629b0413f53de4);
        else if (chain == Constants.CHAIN_LINEA) return address(0xc42b7A34Cb37eE450cc8059B10D839e4753229d5);
        else if (chain == Constants.CHAIN_OPTIMISM) return address(0x67AA77342bE08935380eBece796A0F4f19F16444);
        else if (chain == Constants.CHAIN_POLYGON) return address(0x09f143d3Af1Af9af6AB6BCe1B53fc5a8dc1baA79);
        else if (chain == Constants.CHAIN_POLYGONZKEVM) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else revert("chain not supported");
    }

    function implUSDA(uint256 chain) public view returns (address) {
        if (chain == Constants.CHAIN_ARBITRUM) return address(0x1a23b27aC7775B6220dC4F816b5c6A629E371f19);
        else if (chain == Constants.CHAIN_AVALANCHE) return address(0xE9169817EdBFe5FCF629eD8b3C2a34E2a50ec84C);
        else if (chain == Constants.CHAIN_BASE) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else if (chain == Constants.CHAIN_BNB) return address(0xE9169817EdBFe5FCF629eD8b3C2a34E2a50ec84C);
        else if (chain == Constants.CHAIN_CELO) return address(0xA0E088Fb02A8d5a71d337B88B7629b0413f53de4);
        else if (chain == Constants.CHAIN_ETHEREUM) return address(0x028e1f0DB25DAF4ce8C895215deAfbCE7A873b24);
        else if (chain == Constants.CHAIN_GNOSIS) return address(0xA0E088Fb02A8d5a71d337B88B7629b0413f53de4);
        else if (chain == Constants.CHAIN_LINEA) return address(0xc42b7A34Cb37eE450cc8059B10D839e4753229d5);
        else if (chain == Constants.CHAIN_OPTIMISM) return address(0x67AA77342bE08935380eBece796A0F4f19F16444);
        else if (chain == Constants.CHAIN_POLYGON) return address(0x04A7d169C5b14d2e29A3bA8b5071dDA5E365c199);
        else if (chain == Constants.CHAIN_POLYGONZKEVM) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else revert("chain not supported");
    }

    function implStakedStablecoin(uint256 chain) public view returns (address) {
        if (chain == Constants.CHAIN_ARBITRUM) return address(0xDAcf64fe735F5333474C9aE8000120002327a55A);
        else if (chain == Constants.CHAIN_AVALANCHE) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else if (chain == Constants.CHAIN_BASE) return address(0x1899D4cC1BFf96038f9E8f5ecc898c70E2ff72ee);
        else if (chain == Constants.CHAIN_BNB) return address(0xb5eCAa1a867FeCCD6d87604bc16a2b6B53D706BF);
        else if (chain == Constants.CHAIN_CELO) return address(0xc42b7A34Cb37eE450cc8059B10D839e4753229d5);
        else if (chain == Constants.CHAIN_ETHEREUM) return address(0x25B0a02C8050943483aE5d68165Ebcb47EB01148);
        else if (chain == Constants.CHAIN_GNOSIS) return address(0xc42b7A34Cb37eE450cc8059B10D839e4753229d5);
        else if (chain == Constants.CHAIN_LINEA) return address(0xE9169817EdBFe5FCF629eD8b3C2a34E2a50ec84C);
        else if (chain == Constants.CHAIN_OPTIMISM) return address(0xa25c30044142d2fA243E7Fd3a6a9713117b3c396);
        else if (chain == Constants.CHAIN_POLYGON) return address(0xA87D4F27F49D335ab1deEe6b9c43404414Bee214);
        else if (chain == Constants.CHAIN_POLYGONZKEVM) return address(0x1899D4cC1BFf96038f9E8f5ecc898c70E2ff72ee);
        else revert("chain not supported");
    }

    function _chainTo1InchAggregator(uint256 chain) internal pure returns (address) {
        if (
            chain == Constants.CHAIN_ETHEREUM ||
            chain == Constants.CHAIN_POLYGON ||
            chain == Constants.CHAIN_ARBITRUM ||
            chain == Constants.CHAIN_OPTIMISM ||
            chain == Constants.CHAIN_AVALANCHE ||
            chain == Constants.CHAIN_GNOSIS
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

    function implRouter(uint256 chain) public view returns (address) {
        if (chain == Constants.CHAIN_ARBITRUM) return address(0x3Ee021f6f91911b8a2af6047889C54CC4983f78D);
        else if (chain == Constants.CHAIN_OPTIMISM) return address(0x4Fa745FCCC04555F2AFA8874cd23961636CdF982);
        else if (chain == Constants.CHAIN_AVALANCHE) return address(0xFC48E39fed51F2937c8CE7eE95eD9181c2790ab1);
        else if (chain == Constants.CHAIN_BASE) return address(0x874f1686E8F89374A40196B54F435Cc1A72d04e4);
        else if (chain == Constants.CHAIN_CELO) return address(0x892bf71463Bd9fa57f3c2266aB74dbe1B96DECEa);
        else if (chain == Constants.CHAIN_GNOSIS) return address(0xbDD9a43790BFe85DA12a9EfBf0eaFD8135538c99);
        else if (chain == Constants.CHAIN_LINEA) return address(0x52F0C256E58c579Bf9E41e4332669b4f7C7209c5);
        else if (chain == Constants.CHAIN_POLYGON) return address(0x05E08E1BF31C1882822Cc48D7d51d6fe49Bca9c2);
        else if (chain == Constants.CHAIN_ETHEREUM) return address(0x042d98c63f642797C132B3e99C20fF6F751aaD3a);
        else revert("chain not supported");
    }
}
