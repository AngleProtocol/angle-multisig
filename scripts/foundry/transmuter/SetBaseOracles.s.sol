// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import { console } from "forge-std/console.sol";
import { IVaultManagerFunctions } from "borrow/interfaces/IVaultManager.sol";
import { IERC721Metadata } from "oz/token/ERC721/extensions/IERC721Metadata.sol";
import { Enum } from "safe/Safe.sol";
import { MultiSend, Utils } from "../Utils.s.sol";
import { BaseHarvester, YieldBearingParams } from "transmuter/helpers/BaseHarvester.sol";
import { ISettersGuardian, ISettersGovernor } from "transmuter/interfaces/ITransmuter.sol";
import { TrustedType } from "transmuter/transmuter/Storage.sol";
import { MultiBlockHarvester } from "transmuter/helpers/MultiBlockHarvester.sol";
import "../Constants.s.sol";

contract SetBaseOracles is Utils {
    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;

        uint256 chainId = vm.envUint("CHAIN_ID");

        /** TODO  complete */
        address harvester = 0x9b4C3f0EB7e732A64C549eC989d62Ec82b00D37B;
        /** END  complete */

        // Add to seller harvester
        {
            address transmuter = _chainToContract(chainId, ContractType.TransmuterAgEUR);
            bytes memory data = abi.encodeWithSelector(ISettersGovernor.toggleTrusted.selector, harvester, TrustedType.Seller);
            address to = transmuter;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // Set EURC oracle
        {
            bytes memory readData;
            {
                bytes32[] memory feedIds = new bytes32[](2);
                uint32[] memory stalePeriods = new uint32[](2);
                uint8[] memory isMultiplied = new uint8[](2);
                // pyth address
                address pyth = 0x8250f4aF4B972684F7b336503E2D6dFeDeB1487a;
                // EUROC/USD
                feedIds[0] = 0x76fa85158bf14ede77087fe3ae472f66213f6ea2f5b411cb2de472794990fa5c;
                // USD/EUR
                feedIds[1] = 0xa995d00bb36a63cef7fd2c287dc105fc8f3d93779f062f09551b0af3e81ec30b;
                stalePeriods[0] = 14 days;
                stalePeriods[1] = 14 days;
                isMultiplied[0] = 1;
                isMultiplied[1] = 0;
                OracleQuoteType quoteType = OracleQuoteType.UNIT;
                readData = abi.encode(pyth, feedIds, stalePeriods, isMultiplied, quoteType);
            }
            bytes memory targetData;
            bytes memory oracleConfigCollatToAdd = abi.encode(
                Storage.OracleReadType.PYTH,
                Storage.OracleReadType.STABLE,
                readData,
                targetData,
                abi.encode(uint128(0), uint128(0))
            );
            address transmuter = _chainToContract(chainId, ContractType.TransmuterAgEUR);
            bytes memory data = abi.encodeWithSelector(ISettersGovernor.setOracle.selector, EURC, oracleConfigCollatToAdd);
            address to = transmuter;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // Set MW_EURC oracle
        {
            address transmuter = _chainToContract(chainId, ContractType.TransmuterAgEUR);
            address oracle = 0x312175C3d1f38232946218aA4e68627cD79D631d;
            uint256 normalizationFactor = 1e18;
            bytes memory targetData = abi.encode(1002110880340852975); // 1002345422600947750
            bytes memory readData = abi.encode(oracle, normalizationFactor);
            bytes memory oracleConfigCollatToAdd = abi.encode(
                Storage.OracleReadType.MORPHO_ORACLE,
                Storage.OracleReadType.MAX,
                readData,
                targetData,
                abi.encode(uint128(0), uint128(0.0005e18))
            );
            bytes memory data = abi.encodeWithSelector(ISettersGovernor.setOracle.selector, MW_EURC, oracleConfigCollatToAdd);
            address to = transmuter;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, data.length, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(
            chainId,
            multiSend,
            uint256(0),
            payloadMultiSend,
            Enum.Operation.DelegateCall,
            hex"",
            _chainToContract(chainId, ContractType.GovernorMultisig)
        );
    }
}
