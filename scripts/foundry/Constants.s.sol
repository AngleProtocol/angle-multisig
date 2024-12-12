pragma solidity ^0.8.19;

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

uint64 constant twoPoint5Rate = 782997666703977344;
uint64 constant fourRate = 1243680713969297408;
uint64 constant fourPoint3Rate = 1335019428339023872;
uint64 constant thirtyTwoRate = 8803644702126689280;
uint64 constant thirtyFiveRate = 9516254229069432832;
uint64 constant fifteenRate = 4431822020478648320;
uint64 constant twentyFiveRate = 7075835695147247616;
uint64 constant twentyRate = 5781378709102113792;

string constant JSON_ADDRESSES_PATH = "lib/angle-tokens/scripts/addresses.json";

struct Transaction {
    bytes data;
    address to;
    uint256 value;
    uint256 chainId;
    uint256 operation;
}

struct SafeTransaction {
    bytes data;
    address to;
    uint256 value;
    uint256 chainId;
    uint256 operation;
    address safe;
}

struct MultiSendTransactions {
    SafeTransaction transaction;
    SafeTransaction[] internalTransactions;
}

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
MultiSend constant multiSendMode = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendBlast = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);
MultiSend constant multiSendXLayer = MultiSend(0x40A2aCCbd92BCA938b02010E17A5b8929b49130D);

// MultiSend constant multiSendStarknet = MultiSend();
// MultiSend constant multiSendNear = MultiSend();
// MultiSend constant multiSendSolana = MultiSend();

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                  EXTERNAL CONTRACTS                                                
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

address constant EUROC = 0x1aBaEA1f7C830bD89Acc67eC4af516284b1bC33c;
address constant BASE_EURC = 0x60a3E35Cc302bFA44Cb288Bc5a4F316Fdb1adb42;
address constant BC3M = 0x2F123cF3F37CE3328CC9B5b8415f9EC5109b45e7;
address constant XEVT = 0x3Ee320c9F73a84D1717557af00695A34b26d1F1d;
address constant USDM = 0x59D9356E565Ab3A36dD77763Fc0d87fEaf85508C;
address constant STEAK_USDC = 0xBEEF01735c132Ada46AA9aA4c54623cAA92A64CB;
address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
address constant MW_EURC = 0xf24608E0CCb972b0b0f4A6446a0BBf58c701a026;