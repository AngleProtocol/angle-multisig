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
    mapping(uint256 => uint256) internal forkIdentifier;
    uint256 public arbitrumFork;
    uint256 public avalancheFork;
    uint256 public ethereumFork;
    uint256 public optimismFork;
    uint256 public polygonFork;
    uint256 public gnosisFork;
    uint256 public bnbFork;
    uint256 public celoFork;
    uint256 public polygonZkEVMFork;
    uint256 public baseFork;
    uint256 public lineaFork;

    bytes[] private calldatas;
    string private description;
    address[] private targets;
    uint256[] private values;
    uint256[] private chainIds;

    function setUp() public virtual {
        arbitrumFork = vm.createFork(vm.envString("ETH_NODE_URI_ARBITRUM"));
        avalancheFork = vm.createFork(vm.envString("ETH_NODE_URI_AVALANCHE"));
        ethereumFork = vm.createFork(vm.envString("ETH_NODE_URI_MAINNET"));
        optimismFork = vm.createFork(vm.envString("ETH_NODE_URI_OPTIMISM"));
        polygonFork = vm.createFork(vm.envString("ETH_NODE_URI_POLYGON"));
        gnosisFork = vm.createFork(vm.envString("ETH_NODE_URI_GNOSIS"));
        bnbFork = vm.createFork(vm.envString("ETH_NODE_URI_BSC"));
        celoFork = vm.createFork(vm.envString("ETH_NODE_URI_CELO"));
        polygonZkEVMFork = vm.createFork(vm.envString("ETH_NODE_URI_POLYGON_ZKEVM"));
        baseFork = vm.createFork(vm.envString("ETH_NODE_URI_BASE"));
        lineaFork = vm.createFork(vm.envString("ETH_NODE_URI_LINEA"));

        forkIdentifier[CHAIN_ARBITRUM] = arbitrumFork;
        forkIdentifier[CHAIN_AVALANCHE] = avalancheFork;
        forkIdentifier[CHAIN_ETHEREUM] = ethereumFork;
        forkIdentifier[CHAIN_OPTIMISM] = optimismFork;
        forkIdentifier[CHAIN_POLYGON] = polygonFork;
        forkIdentifier[CHAIN_GNOSIS] = gnosisFork;
        forkIdentifier[CHAIN_BNB] = bnbFork;
        forkIdentifier[CHAIN_CELO] = celoFork;
        forkIdentifier[CHAIN_POLYGONZKEVM] = polygonZkEVMFork;
        forkIdentifier[CHAIN_BASE] = baseFork;
        forkIdentifier[CHAIN_LINEA] = lineaFork;
    }

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
        else if (chain == CHAIN_LINEA) return multiSendLinea;
        else if (chain == CHAIN_MANTLE) return multiSendMantle;
        else revert("chain not supported");
    }

    function _chainToContract(uint256 chainId, ContractType name) internal returns (address) {
        string[] memory cmd = new string[](4);
        cmd[0] = "node";
        cmd[1] = "utils/contractAddress.js";
        cmd[2] = vm.toString(chainId);

        if (name == ContractType.AgEUR) cmd[3] = "agEUR";
        else if (name == ContractType.AgUSD) cmd[3] = "agUSD";
        else if (name == ContractType.AgEURLZ) cmd[3] = "agEURLz";
        else if (name == ContractType.AgUSDLZ) cmd[3] = "agUSDLz";
        else if (name == ContractType.Angle) cmd[3] = "angle";
        else if (name == ContractType.AngleLZ) cmd[3] = "angleLz";
        else if (name == ContractType.AngleDistributor) cmd[3] = "angleDistributor";
        else if (name == ContractType.AngleMiddleman) cmd[3] = "angleMiddleman";
        else if (name == ContractType.AngleRouter) cmd[3] = "angleRouter";
        else if (name == ContractType.CoreBorrow) cmd[3] = "coreBorrow";
        else if (name == ContractType.CoreMerkl) cmd[3] = "coreMerkl";
        else if (name == ContractType.DistributionCreator) cmd[3] = "distributionCreator";
        else if (name == ContractType.Distributor) cmd[3] = "distributor";
        else if (name == ContractType.FeeDistributor) cmd[3] = "feeDistributor";
        else if (name == ContractType.GaugeController) cmd[3] = "gaugeController";
        else if (name == ContractType.Governor) cmd[3] = "governor";
        else if (name == ContractType.GovernorMultisig) cmd[3] = "governorMultisig";
        else if (name == ContractType.GuardianMultisig) cmd[3] = "guardianMultisig";
        else if (name == ContractType.MerklMiddleman) cmd[3] = "merklMiddleman";
        else if (name == ContractType.ProposalReceiver) cmd[3] = "proposalReceiver";
        else if (name == ContractType.ProposalSender) cmd[3] = "proposalSender";
        else if (name == ContractType.ProxyAdmin) cmd[3] = "proxyAdmin";
        else if (name == ContractType.SmartWalletWhitelist) cmd[3] = "smartWalletWhitelist";
        else if (name == ContractType.StEUR) cmd[3] = "stEUR";
        else if (name == ContractType.StUSD) cmd[3] = "stUSD";
        else if (name == ContractType.Timelock) cmd[3] = "timelock";
        else if (name == ContractType.TransmuterAgEUR) cmd[3] = "transmuterAgEUR";
        else if (name == ContractType.TransmuterAgUSD) cmd[3] = "transmuterAgUSD";
        else if (name == ContractType.TreasuryAgEUR) cmd[3] = "treasuryAgEUR";
        else if (name == ContractType.TreasuryAgUSD) cmd[3] = "treasuryAgUSD";
        else if (name == ContractType.veANGLE) cmd[3] = "veANGLE";
        else if (name == ContractType.veBoost) cmd[3] = "veBoost";
        else if (name == ContractType.veBoostProxy) cmd[3] = "veBoostProxy";
        else revert("contract not supported");

        bytes memory res = vm.ffi(cmd);
        // When process exit code is 1, it will return an empty bytes "0x"
        if (res.length == 0) revert("Chain not supported");
        return address(bytes20(res));
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        // Check length is 0. `iszero` return 1 for `true` and 0 for `false`.
        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // Calculate length mod 32 to handle slices that are not a multiple of 32 in size.
                let lengthmod := and(_length, 31)

                // tempBytes will have the following format in memory: <length><data>
                // When copying data we will offset the start forward to avoid allocating additional memory
                // Therefore part of the length area will be written, but this will be overwritten later anyways.
                // In case no offset is require, the start is set to the data region (0x20 from the tempBytes)
                // mc will be used to keep track where to copy the data to.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // Same logic as for mc is applied and additionally the start offset specified for the method is added
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    // increase `mc` and `cc` to read the next word from memory
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // Copy the data from source (cc location) to the slice data (mc location)
                    mstore(mc, mload(cc))
                }

                // Store the length of the slice. This will overwrite any partial data that
                // was copied when having slices that are not a multiple of 32.
                mstore(tempBytes, _length)

                // update free-memory pointer
                // allocating the array padded to 32 bytes like the compiler does now
                // To set the used memory as a multiple of 32, add 31 to the actual memory usage (mc)
                // and remove the modulo 32 (the `and` with `not(31)`)
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            // if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                // zero out the 32 bytes slice we are about to return
                // we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                // update free-memory pointer
                // tempBytes uses 32 bytes in memory (even when empty) for the length.
                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}
