import { generic } from './utils'
import { parseAmount } from './bignumber'
import { submit, execute } from './submitTx'
import Web3 from 'web3'
import { ethers, utils, BigNumber } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'

async function main() {
  const rewardDistributorAddress =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].RewardsDistributor
  const rewardDistributorInterface = new utils.Interface([
    'function setStakingContract(address _stakingContract, uint256 _duration, uint256 _incentiveAmount, uint256 _updateFrequency, uint256 _amountToDistribute) external',
    'function setAmountToDistribute(uint256 _amountToDistribute, address stakingContract) external',
    'function governorWithdrawRewardToken(uint256 amount, address to) external',
  ])

  const curveInterface = new utils.Interface([
    'function deposit_reward_token(address _reward_token, uint256 _amount) external',
  ])

  const curveGaugeAddress = '0x1E212e054d74ed136256fc5a5DDdB4867c6E003F'
  const curveGaugeAddressIbEUR = '0x38039dd47636154273b287f74c432cac83da97e2'

  const stakingRewardsGUni =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].ExternalStakings[0]
      .stakingContractAddress
  const stakingRewardsGUniWETH =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].ExternalStakings[1]
      .stakingContractAddress
  const stakingRewardsSushi =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].ExternalStakings[2]
      .stakingContractAddress
  const stakingRewardsUniV2FEI =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].ExternalStakings[3]
      .stakingContractAddress

  const ANGLE = CONTRACTS_ADDRESSES[ChainId.MAINNET].ANGLE

  const newFunctionName = 'setAmountToDistribute'
  const curveFunction = 'deposit_reward_token'

  const amountHADAI = parseAmount.ether(34951381.05)
  const amountHAUSDC = parseAmount.ether(88829502.74)
  const amountSLPDAI = parseAmount.ether(38989085.72)
  const amountSLPUSDC = parseAmount.ether(92110137.78)
  const amountAgEUR = parseAmount.ether(200623450.8)
  const amountGUNI = parseAmount.ether(161003473.7)
  const amountSushi = parseAmount.ether(211979495.2)
  const amountFEI = parseAmount.ether(3532991.586)
  const amountCurve = parseAmount.ether(159952.56)
  const amountRecoverPolygon = parseAmount.ether(134060.09)
  const amountHAFEI = parseAmount.ether(6056557.005)
  const amountHAFRAX = parseAmount.ether(5299487.379)
  const amountSLPFEI = parseAmount.ether(11860757.47)
  const amountSLPFRAX = parseAmount.ether(12365470.55)
  const amountGUNIagEURwETH = parseAmount.ether(160624938.9)
  const amountCurveibEUR = parseAmount.ether(129220.38)
  const amountRecoverAvalanche = parseAmount.ether(23956.59)

  const baseTxnHADAI = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [
      amountHADAI,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['DAI']
        .PerpetualManager,
    ],
  )
  const baseTxnHAUSDC = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [
      amountHAUSDC,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['USDC']
        .PerpetualManager,
    ],
  )
  const baseTxnSLPDAI = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [
      amountSLPDAI,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['DAI'].Staking,
    ],
  )
  const baseTxnSLPUSDC = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [
      amountSLPUSDC,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['USDC'].Staking,
    ],
  )
  const baseTxnAgEUR = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [amountAgEUR, CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.Staking],
  )

  const baseTxnGUNI = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [amountGUNI, stakingRewardsGUni],
  )

  const baseTxnSushi = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [amountSushi, stakingRewardsSushi],
  )

  const baseTxnFEIUni = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [amountFEI, stakingRewardsUniV2FEI],
  )

  const baseTxnHAFEI = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [
      amountHAFEI,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['FEI']
        .PerpetualManager,
    ],
  )

  const baseTxnHAFRAX = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [
      amountHAFRAX,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['FRAX']
        .PerpetualManager,
    ],
  )

  const baseTxnSLPFEI = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [
      amountSLPFEI,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['FEI'].Staking,
    ],
  )

  const baseTxnSLPFRAX = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [
      amountSLPFRAX,
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['FRAX'].Staking,
    ],
  )

  const baseTxnGUNIagEURwETH = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [amountGUNIagEURwETH, stakingRewardsGUniWETH],
  )

  const baseTxnCurve = await generic(
    curveGaugeAddress,
    curveInterface,
    curveFunction,
    [ANGLE, amountCurve],
  )

  const baseTxnCurveIbEUR = await generic(
    curveGaugeAddressIbEUR,
    curveInterface,
    curveFunction,
    [ANGLE, amountCurveibEUR],
  )

  // Comment the following if you don't want to push the transaction to Gnosis

  const startNonce = 159

  await submit(baseTxnHADAI, startNonce)
  await submit(baseTxnHAUSDC, startNonce + 1)
  await submit(baseTxnSLPDAI, startNonce + 2)
  await submit(baseTxnSLPUSDC, startNonce + 3)
  await submit(baseTxnAgEUR, startNonce + 4)
  await submit(baseTxnSushi, startNonce + 5)
  await submit(baseTxnGUNI, startNonce + 6)
  await submit(baseTxnFEIUni, startNonce + 7)
  await submit(baseTxnHAFEI, startNonce + 8)
  await submit(baseTxnHAFRAX, startNonce + 9)
  await submit(baseTxnSLPFEI, startNonce + 10)
  await submit(baseTxnSLPFRAX, startNonce + 11)
  await submit(baseTxnGUNIagEURwETH, startNonce + 12)
  await submit(baseTxnCurve, startNonce + 13)
  await submit(baseTxnCurveIbEUR, startNonce + 14)

  await execute(
    baseTxnHADAI,
    '0x847821c8e6d90cfaab493c4d03bb87934b11d939a0180bf7551c53854204a074',
  )

  await execute(
    baseTxnHAUSDC,
    '0x5809d6309f99d93dc2e274f02e955fef1a9d0ee15e49b13c20dee2e27739eb2b',
  )
  await execute(
    baseTxnSLPDAI,
    '0x20ab34b546cf76de8722e7dc5809fdc5848f5051ab76ffdd8ece39153e1fd2ea',
  )
  await execute(
    baseTxnSLPUSDC,
    '0x1273f2e3439bd2c44f05ee14dd75b52878f415ffb98f295131943dc6964194d8',
  )
  await execute(
    baseTxnAgEUR,
    '0x1bb2b694ffb88dc34167dffef4b81197983893cdc28207fda145ba8a721da03e',
  )
  await execute(
    baseTxnSushi,
    '0xde8aea40eef750f70e6d310dbac2bff6af21d94541e12dcc9a4afba68092f5e7',
  )
  await execute(
    baseTxnGUNI,
    '0xcd301a512ab6e87bb937b5ef65789306cfcae61bbbaa636486fe3f4513094bee',
  )
  await execute(
    baseTxnFEIUni,
    '0x90b0e218ad861b56d03c29eea1c4bd6c8f85f618c63c0806560e573cd88bb9cc',
  )
  await execute(
    baseTxnHAFEI,
    '0x9ce2fa1bc9415a554d0a6551b6b405384d349000c6d09edcdf0aec82a6b196a4',
  )
  await execute(
    baseTxnHAFRAX,
    '0x13b6492af897e823859a87f96459d640b9d12c19e6f64ce20fd5112082e20d96',
  )
  await execute(
    baseTxnSLPFEI,
    '0x84c1edababbe581daee4a2c07ac5e1701e769dc0ca08774da68ce28cadfc1aba',
  )
  await execute(
    baseTxnSLPFRAX,
    '0xf0f337b55dd996030ede5b2e53c45fd159aae439721d5bc8849f6a77e98c843e',
  )
  await execute(
    baseTxnGUNIagEURwETH,
    '0x2a8084ff9f2fec7cd2f95a82799b0a5002c8464d71d6fee78343f1ea31055fa4',
  )

  // Transactions to be executed later

  await execute(
    baseTxnCurve,
    '0xfbcc9f27a51c1ccb0483bce0a7da65db6f13f3bb4c09459d12199a3f44c15cbf',
  )

  await execute(
    baseTxnCurveIbEUR,
    '0x44db4494ac9f7f2f8fe99b866f6750098ef419fcf859ec5e3af74e0523369a4a',
  )
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
