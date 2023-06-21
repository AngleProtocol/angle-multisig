// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { Safe, Enum } from "safe/Safe.sol";

/// @title Utils
/// @author Angle Labs, Inc.
contract Utils is Script {
    ITransmuter public transmuter = ITransmuter(address(0x0));
    Safe public governorMainnetSafe = Safe(payable(address(0x0)));
    Safe public guardianMainnetSafe = Safe(payable(address(0x0)));
    Safe public governorArbitrumSafe = Safe(payable(address(0x0)));
    Safe public guardianArbitrumSafe = Safe(payable(address(0x0)));
    MultiSend public multiSend = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);

    function _serializeJson(address to, uint256 value, bytes memory data, Enum.Operation operation) internal {
        string memory json = "";
        vm.serializeAddress(json, "to", to);
        vm.serializeUint(json, "value", value);
        vm.serializeUint(json, "operation", uint256(operation));
        string memory finalJson = vm.serializeBytes(json, "data", data);

        console.log(finalJson);
        vm.writeJson(finalJson, "./scripts/foundry/transaction.json");
    }
}
