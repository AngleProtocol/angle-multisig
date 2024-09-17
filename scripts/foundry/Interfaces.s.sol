pragma solidity ^0.8.19;

import { ITreasury as IBorrowTreasury } from "borrow/interfaces/ITreasury.sol";

interface IVaultManagerGovernance {
    function setUint64(uint64 param, bytes32 what) external;

    function interestRate() external view returns (uint64);
}

interface ISavings {
    function setRate(uint208 newRate) external;

    function rate() external view returns (uint208);

    function maxRate() external view returns (uint256);

    function setMaxRate(uint256 newRate) external;

    function toggleTrusted(address keeper) external;

    function isTrustedUpdater(address keeper) external view returns (bool);
}

interface ITreasury is IBorrowTreasury {
    function addMinter(address minter) external;
}

interface INameable {
    function setNameAndSymbol(string memory name, string memory symbol) external;
}

interface IAngle {
    function setMinter(address minter) external;
}

interface IVeAngle {
    function commit_transfer_ownership(address newAdmin) external;

    function apply_transfer_ownership() external;

    function set_emergency_withdrawal() external;

    function admin() external view returns (address);

    function emergency_withdrawal() external view returns (bool);
}

interface IGaugeController {
    function commit_transfer_ownership(address newAdmin) external;

    function apply_transfer_ownership() external;
}

interface ILiquidityGauge {
    function commit_transfer_ownership(address newAdmin) external;

    function apply_transfer_ownership() external;
}

interface IVeBoost {
    function commit_transfer_ownership(address newAdmin) external;

    function apply_transfer_ownership() external;
}

interface IVeBoostProxy {
    function commit_admin(address newAdmin) external;

    function apply_transfer_ownership() external;
}

interface ISmartWalletWhitelist {
    function commitAdmin(address newAdmin) external;

    function applyAdmin() external;
}

interface IFeeDistributor {
    function commit_admin(address newAdmin) external;

    function accept_admin() external;
}
