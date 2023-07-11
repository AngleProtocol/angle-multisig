// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Test } from "forge-std/Test.sol";
import "../scripts/foundry/Constants.s.sol";

struct TxJson {
    uint256 chainId;
    address to;
    uint256 value;
    uint256 operation;
    bytes data;
}

/// @title Test
/// @author Angle Labs, Inc.
contract Utils is Test {
    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                         FORKS                                                      
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    uint256 public arbitrumFork;
    uint256 public avalancheFork;
    uint256 public ethereumFork;
    uint256 public optimismFork;
    uint256 public polygonFork;
    string public json;

    function setUp() public virtual {
        arbitrumFork = vm.createFork(vm.envString("ETH_NODE_URI_ARBITRUM"));
        avalancheFork = vm.createFork(vm.envString("ETH_NODE_URI_AVALANCHE"));
        ethereumFork = vm.createFork(vm.envString("ETH_NODE_URI_MAINNET"));
        optimismFork = vm.createFork(vm.envString("ETH_NODE_URI_OPTIMISM"));
        polygonFork = vm.createFork(vm.envString("ETH_NODE_URI_POLYGON"));

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/scripts/foundry/transaction.json");
        json = vm.readFile(path);
    }
}
