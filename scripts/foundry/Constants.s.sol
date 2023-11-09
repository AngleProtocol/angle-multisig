pragma solidity ^0.8.19;

import { ITreasury } from "borrow/interfaces/ITreasury.sol";
import { MultiSend } from "safe/libraries/MultiSend.sol";
import { Safe, Enum } from "safe/Safe.sol";
import { ITransmuter } from "transmuter/interfaces/ITransmuter.sol";
import { IAgToken } from "borrow/interfaces/IAgToken.sol";

interface IVaultManagerGovernance {
    function setUint64(uint64 param, bytes32 what) external;

    function interestRate() external view returns (uint64);

    function setDebtCeiling(uint256) external;
}

interface ISavings {
    function setRate(uint208 newRate) external;

    function rate() external view returns (uint208);
}

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    CONSTANTS                                                    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

uint256 constant BASE_18 = 1e18;
uint256 constant BASE_9 = 1e9;

uint256 constant CHAIN_ARBITRUM = 42161;
uint256 constant CHAIN_AVALANCHE = 43114;
uint256 constant CHAIN_ETHEREUM = 1;
uint256 constant CHAIN_OPTIMISM = 10;
uint256 constant CHAIN_POLYGON = 137;

uint64 constant twoPoint5Rate = 782997666703977344;
uint64 constant fourRate = 1243680713969297408;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    CONTRACTS                                                    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

ITreasury constant treasuryArbitrum = ITreasury(0x0D710512E100C171139D2Cf5708f22C680eccF52);
ITreasury constant treasuryAvalanche = ITreasury(0xa014A485D64efb236423004AB1a99C0aaa97a549);
ITreasury constant treasuryEthereum = ITreasury(0x8667DBEBf68B0BFa6Db54f550f41Be16c4067d60);
ITreasury constant treasuryPolygon = ITreasury(0x2F2e0ba9746aae15888cf234c4EB5B301710927e);
ITreasury constant treasuryOptimism = ITreasury(0xe9f183FC656656f1F17af1F2b0dF79b8fF9ad8eD);

Safe constant governorArbitrum = Safe(payable(0xAA2DaCCAb539649D1839772C625108674154df0B));
Safe constant guardianArbitrum = Safe(payable(0x55F01DDaE74b60e3c255BD2f619FEbdFce560a9C));
Safe constant governorAvalanche = Safe(payable(0x43a7947A1288e65fAF30D8dDb3ca61Eaabd41613));
Safe constant guardianAvalanche = Safe(payable(0xCcD44983f597aE4d4E2B70CF979597D63a10870D));
Safe constant governorEthereum = Safe(payable(0xdC4e6DFe07EFCa50a197DF15D9200883eF4Eb1c8));
Safe constant guardianEthereum = Safe(payable(0x0C2553e4B9dFA9f83b1A6D3EAB96c4bAaB42d430));
Safe constant governorOptimism = Safe(payable(0x3245d3204EEB67afba7B0bA9143E8081365e08a6));
Safe constant guardianOptimism = Safe(payable(0xD245678e417aEE2d91763F6f4eFE570FF52fD080));
Safe constant governorPolygon = Safe(payable(0xdA2D2f638D6fcbE306236583845e5822554c02EA));
Safe constant guardianPolygon = Safe(payable(0x3b9D32D0822A6351F415BeaB05251c1457FF6f8D));

MultiSend constant multiSendEthereum = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendArbitrum = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendOptimism = MultiSend(0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B);
MultiSend constant multiSendPolygon = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendAvalanche = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);

IAgToken constant agEUREthereum = IAgToken(0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8);
IAgToken constant agEURArbitrum = IAgToken(0xFA5Ed56A203466CbBC2430a43c66b9D8723528E7);
IAgToken constant agEUROptimism = IAgToken(0x9485aca5bbBE1667AD97c7fE7C4531a624C8b1ED);
IAgToken constant agEURPolygon = IAgToken(0xE0B52e49357Fd4DAf2c15e02058DCE6BC0057db4);
IAgToken constant agEURAvalanche = IAgToken(0xAEC8318a9a59bAEb39861d10ff6C7f7bf1F96C57);

ITransmuter constant transmuter = ITransmuter(0x00253582b2a3FE112feEC532221d9708c64cEFAb);

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                 CROSS-CHAIN CONSTANTS                                              
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

address constant stEUR = 0x004626A008B1aCdC4c74ab51644093b155e59A23;
address constant distributionCreator = 0x8BB4C975Ff3c250e0ceEA271728547f3802B36Fd;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                  EXTERNAL CONTRACTS                                                
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

address constant EUROC = 0x1aBaEA1f7C830bD89Acc67eC4af516284b1bC33c;
address constant BC3M = 0x2F123cF3F37CE3328CC9B5b8415f9EC5109b45e7;
