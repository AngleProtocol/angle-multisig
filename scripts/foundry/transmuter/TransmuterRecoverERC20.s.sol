// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ITransmuter, ISettersGovernor, ISettersGuardian, ISwapper } from "transmuter/interfaces/ITransmuter.sol";
import { Enum } from "safe/Safe.sol";
import { IERC20 } from "oz/token/ERC20/extensions/IERC20Metadata.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract TransmuterRecoverERC20 is Utils {
    address[] public erc20ToRecover;
    uint256[] public amountToRecover;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_ID");

        address safe = _chainToContract(chainId, ContractType.GovernorMultisig);
        bytes memory transactions;

        erc20ToRecover = new address[](3);
        erc20ToRecover[0] = 0xCA30c93B02514f86d5C86a6e375E3A330B435Fb5;
        erc20ToRecover[1] = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
        erc20ToRecover[2] = 0x9994E35Db50125E0DF82e4c2dde62496CE330999;

        amountToRecover = new uint256[](3);
        amountToRecover[0] = 319821197533155415531;
        amountToRecover[1] = 2795614800816400737;
        amountToRecover[2] = 309033239278443116794779;

        {
            ITransmuter transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgUSD));
            uint8 isDelegateCall = 0;
            for (uint256 i = 0; i < erc20ToRecover.length; i++) {
                console.log(erc20ToRecover[i]);
                address to = address(transmuter);
                bytes memory data = abi.encodeWithSelector(
                    ISettersGovernor.recoverERC20.selector,
                    address(0),
                    erc20ToRecover[i],
                    0xA9DdD91249DFdd450E81E1c56Ab60E1A62651701,
                    amountToRecover[i]
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        _serializeJson(
            chainId,
            address(_chainToMultiSend(chainId)),
            uint256(0),
            payloadMultiSend,
            Enum.Operation.DelegateCall,
            hex"",
            safe
        );
    }
}
