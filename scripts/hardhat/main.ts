import { generic } from '../utils'
import { parseAmount } from './bignumber'
import { submit } from '../utils/submitTx'
import Web3 from 'web3'
import { ethers, utils } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'

async function main() {
  const web3 = new Web3(Web3.givenProvider)

  const contractInterface = Interfaces.Strategy_Interface

  const strategyAddress =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['USDC'].Strategy

  const functionName = 'setWithdrawalThreshold'
  const baseTxn = await generic(
    strategyAddress,
    contractInterface,
    functionName,
    [parseAmount.usdc('1000')],
  )

  // Comment the following if you don't want to push the transaction to Gnosis
  await submit(baseTxn)
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
