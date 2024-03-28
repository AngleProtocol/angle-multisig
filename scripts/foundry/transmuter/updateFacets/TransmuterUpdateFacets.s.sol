// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import { console } from "forge-std/console.sol";
import { stdJson } from "forge-std/StdJson.sol";
import { TransmuterUtils } from "./TransmuterUtils.s.sol";
import "../../Constants.s.sol";

import { IERC20 } from "oz/token/ERC20/IERC20.sol";
import "transmuter/transmuter/Storage.sol" as Storage;
import { DiamondCut } from "transmuter/transmuter/facets/DiamondCut.sol";
import { DiamondEtherscan } from "transmuter/transmuter/facets/DiamondEtherscan.sol";
import { DiamondLoupe } from "transmuter/transmuter/facets/DiamondLoupe.sol";
import { DiamondProxy } from "transmuter/transmuter/DiamondProxy.sol";
import { Getters } from "transmuter/transmuter/facets/Getters.sol";
import { Redeemer } from "transmuter/transmuter/facets/Redeemer.sol";
import { RewardHandler } from "transmuter/transmuter/facets/RewardHandler.sol";
import { SettersGovernor } from "transmuter/transmuter/facets/SettersGovernor.sol";
import { SettersGuardian } from "transmuter/transmuter/facets/SettersGuardian.sol";
import { Swapper } from "transmuter/transmuter/facets/Swapper.sol";
import { AggregatorV3Interface } from "transmuter/interfaces/external/chainlink/AggregatorV3Interface.sol";
import { ITransmuter, IDiamondCut, ISettersGovernor, ISettersGuardian } from "transmuter/interfaces/ITransmuter.sol";
import { BASE_8, MAX_MINT_FEE, MAX_BURN_FEE } from "transmuter/utils/Constants.sol";

interface OldTransmuter {
    function getOracle(
        address
    ) external view returns (Storage.OracleReadType, Storage.OracleReadType, bytes memory, bytes memory);
}

contract TransmuterUpdateFacets is TransmuterUtils {
    using stdJson for string;

    string[] replaceFacetNames;
    string[] addFacetNames;
    address[] replaceFacetAddressList;
    address[] addFacetAddressList;
    bytes oracleConfigBERNX;

    ITransmuter transmuter;
    IERC20 agEUR;
    address governor;

    function run() external {
        bytes memory transactions;
        uint8 isDelegateCall = 0;
        uint256 value = 0;
        address to;

        uint256 chainId = vm.envUint("CHAIN_ID");

        uint256 executionChainId = chainId;
        chainId = chainId != 0 ? chainId : CHAIN_SOURCE;

        vm.selectFork(forkIdentifier[executionChainId]);

        transmuter = ITransmuter(_chainToContract(chainId, ContractType.TransmuterAgEUR));

        Storage.FacetCut[] memory replaceCut;
        Storage.FacetCut[] memory addCut;

        replaceFacetNames.push("Getters");
        replaceFacetAddressList.push(GETTERS);

        replaceFacetNames.push("Redeemer");
        replaceFacetAddressList.push(REDEEMER);

        replaceFacetNames.push("SettersGovernor");
        replaceFacetAddressList.push(SETTERS_GOVERNOR);

        replaceFacetNames.push("Swapper");
        replaceFacetAddressList.push(SWAPPER);

        addFacetNames.push("SettersGovernor");
        addFacetAddressList.push(SETTERS_GOVERNOR);

        {
            string memory jsonReplace = vm.readFile(JSON_SELECTOR_PATH_REPLACE);
            // Build appropriate payload
            uint256 n = replaceFacetNames.length;
            replaceCut = new Storage.FacetCut[](n);
            for (uint256 i = 0; i < n; ++i) {
                // Get Selectors from json
                bytes4[] memory selectors = _arrayBytes32ToBytes4(
                    jsonReplace.readBytes32Array(string.concat("$.", replaceFacetNames[i]))
                );

                replaceCut[i] = Storage.FacetCut({
                    facetAddress: replaceFacetAddressList[i],
                    action: Storage.FacetCutAction.Replace,
                    functionSelectors: selectors
                });
            }
        }

        {
            string memory jsonAdd = vm.readFile(JSON_SELECTOR_PATH_ADD);
            // Build appropriate payload
            uint256 n = addFacetNames.length;
            addCut = new Storage.FacetCut[](n);
            for (uint256 i = 0; i < n; ++i) {
                // Get Selectors from json
                bytes4[] memory selectors = _arrayBytes32ToBytes4(
                    jsonAdd.readBytes32Array(string.concat("$.", addFacetNames[i]))
                );
                addCut[i] = Storage.FacetCut({
                    facetAddress: addFacetAddressList[i],
                    action: Storage.FacetCutAction.Add,
                    functionSelectors: selectors
                });
            }
        }

        bytes memory callData;
        to = address(transmuter);
        {
            bytes memory data = abi.encodeWithSelector(
                IDiamondCut.diamondCut.selector,
                replaceCut,
                address(0),
                callData
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }
        {
            bytes memory data = abi.encodeWithSelector(IDiamondCut.diamondCut.selector, addCut, address(0), callData);
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // update the oracles

        // EURC
        {
            // Get the previous oracles configs
            (
                Storage.OracleReadType oracleTypeEUROC,
                Storage.OracleReadType targetTypeEUROC,
                bytes memory oracleDataEUROC,
                bytes memory targetDataEUROC
            ) = OldTransmuter(address(transmuter)).getOracle(address(EUROC));

            bytes memory data = abi.encodeWithSelector(
                ISettersGovernor.setOracle.selector,
                EUROC,
                abi.encode(
                    oracleTypeEUROC,
                    targetTypeEUROC,
                    oracleDataEUROC,
                    targetDataEUROC,
                    abi.encode(USER_PROTECTION_EUROC, FIREWALL_BURN_RATIO_EUROC)
                )
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // BC3M
        {
            // Get the previous oracles configs
            (Storage.OracleReadType oracleTypeBC3M, , bytes memory oracleDataBC3M, ) = OldTransmuter(
                address(transmuter)
            ).getOracle(address(BC3M));
            (, , , , uint256 currentBC3MPrice) = transmuter.getOracleValues(address(BC3M));
            bytes memory data = abi.encodeWithSelector(
                ISettersGovernor.setOracle.selector,
                BC3M,
                abi.encode(
                    oracleTypeBC3M,
                    Storage.OracleReadType.MAX,
                    oracleDataBC3M,
                    // We can hope that the oracleDataBC3M won't move much before the proposal is executed
                    abi.encode(currentBC3MPrice),
                    abi.encode(USER_PROTECTION_BC3M, FIREWALL_BURN_RATIO_BC3M)
                )
            );
            uint256 dataLength = data.length;
            bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
            transactions = abi.encodePacked(transactions, internalTx);
        }

        // Set the new collateral: bERNX
        {
            uint64[] memory xMintFeeERNX = new uint64[](3);
            xMintFeeERNX[0] = uint64(0);
            xMintFeeERNX[1] = uint64((49 * BASE_9) / 100);
            xMintFeeERNX[2] = uint64((50 * BASE_9) / 100);

            int64[] memory yMintFeeERNX = new int64[](3);
            yMintFeeERNX[0] = int64(0);
            yMintFeeERNX[1] = int64(0);
            yMintFeeERNX[2] = int64(uint64(MAX_MINT_FEE));

            uint64[] memory xBurnFeeERNX = new uint64[](3);
            xBurnFeeERNX[0] = uint64(BASE_9);
            xBurnFeeERNX[1] = uint64((26 * BASE_9) / 100);
            xBurnFeeERNX[2] = uint64((25 * BASE_9) / 100);

            int64[] memory yBurnFeeERNX = new int64[](3);
            yBurnFeeERNX[0] = int64(uint64((50 * BASE_9) / 10000));
            yBurnFeeERNX[1] = int64(uint64((50 * BASE_9) / 10000));
            yBurnFeeERNX[2] = int64(uint64(MAX_BURN_FEE));

            {
                bytes memory readData;
                {
                    AggregatorV3Interface[] memory circuitChainlink = new AggregatorV3Interface[](1);
                    uint32[] memory stalePeriods = new uint32[](1);
                    uint8[] memory circuitChainIsMultiplied = new uint8[](1);
                    uint8[] memory chainlinkDecimals = new uint8[](1);

                    // Chainlink ERNX/EUR oracle
                    circuitChainlink[0] = AggregatorV3Interface(0x475855DAe09af1e3f2d380d766b9E630926ad3CE);
                    stalePeriods[0] = 3 days;
                    circuitChainIsMultiplied[0] = 1;
                    chainlinkDecimals[0] = 8;
                    Storage.OracleQuoteType quoteType = Storage.OracleQuoteType.UNIT;
                    readData = abi.encode(
                        circuitChainlink,
                        stalePeriods,
                        circuitChainIsMultiplied,
                        chainlinkDecimals,
                        quoteType
                    );
                }

                bytes memory targetData;
                {
                    (, int256 ratio, , uint256 updatedAt, ) = AggregatorV3Interface(
                        0x475855DAe09af1e3f2d380d766b9E630926ad3CE
                    ).latestRoundData();
                    targetData = abi.encode((uint256(ratio) * BASE_18) / BASE_8);
                }

                oracleConfigBERNX = abi.encode(
                    Storage.OracleReadType.CHAINLINK_FEEDS,
                    Storage.OracleReadType.MAX,
                    readData,
                    targetData,
                    abi.encode(USER_PROTECTION_BERNX, FIREWALL_BURN_RATIO_BERNX)
                );
            }
            {
                bytes memory data = abi.encodeWithSelector(ISettersGovernor.addCollateral.selector, BERNX);
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGovernor.setOracle.selector,
                    BERNX,
                    oracleConfigBERNX
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                // Mint fees
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.setFees.selector,
                    BERNX,
                    xMintFeeERNX,
                    yMintFeeERNX,
                    true
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                // Burn fees
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.setFees.selector,
                    BERNX,
                    xBurnFeeERNX,
                    yBurnFeeERNX,
                    false
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.togglePause.selector,
                    BERNX,
                    Storage.ActionType.Mint
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.togglePause.selector,
                    BERNX,
                    Storage.ActionType.Burn
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                bytes memory data;
                {
                    // Set whitelist status for bC3M
                    bytes memory whitelistData = abi.encode(
                        Storage.WhitelistType.BACKED,
                        // Keyring whitelist check
                        abi.encode(address(0x9391B14dB2d43687Ea1f6E546390ED4b20766c46))
                    );

                    data = abi.encodeWithSelector(
                        ISettersGovernor.setWhitelistStatus.selector,
                        BERNX,
                        1,
                        whitelistData
                    );
                }
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        // Set target exposures for EUROC
        {
            uint64[] memory xMintFeeEUROC = new uint64[](3);
            xMintFeeEUROC[0] = uint64(0);
            xMintFeeEUROC[1] = uint64((69 * BASE_9) / 100);
            xMintFeeEUROC[2] = uint64((70 * BASE_9) / 100);

            int64[] memory yMintFeeEUROC = new int64[](3);
            yMintFeeEUROC[0] = int64(0);
            yMintFeeEUROC[1] = int64(0);
            yMintFeeEUROC[2] = int64(uint64(MAX_MINT_FEE));

            uint64[] memory xBurnFeeEUROC = new uint64[](3);
            xBurnFeeEUROC[0] = uint64(BASE_9);
            xBurnFeeEUROC[1] = uint64((11 * BASE_9) / 100);
            xBurnFeeEUROC[2] = uint64((10 * BASE_9) / 100);

            int64[] memory yBurnFeeEUROC = new int64[](3);
            yBurnFeeEUROC[0] = int64(0);
            yBurnFeeEUROC[1] = int64(0);
            yBurnFeeEUROC[2] = int64(uint64(MAX_BURN_FEE));
            {
                // Mint fees
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.setFees.selector,
                    EUROC,
                    xMintFeeEUROC,
                    yMintFeeEUROC,
                    true
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                // Burn fees
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.setFees.selector,
                    EUROC,
                    xBurnFeeEUROC,
                    yBurnFeeEUROC,
                    false
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        // Set target exposures for bC3M
        {
            uint64[] memory xMintFeeC3M = new uint64[](3);
            xMintFeeC3M[0] = uint64(0);
            xMintFeeC3M[1] = uint64((49 * BASE_9) / 100);
            xMintFeeC3M[2] = uint64((50 * BASE_9) / 100);

            int64[] memory yMintFeeC3M = new int64[](3);
            yMintFeeC3M[0] = int64(0);
            yMintFeeC3M[1] = int64(0);
            yMintFeeC3M[2] = int64(uint64(MAX_MINT_FEE));

            uint64[] memory xBurnFeeC3M = new uint64[](3);
            xBurnFeeC3M[0] = uint64(BASE_9);
            xBurnFeeC3M[1] = uint64((26 * BASE_9) / 100);
            xBurnFeeC3M[2] = uint64((25 * BASE_9) / 100);

            int64[] memory yBurnFeeC3M = new int64[](3);
            yBurnFeeC3M[0] = int64(uint64((50 * BASE_9) / 10000));
            yBurnFeeC3M[1] = int64(uint64((50 * BASE_9) / 10000));
            yBurnFeeC3M[2] = int64(uint64(MAX_BURN_FEE));
            {
                // Mint fees
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.setFees.selector,
                    BC3M,
                    xMintFeeC3M,
                    yMintFeeC3M,
                    true
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
            {
                // Burn fees
                bytes memory data = abi.encodeWithSelector(
                    ISettersGuardian.setFees.selector,
                    BC3M,
                    xBurnFeeC3M,
                    yBurnFeeC3M,
                    false
                );
                uint256 dataLength = data.length;
                bytes memory internalTx = abi.encodePacked(isDelegateCall, to, value, dataLength, data);
                transactions = abi.encodePacked(transactions, internalTx);
            }
        }

        bytes memory payloadMultiSend = abi.encodeWithSelector(MultiSend.multiSend.selector, transactions);
        address multiSend = address(_chainToMultiSend(chainId));
        _serializeJson(chainId, multiSend, 0, payloadMultiSend, Enum.Operation.DelegateCall, hex"");
    }
}
