import { generic } from '../../utils'
import { parseAmount } from '../bignumber'
import { submit } from '../../utils/submitTx'
import Web3 from 'web3'
import { ethers, utils } from 'ethers'

import {
  CONTRACTS_ADDRESSES,
  ChainId,
  Interfaces,
  CONSTANTS,
} from '@angleprotocol/sdk'

// Only change this line to submit a proposal
import aip from '../../../proposals/aip-curve'

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

  const proposalID = await contract.hashProposal(
    aip.targets,
    aip.values,
    aip.callDatas,
    utils.keccak256(utils.toUtf8Bytes(aip.description)),
  )
  /*
  console.log(aip.targets)
  console.log(aip.values)
  console.log(aip.callDatas)
  console.log(utils.keccak256(utils.toUtf8Bytes(aip.description)))
  */

  console.log(proposalID.toString())

  const functionName = 'castVote'
  const parameters = [proposalID, 1]
  const baseTxn = await generic(
    governorAddress,
    contractInterface,
    functionName,
    parameters,
  )
  // After calling this function, we'd need to set the staking contracts from the RewardDistributor

  // Comment the following if you don't want to push the transaction to Gnosis
  // await submit(baseTxn);
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
