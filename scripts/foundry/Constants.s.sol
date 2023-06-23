pragma solidity ^0.8.19;

import { ITreasury } from "borrow/interfaces/ITreasury.sol";
import { MultiSend } from "safe/libraries/MultiSend.sol";
import { Safe, Enum } from "safe/Safe.sol";
import { ITransmuter } from "transmuter/interfaces/ITransmuter.sol";

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    CONSTANTS                                                    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

uint256 constant BASE_18 = 1e18;

uint256 constant CHAIN_ARBITRUM = 42161;
uint256 constant CHAIN_AVALANCHE = 43114;
uint256 constant CHAIN_ETHEREUM = 1;
uint256 constant CHAIN_OPTIMISM = 10;
uint256 constant CHAIN_POLYGON = 137;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    CONTRACTS                                                    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

ITransmuter constant transmuter = ITransmuter(address(0x0));
ITreasury constant treasuryArbitrum = ITreasury(0x0D710512E100C171139D2Cf5708f22C680eccF52);
ITreasury constant treasuryAvalanche = ITreasury(0xa014A485D64efb236423004AB1a99C0aaa97a549);
ITreasury constant treasuryEthereum = ITreasury(0x8667DBEBf68B0BFa6Db54f550f41Be16c4067d60);
ITreasury constant treasuryPolygon = ITreasury(0x2F2e0ba9746aae15888cf234c4EB5B301710927e);
ITreasury constant treasuryOptimism = ITreasury(0xe9f183FC656656f1F17af1F2b0dF79b8fF9ad8eD);

Safe constant governorArbitrumSafe = Safe(payable(0xAA2DaCCAb539649D1839772C625108674154df0B));
Safe constant guardianArbitrumSafe = Safe(payable(0x55F01DDaE74b60e3c255BD2f619FEbdFce560a9C));
Safe constant governorAvalancheSafe = Safe(payable(address(0x0)));
Safe constant guardianAvalancheSafe = Safe(payable(0xCcD44983f597aE4d4E2B70CF979597D63a10870D));
Safe constant governorEthereumSafe = Safe(payable(0xdC4e6DFe07EFCa50a197DF15D9200883eF4Eb1c8));
Safe constant guardianEthereumSafe = Safe(payable(0x0C2553e4B9dFA9f83b1A6D3EAB96c4bAaB42d430));
Safe constant governorOptimismSafe = Safe(payable(0x3245d3204EEB67afba7B0bA9143E8081365e08a6));
Safe constant guardianOptimismSafe = Safe(payable(0xD245678e417aEE2d91763F6f4eFE570FF52fD080));
Safe constant governorPolygonSafe = Safe(payable(0xdA2D2f638D6fcbE306236583845e5822554c02EA));
Safe constant guardianPolygonSafe = Safe(payable(0x3b9D32D0822A6351F415BeaB05251c1457FF6f8D));

MultiSend constant multiSendEthereum = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendArbitrum = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendOptimism = MultiSend(0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B);
MultiSend constant multiSendPolygon = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
