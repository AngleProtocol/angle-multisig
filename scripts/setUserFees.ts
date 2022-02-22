import { generic } from './utils'
import { submit } from './submitTx'

import {
  CONTRACTS_ADDRESSES,
  ChainId,
  Interfaces,
  CONSTANTS,
  formatAmount,
} from '@angleprotocol/sdk'
import { BigNumber } from 'ethers'

async function main() {
  const stables = ['agEUR'] as const
  const collaterals = ['FRAX'] as const

  const constants = CONSTANTS(ChainId.MAINNET)

  const stableMasterInterface = Interfaces.StableMasterFront_Interface
  const functionName = 'setUserFees'

  let nonce = 38
  for (const stable of stables) {
    const stableMasterAddress =
      CONTRACTS_ADDRESSES[ChainId.MAINNET][stable].StableMaster
    for (const col of collaterals) {
      console.log(`Changing mint fees for ${col}`)
      const poolManagerAddress =
        CONTRACTS_ADDRESSES[ChainId.MAINNET][stable].collaterals[col]
          .PoolManager
      const xFees = constants.poolsParameters[stable.substr(2)][col].xFeeMint
      const yFees = constants.poolsParameters[stable.substr(2)][col].yFeeMint

      for (let i = 0; i < xFees.length; i++) {
        console.log('x thres ', formatAmount.gwei(xFees[i]))
        console.log('y thres ', formatAmount.gwei(yFees[i]))
      }
      console.log(`Preparing transaction to set mint fees for ${col}`)
      const baseTxnSetUserFees = await generic(
        stableMasterAddress,
        stableMasterInterface,
        functionName,
        [poolManagerAddress, xFees, yFees, 1],
      )
      console.log('')
      console.log('------------------------------------------------')
      console.log('')

      console.log(
        `Submitting transaction to set mint fees for ${stable}-${col}`,
      )
      await submit(baseTxnSetUserFees, nonce)
      nonce += 1
    }
  }
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
