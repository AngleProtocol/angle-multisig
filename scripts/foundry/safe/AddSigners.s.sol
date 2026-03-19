// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import "../Constants.s.sol";

interface ISafe {
    function addOwnerWithThreshold(address owner, uint256 _threshold) external;
    function getOwners() external view returns (address[] memory);
    function getThreshold() external view returns (uint256);
}

contract AddSigners is Utils {
    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                   CONFIGURATION
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    // New signers to add — modify this array
    address[] internal NEW_SIGNERS;

    // Target threshold after all signers are added
    uint256 constant TARGET_THRESHOLD = 4;

    function _setupSigners() internal {
        // TODO: Fill in the new signer addresses
        NEW_SIGNERS.push(address(0x72b7BDdfd2AB1BAb6fce0aa8c3ba38953c3A4cef));
        NEW_SIGNERS.push(address(0x6a75d4ddA3849F6755a0f83e5f9f29a4c9461EB3));
        NEW_SIGNERS.push(address(0x957947b78857811a7C7bF62A0c6cd23c87adc7cC));
    }

    struct ChainSafe {
        uint256 chainId;
        address safe;
        uint256 currentThreshold; // current threshold to preserve during intermediate adds
        bool hasMultiSend; // false = submit individual txs, no batching
    }

    function _setupChainSafes() internal pure returns (ChainSafe[] memory) {
        // 56 chains with confirmed Safe contracts
        // Excluded 12 chains where Safe was not found:
        //   108 (ThunderCore), 314 (Filecoin), 999 (Zeta), 1116 (Core),
        //   4326 (TAC), 5464 (Gensyn), 6900 (Katana), 9745 (MegaETH),
        //   10242 (Etherlink), 98866 (Stable), 1440000 (XRPL EVM), 2046399126 (SKALE Europa)
        ChainSafe[] memory cs = new ChainSafe[](56);
        uint256 i = 0;

        // --- Chains with MultiSend confirmed ---
        cs[i++] = ChainSafe(1, 0x529619a10129396a2F642cae32099C1eA7FA2834, 2, true);
        cs[i++] = ChainSafe(10, 0x17a7F6a839fea3b716b43f9414ffc93131878BD2, 2, true);
        cs[i++] = ChainSafe(30, 0x8b449bd5936B1A056D89eDe011075fa2906B2F94, 2, true);
        cs[i++] = ChainSafe(50, 0x496F1674d7E35440931A32548dB1064eef315257, 2, true);
        cs[i++] = ChainSafe(56, 0x2Dd2290EabdB5654609352Cc267C9BAc82d01877, 2, true);
        cs[i++] = ChainSafe(100, 0xf4b426A9849933c83041D6554cb39955ddA5c767, 2, true);
        cs[i++] = ChainSafe(122, 0x167f9bAF9B6C45370E7C5032557E6500cda37328, 2, true);
        cs[i++] = ChainSafe(130, 0xEa4d19e9c2A3FAf206cf7BB1A29B9AAE8E9FAA3d, 2, true);
        cs[i++] = ChainSafe(137, 0xc0c07644631543c3af2fA7230D387C5fA418a131, 2, true);
        cs[i++] = ChainSafe(146, 0x3B1CE275D2de4F82cE0d7487571EA047EC86dBF3, 2, true);
        cs[i++] = ChainSafe(169, 0x9A40Ed6Af46EdFccBAf26425E6c8E23590C4762B, 2, true);
        cs[i++] = ChainSafe(196, 0xAFebb5bA21a29a8C0Cf78e3CdE2552DFD4a6cc3E, 2, true);
        cs[i++] = ChainSafe(239, 0x4D5cd2a35e7B55397c912104671d61274653FddF, 2, true);
        cs[i++] = ChainSafe(252, 0xEa4d19e9c2A3FAf206cf7BB1A29B9AAE8E9FAA3d, 2, true);
        cs[i++] = ChainSafe(324, 0x3d3Fd37af3aEaBD0154230AdcfC9C177E13142c8, 2, true);
        cs[i++] = ChainSafe(480, 0xC760C15AeCB840084F2eb4906E3E5A8dbA667742, 2, true);
        cs[i++] = ChainSafe(592, 0x15416200C0846a58C0a494fEd93362853dC90907, 2, true);
        cs[i++] = ChainSafe(747, 0xA03Dc150972D555939E1c22860F56e9C19F33264, 3, true); // threshold 3
        cs[i++] = ChainSafe(1101, 0x9439B96E39dA5AD7EAA75d7a136383D1D9737055, 2, true);
        cs[i++] = ChainSafe(1135, 0x4D5cd2a35e7B55397c912104671d61274653FddF, 2, true);
        cs[i++] = ChainSafe(1284, 0x8b449bd5936B1A056D89eDe011075fa2906B2F94, 2, true);
        cs[i++] = ChainSafe(1329, 0x8b449bd5936B1A056D89eDe011075fa2906B2F94, 2, true);
        cs[i++] = ChainSafe(1868, 0xf30cfD00fA4c48B42ED41f4284a15aCec6755839, 2, true);
        cs[i++] = ChainSafe(1923, 0x83bbEF66a3E6732bF8d1AD55F016c02D876464eA, 2, true);
        cs[i++] = ChainSafe(2020, 0x8b449bd5936B1A056D89eDe011075fa2906B2F94, 2, true);
        cs[i++] = ChainSafe(4217, 0x4D5cd2a35e7B55397c912104671d61274653FddF, 2, true);
        cs[i++] = ChainSafe(5000, 0xe5cFa764F35eB0Ce24b4599EDd50882C1833d20F, 2, true);
        cs[i++] = ChainSafe(8453, 0x19c41F6607b2C0e80E84BaadaF886b17565F278e, 2, true);
        cs[i++] = ChainSafe(13371, 0xA82cc51D3d5723c0534C8A8476d740d0288099cb, 2, true);
        cs[i++] = ChainSafe(31612, 0x496F1674d7E35440931A32548dB1064eef315257, 2, true);
        cs[i++] = ChainSafe(33139, 0x4848C097AC3f84D06870438F9D17016AbDe90FB4, 2, true);
        cs[i++] = ChainSafe(34443, 0x222D18309000BDCB4261F746Af48C9Ea84B8c532, 2, true);
        cs[i++] = ChainSafe(42161, 0x3350bef226F7BdCA874C5561320aB7EF9DC89E70, 2, true);
        cs[i++] = ChainSafe(42220, 0xEa4d19e9c2A3FAf206cf7BB1A29B9AAE8E9FAA3d, 2, true);
        cs[i++] = ChainSafe(42793, 0x1D4Bb009e38411d8621caa51CFe774725fF0049c, 2, true);
        cs[i++] = ChainSafe(43111, 0xf30cfD00fA4c48B42ED41f4284a15aCec6755839, 2, true);
        cs[i++] = ChainSafe(43114, 0xC493c5Fec851768deEB8F5ecba213e204A7256b6, 2, true);
        cs[i++] = ChainSafe(48900, 0x496F1674d7E35440931A32548dB1064eef315257, 2, true);
        cs[i++] = ChainSafe(57073, 0x2c1D5ab89D636d8D6a3B9aA05D0A1ff7eAbd31A7, 2, true);
        cs[i++] = ChainSafe(59144, 0x65e043c894F15A899FD18d454BeeAd577e792B81, 2, true);
        cs[i++] = ChainSafe(60808, 0xEa4d19e9c2A3FAf206cf7BB1A29B9AAE8E9FAA3d, 2, true);
        cs[i++] = ChainSafe(80094, 0x97e7BD8342C171212FEfD2C236F0f10Be0736243, 3, true); // threshold 3
        cs[i++] = ChainSafe(81457, 0xb2846F05b58c8e29Aa971297A04aA947CF89cC46, 2, true);
        cs[i++] = ChainSafe(167000, 0xEa4d19e9c2A3FAf206cf7BB1A29B9AAE8E9FAA3d, 2, true);
        cs[i++] = ChainSafe(534352, 0x700714a7Dc596295aACC7b09D4b9BcE2c3A1Ec2C, 2, true);
        cs[i++] = ChainSafe(685689, 0x3F12CB2F811F61e3425C3DE180975F9ED683FD55, 2, true);
        cs[i++] = ChainSafe(747474, 0x496F1674d7E35440931A32548dB1064eef315257, 2, true);

        // --- Chains with Safe but NO standard MultiSend deployed ---
        // These will generate individual transactions (one per addOwnerWithThreshold call)
        cs[i++] = ChainSafe(143, 0xa493b938a3C6F5a4801861397D76AF4cD09a2d91, 2, false);
        cs[i++] = ChainSafe(151, 0x5445006E0117fd0fA2f795Cc1b99557Edfc17d8D, 2, false);
        cs[i++] = ChainSafe(250, 0x8b449bd5936B1A056D89eDe011075fa2906B2F94, 2, false);
        cs[i++] = ChainSafe(714, 0xb9d5A0e3aD4892A8c1672a3365c27cf63F19d086, 2, false);
        cs[i++] = ChainSafe(988, 0x4Fa58741a0cc2b166D589Ad6B0825Bf04c3dC7B0, 2, false);
        cs[i++] = ChainSafe(4114, 0x4D5cd2a35e7B55397c912104671d61274653FddF, 2, false);
        cs[i++] = ChainSafe(16661, 0xa493b938a3C6F5a4801861397D76AF4cD09a2d91, 2, false);
        cs[i++] = ChainSafe(5064014, 0x4D5cd2a35e7B55397c912104671d61274653FddF, 2, false);
        cs[i++] = ChainSafe(21000000, 0x5375C79ffB31981b92defAF334AA382704E24fFf, 2, false);

        assembly ("memory-safe") {
            mstore(cs, i)
        }
        return cs;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                   MULTISEND ADDRESSES
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    // Standard Safe MultiSend v1.3.0
    address constant MULTISEND_DEFAULT = 0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761;
    // Safe MultiSend v1.4.1 variant A
    address constant MULTISEND_V141_A = 0x40A2aCCbd92BCA938b02010E17A5b8929b49130D;
    // Safe MultiSend v1.4.1 variant B (OP stack chains, Celo, Mantle, ApeChain)
    address constant MULTISEND_V141_B = 0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B;

    function _getMultiSend(uint256 chainId) internal pure returns (address) {
        if (
            chainId == 1 ||
            chainId == 42161 ||
            chainId == 137 ||
            chainId == 43114 ||
            chainId == 100 ||
            chainId == 56 ||
            chainId == 1101 ||
            chainId == 59144 ||
            chainId == 34443 ||
            chainId == 81457 ||
            chainId == 196 ||
            chainId == 534352
        ) return MULTISEND_V141_A;

        if (
            chainId == 10 || chainId == 8453 || chainId == 42220 || chainId == 5000 || chainId == 33139 // ApeChain
        ) return MULTISEND_V141_B;

        return MULTISEND_DEFAULT;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                       SCRIPT
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    function run() external {
        _setupSigners();
        require(NEW_SIGNERS.length > 0, "No new signers configured");

        ChainSafe[] memory chainSafes = _setupChainSafes();
        _buildAndSerialize(chainSafes);
    }

    function _buildMultiSendPayload(address safe, uint256 currentThreshold) internal view returns (bytes memory) {
        bytes memory packed;
        for (uint256 s = 0; s < NEW_SIGNERS.length; s++) {
            uint256 newThreshold = (s == NEW_SIGNERS.length - 1) ? TARGET_THRESHOLD : currentThreshold;
            bytes memory data = abi.encodeWithSelector(
                ISafe.addOwnerWithThreshold.selector,
                NEW_SIGNERS[s],
                newThreshold
            );
            packed = abi.encodePacked(
                packed,
                uint8(0), // Enum.Operation.Call
                safe,
                uint256(0),
                data.length,
                data
            );
        }
        return abi.encodeWithSelector(MultiSend.multiSend.selector, packed);
    }

    function _serializeTransactionFields(ChainSafe[] memory chainSafes) internal returns (string memory) {
        string memory txJson = "chain";

        string memory targetsOutput;
        string memory valuesOutput;
        string memory datasOutput;

        uint256 txCount = 0;
        for (uint256 c = 0; c < chainSafes.length; c++) {
            if (chainSafes[c].hasMultiSend) {
                // One batched MultiSend transaction per chain
                string memory idx = vm.toString(txCount);
                address multiSend = _getMultiSend(chainSafes[c].chainId);
                bytes memory payload = _buildMultiSendPayload(chainSafes[c].safe, chainSafes[c].currentThreshold);

                targetsOutput = vm.serializeAddress("to", idx, multiSend);
                valuesOutput = vm.serializeUint("value", idx, 0);
                datasOutput = vm.serializeBytes("data", idx, payload);
                txCount++;
            } else {
                // Individual transactions for chains without MultiSend
                for (uint256 s = 0; s < NEW_SIGNERS.length; s++) {
                    string memory idx = vm.toString(txCount);
                    uint256 newThreshold = (s == NEW_SIGNERS.length - 1)
                        ? TARGET_THRESHOLD
                        : chainSafes[c].currentThreshold;
                    bytes memory data = abi.encodeWithSelector(
                        ISafe.addOwnerWithThreshold.selector,
                        NEW_SIGNERS[s],
                        newThreshold
                    );

                    targetsOutput = vm.serializeAddress("to", idx, chainSafes[c].safe);
                    valuesOutput = vm.serializeUint("value", idx, 0);
                    datasOutput = vm.serializeBytes("data", idx, data);
                    txCount++;
                }
            }
        }

        vm.serializeString(txJson, "to", targetsOutput);
        vm.serializeString(txJson, "value", valuesOutput);
        vm.serializeString(txJson, "data", datasOutput);

        return _serializeTransactionMeta(chainSafes, txJson, txCount);
    }

    function _serializeTransactionMeta(
        ChainSafe[] memory chainSafes,
        string memory txJson,
        uint256 txCount
    ) internal returns (string memory) {
        string memory chainIdsOutput;
        string memory operationsOutput;
        string memory safesOutput;

        uint256 idx = 0;
        for (uint256 c = 0; c < chainSafes.length; c++) {
            if (chainSafes[c].hasMultiSend) {
                string memory key = vm.toString(idx);
                chainIdsOutput = vm.serializeUint("chainId", key, chainSafes[c].chainId);
                operationsOutput = vm.serializeUint("operation", key, 1); // DelegateCall
                safesOutput = vm.serializeAddress("safe", key, chainSafes[c].safe);
                idx++;
            } else {
                for (uint256 s = 0; s < NEW_SIGNERS.length; s++) {
                    string memory key = vm.toString(idx);
                    chainIdsOutput = vm.serializeUint("chainId", key, chainSafes[c].chainId);
                    operationsOutput = vm.serializeUint("operation", key, 0); // Call (direct)
                    safesOutput = vm.serializeAddress("safe", key, chainSafes[c].safe);
                    idx++;
                }
            }
        }

        vm.serializeString(txJson, "chainId", chainIdsOutput);
        vm.serializeString(txJson, "operation", operationsOutput);
        return vm.serializeString(txJson, "safe", safesOutput);
    }

    function _serializeInternalTx(uint256 c, ChainSafe memory cs) internal returns (string memory) {
        string memory jsonChain = string.concat("chain.", vm.toString(c));

        vm.serializeUint(jsonChain, "chainId", cs.chainId);
        vm.serializeAddress(jsonChain, "safe", cs.safe);

        string memory subTargets;
        string memory subValues;
        string memory subDatas;
        string memory subOps;

        for (uint256 s = 0; s < NEW_SIGNERS.length; s++) {
            string memory idx = vm.toString(s);
            uint256 newThreshold = (s == NEW_SIGNERS.length - 1) ? TARGET_THRESHOLD : cs.currentThreshold;
            bytes memory data = abi.encodeWithSelector(
                ISafe.addOwnerWithThreshold.selector,
                NEW_SIGNERS[s],
                newThreshold
            );

            subTargets = vm.serializeAddress(string.concat("to.", vm.toString(c)), idx, cs.safe);
            subValues = vm.serializeUint(string.concat("value.", vm.toString(c)), idx, 0);
            subDatas = vm.serializeBytes(string.concat("data.", vm.toString(c)), idx, data);
            subOps = vm.serializeUint(string.concat("op.", vm.toString(c)), idx, 0);
        }

        vm.serializeString(jsonChain, "to", subTargets);
        vm.serializeString(jsonChain, "value", subValues);
        vm.serializeString(jsonChain, "data", subDatas);
        return vm.serializeString(jsonChain, "operation", subOps);
    }

    function _buildAndSerialize(ChainSafe[] memory chainSafes) internal {
        string memory output = _serializeTransactionFields(chainSafes);

        string memory internalTxJson = "internal";
        string memory internalOutput;
        for (uint256 c = 0; c < chainSafes.length; c++) {
            internalOutput = vm.serializeString(internalTxJson, vm.toString(c), _serializeInternalTx(c, chainSafes[c]));
            console.log(
                "Prepared chain %d, safe %s%s",
                chainSafes[c].chainId,
                chainSafes[c].safe,
                chainSafes[c].hasMultiSend ? "" : " [NO MULTISEND - individual txs]"
            );
        }

        string memory json = "";
        vm.serializeString(json, "internalTransactions", internalOutput);
        string memory finalJson = vm.serializeString(json, "transaction", output);
        vm.writeJson(finalJson, "./scripts/foundry/transactions.json");

        console.log("Wrote transactions.json for %d chains", chainSafes.length);
    }
}
