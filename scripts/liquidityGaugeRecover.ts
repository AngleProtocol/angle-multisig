import { generic } from './utils'
import { parseAmount } from './bignumber'
import { submit } from './submitTx'

import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'
import { ethers } from 'hardhat'

async function main() {
  const liquidityGaugeAddress =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['USDC']
      .LiquidityGauge
  const functionName = 'recover_erc20'
  const newLiquidityGaugeInterface = new ethers.utils.Interface([
    'function recover_erc20(address token, address addr, uint256 amount) external',
  ])
  const amount = 124702274179
  const toAddress = '0x620e4e2F2573C8d10Db9b16C7e8Ca12742C010F7'

  const baseTxnUpdateMaxInterest = await generic(
    liquidityGaugeAddress,
    newLiquidityGaugeInterface,
    functionName,
    [liquidityGaugeAddress, toAddress, amount],
  )
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
