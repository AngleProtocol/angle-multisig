import { generic } from './utils'
import { parseAmount } from './bignumber'
import { submit } from './submitTx'
import Web3 from 'web3'
import { ethers, utils } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'

async function main() {
  const web3 = new Web3(Web3.givenProvider)

  const contractInterface = Interfaces.Governor_Interface

  const governorAddress = CONTRACTS_ADDRESSES[ChainId.MAINNET].Governor
  const timestampAddress = CONTRACTS_ADDRESSES[ChainId.MAINNET].Timelock
  const targets = [governorAddress, timestampAddress]
  const values = [0, 0]
  const callDatas = [
    web3.eth.abi.encodeFunctionCall(
      {
        name: 'setQuorum',
        type: 'function',
        inputs: [
          {
            type: 'uint256',
            name: 'newQuorum',
          },
        ],
      },
      ['5000000000000000000000000'],
    ),
    web3.eth.abi.encodeFunctionCall(
      {
        name: 'updateDelay',
        type: 'function',
        inputs: [
          {
            type: 'uint256',
            name: 'newDelay',
          },
        ],
      },
      ['0'],
    ),
  ]
  const description = 'Start DAO: Lower the quorum and reduce timestamp delay'

  const contract = new ethers.Contract(
    governorAddress,
    contractInterface,
    ethers.getDefaultProvider(),
  )

  const proposalID = await contract.hashProposal(
    targets,
    values,
    callDatas,
    utils.keccak256(utils.toUtf8Bytes(description)),
  )

  console.log(proposalID.toString())

  const functionName = 'propose'
  const parameters = [targets, values, callDatas, description]
  const baseTxn = await generic(
    governorAddress,
    contractInterface,
    functionName,
    parameters,
  )

  // Comment the following if you don't want to push the transaction to Gnosis
  await submit(baseTxn)
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
