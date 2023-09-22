// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import { IERC20Metadata } from "oz/token/ERC20/extensions/IERC20Metadata.sol";
import "../Constants.s.sol";

interface IDistributionCreator {
    function setRewardTokenMinAmounts(address[] calldata tokens, uint256[] calldata amounts) external;

    function rewardTokenMinAmounts(address token) external returns (uint256);
}

contract SetMinAmountsRewardToken is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        // TODO complete for the tokens
        
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory decimals = new uint256[](1);

        uint256 CHAIN = CHAIN_POLYGON;
        tokens[0] = address(0x18e73A5333984549484348A94f4D219f4faB7b81);
        amounts[0] = 105;
        // end TODO

        for (uint256 i = 0; i < tokens.length; i++) {
            decimals[i] = IERC20Metadata(tokens[i]).decimals();
            amounts[i] = amounts[i] * 10**decimals[i];
        }
        address multiSend = address(_chainToMultiSend(CHAIN));

        console.log("Set min rewards amount on chain %s", CHAIN);
        address to = distributionCreator;
        bytes memory data = abi.encodeWithSelector(
            IDistributionCreator.setRewardTokenMinAmounts.selector,
            tokens,
            amounts
        );
        uint256 dataLength = data.length;
        transactions = abi.encodePacked(isDelegateCall, to, value, dataLength, data);

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        _serializeJson(CHAIN, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall);
    }
}
