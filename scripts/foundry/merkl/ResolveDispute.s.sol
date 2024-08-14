// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import { IERC20Metadata, IERC20 } from "oz/token/ERC20/extensions/IERC20Metadata.sol";
import "../Constants.s.sol";

interface IDistribution {
    function resolveDispute(bool valid) external;

    function disputer() external returns (address);
}

contract ResolveDispute is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;
        address to;
        bytes memory data;

        uint256 chainId = vm.envUint("CHAIN_ID");

        IDistribution distributor = IDistribution(_chainToContract(chainId, ContractType.Distributor));
        IAgToken agEUR = IAgToken(_chainToContract(chainId, ContractType.AgEUR));

        {
            to = address(distributor);
            data = abi.encodeWithSelector(IDistribution.resolveDispute.selector, false);
            uint256 dataLength = data.length;
            transactions = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
        }

        {
            to = address(agEUR);
            data = abi.encodeWithSelector(
                IERC20.transfer.selector,
                0xF4c94b2FdC2efA4ad4b831f312E7eF74890705DA,
                100 ether
            );
            uint256 dataLength = data.length;
            transactions = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, data);
    }
}
