// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { IVaultManagerFunctions } from "borrow/interfaces/IVaultManager.sol";
import { IERC721Metadata } from "oz/token/ERC721/extensions/IERC721Metadata.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, ITreasury, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract SetDebtCeiling is Utils {
    function run() external {

        /** TODO  complete */
        uint256 chainId = CHAIN_ARBITRUM;
        address[] memory vaults = new address[](2);
        uint256[] memory debtCeilings = new uint256[](2);
        // wETH
        vaults[0] = 0xe9f183FC656656f1F17af1F2b0dF79b8fF9ad8eD;
        debtCeilings[0] = 1500000000000000000000000;
        // wBTC
        vaults[1] = 0xF664118E79C0B34f1Ed20e6606a0068d213839b9;
        debtCeilings[1] = 650000000000000000000000;
        /** END  complete */

        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        for(uint256 i=0;i<vaults.length;++i) {
            address to = vaults[i];
            bytes memory data = abi.encodeWithSelector(IVaultManagerGovernance.setDebtCeiling.selector, debtCeilings[i]);
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }


        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        address multiSend = address(_chainToMultiSend(chainId));
        address guardian = address(_chainToGuardian(chainId));
        // Verify that the calls will succeed
        vm.startBroadcast(guardian);
        address(multiSend).delegatecall(payloadMultiSend);
        vm.stopBroadcast();

        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, hex"");
    }
}
