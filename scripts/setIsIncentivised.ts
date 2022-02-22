import { generic } from './utils'
import { parseAmount } from './bignumber'
import { submit } from './submitTx'
import Web3 from 'web3'
import { ethers, utils } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'

async function main() {
  const collaterals = ['FRAX'] as const

  for (const col of collaterals) {
    const genericLenderAddress =
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals[col].GenericAave
    console.log(genericLenderAddress)
    const genericLenderInterface = new utils.Interface([
      'function setIsIncentivised(bool _isIncentivised) external',
    ])

    console.log(`Preparing transaction to setIsIncentivised for ${col}`)
    const baseTxnFRAX = await generic(
      genericLenderAddress,
      genericLenderInterface,
      'setIsIncentivised',
      [true],
    )
    console.log('')
    console.log('------------------------------------------------')
    console.log('')

    /*
    console.log(`Submitting transaction to unpause SLPs for ${col}`)
    await submit(baseTxnFRAX, 17)
    console.log('')
    console.log('------------------------------------------------')
    console.log('')
    */
  }
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
