import { generic } from './utils'
import { submit } from './submitTx'
import { SupportedEtehreumChain } from '../constants'

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
  const collaterals = ['USDC', 'DAI'] as const
  // whether for deposit or withdrax or both
  const actions = [1, 0]

  const constants = CONSTANTS(SupportedEtehreumChain.MAINNET)

  const perpetualManagerInterface = Interfaces.Perpetual_Manager_Interface
  const functionName = 'setHAFees'

  let nonce = 21
  for (const stable of stables) {
    for (const col of collaterals) {
      for (const deposit of actions) {
        const perpetualManagerAddress =
          CONTRACTS_ADDRESSES[ChainId.MAINNET][stable].collaterals[col]
            .PerpetualManager

        console.log(
          `Changing deposit=${deposit} fee for perpetuals ${stable} - ${col} at address ${perpetualManagerAddress}`,
        )

        const xHAFees = deposit
          ? constants.poolsParameters[stable.substr(2)][col].xHAFeesDeposit
          : constants.poolsParameters[stable.substr(2)][col].xHAFeesWithdraw
        const yHAFees = deposit
          ? constants.poolsParameters[stable.substr(2)][col].yHAFeesDeposit
          : constants.poolsParameters[stable.substr(2)][col].yHAFeesWithdraw

        console.log('Is it a deposit?', deposit)
        for (let i = 0; i < xHAFees.length; i++) {
          console.log('x thres ', formatAmount.gwei(xHAFees[i]))
          console.log('y thres ', formatAmount.gwei(yHAFees[i]))
        }
        console.log(`Preparing transaction to set max interest ${col}`)
        const baseTxnSetHAFees = await generic(
          perpetualManagerAddress,
          perpetualManagerInterface,
          functionName,
          [xHAFees, yHAFees, deposit],
        )
        console.log('')
        console.log('------------------------------------------------')
        console.log('')

        console.log(
          `Submitting transaction to set perpetual fees for ${stable}-${col}`,
        )
        // await submit(baseTxnSetHAFees, nonce);
        nonce += 1
      }
    }
  }
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
