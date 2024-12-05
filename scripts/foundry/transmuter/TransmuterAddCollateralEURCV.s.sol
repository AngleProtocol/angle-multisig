// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ITransmuter, ISettersGovernor, ISettersGuardian, ISwapper } from "transmuter/interfaces/ITransmuter.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract TransmuterAddCollateralEURCV is Utils {
    address public constant COLLATERAL_TO_ADD = 0x5F7827FDeb7c20b443265Fc2F40845B715385Ff2;

    bytes oracleConfigCollatToAdd;
    uint64[] public xFeeMint;
    int64[] public yFeeMint;
    uint64[] public xFeeBurn;
    int64[] public yFeeBurn;
    address public agToken;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_ID");

        address safe = _chainToContract(chainId, ContractType.GovernorMultisig);
        ITransmuter transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));
        agToken = address(transmuter.agToken());
        bytes memory transactions;

        uint64[] memory xFeeBurn = new uint64[](1);
        uint64[] memory xFeeMint = new uint64[](3);
        int64[] memory yFeeMint = new int64[](xFeeMint.length);
        int64[] memory yFeeBurn = new int64[](xFeeBurn.length);
        xFeeBurn[0] = 1e9;
        yFeeBurn[0] = 0.0005e9;

        xFeeMint[0] = 0;
        xFeeMint[1] = 0.29e9;
        xFeeMint[2] = 0.30e9;
        yFeeMint[0] = 0;
        yFeeMint[1] = 0;
        yFeeMint[2] = 100e9 - 1;

        // Add the new collateral
        {
            address to = address(transmuter);
            uint8 isDelegateCall = 0;
            {
                bytes memory readData;
                bytes memory targetData;
                oracleConfigCollatToAdd = abi.encode(
                    Storage.OracleReadType.NO_ORACLE,
                    Storage.OracleReadType.STABLE,
                    readData,
                    targetData,
                    // With no oracle the below oracles are useless
                    abi.encode(uint128(0), uint128(0))
                );
            }
            {
                bytes memory data = abi.encodeWithSelector(ISettersGovernor.addCollateral.selector, COLLATERAL_TO_ADD);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                // Mint fees
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.setFees.selector,
                    COLLATERAL_TO_ADD,
                    xFeeMint,
                    yFeeMint,
                    true
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                // Burn fees
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.setFees.selector,
                    COLLATERAL_TO_ADD,
                    xFeeBurn,
                    yFeeBurn,
                    false
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGovernor.setOracle.selector,
                    COLLATERAL_TO_ADD,
                    oracleConfigCollatToAdd
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.togglePause.selector,
                    COLLATERAL_TO_ADD,
                    Storage.ActionType.Mint
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.togglePause.selector,
                    COLLATERAL_TO_ADD,
                    Storage.ActionType.Burn
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        _serializeJson(chainId, address(_chainToMultiSend(chainId)), uint256(0), payloadMultiSend, Enum.Operation.DelegateCall, hex"", safe);
    }
}
