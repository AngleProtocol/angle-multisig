// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import {ITransparentUpgradeableProxy} from "oz/proxy/transparent/TransparentUpgradeableProxy.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import { Enum } from "safe/Safe.sol";
import "../Constants.s.sol";

contract UpgradeRouter is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        uint256 chainId = vm.envUint("CHAIN_ID");

        /** TODO  complete */
        address router = _chainToContract(chainId, ContractType.AngleRouter);
        address routerImpl = implRouter(chainId);
        /** END  complete */

        if (chainId == CHAIN_LINEA) {
            {
                bytes memory data = abi.encodeWithSelector(ITransparentUpgradeableProxy.upgradeTo.selector, routerImpl);
                address to = router;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        } else {
            {
                bytes memory data = abi.encodeWithSelector(ProxyAdmin.upgrade.selector, router, routerImpl);
                address to = _chainToContract(chainId, ContractType.ProxyAdminGuardian);
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);

        // Verify that the calls will succeed
        address multiSend = address(_chainToMultiSend(chainId));
        address safe = address(_chainToContract(chainId, ContractType.GuardianMultisig));

        vm.startBroadcast(safe);
        address(multiSend).delegatecall(payloadMultiSend);
        vm.stopBroadcast();
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, hex"", safe);
    }
}
