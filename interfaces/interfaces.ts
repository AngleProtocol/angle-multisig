import { utils } from "ethers";

export const StableMasterInterface = new utils.Interface([
    'function deployCollateral(address poolManager, address perpetualManager, address feeManager, address oracle, address sanToken) external',
    'function revokeCollateral(address poolManager, address settlementContract) external',
    'function pause(bytes32 agent, address poolManager) external',
    'function unpause(bytes32 agent, address poolManager) external',
    'function rebalanceStocksUsers(uint256 amount, address poolManagerUp, address poolManagerDown) external',
    'function setOracle(address _oracle, address poolManager) external',
    'function setCapOnStableAndMaxInterests(uint256 _capOnStableMinted, uint256 _maxInterestsDistributed, address poolManager) external',
    'function setFeeManager(address newFeeManager, address oldFeeManager, address poolManager) external',
    'function setIncentivesForSLPs( uint64 _feesForSLPs, uint64 _interestsForSLPs, address poolManager) external',
    'function setUserFees(address poolManager, uint64[] memory _xFee, uint64[] memory _yFee, uint8 _mint) external'
  ]);

export const PerpetualManagerInterface = new utils.Interface([
    'function setLockTime(uint64 _lockTime) external',
    'function setBoundsPerpetual(uint64 _maxLeverage, uint64 _maintenanceMargin) external',
    'function setNewRewardsDistributor(address _rewardsDistribution) external',
    'function setRewardDistribution(uint256 _rewardsDuration, address _rewardsDistribution) external',
    'function setHAFees(uint64[] memory _xHAFees, uint64[] memory _yHAFees, uint8 deposit) external',
    'function setTargetAndLimitHAHedge(uint64 _targetHAHedge, uint64 _limitHAHedge) external',
    'function setKeeperFeesLiquidationRatio(uint64 _keeperFeesRatio) external',
    'function setKeeperFeesCap(uint256 _keeperFeesLiquidationCap, uint256 _keeperFeesClosingCap) external',
    'function setKeeperFeesClosing(uint64[] memory _xKeeperFeesClosing, uint64[] memory _yKeeperFeesClosing) external',
    'function recoverERC20(address tokenAddress,address to, uint256 tokenAmount) external',
    'function pause() external',
    'function unpause() external',
  ]);

export const PoolManagerInterface = new utils.Interface([
    'function recoverERC20(address tokenAddress, address to, uint256 amountToRecover) external',
    'function addStrategy(address strategy, uint256 _debtRatio) external',
    'function updateStrategyDebtRatio(address strategy, uint256 _debtRatio) external',
    'function setStrategyEmergencyExit(address strategy) external',
    'function revokeStrategy(address strategy) external',
    'function withdrawFromStrategy(address strategy, uint256 amount) external',
  ]);

export const StrategyInterface = new utils.Interface([
    'function setRewards(address _rewards) external',
    'function setRewardAmount(uint256 amount) external',
    'function setMinReportDelay(uint256 _delay) external',
    'function setMaxReportDelay(uint256 _delay) external',
    'function setProfitFactor(uint256 _profitFactor) external',
    'function setDebtThreshold(uint256 _debtThreshold) external',
    'function sweep(address _token, address to) external',
  ]);

  export const RewardsDistributorInterface = new utils.Interface([
    'function governorWithdrawRewardToken(uint256 amount, address to) external',
    'function governorRecover(address tokenAddress, address to, uint256 amount, address stakingContract) external',
    'function setNewRewardsDistributor(address newRewardsDistributor) external',
    'function removeStakingContract(address stakingContract) external',
    'function setStakingContract(address _stakingContract, uint256 _duration, uint256 _incentiveAmount, uint256 _updateFrequency, uint256 _amountToDistribute) external',
    'function setUpdateFrequency(uint256 _updateFrequency, address stakingContract) external',
    'function setIncentiveAmount(uint256 _incentiveAmount, address stakingContract) external',
    'function setAmountToDistribute(uint256 _amountToDistribute, address stakingContract) external',
    'function setDuration(uint256 _duration, address stakingContract) external',
  ]);

export const BondingCurveInterface = new utils.Interface([
    'function recoverERC20(address tokenAddress, address to, uint256 amountToRecover) external',
    'function allowNewStablecoin(address _agToken, address _oracle, uint256 _isReference) external',
    'function changeOracle(address _agToken, address _oracle) external',
    'function revokeStablecoin(address _agToken) external',
    'function changeStartPrice(uint256 _startPrice) external',
    'function changeTokensToSell(uint256 _totalTokensToSell) external',
    'function pause() external',
    'function unpause() external',
]);

export const CollateralSettlerInterface = new utils.Interface([
    'function setAmountToRedistribute(uint256 newAmountToRedistribute) external',
    'function recoverERC20(address tokenAddress, address to, uint256 amountToRecover) external',
    'function setProportionalRatioGov(uint64 _proportionalRatioGovUser, uint64 _proportionalRatioGovLP) external',
    'function pause() external',
    'function unpause() external',
]);

export const CoreInterface = new utils.Interface([
    'function setCore(address newCore) external',
    'function deployStableMaster(address agToken) external',
    'function revokeStableMaster(address stableMaster) external',
    'function addGovernor(address _governor) external',
    'function removeGovernor(address _governor) external',
    'function setGuardian(address _newGuardian) external',
    'function revokeGuardian() external',
]);

export const FeeManagerInterface = new utils.Interface([
    'function setFees(uint256[] memory xArray, uint64[] memory yArray, uint8 typeChange) external',
    'function setHAFees(uint64 _haFeeDeposit, uint64 _haFeeWithdraw) external',
]);

export const OracleInterface = new utils.Interface([
    'function changeTwapPeriod(uint32 _twapPeriod) external'
]);

export const ANGLEInterface = new utils.Interface([
  'function delegate(address delegatee) public '
]);


