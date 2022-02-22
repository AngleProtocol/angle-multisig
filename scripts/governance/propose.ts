import { generic } from '../utils'
import Web3 from 'web3'
import { ethers } from 'ethers'
import { submit, execute } from '../submitTx'

import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'

// Only change this line to submit a proposal
import aip from '../../proposals/aip-curve'

// ====================== TO NOT CHANGE ======================

async function main() {
  const web3 = new Web3(Web3.givenProvider)

  const contractInterface = Interfaces.Governor_Interface

  const governorAddress = CONTRACTS_ADDRESSES[ChainId.MAINNET].Governor
  const coreAddress = CONTRACTS_ADDRESSES[ChainId.MAINNET].Core

  const contract = new ethers.Contract(
    governorAddress,
    contractInterface,
    ethers.getDefaultProvider(),
  )

  const functionName = 'propose'
  const parameters = [aip.targets, aip.values, aip.callDatas, aip.description]
  const baseTxn = await generic(
    governorAddress,
    contractInterface,
    functionName,
    parameters,
  )
  // After calling this function, we'd need to set the staking contracts from the RewardDistributor

  // Comment the following if you don't want to push the transaction to Gnosis
  // await submit(baseTxn)
  await execute(
    baseTxn,
    '0x593331d34c6fddc0e1bf6cb8fe1b241b328cc4993f0d2a967687fbc7792b2804',
  )
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
