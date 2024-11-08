// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { ITransmuter, ISettersGovernor, ISettersGuardian, ISwapper } from "transmuter/interfaces/ITransmuter.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

contract TransmuterSetFees is Utils {
    uint64[] public xFeeBurn;
    int64[] public yFeeBurn;

    function run() external {
        uint256 chainId = vm.envUint("CHAIN_ID");

        address safe = _chainToContract(chainId, ContractType.GuardianMultisig);
        bytes memory transactions;

        xFeeBurn = new uint64[](1);
        yFeeBurn = new int64[](xFeeBurn.length);
        xFeeBurn[0] = 1e9;
        yFeeBurn[0] = 0;

        {
            ITransmuter transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));
            address to = address(transmuter);
            uint8 isDelegateCall = 0;
            {
                bytes memory data = abi.encodeWithSelector(ISettersGuardian.setFees.selector, 0x3Ee320c9F73a84D1717557af00695A34b26d1F1d, xFeeBurn, yFeeBurn, false);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, uint256(0), dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        _serializeJson(chainId, address(_chainToMultiSend(chainId)), uint256(0), payloadMultiSend, Enum.Operation.DelegateCall, hex"", safe);
    }
}
