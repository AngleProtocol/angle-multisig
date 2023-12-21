// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Test } from "forge-std/Test.sol";
import "../scripts/foundry/Constants.s.sol";
import { ContractType } from "../scripts/foundry/Constants.s.sol";

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
    uint256 public gnosisFork;
    uint256 public polygonFork;
    uint256 public localFork;
    string public json;

    function setUp() public virtual {
        arbitrumFork = vm.createFork(vm.envString("ETH_NODE_URI_ARBITRUM"));
        avalancheFork = vm.createFork(vm.envString("ETH_NODE_URI_AVALANCHE"));
        ethereumFork = vm.createFork(vm.envString("ETH_NODE_URI_MAINNET"));
        optimismFork = vm.createFork(vm.envString("ETH_NODE_URI_OPTIMISM"));
        gnosisFork = vm.createFork(vm.envString("ETH_NODE_URI_GNOSIS"));
        polygonFork = vm.createFork(vm.envString("ETH_NODE_URI_POLYGON"));
        localFork = vm.createFork(vm.envString("ETH_NODE_URI_FORK"));

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/scripts/foundry/transaction.json");
        json = vm.readFile(path);
    }

    function _chainToFork(uint256 chainId) internal view returns (uint256) {
        return
            chainId == CHAIN_ETHEREUM ? ethereumFork : chainId == CHAIN_OPTIMISM
                ? optimismFork
                : chainId == CHAIN_POLYGON
                ? polygonFork
                : chainId == CHAIN_ARBITRUM
                ? arbitrumFork
                : chainId == CHAIN_GNOSIS
                ? gnosisFork
                : avalancheFork;
    }

    function _chainToContract(uint256 chainId, ContractType name) internal returns (address) {
        string[] memory cmd = new string[](3);
        cmd[0] = "node";
        cmd[2] = vm.toString(chainId);
        if (name == ContractType.AgEUR) cmd[1] = "utils/agEUR.js";
        else if (name == ContractType.Angle) cmd[1] = "utils/angle.js";
        else if (name == ContractType.CoreBorrow) cmd[1] = "utils/coreBorrow.js";
        else if (name == ContractType.DistributionCreator) cmd[1] = "utils/distributionCreator.js";
        else if (name == ContractType.GovernorMultisig) cmd[1] = "utils/governorMultisig.js";
        else if (name == ContractType.GuardianMultisig) cmd[1] = "utils/guardianMultisig.js";
        else if (name == ContractType.ProxyAdmin) cmd[1] = "utils/proxyAdmin.js";
        else if (name == ContractType.StEUR) cmd[1] = "utils/stEUR.js";
        else if (name == ContractType.TransmuterAgEUR) cmd[1] = "utils/transmuter.js";
        else if (name == ContractType.TreasuryAgEUR) cmd[1] = "utils/treasury.js";
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
