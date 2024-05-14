// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { IERC721Metadata } from "oz/token/ERC721/extensions/IERC721Metadata.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

interface IAngleRouter {
    function setRouter(address router, uint8 who) external;

    function oneInch() external returns (address);
}

contract RouterSetAggregator is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        bytes memory additionalData;
        uint256 value = 0;

        uint256 chainId = vm.envUint("CHAIN_ID");

        /** TODO  complete */
        address aggregator = 0x111111125421cA6dc452d289314280a0f8842A65;
        /** END  complete */
        address angleRouter = _chainToContract(chainId, ContractType.AngleRouter);

        {
            bytes memory data = abi.encodeWithSelector(IAngleRouter.setRouter.selector, aggregator, 1);
            additionalData = abi.encode(aggregator);
            uint256 dataLength = data.length;
            address to = angleRouter;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        // Verify that the calls will succeed
        address multiSend = address(_chainToMultiSend(chainId));
        address guardian = address(_chainToContract(chainId, ContractType.GuardianMultisig));
        vm.startBroadcast(guardian);
        address(multiSend).delegatecall(payloadMultiSend);
        vm.stopBroadcast();

        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, additionalData);
    }
}
