import axios from 'axios'
// import {signHash} from "./sign";

import { ethers } from 'ethers'
import { config } from 'dotenv'
import { SAFE_API } from './constants'

config()
export async function signHash(hash: string) {
  let signingKey = new ethers.utils.SigningKey(
    process.env.PRIVATE_KEY.toString(),
  )
  var signature = signingKey.signDigest(hash)
  console.log('')
  console.log(
    'Signature from the delegate of the new contract transaction hash',
  )
  const result = ethers.utils.joinSignature(signature)
  console.log(result)
  console.log('')
  return result
}

export async function generic(
  toAddress: string,
  contractInterface,
  functionName: string,
  parameters,
) {
  const to = ethers.utils.getAddress(toAddress)
  const data = contractInterface.encodeFunctionData(functionName, parameters)
  const baseTxn = {
    to,
    value: '0',
    data: data,
    operation: '0', /// 0 is call, 1 is delegate call
  }
  console.log('Base transaction to execute on-chain')
  console.log(JSON.stringify({ baseTxn }))
  console.log('')
  return baseTxn
}

export const gnosisEstimateTransaction = async (
  safe: string,
  tx: any,
): Promise<any> => {
  try {
    const resp = await axios.post(
      `${SAFE_API}/safes/${safe}/multisig-transactions/estimations/`,
      tx,
    )
    console.log('')
    return resp.data
  } catch (e) {
    console.log('')
    console.log('There has been an error estimating the transaction')
    console.log('')
    if (e.response) console.log(JSON.stringify(e.response.data))
    throw e
  }
}

export const gnosisEstimateNonce = async (safe: string): Promise<any> => {
  try {
    const resp = await axios.post(
      `${SAFE_API}/safes/${safe}`,
    )
    return resp.data
  } catch (e) {
    console.log('')
    console.log('There has been an error estimating the nonce')
    console.log('')
    console.log(JSON.stringify(e.response.data))
    throw e
  }
}

export const gnosisProposeTx = async (safe: string, tx: any): Promise<any> => {
  try {
    const resp = await axios.post(
      `${SAFE_API}/safes/${safe}/multisig-transactions/`,
      tx,
    )
    console.log(resp.data)
    return resp.data
  } catch (e) {
    console.log('')
    console.log(
      'There has been an error proposing the transaction, trying again with a new contract hash',
    )
    console.log('')
    // console.log(e)
    if (e.response) {
      console.log(e.response.data)
      const newContractTxHash = e.response.data.nonFieldErrors[0].substr(26, 66)
      console.log('New contract transaction hash')
      console.log(newContractTxHash)
      const newTx = tx
      newTx.contractTransactionHash = newContractTxHash
      const signature = await signHash(newContractTxHash)
      newTx.signature = signature
      try {
        const resp2 = await axios.post(
          `${SAFE_API}/safes/${safe}/multisig-transactions/`,
          newTx,
        )
        console.log('Success, transaction sent!')
        console.log('Data sent to Gnosis:')
        console.log(newTx)
        return resp2.data
      } catch (f) {
        console.log('')
        console.log('There has been an error on the second try')
        console.log('')
        console.log(JSON.stringify(f.response.data))
        throw f
      }
    }
  }
}

export const gnosisGetSignatures = async (
  safe_tx_hash: string,
  numConfirmations = 2,
): Promise<any> => {
  try {
    const resp = await axios.get(
      `${SAFE_API}/multisig-transactions/${safe_tx_hash}/confirmations/`,
    )
    console.log('')
    console.log(resp.data)
    let executable = false
    let order = true
    let encoded = ''
    if (resp.data.count == numConfirmations) {
      executable = true
      order =
        parseInt(resp.data.results[0], 16) <= parseInt(resp.data.results[1], 16)
      for (let i = 0; i < resp.data.count; i++) {
        if (order) {
          if (i == 0) {
            encoded = '0x'
          }
          encoded += resp.data.results[i].signature.slice(2)
        } else {
          encoded = resp.data.results[i].signature.slice(2) + encoded
          if (i == resp.data.count - 1) {
            encoded = '0x' + encoded
          }
        }
      }
    }

    console.log(encoded)
    return [encoded, executable]
  } catch (e) {
    console.log('')
    console.log('There has been an error getting the signature')
    console.log('')
    if (e.response) console.log(JSON.stringify(e.response.data))
    throw e
  }
}
