import { generic } from '../utils'
import { parseAmount } from './bignumber'
import { submit } from '../utils/submitTx'
import Web3 from 'web3'
import { ethers, utils } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'

async function main() {
  const collaterals = ['FRAX'] as const
  const poolManagerInterface = Interfaces.PoolManager_Interface
  const functionName = 'updateStrategyDebtRatio'
  const debtRatioValue = parseAmount.gwei(0.6)
  for (const col of collaterals) {
    const poolManagerAddress =
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals[col].PoolManager
    const strategyAddress =
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals[col].Strategy
    console.log(`Preparing transaction to set debt ratio for ${col}`)
    const baseTxnUpdateDebtRatio = await generic(
      poolManagerAddress,
      poolManagerInterface,
      functionName,
      [strategyAddress, debtRatioValue],
    )
    console.log('')
    console.log('------------------------------------------------')
    console.log('')

    console.log(`Submitting transaction to set debt ratio for ${col}`)
    await submit(baseTxnUpdateDebtRatio, 18)
    console.log('')
    console.log('------------------------------------------------')
    console.log('')
  }
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
