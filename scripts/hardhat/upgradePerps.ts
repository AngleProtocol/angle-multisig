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
  const collaterals = ['USDC', 'DAI', 'FEI', 'FRAX'] as const

  const proxyAdminInterface = Interfaces.ProxyAdmin_Interface
  const functionName = 'upgrade'

  const proxyAdminAddress = CONTRACTS_ADDRESSES[ChainId.MAINNET].ProxyAdmin
  const implementationAddress = '0x9Ca144C12a9dce3B72Be31048CF54C79b42E02df'

  let nonce = 21
  for (const stable of stables) {
    for (const col of collaterals) {
      const perpetualManagerAddress =
        CONTRACTS_ADDRESSES[ChainId.MAINNET][stable].collaterals[col]
          .PerpetualManager

      console.log(`Preparing transaction to upgrade perpManager for ${col}`)
      const baseTxnSetHAFees = await generic(
        proxyAdminAddress,
        proxyAdminInterface,
        functionName,
        [perpetualManagerAddress, implementationAddress],
      )
      console.log('')
      console.log('------------------------------------------------')
      console.log('')

      console.log(
        `Submitting transaction to upgrade perpetual Manager for ${stable}-${col}`,
      )
      await submit(baseTxnSetHAFees, nonce)
      nonce += 1
    }
  }
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
