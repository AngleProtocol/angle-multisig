pragma solidity ^0.8.19;

import { ITreasury } from "borrow/interfaces/ITreasury.sol";
import { MultiSend } from "safe/libraries/MultiSend.sol";
import { Safe, Enum } from "safe/Safe.sol";
import { ITransmuter } from "transmuter/interfaces/ITransmuter.sol";
import { IAgToken } from "borrow/interfaces/IAgToken.sol";
import { ProxyAdmin } from "oz/proxy/transparent/ProxyAdmin.sol";
import { Ownable } from "oz/access/Ownable.sol";
import { CoreBorrow } from "borrow/coreBorrow/CoreBorrow.sol";
import "utils/src/Constants.sol";
import "./Interfaces.s.sol";

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    CONSTANTS                                                    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

uint256 constant CHAIN_SOURCE = CHAIN_ETHEREUM;
uint256 constant CHAIN_FORK = 0;

uint64 constant twoPoint5Rate = 782997666703977344;
uint64 constant fourRate = 1243680713969297408;
uint64 constant fourPoint3Rate = 1335019428339023872;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    CONTRACTS                                                    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

MultiSend constant multiSendEthereum = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendArbitrum = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendOptimism = MultiSend(0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B);
MultiSend constant multiSendPolygon = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendAvalanche = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendGnosis = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendBNB = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendCelo = MultiSend(0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B);
MultiSend constant multiSendBase = MultiSend(0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B);
MultiSend constant multiSendPolygonZkEVM = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendLinea = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendMantle = MultiSend(0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B);
// MultiSend constant multiSendStarknet = MultiSend();
// MultiSend constant multiSendNear = MultiSend();
// MultiSend constant multiSendSolana = MultiSend();

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                  EXTERNAL CONTRACTS                                                
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

address constant EUROC = 0x1aBaEA1f7C830bD89Acc67eC4af516284b1bC33c;
address constant BC3M = 0x2F123cF3F37CE3328CC9B5b8415f9EC5109b45e7;
