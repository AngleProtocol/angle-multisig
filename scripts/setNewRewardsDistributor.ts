import { generic } from './utils'
import { parseAmount } from './bignumber'
import { submit, execute } from './submitTx'
import Web3 from 'web3'
import { ethers, utils, BigNumber } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId } from '@angleprotocol/sdk'

async function main() {
  const rewardDistributorAddress =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].RewardsDistributor
  const rewardDistributorInterface = new utils.Interface([
    'function setNewRewardsDistributor(address newRewardsDistributor) external',
  ])
  const angleDistributorAddress =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].AngleDistributor

  const baseTxnSetNewRewardsDistributor = await generic(
    rewardDistributorAddress,
    rewardDistributorInterface,
    'setNewRewardsDistributor',
    [angleDistributorAddress],
  )
  // await submit(baseTxnSetNewRewardsDistributor)
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
