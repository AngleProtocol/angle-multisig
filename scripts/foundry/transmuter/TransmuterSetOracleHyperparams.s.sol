// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ITransmuter, ISettersGovernor, ISettersGuardian, ISwapper } from "transmuter/interfaces/ITransmuter.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract TransmuterSetOracleHyperparams is Utils {
    address public constant COLLATERAL = 0x60a3E35Cc302bFA44Cb288Bc5a4F316Fdb1adb42;

    bytes oracleConfigCollat;
    address public agToken;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_ID");

        ITransmuter transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));
        // ITransmuter transmuter = ITransmuter(0xBA0e73218a80C3deC1213d64873aF83B02cE0455);

        agToken = address(transmuter.agToken());
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        address to = address(transmuter);
        uint256 value = 0;

        // Get current oracle config
        {
            (
                Storage.OracleReadType oracleType,
                Storage.OracleReadType targetType,
                bytes memory oracleData,
                bytes memory targetData,
                bytes memory hyperparameters
            ) = transmuter.getOracle(COLLATERAL);

            // overwrite hyperparamters config
            hyperparameters = abi.encode(uint128(1000000000000000), 0);

            // Set new oracle config
            oracleConfigCollat = abi.encode(oracleType, targetType, oracleData, targetData, hyperparameters);

            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGovernor.setOracle.selector,
                    COLLATERAL,
                    oracleConfigCollat
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        {
            bytes memory data = abi.encodeWithSelector(
                ISettersGovernor.toggleTrusted.selector,
                0xa9bbbDDe822789F123667044443dc7001fb43C01,
                Storage.TrustedType.Seller
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, hex"");
    }
}
