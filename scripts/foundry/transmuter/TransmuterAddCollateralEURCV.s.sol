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
    uint256 constant BPS = 1e14;

    bytes oracleConfigCollatToAdd;
    uint64[] public xFeeMint;
    int64[] public yFeeMint;
    uint64[] public xFeeBurn;
    int64[] public yFeeBurn;
    address public agToken;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_ID");

        ITransmuter transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));
        agToken = address(transmuter.agToken());
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        address to = address(transmuter);
        uint256 value = 0;

        (uint64[] memory xFeeMint, int64[] memory yFeeMint) = transmuter.getCollateralMintFees(EUROC);
        (uint64[] memory xFeeBurn, int64[] memory yFeeBurn) = transmuter.getCollateralBurnFees(EUROC);

        // Add the new collateral
        {
            {
                bytes memory readData;
                bytes memory targetData;
                oracleConfigCollatToAdd = abi.encode(
                    Storage.OracleReadType.NO_ORACLE,
                    Storage.OracleReadType.STABLE,
                    readData,
                    targetData,
                    // With no oracle the below oracles are useless
                    abi.encode(uint128(0), uint128(50 * BPS))
                );
            }
            {
                bytes memory data = abi.encodeWithSelector(ISettersGovernor.addCollateral.selector, COLLATERAL_TO_ADD);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
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
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
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
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGovernor.setOracle.selector,
                    COLLATERAL_TO_ADD,
                    oracleConfigCollatToAdd
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.togglePause.selector,
                    COLLATERAL_TO_ADD,
                    Storage.ActionType.Mint
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.togglePause.selector,
                    COLLATERAL_TO_ADD,
                    Storage.ActionType.Burn
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, hex"");
    }
}
