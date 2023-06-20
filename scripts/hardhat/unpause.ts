import { generic } from './utils'
import { parseAmount } from './bignumber'
import { submit } from './submitTx'
import Web3 from 'web3'
import { ethers, utils } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'

async function main() {
  const collaterals = ['FEI'] as const
  const stableMasterInterface = Interfaces.StableMasterFront_Interface
  const perpetualManagerInterface = Interfaces.Perpetual_Manager_Interface
  const stableMasterAddress =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.StableMaster
  const functionName = 'unpause'
  const SLPHash = Web3.utils.soliditySha3('SLP')
  const userHash = Web3.utils.soliditySha3('STABLE')
  for (const col of collaterals) {
    const poolManagerAddress =
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals[col].PoolManager
    const perpetualManagerAddress =
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals[col]
        .PerpetualManager

    console.log(`Preparing transaction to unpause users for ${col}`)
    const baseTxnUnpauseUsers = await generic(
      stableMasterAddress,
      stableMasterInterface,
      functionName,
      [userHash, poolManagerAddress],
    )
    console.log('')
    console.log('------------------------------------------------')
    console.log('')

    console.log(`Preparing transaction to unpause SLPs for ${col}`)
    const baseTxnUnpauseSLPs = await generic(
      stableMasterAddress,
      stableMasterInterface,
      functionName,
      [SLPHash, poolManagerAddress],
    )

    console.log('')
    console.log('------------------------------------------------')
    console.log('')

    console.log(`Preparing transaction to unpause HAs for ${col}`)
    const baseTxnUnpauseHAs = await generic(
      perpetualManagerAddress,
      perpetualManagerInterface,
      functionName,
      [],
    )

    console.log('')
    console.log('------------------------------------------------')
    console.log('')
    /*
    console.log(`Submitting transaction to unpause users for ${col}`)
    await submit(baseTxnUnpauseUsers)
    console.log('')
    console.log('------------------------------------------------')
    console.log('')
    */
    console.log(`Submitting transaction to unpause SLPs for ${col}`)
    await submit(baseTxnUnpauseSLPs, 8)
    console.log('')
    console.log('------------------------------------------------')
    console.log('')

    console.log(`Submitting transaction to unpause HAs for ${col}`)
    await submit(baseTxnUnpauseHAs, 9)
    console.log('')
    console.log('------------------------------------------------')
    console.log('')
  }
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
