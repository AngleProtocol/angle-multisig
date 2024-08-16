// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ITransmuter, ISettersGovernor, ISettersGuardian, ISwapper } from "transmuter/interfaces/ITransmuter.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract TransmuterRevokeAddCollateral is Utils {
    address public constant COLLATERAL_TO_REMOVE = 0xCA30c93B02514f86d5C86a6e375E3A330B435Fb5;
    address public constant COLLATERAL_TO_ADD = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;
    address public RECEIVER = 0xA9DdD91249DFdd450E81E1c56Ab60E1A62651701;
    uint256 constant BPS = 1e14;

    bytes oracleConfigCollatToAdd;
    uint64[] public xFeeMint;
    int64[] public yFeeMint;
    uint64[] public xFeeBurn;
    int64[] public yFeeBurn;
    address public agToken;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_ID");

        ITransmuter transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgUSD));
        agToken = address(transmuter.agToken());
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        address to = address(transmuter);
        uint256 value = 0;

        // Allow full burn of revoked collateral
        {
            uint64[] memory xFeeBurn = new uint64[](1);
            xFeeBurn[0] = uint64(1000000000);
            int64[] memory yFeeBurn = new int64[](1);
            yFeeBurn[0] = 0;

            // Burn fees
            bytes memory data = abi.encodeWithSelector(
                ISettersGuardian.setFees.selector,
                COLLATERAL_TO_REMOVE,
                xFeeBurn,
                yFeeBurn,
                false
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // Whitelist deployer multisig to receive bC3M
        {
            bytes memory data = abi.encodeWithSelector(
                ISettersGuardian.toggleWhitelist.selector,
                Storage.WhitelistType.BACKED,
                RECEIVER
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // Empty the stables minted through the revoked collateral
        {
            (uint256 stablecoinsFromCollateral, ) = transmuter.getIssuedByCollateral(COLLATERAL_TO_REMOVE);
            (, , , , uint256 oraclePrice) = transmuter.getOracleValues(COLLATERAL_TO_REMOVE);

            bytes memory data = abi.encodeWithSelector(
                ISwapper.swapExactInput.selector,
                stablecoinsFromCollateral,
                (stablecoinsFromCollateral * BASE_18 * 995) / 1000 / oraclePrice,
                agToken,
                COLLATERAL_TO_REMOVE,
                RECEIVER,
                0
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // Collateral to remove
        {
            // Get the previous mint/burn configs
            // TODO actually it may be too soft to let up to 50% with no oracle + increase burn the fees to 10 BPS
            // as we may be more close to that
            (xFeeMint, yFeeMint) = transmuter.getCollateralMintFees(address(COLLATERAL_TO_REMOVE));
            (xFeeBurn, yFeeBurn) = transmuter.getCollateralBurnFees(address(COLLATERAL_TO_REMOVE));
        }

        // Revoke the collateral
        {
            bytes memory data = abi.encodeWithSelector(
                ISettersGovernor.revokeCollateral.selector,
                COLLATERAL_TO_REMOVE
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // Add the new collateral
        {
            {
                bytes memory readData;
                bytes memory targetData;
                oracleConfigCollatToAdd = abi.encode(
                    // TODO this should be temporary as long as we don't have a price on USDM
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
