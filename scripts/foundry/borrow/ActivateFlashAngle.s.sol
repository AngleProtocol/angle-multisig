// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { OFTCore } from "angle-tokens/agToken/layerZero/utils/OFTCore.sol";
import { NonblockingLzApp } from "angle-tokens/agToken/layerZero/utils/NonblockingLzApp.sol";
import { AgTokenSideChainMultiBridge } from "angle-tokens/agToken/AgTokenSideChainMultiBridge.sol";
import { FlashAngle } from "borrow/flashloan/FlashAngle.sol";
import "../Utils.s.sol";

contract ActivateFlashAngle is Utils {
    function run() external {
        bytes memory transactions;
        uint256 chainId = vm.envUint("CHAIN_ID");
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        /** TODO complete */
        address flashAngle = 0x4e4C68B5De42aFE4fDceFE4e2F9dA684822cBa18; // _chainToContract(chainId, ContractType.FlashLoan);
        address coreBorrow = _chainToContract(chainId, ContractType.CoreBorrow);
        address treasury = _chainToContract(chainId, ContractType.TreasuryAgEUR);
        address agToken = _chainToContract(chainId, ContractType.AgEUR);
        uint64 flashLoanFee = 0;
        uint256 maxBorrowable = 300000e18;
        /** END  complete */

        {
            bytes memory data = abi.encodeWithSelector(
                CoreBorrow.setFlashLoanModule.selector,
                flashAngle
            );
            address to = coreBorrow;
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }
        {
            bytes memory data = abi.encodeWithSelector(
                CoreBorrow.addFlashLoanerTreasuryRole.selector,
                treasury
            );
            address to = coreBorrow;
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }
        {
            bytes memory data = abi.encodeWithSelector(
                FlashAngle.setFlashLoanParameters.selector,
                agToken,
                flashLoanFee,
                maxBorrowable
            );
            address to = flashAngle;
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        // Verify that the calls will succeed
        address multiSend = address(_chainToMultiSend(chainId));
        address safe = address(_chainToContract(chainId, ContractType.GovernorMultisig));
        vm.startBroadcast(safe);
        address(multiSend).delegatecall(payloadMultiSend);
        vm.stopBroadcast();
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, new bytes(0), safe);
    }
}
