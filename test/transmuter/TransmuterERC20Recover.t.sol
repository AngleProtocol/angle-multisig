// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import "../../scripts/foundry/Constants.s.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import "transmuter/utils/Errors.sol" as Errors;
import { ITransmuter, ISettersGovernor, ISettersGuardian, ISwapper, IGetters } from "transmuter/interfaces/ITransmuter.sol";
import { MAX_MINT_FEE, MAX_BURN_FEE } from "transmuter/utils/Constants.sol";
import { IERC20 } from "oz/token/ERC20/IERC20.sol";
import { IERC4626 } from "oz/token/ERC20/extensions/ERC4626.sol";
import { BaseHarvester } from "transmuter/helpers/BaseHarvester.sol";

contract TransmuterRecoverERC20Test is BaseTest {
    using stdJson for string;

    ITransmuter public transmuter;
    address[] public erc20ToRecover;
    uint256[] public amountToRecover;
    uint256[] public balancesBefore;
    address public receiver = 0xA9DdD91249DFdd450E81E1c56Ab60E1A62651701;

    function testScript() external {
        erc20ToRecover = new address[](3);
        erc20ToRecover[0] = 0xCA30c93B02514f86d5C86a6e375E3A330B435Fb5;
        erc20ToRecover[1] = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
        erc20ToRecover[2] = 0x9994E35Db50125E0DF82e4c2dde62496CE330999;

        amountToRecover = new uint256[](3);
        amountToRecover[0] = 319821197533155415531;
        amountToRecover[1] = 2795614800816400737;
        amountToRecover[2] = 309033239278443116794779;

        balancesBefore = new uint256[](erc20ToRecover.length);

        uint256 chainId = json.readUint("$.chainId");
        address safe = json.readAddress("$.safe");
        vm.selectFork(forkIdentifier[chainId]);
        transmuter = transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));

        address to = json.readAddress("$.to");
        // uint256 value = json.readUint("$.value");
        uint256 operation = json.readUint("$.operation");
        bytes memory payload = json.readBytes("$.data");

        for (uint256 i = 0; i < erc20ToRecover.length; i++) {
            balancesBefore[i] = IERC20(erc20ToRecover[i]).balanceOf(receiver);
        }

        // Verify that the call will succeed
        MockSafe mockSafe = new MockSafe();
        vm.etch(safe, address(mockSafe).code);
        vm.prank(safe);
        (bool success, ) = safe.call(abi.encode(address(to), payload, operation, 1e7));
        if (!success) revert();

        for (uint256 i = 0; i < erc20ToRecover.length; i++) {
            uint256 balanceAfter = IERC20(erc20ToRecover[i]).balanceOf(receiver);
            assertEq(balanceAfter, balancesBefore[i] + amountToRecover[i]);
        }
    }
}
