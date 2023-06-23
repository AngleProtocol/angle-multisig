// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import { Safe, Enum } from "safe/Safe.sol";
import { MultiSend } from "safe/libraries/MultiSend.sol";
import { ITreasury } from "borrow/interfaces/ITreasury.sol";

/// @title Utils
/// @author Angle Labs, Inc.
contract Utils is Script {
    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                       CONSTANTS                                                    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    uint256 public constant BASE_18 = 1e18;

    uint256 public constant CHAIN_ARBITRUM = 42161;
    uint256 public constant CHAIN_AVALANCHE = 43114;
    uint256 public constant CHAIN_MAINNET = 1;
    uint256 public constant CHAIN_OPTIMISM = 10;
    uint256 public constant CHAIN_POLYGON = 137;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                       CONTRACTS                                                    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    ITransmuter public transmuter = ITransmuter(address(0x0));
    ITransmuter public treasuryArbitrum = ITreasury(0x0D710512E100C171139D2Cf5708f22C680eccF52);
    ITransmuter public treasuryAvalanche = ITreasury(0xa014A485D64efb236423004AB1a99C0aaa97a549);
    ITransmuter public treasuryEthereum = ITreasury(0x8667DBEBf68B0BFa6Db54f550f41Be16c4067d60);
    ITransmuter public treasuryPolygon = ITreasury(0x2F2e0ba9746aae15888cf234c4EB5B301710927e);
    ITransmuter public treasuryOptimism = ITreasury(0xe9f183FC656656f1F17af1F2b0dF79b8fF9ad8eD);
    Safe public governorArbitrumSafe = Safe(payable(address(0x0)));
    Safe public governorAvalancheSafe = Safe(payable(address(0x0)));
    Safe public guardianMainnetSafe = Safe(payable(address(0x0)));
    Safe public guardianOptimismSafe = Safe(payable(address(0x0)));
    Safe public guardianPolygonSafe = Safe(payable(address(0x0)));
    MultiSend public multiSendMainnet = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
    MultiSend public multiSendArbitrum = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
    MultiSend public multiSendOptimism = MultiSend(0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B);
    MultiSend public multiSendPolygon = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);

    function _serializeJson(
        uint256 chainId,
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal {
        string memory json = "";
        vm.serializeAddress(json, "chainId", chainId);
        vm.serializeAddress(json, "to", to);
        vm.serializeUint(json, "value", value);
        vm.serializeUint(json, "operation", uint256(operation));
        string memory finalJson = vm.serializeBytes(json, "data", data);

        console.log(finalJson);
        vm.writeJson(finalJson, "./scripts/foundry/transaction.json");
    }
}
