// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ITransmuter, ISettersGovernor, ISettersGuardian, ISwapper } from "transmuter/interfaces/ITransmuter.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract TransmuterAddCollateralMW_EURC is Utils {
    address public constant COLLATERAL_TO_ADD = 0xf24608E0CCb972b0b0f4A6446a0BBf58c701a026;

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

        uint64[] memory xFeeBurn = new uint64[](3);
        uint64[] memory xFeeMint = new uint64[](3);
        int64[] memory yFeeMint = new int64[](xFeeMint.length);
        int64[] memory yFeeBurn = new int64[](xFeeBurn.length);
        xFeeBurn[0] = 1e9;
        xFeeBurn[1] = 0.31e9;
        xFeeBurn[2] = 0.30e9;
        yFeeBurn[0] = 0.005e9;
        yFeeBurn[1] = 0.005e9;
        yFeeBurn[2] = 0.999e9;

        xFeeMint[0] = 0;
        xFeeMint[1] = 0.79e9;
        xFeeMint[2] = 0.80e9;
        yFeeMint[0] = 0.0005e9;
        yFeeMint[1] = 0.0005e9;
        yFeeMint[2] = 100e9 - 1;

        // Add the new collateral
        {
            {
                address oracle = 0x6B102047A4bB943DE39233E44487F2d57bDCb33e; // TODO
                uint256 normalizationFactor = 1e18; // TODO
                bytes memory readData;
                bytes memory targetData = abi.encode(oracle, normalizationFactor);
                oracleConfigCollatToAdd = abi.encode(
                    Storage.OracleReadType.NO_ORACLE,
                    Storage.OracleReadType.MORPHO_ORACLE,
                    readData,
                    targetData,
                    abi.encode(uint128(0), uint128(0))
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
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, hex"", _chainToContract(chainId, ContractType.GovernorMultisig));
    }
}
