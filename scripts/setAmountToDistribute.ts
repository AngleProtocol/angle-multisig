import { generic } from './utils'
import { parseAmount } from './bignumber'
import { submit } from './submitTx'
import { utils } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId } from '@angleprotocol/sdk'

async function main() {
  const rewardDistributorAddress =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].RewardsDistributor
  const rewardDistributorInterface = new utils.Interface([
    'function setStakingContract(address _stakingContract, uint256 _duration, uint256 _incentiveAmount, uint256 _updateFrequency, uint256 _amountToDistribute) external',
    'function setAmountToDistribute(uint256 _amountToDistribute, address stakingContract) external',
  ])

  const stakingRewardsGUni =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].ExternalStakings[0]
      .stakingContractAddress
  const stakingRewardsSushi =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].ExternalStakings[1]
      .stakingContractAddress
  const stakingRewardsUniV2FEI =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].ExternalStakings[2]
      .stakingContractAddress
  const stakingRewardsCurveEUR3 =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].ExternalStakings[3]
      .stakingContractAddress

  const amountHADAI = parseAmount.ether(26744868.57)
  const amountHAUSDC = parseAmount.ether(35290566.22)
  const amountSLPDAI = parseAmount.ether(126444674.5)
  const amountSLPUSDC = parseAmount.ether(189429631.2)
  const amountAgEUR = parseAmount.ether(861058165)
  const amountGUNI = parseAmount.ether(142111786.8)
  const amountSushi = parseAmount.ether(111094069.4)
  const amountToDistributeForFEI = parseAmount.ether(31967239.36)
  const amountToDistributeForCurve = parseAmount.ether(58395600.6)

  const functionName = 'setAmountToDistribute'

  const baseTxnHADAI = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    functionName,
    [
      amountHADAI,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['DAI']
        .PerpetualManager,
    ],
  )
  const baseTxnHAUSDC = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    functionName,
    [
      amountHAUSDC,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['USDC']
        .PerpetualManager,
    ],
  )
  const baseTxnSLPDAI = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    functionName,
    [
      amountSLPDAI,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['DAI'].Staking,
    ],
  )
  const baseTxnSLPUSDC = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    functionName,
    [
      amountSLPUSDC,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['USDC'].Staking,
    ],
  )
  const baseTxnAgEUR = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    functionName,
    [amountAgEUR, CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.Staking],
  )

  const baseTxnGUNI = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    functionName,
    [amountGUNI, stakingRewardsGUni],
  )

  const baseTxnSushi = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    functionName,
    [amountSushi, stakingRewardsSushi],
  )

  const baseTxnFEI = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    functionName,
    [amountToDistributeForFEI, stakingRewardsUniV2FEI],
  )
  const baseTxnCurve = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    functionName,
    [amountToDistributeForCurve, stakingRewardsCurveEUR3],
  )

  // Comment the following if you don't want to push the transaction to Gnosis

  const startNonce = 36
  /*
  await submit(baseTxnHADAI, startNonce)
  await submit(baseTxnHAUSDC, startNonce + 1)
  await submit(baseTxnSLPDAI, startNonce + 2)
  await submit(baseTxnSLPUSDC, startNonce + 3)
  await submit(baseTxnAgEUR, startNonce + 4)
  await submit(baseTxnSushi, startNonce + 5)
  await submit(baseTxnGUNI, startNonce + 6)
  await submit(baseTxnFEI, startNonce + 7)
  await submit(baseTxnCurve, startNonce + 8)
  */
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
