import { generic } from '../utils'
import { parseAmount } from './bignumber'
import { submit, execute } from '../utils/submitTx'
import Web3 from 'web3'
import { ethers, utils, BigNumber } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'

async function main() {
  const bribeInterface = new utils.Interface([
    'function add_reward_amount(address gauge, address reward_token, uint amount) external returns (bool)',
  ])

  const toAddress = '0x7893bbb46613d7a4FbcC31Dab4C9b823FfeE1026'
  const bribeFunction = 'add_reward_amount'
  const amountBribe = parseAmount.ether(50000)
  // Address of 3EUR Gauge
  const gaugeAddress = '0x1E212e054d74ed136256fc5a5DDdB4867c6E003F'
  const rewardToken = CONTRACTS_ADDRESSES[ChainId.MAINNET].ANGLE
  const baseTxnBribe = await generic(toAddress, bribeInterface, bribeFunction, [
    gaugeAddress,
    rewardToken,
    amountBribe,
  ])

  // Comment the following if you don't want to push the transaction to Gnosis
  // const startNonce = 179

  // await submit(baseTxnBribe)

  // Transactions to be executed later
  /*
  await execute(
    baseTxnBribe,
    '0xe4765a6d6c645d5f87ef9df84f91406572dadd1346212c31f67a51498eb98cce',
  )
  */
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
