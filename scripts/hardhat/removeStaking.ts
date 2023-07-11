import { generic } from '../utils'
import { parseAmount } from './bignumber'
import { submit } from '../utils/submitTx'
import Web3 from 'web3'
import { ethers, utils, BigNumber } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'

async function main() {
  const web3 = new Web3(Web3.givenProvider)

  const contractInterface = Interfaces.Governor_Interface

  const governorAddress = CONTRACTS_ADDRESSES[ChainId.MAINNET].Governor
  const timestampAddress = CONTRACTS_ADDRESSES[ChainId.MAINNET].Timelock
  const ANGLE = CONTRACTS_ADDRESSES[ChainId.MAINNET].ANGLE
  const rewardDistributorAddress =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].RewardsDistributor
  const rewardDistributorInterface = new utils.Interface([
    'function setStakingContract(address _stakingContract, uint256 _duration, uint256 _incentiveAmount, uint256 _updateFrequency, uint256 _amountToDistribute) external',
    'function setAmountToDistribute(uint256 _amountToDistribute, address stakingContract) external',
    'function governorWithdrawRewardToken(uint256 amount, address to) external',
    'function setUpdateFrequency(uint256 _updateFrequency, address stakingContract) external',
    'function governorRecover(address tokenAddress, address to, uint256 amount) external',
    'function removeStakingContract(address stakingContract) external',
  ])

  const stakingRewardsCurve = '0xf868da244C17CF0E288AE4A92c8636f072A7BaE3'

  const newFunctionName = 'removeStakingContract'

  const baseTxnRemoveStaking = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    newFunctionName,
    [stakingRewardsCurve],
  )

  /*
  await submit(baseTxnApprove, 61)
  */
  await submit(baseTxnRemoveStaking, 64)
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
