import EIP712Domain from 'eth-typed-data';
import * as ethUtil from 'ethereumjs-util';
import { ethers } from 'ethers';
import { gnosisEstimateTransaction, gnosisProposeTx, gnosisEstimateNonce, gnosisGetSignatures } from '.';
import { executeTx } from './executeTx';
import { config } from 'dotenv';

const { utils } = ethers;

/*
 * This function submits a transaction to be voted on the guardian multisig.
 * It wraps a transaction that has already been encoded using the `transaction.ts` file
 * * * * * * * * * * * * * * * * * * * */
config();
export const submit = async (baseTxn, nonceCustom = 0, chainId: number | null = null, safe: string | null = null) => {
  console.log('Now wrapping the base transaction for Gnosis');
  safe = safe ?? process.env.SAFE;
  chainId = chainId ?? Number(process.env.CHAIN_ID);
  const sender: string = process.env.SENDER;

  // Lets the Safe service estimate the tx and retrieve the nonce
  // We can also simply find the nonce using `gnosisEstimateNonce` and use a bad value for gas
  /*
  const lastUsedNonce = 9;
  const safeTxGas = "1000000";
  */
  const { safeTxGas } = await gnosisEstimateTransaction(safe, chainId, baseTxn);
  const safeNonce = await gnosisEstimateNonce(safe, chainId, true);
  console.log('safeTxGas', safeTxGas);
  console.log('Nonce', safeNonce);
  console.log('');

  const nonce = safeNonce === undefined || nonceCustom != 0 ? nonceCustom : safeNonce;

  const txn = {
    ...baseTxn,
    safeTxGas,
    // Here we can also set any custom nonce
    nonce: nonce,
    // nonce: 0,
    // We don't want to use the refund logic of the safe to let use the default values
    baseGas: 0,
    gasPrice: 0,
    gasToken: '0x0000000000000000000000000000000000000000',
    refundReceiver: '0x0000000000000000000000000000000000000000',
  };

  const toSend = {
    ...txn,
    sender,
    // Random contract transaction hash
    contractTransactionHash: '0x4cb866ee4662b0710e83802e81bd448f5d7e62ed8ea8967dfa3f5ac6d1136c3a',
    // Random signature
    signature:
      '0xf434dc7ca81db0ad0078350c1acabff377c9cb8996fdee062ff829f3fac8fea328bc75716792fd60a7ed452c86165614e807a794d70be8216a6d80ef6030f4be1b',
  };
  console.log('Transaction to propose to Gnosis');
  console.log(JSON.stringify({ toSend }));

  await gnosisProposeTx(safe, chainId, toSend);
  console.log('');
  console.log('Done?');
};

export const execute = async (baseTxn, safe_tx_hash, numConfirmations = 2, chainId = null) => {
  console.log(`Now executing the transaction`);
  const safe: string = process.env.SAFE;
  chainId = chainId ?? process.env.CHAIN_ID;

  // Lets the Safe service estimate the tx and retrieve the nonce

  const { safeTxGas } = await gnosisEstimateTransaction(safe, chainId, baseTxn);
  const { lastUsedNonce } = await gnosisEstimateNonce(safe, chainId);
  console.log('safeTxGas', safeTxGas);
  console.log('Nonce', lastUsedNonce);
  console.log('');

  const txn = {
    ...baseTxn,
    safeTxGas,
    baseGas: 0,
    gasPrice: 0,
    gasToken: '0x0000000000000000000000000000000000000000',
    refundReceiver: '0x0000000000000000000000000000000000000000',
  };

  const resp = await gnosisGetSignatures(safe_tx_hash, chainId, numConfirmations);
  const feasible = resp[1];
  if (feasible) {
    const txn = {
      ...baseTxn,
      safeTxGas,
      baseGas: 0,
      gasPrice: 0,
      gasToken: '0x0000000000000000000000000000000000000000',
      refundReceiver: '0x0000000000000000000000000000000000000000',
      signature: resp[0],
    };
    await executeTx(txn);
  }
};
