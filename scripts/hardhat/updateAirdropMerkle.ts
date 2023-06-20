import { generic } from './utils'
import { submit } from './submitTx'
import { utils } from 'ethers'

async function main() {
  // Address of the airdrop contract
  const toAddress = '0x381A815b112A394f27121e2A99e86f88b1Ef85A2'

  const AirdropInterface = new utils.Interface([
    'function updateMerkleRoot(bytes32 _merkleRoot) external',
  ])

  // Obtained in the `angle-vesting` repo
  const merkleRoot =
    '0xd0e8c40baef4cec55a5a9f942a5f876fdbfbb5990d8d8d0695b68507176c2f08'

  const functionName = 'updateMerkleRoot'
  const parameters = [merkleRoot]
  const baseTxn = await generic(
    toAddress,
    AirdropInterface,
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
