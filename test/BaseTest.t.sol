// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Test } from "forge-std/Test.sol";
import "../scripts/foundry/Constants.s.sol";
import "../scripts/foundry/Utils.s.sol";
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
contract BaseTest is Test, Utils {
    string public json;

    function setUp() public virtual override {
        super.setUp();
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/scripts/foundry/transaction.json");
        json = vm.readFile(path);
    }
}
