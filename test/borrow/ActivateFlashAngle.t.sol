// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { stdJson } from "forge-std/StdJson.sol";
import { console } from "forge-std/console.sol";
import { MockSafe } from "../mock/MockSafe.sol";
import { BaseTest } from "../BaseTest.t.sol";
import { FlashAngle, IERC3156FlashBorrower } from "borrow/flashloan/FlashAngle.sol";
import "../../scripts/foundry/Constants.s.sol";

contract ActivateFlashAngleTest is BaseTest {
    using stdJson for string;

    function testScript() external {
        uint256 chainId = json.readUint("$.chainId");
        address safe = json.readAddress("$.safe");
        vm.selectFork(forkIdentifier[chainId]);

         /** TODO  complete */
        address agToken = _chainToContract(chainId, ContractType.AgEUR);
        address treasury = _chainToContract(chainId, ContractType.TreasuryAgEUR);
        address flashAngle = 0x4e4C68B5De42aFE4fDceFE4e2F9dA684822cBa18; // _chainToContract(chainId, ContractType.FlashLoan);
        uint64 flashLoanFee = 0;
        uint256 maxBorrowable = 300000e18;
        /** END  complete */

        address to = json.readAddress("$.to");
        // uint256 value = json.readUint("$.value");
        uint256 operation = json.readUint("$.operation");
        bytes memory payload = json.readBytes("$.data");

        // Verify that the call will succeed
        MockSafe mockSafe = new MockSafe();
        vm.etch(safe, address(mockSafe).code);
        vm.prank(safe);
        (bool success, ) = safe.call(abi.encode(address(to), payload, operation, 1e6));
        if (!success) revert();

        (uint256 _maxBorrowable, uint64 _flashLoanFee, address _treasury) = FlashAngle(flashAngle).stablecoinMap(IAgToken(agToken));
        assertEq(_maxBorrowable, maxBorrowable);
        assertEq(_flashLoanFee, flashLoanFee);
        assertEq(_treasury, treasury);

        vm.expectCall(address(agToken), abi.encodeWithSelector(IAgToken.mint.selector, address(this), 10e18));
        vm.expectRevert();
        FlashAngle(flashAngle).flashLoan(IERC3156FlashBorrower(address(this)), agToken, 10e18, "");
    }
}
