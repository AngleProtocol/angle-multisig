import { generic } from './utils'
import { parseAmount } from './bignumber'
import { execute, submit } from './submitTx'
import { utils } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import {
  CONTRACTS_ADDRESSES,
  ChainId,
  Interfaces,
  CONSTANTS,
} from '@angleprotocol/sdk'

async function main() {
  const surplusConverterUSDC =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].SurplusConverterSanTokens_EUR_USDC
  const surplusConverterUniV3 =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].SurplusConverterUniV3_IntraCollaterals
  const poolManagerUSDC =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals['USDC'].PoolManager
  const collaterals = ['DAI', 'FEI', 'FRAX']
  const collateralsFull = ['DAI', 'FEI', 'FRAX', 'USDC']

  let nonce = 25

  console.log(surplusConverterUSDC, surplusConverterUniV3)

  /*
  const baseTxnSetSurplusConverterUSDC = await generic(
    poolManagerUSDC,
    Interfaces.PoolManager_Interface,
    'setSurplusConverter',
    [surplusConverterUSDC],
  )
  // await submit(baseTxnSetSurplusConverterUSDC, nonce)
  await execute(
    baseTxnSetSurplusConverterUSDC,
    '0x0e2c4b27479bdea7718cd544cd9f7da3ac53ed15c83387f849fa5bc4a4d06391',
  )
  nonce += 1
  */
  for (const col of collaterals) {
    const poolManager =
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals[col].PoolManager
    const baseTxnSetSurplusConverter = await generic(
      poolManager,
      Interfaces.PoolManager_Interface,
      'setSurplusConverter',
      [surplusConverterUniV3],
    )
    // await submit(baseTxnSetSurplusConverter, nonce)
    if (nonce === 26) {
      await execute(
        baseTxnSetSurplusConverter,
        '0xa2ecd8d58ac72d8bc7d00b1478314364510e6e9632448c2cedbc150c33131b73',
      )
    } else if (nonce === 27) {
      await execute(
        baseTxnSetSurplusConverter,
        '0x88fcb81617245e43db16ded4f61b50c894637514bcee9d3a9ad5f4dd96688360',
      )
    } else {
      await execute(
        baseTxnSetSurplusConverter,
        '0xaed1bd7125361a487eedb51d3d86acfac20332d227588f70fc6e1eba718899eb',
      )
    }
    nonce += 1
  }
  for (const col of collateralsFull) {
    const poolManager =
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals[col].PoolManager
    const interestsForSurplus = CONSTANTS(ChainId.MAINNET).poolsParameters[
      'EUR'
    ][col].interestsForSurplus
    const baseTxnSetInterestsForSurplus = await generic(
      poolManager,
      Interfaces.PoolManager_Interface,
      'setInterestsForSurplus',
      [interestsForSurplus],
    )
    // await submit(baseTxnSetInterestsForSurplus, nonce)
    if (nonce === 29) {
      await execute(
        baseTxnSetInterestsForSurplus,
        '0x1e7f8694d40b57b35613ad8172526a750d8cf8f7452b0f3fb51ebb2aff8f50ff',
      )
    } else if (nonce === 30) {
      await execute(
        baseTxnSetInterestsForSurplus,
        '0x72881c60babe898b70c1967c526983ceb2acbea59d5dcab23bcd6b8a8540e7e0',
      )
    } else if (nonce === 31) {
      await execute(
        baseTxnSetInterestsForSurplus,
        '0x7a33e7f05e12d81dc07cdce68f62a92ef5cd346880d6207f0d5abc1892f15b5b',
      )
    } else {
      await execute(
        baseTxnSetInterestsForSurplus,
        '0x14b6754c5d8532c53e21cbbb2e01e05fd69bf8a15f5bea763dee8688225f6c03',
      )
    }
    nonce += 1
  }
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
