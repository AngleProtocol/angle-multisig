// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import { IERC20Metadata } from "oz/token/ERC20/extensions/IERC20Metadata.sol";
import "../Constants.s.sol";

import { TimelockController } from "oz/governance/TimelockController.sol";

contract SetExecutor is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        uint256 chainId = vm.envUint("CHAIN_ID");

        TimelockController timelock = TimelockController(payable(_chainToContract(chainId, ContractType.Timelock)));

        /** TODO  complete */
        address target = address(timelock);
        uint256 timelockValue = 0;
        bytes
            memory payload = hex"2f2ff15dd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e630000000000000000000000000000000000000000000000000000000000000000";
        bytes32 predecessor = hex"";
        bytes32 salt = hex"";
        /** END  complete */

        address to = address(timelock);
        bytes memory data = abi.encodeWithSelector(
            TimelockController.execute.selector,
            target,
            timelockValue,
            payload,
            predecessor,
            salt
        );
        uint256 dataLength = data.length;
        transactions = abi.encodePacked(isDelegateCall, to, value, dataLength, data);

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, data);
    }
}
