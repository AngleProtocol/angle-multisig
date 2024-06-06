// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ISettersGuardian } from "transmuter/interfaces/ISetters.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";
import { ITransmuter, ISettersGovernor, ISettersGuardian } from "transmuter/interfaces/ITransmuter.sol";

interface IAddMinter {
    function addMinter(address minter) external;
}

interface ISetStablecoin {
    function setStablecoinCap(address collateral, uint256 cap) external;
}

contract TransmuterCrosschainActivation is Utils {
    ITransmuter public transmuter;
    IAgToken public agToken;
    ITreasury public treasury;
    address[] public collateralList;
    uint128 public userProtection;
    uint256 constant BPS = 1e14;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_ID");

        // TODO
        StablecoinType fiat = StablecoinType.USD;
        uint256 newCap = 2_000_000 ether;
        userProtection = uint128(5 * BPS);
        // TODO END

        transmuter = _getTransmuter(chainId, fiat);
        treasury = _getTreasury(chainId, fiat);
        agToken = _getAgToken(chainId, fiat);
        // There should only be one collateral
        collateralList = transmuter.getCollateralList();

        bytes memory transactions;
        uint8 isDelegateCall = 0;
        address to;
        uint256 value = 0;

        if (chainId != CHAIN_ARBITRUM) {
            to = address(treasury);
            bytes memory data = abi.encodeWithSelector(IAddMinter.addMinter.selector, address(transmuter));
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        {
            to = address(transmuter);
            bytes memory data = abi.encodeWithSelector(
                ISetStablecoin.setStablecoinCap.selector,
                collateralList[0],
                newCap
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        {
            (
                Storage.OracleReadType oracleType,
                Storage.OracleReadType targetType,
                bytes memory oracleData,
                bytes memory targetData,

            ) = transmuter.getOracle(collateralList[0]);

            to = address(transmuter);
            bytes memory data = abi.encodeWithSelector(
                ISettersGovernor.setOracle.selector,
                collateralList[0],
                abi.encode(oracleType, targetType, oracleData, targetData, abi.encode(userProtection, uint128(0)))
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // // TODO only on BASE
        // // No minter role
        // if (chainId == CHAIN_BASE) {
        //     address receiver = 0xa9bbbDDe822789F123667044443dc7001fb43C01;
        //     uint256 amount = 100_000 ether;

        //     to = address(agToken);
        //     bytes memory data = abi.encodeWithSelector(IAgToken.mint.selector, receiver, amount);
        //     uint256 dataLength = data.length;
        //     bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
        //     transactions = abi.encodePacked(transactions, internalTx);
        // }
        // // TODO END

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, hex"");
    }
}
