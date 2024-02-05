// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { IERC721Metadata } from "oz/token/ERC721/extensions/IERC721Metadata.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, ITreasury, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

interface IVaultManager {
 function setDebtCeiling(uint256 _debtCeiling) external;
}

contract SetDebtCeiling is Utils {
    function run() external {

        /** TODO  complete */
        uint256 chainId = CHAIN_ARBITRUM;
        address[] memory vaults = new address[](1);
        uint256[] memory debtCeilings = new uint256[](1);
        // cvx-3CRV
        vaults[0] = 0x7f27082EABddDC9dc3CC6632C9f594d210B9d43c;
        debtCeilings[0] = 0;
        /** END  complete */

        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        for(uint256 i=0;i<vaults.length;++i) {
            address to = vaults[i];
            bytes memory data = abi.encodeWithSelector(IVaultManager.setDebtCeiling.selector, debtCeilings[i]);
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }


        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        address multiSend = address(_chainToMultiSend(chainId));
        address guardian = address(_chainToContract(chainId, ContractType.GuardianMultisig));
        // Verify that the calls will succeed
        vm.startBroadcast(guardian);
        address(multiSend).delegatecall(payloadMultiSend);
        vm.stopBroadcast();

        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, hex"");
    }
}
