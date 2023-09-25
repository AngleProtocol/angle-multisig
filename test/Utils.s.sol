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
    uint256 public localFork;
    string public json;

    function setUp() public virtual {
        arbitrumFork = vm.createFork(vm.envString("ETH_NODE_URI_ARBITRUM"));
        avalancheFork = vm.createFork(vm.envString("ETH_NODE_URI_AVALANCHE"));
        ethereumFork = vm.createFork(vm.envString("ETH_NODE_URI_MAINNET"));
        optimismFork = vm.createFork(vm.envString("ETH_NODE_URI_OPTIMISM"));
        polygonFork = vm.createFork(vm.envString("ETH_NODE_URI_POLYGON"));
        localFork = vm.createFork(vm.envString("ETH_NODE_URI_FORK"));

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/scripts/foundry/transaction.json");
        json = vm.readFile(path);
    }

    function _chainToForkAndSafe(uint256 chainId) internal view returns (uint256, address) {
        return
            chainId == CHAIN_ETHEREUM ? (ethereumFork, address(guardianEthereum)) : chainId == CHAIN_OPTIMISM
                ? (optimismFork, address(guardianOptimism))
                : chainId == CHAIN_POLYGON
                ? (polygonFork, address(guardianPolygon))
                : chainId == CHAIN_ARBITRUM
                ? (arbitrumFork, address(guardianArbitrum))
                : (avalancheFork, address(guardianAvalanche));
    }

    function _chainToAgEUR(uint256 chainId) internal pure returns (address) {
        return
            chainId == CHAIN_ETHEREUM ? address(agEUREthereum) : chainId == CHAIN_OPTIMISM
                ? address(agEUROptimism)
                : chainId == CHAIN_POLYGON
                ? address(agEURPolygon)
                : chainId == CHAIN_ARBITRUM
                ? address(agEURArbitrum)
                : address(agEURAvalanche);
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
