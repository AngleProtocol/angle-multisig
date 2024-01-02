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

        uint256 chainId = vm.envUint("CHAIN_ID");

        /** TODO  complete */
        address[] memory tokens = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory decimals = new uint256[](1);

        tokens[0] = address(0x3E6648C5a70A150A88bCE65F4aD4d506Fe15d2AF);
        amounts[0] = 3000;
        /** END  complete */
        IDistributionCreator distributionCreator = IDistributionCreator(
            _chainToContract(chainId, ContractType.DistributionCreator)
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            decimals[i] = IERC20Metadata(tokens[i]).decimals();
            amounts[i] = amounts[i] * 10 ** decimals[i];
        }
        console.log("Set min rewards amount on chain %s", chainId);
        address to = address(distributionCreator);
        bytes memory data = abi.encodeWithSelector(
            IDistributionCreator.setRewardTokenMinAmounts.selector,
            tokens,
            amounts
        );
        uint256 dataLength = data.length;
        transactions = abi.encodePacked(isDelegateCall, to, value, dataLength, data);

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, data);
    }
}
