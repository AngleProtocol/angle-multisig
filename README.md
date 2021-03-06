# Angle Multisig

This repo contains scripts to push transaction to multisigs associated to Angle Protocol on Gnosis.
More generally, signers of multisig can also use this repo to check that the transactions they see on the Gnosis Safe interface on the front correspond to what they expect.

## Setup

To install all the packages needed to run the tests, run:

```javascript
yarn
```

## Setup environment

Create a `.env` file from the template file `.env.example`.
If you don't define URI and mnemonics, default mnemonic will be used with a brand new local hardhat node.

This repo can be used to interact with different Gnosis Safe. If so, you would need to have one specific `.env` file per safe.

## Gnosis interactions

### Add Delegate

The `addDelegate.py` file helps to add a delegate to a Gnosis Safe. A delegate is an address that can propose transactions to a Gnosis Safe, it does not have any on-chain right. The delegate address just has the right to mess up with the portal of waiting transactions associated to a safe. There are some other utility functions in this file.

The reason for introducing a delegate is that the address of the delegate can be unsafe and its private key can be stored in clear (because it never directly interacts with the blockchain). In the multisig, most addresses are going to be Ledger for which you do not want to store the private key, even on a GitHub repo.

### Scripts

There are different types of scripts within this repo: some to check whether transactions on Gnosis are valid, some to push transactions to Gnosis front, other to execute transactions from Gnosis.

In general to execute a script:

`yarn hardhat run --network YOUR_NETWORK PATH_TO_SCRIPT`

A good example of script to verify, push and execute a transaction is the `scripts/setStakingContract.ts` file.

#### Verify a transaction

To just verify a transaction, you need to run:

```typescript
const transaction = await generic(contractAddress, contractInterface, contractFunctionToCall, [contractParameters]
])
```

This will generate in your terminal the hex data that is printed on Gnosis

#### Push a transaction to Gnosis

Simply run:

```typescript
await submit(transaction, gnosisNonceOfTheTx)
```

Make sure that your `.env` is correctly set for this

#### Executing a transaction

This only works for the moment for Gnosis which require 2/3 signatures. You need to execute:

```typescript
await execute(transaction, safeTxHashOnGnosis)
```

## Changing Network

To change the network, you need to remplace `mainnet` in the `./scripts/utils.ts` file by your desired network.
