import { generic } from './utils'
import { parseAmount } from './bignumber'
import { submit } from './submitTx'
import Web3 from 'web3'
import { ethers, utils } from 'ethers'

// import {StableMasterInterface} from "../interfaces/interfaces";
import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from '@angleprotocol/sdk'

async function main() {
  // const AngleDistributorInterface = Interfaces.AngleDistributor_Interface
  const AngleDistributorInterface = new ethers.utils.Interface([
    'function setDelegateGauge(address gaugeAddr, address _delegateGauge, bool toggleInterface) external',
  ])
  const AngleDistributorAddress =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].AngleDistributor
  const functionName = 'setDelegateGauge'
  const zeroAddress = '0x0000000000000000000000000000000000000000'
  const delegateGauge = '0xe02F8E39b8cFA7d3b62307E46077669010883459'
  const baseTxnSetDelegate = await generic(
    AngleDistributorAddress,
    AngleDistributorInterface,
    functionName,
    [zeroAddress, delegateGauge, false],
  )
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
