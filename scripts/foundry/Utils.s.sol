// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { ITreasury } from "borrow/interfaces/ITreasury.sol";
import { IAgToken } from "borrow/interfaces/IAgToken.sol";
import { MultiSend } from "safe/libraries/MultiSend.sol";
import { Safe, Enum } from "safe/Safe.sol";
import { ITransmuter } from "transmuter/interfaces/ITransmuter.sol";
import "./Constants.s.sol";
import { IAngle } from "./Constants.s.sol";
import { CoreBorrow } from "borrow/coreBorrow/CoreBorrow.sol";
import { ProxyAdmin } from "oz/proxy/transparent/ProxyAdmin.sol";

/// @title Utils
/// @author Angle Labs, Inc.
contract Utils is Script {
    function _serializeJson(
        uint256 chainId,
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        bytes memory additionalData
    ) internal {
        string memory json = "";
        vm.serializeUint(json, "chainId", chainId);
        vm.serializeAddress(json, "to", to);
        vm.serializeUint(json, "value", value);
        vm.serializeUint(json, "operation", uint256(operation));
        vm.serializeBytes(json, "additionalData", additionalData);
        string memory finalJson = vm.serializeBytes(json, "data", data);

        vm.writeJson(finalJson, "./scripts/foundry/transaction.json");
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
        // else if (chain == CHAIN_LINEA) return multiSendLinea;
        // else if (chain == CHAIN_MANTLE) return multiSendMantle;
        else revert("chain not supported");
    }

    function _chainToContract(uint256 chainId, ContractType name) internal returns (address) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[2] = vm.toString(chainId);
        if (name == ContractType.AgEUR) cmd[1] = "utils/agEUR.js";
        else if (name == ContractType.Angle) cmd[1] = "utils/angle.js";
        else if (name == ContractType.AngleDistributor) cmd[1] = "utils/angleDistributor.js";
        else if (name == ContractType.AngleMiddleman) cmd[1] = "utils/angleMiddleman.js";
        else if (name == ContractType.CoreBorrow) cmd[1] = "utils/coreBorrow.js";
        else if (name == ContractType.DistributionCreator) cmd[1] = "utils/distributionCreator.js";
        else if (name == ContractType.FeeDistributor) cmd[1] = "utils/feeDistributor.js";
        else if (name == ContractType.GaugeController) cmd[1] = "utils/gaugeController.js";
        else if (name == ContractType.Governor) cmd[1] = "utils/governor.js";
        else if (name == ContractType.GovernorMultisig) cmd[1] = "utils/governorMultisig.js";
        else if (name == ContractType.GuardianMultisig) cmd[1] = "utils/guardianMultisig.js";
        else if (name == ContractType.MerklMiddleman) cmd[1] = "utils/merklMiddleman.js";
        else if (name == ContractType.ProxyAdmin) cmd[1] = "utils/proxyAdmin.js";
        else if (name == ContractType.SmartWalletWhitelist) cmd[1] = "utils/smartWalletWhitelist.js";
        else if (name == ContractType.StEUR) cmd[1] = "utils/stEUR.js";
        else if (name == ContractType.TransmuterAgEUR) cmd[1] = "utils/transmuter.js";
        else if (name == ContractType.TreasuryAgEUR) cmd[1] = "utils/treasury.js";
        else if (name == ContractType.veANGLE) cmd[1] = "utils/veANGLE.js";
        else if (name == ContractType.veBoost) cmd[1] = "utils/veBoost.js";
        else if (name == ContractType.veBoostProxy) cmd[1] = "utils/veBoostProxy.js";
        else revert("contract not supported");

        bytes memory res = vm.ffi(cmd);
        // When process exit code is 1, it will return an empty bytes "0x"
        if (res.length == 0) revert("Chain not supported");
        console.log(address(bytes20(res)));
        return address(bytes20(res));
    }
}
