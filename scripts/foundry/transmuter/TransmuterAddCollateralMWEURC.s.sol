// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ITransmuter, ISettersGovernor, ISettersGuardian, ISwapper } from "transmuter/interfaces/ITransmuter.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import { MAX_MINT_FEE, MAX_BURN_FEE } from "transmuter/utils/Constants.sol";
import "../Constants.s.sol";

contract TransmuterAddCollateralMWEURC is Utils {
    address public constant COLLATERAL_TO_ADD = 0xf24608E0CCb972b0b0f4A6446a0BBf58c701a026;

    bytes oracleConfigCollatToAdd;
    uint64[] public xFeeMint;
    int64[] public yFeeMint;
    uint64[] public xFeeBurn;
    int64[] public yFeeBurn;
    uint256 public capStablecoin;
    address public agToken;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_ID");

        ITransmuter transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));
        agToken = address(transmuter.agToken());
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        address to = address(transmuter);
        uint256 value = 0;

        xFeeBurn = new uint64[](3);
        xFeeMint = new uint64[](3);
        yFeeMint = new int64[](xFeeMint.length);
        yFeeBurn = new int64[](xFeeBurn.length);
        xFeeBurn[0] = 1e9;
        xFeeBurn[1] = 0.21e9;
        xFeeBurn[2] = 0.2e9;
        yFeeBurn[0] = 0.005e9;
        yFeeBurn[1] = 0.005e9;
        yFeeBurn[2] = int64(uint64(MAX_BURN_FEE));

        xFeeMint[0] = 0;
        xFeeMint[1] = 0.59e9;
        xFeeMint[2] = 0.6e9;
        yFeeMint[0] = 0.0005e9;
        yFeeMint[1] = 0.0005e9;
        yFeeMint[2] = int64(uint64(MAX_MINT_FEE));

        capStablecoin = 2_000_000 ether;

        // Add the new collateral
        {
            {
                bytes memory data = abi.encodeWithSelector(ISettersGovernor.addCollateral.selector, COLLATERAL_TO_ADD);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                // Mint fees
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.setFees.selector, COLLATERAL_TO_ADD, xFeeMint, yFeeMint, true
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                // Burn fees
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.setFees.selector, COLLATERAL_TO_ADD, xFeeBurn, yFeeBurn, false
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }

            {
                bytes memory readData;
                {
                    bytes32[] memory feedIds = new bytes32[](2);
                    uint32[] memory stalePeriods = new uint32[](2);
                    uint8[] memory isMultiplied = new uint8[](2);
                    // pyth address
                    address pyth = 0x8250f4aF4B972684F7b336503E2D6dFeDeB1487a;
                    // EUROC/USD
                    feedIds[0] = 0x76fa85158bf14ede77087fe3ae472f66213f6ea2f5b411cb2de472794990fa5c;
                    // USD/EUR
                    feedIds[1] = 0xa995d00bb36a63cef7fd2c287dc105fc8f3d93779f062f09551b0af3e81ec30b;
                    stalePeriods[0] = 14 days;
                    stalePeriods[1] = 14 days;
                    isMultiplied[0] = 1;
                    isMultiplied[1] = 0;
                    Storage.OracleQuoteType quoteType = Storage.OracleQuoteType.UNIT;
                    readData = abi.encode(pyth, feedIds, stalePeriods, isMultiplied, quoteType);
                }
                bytes memory targetData;
                oracleConfigCollatToAdd = abi.encode(
                    Storage.OracleReadType.PYTH,
                    Storage.OracleReadType.STABLE,
                    readData,
                    targetData,
                    abi.encode(uint128(0), uint128(0))
                );
            }

            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGovernor.setOracle.selector, COLLATERAL_TO_ADD, oracleConfigCollatToAdd
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.togglePause.selector, COLLATERAL_TO_ADD, Storage.ActionType.Mint
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.togglePause.selector, COLLATERAL_TO_ADD, Storage.ActionType.Burn
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data =
                    abi.encodeWithSelector(ISettersGuardian.setStablecoinCap.selector, COLLATERAL_TO_ADD, capStablecoin);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(
            chainId,
            multiSend,
            0,
            payloadMultiSend,
            Enum.Operation.DelegateCall,
            hex"",
            _chainToContract(chainId, ContractType.GovernorMultisig)
        );
    }
}
