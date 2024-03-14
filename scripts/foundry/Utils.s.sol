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
import { CommonUtils } from "utils/src/CommonUtils.sol";

/// @title Utils
/// @author Angle Labs, Inc.
contract Utils is Script, CommonUtils {
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

        function implEURA(uint256 chain) public view returns (address) {
        if(chain == CHAIN_ARBITRUM) return address(0x1a23b27aC7775B6220dC4F816b5c6A629E371f19);
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
        if(chain == CHAIN_ARBITRUM) return address(0x1a23b27aC7775B6220dC4F816b5c6A629E371f19);
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
        if(chain == CHAIN_ARBITRUM) return address(0xDAcf64fe735F5333474C9aE8000120002327a55A);
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
}
