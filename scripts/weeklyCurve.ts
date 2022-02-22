import { generic } from './utils'
import { parseAmount } from './bignumber'
import { submit, execute } from './submitTx'
import Web3 from 'web3'
import { ethers, utils, BigNumber } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'

async function main() {
  const curveInterface = new utils.Interface([
    'function deposit_reward_token(address _reward_token, uint256 _amount) external',
  ])

  const curveGaugeAddress = '0x1E212e054d74ed136256fc5a5DDdB4867c6E003F'
  const curveGaugeAddressIbEUR = '0x38039dd47636154273b287f74c432cac83da97e2'
  const ANGLE = CONTRACTS_ADDRESSES[ChainId.MAINNET].ANGLE
  const curveFunction = 'deposit_reward_token'
  const amountCurve = parseAmount.ether(277419.073219585491787716)
  const amountCurveibEUR = parseAmount.ether(97321.02849335389937107)
  const baseTxnCurve = await generic(
    curveGaugeAddress,
    curveInterface,
    curveFunction,
    [ANGLE, amountCurve],
  )
  const baseTxnCurveIbEUR = await generic(
    curveGaugeAddressIbEUR,
    curveInterface,
    curveFunction,
    [ANGLE, amountCurveibEUR],
  )
  // Comment the following if you don't want to push the transaction to Gnosis
  const startNonce = 179

  await submit(baseTxnCurve, startNonce)
  await submit(baseTxnCurveIbEUR, startNonce + 1)

  // Transactions to be executed later
  /*
  await execute(
    baseTxnCurve,
    '0xe4765a6d6c645d5f87ef9df84f91406572dadd1346212c31f67a51498eb98cce',
  )
  
  await execute(
    baseTxnCurveIbEUR,
    '0xa617455d1e1651ae1ce0090d61322eec661df37620bc1a54def4dcbbc9d21355',
  )
  */
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
