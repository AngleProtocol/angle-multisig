// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { TransparentUpgradeableProxy, ITransparentUpgradeableProxy } from "oz/proxy/transparent/TransparentUpgradeableProxy.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import { Enum } from "safe/Safe.sol";
import { DistributionCreator } from "lib/merkl-contracts/contracts/DistributionCreator.sol";
import "../Constants.s.sol";

contract UpgradeDistributionCreator is Utils {
    function run() external {
        uint256 chainId = block.chainid;
        uint256 privateKey = vm.envUint("MERKL_PRIVATE_KEY");
        address distributionCreator = _chainToContract(chainId, ContractType.DistributionCreator);
        vm.startBroadcast(privateKey);
        address distributionCreatorImpl = address(new DistributionCreator());
        vm.stopBroadcast();

        bytes memory payload = abi.encodeWithSelector(
            ITransparentUpgradeableProxy.upgradeTo.selector,
            distributionCreatorImpl
        );

        try this.chainToContract(chainId, ContractType.AngleLabsMultisig) returns (address safe) {
            _serializeJson(
                chainId,
                distributionCreator, // target address (the proxy)
                0, // value
                payload, // direct upgrade call
                Enum.Operation.Call, // standard call (not delegate)
                hex"", // signature
                safe // safe address
            );
        } catch {}
    }
}
