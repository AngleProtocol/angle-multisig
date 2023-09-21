# Angle Multisig

This repo contains scripts to push transaction to multisigs associated to Angle Protocol on Gnosis.
More generally, signers of multisig can also use this repo to check that the transactions they see on the Gnosis Safe interface on the front correspond to what they expect.

## Getting started

### Install Foundry

If you don't have Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash

source /root/.zshrc
# or, if you're under bash: source /root/.bashrc

foundryup
```

To install the standard library:

```bash
forge install foundry-rs/forge-std
```

To update libraries:

```bash
forge update
```

### Install packages

You can install all dependencies by running

```bash
yarn
forge i
```

## Setup environment

Create a `.env` file from the template file `.env.example`.
If you don't define URI and mnemonics, default mnemonic will be used with a brand new local hardhat node.

This repo can be used to interact with different Gnosis Safe. If so, you would need to have one specific `.env` file per safe.

## Gnosis interactions

### Add Delegate

The `addDelegate.py` file helps to add a delegate to a Gnosis Safe. A delegate is an address that can propose transactions to a Gnosis Safe, it does not have any on-chain right. The delegate address just has the right to mess up with the portal of waiting transactions associated to a safe. There are some other utility functions in this file.

The reason for introducing a delegate is that the address of the delegate can be unsafe and its private key can be stored in clear (because it never directly interacts with the blockchain). In the multisig, most addresses are going to be Ledger for which you do not want to store the private key, even on a GitHub repo.

### Scripts: Propose and Verify

You can run a script with

```bash
yarn script:fork
```

which will generate an object in `scripts/foundry/transaction.json` with properties: chainId, data,operation,to,value. These are required to pass a transaction on Gnosis Safe.

Some scripts need to make on chain calls, so you should run beforehand:

```bash
yarn fork:{CHAIN_NAME}
```

#### Push a transaction to Gnosis

Simply run:

```bash
yarn submit:foundry
```

Make sure that your `.env` is correctly set for this and that you have the right values in `scripts/foundry/transaction.json`

#### Executing a transaction

This only works for the moment for Gnosis which require 2/3 signatures. You need to execute:

```typescript
await execute(transaction, safeTxHashOnGnosis);
```

## Changing Network

To change the network, you need to remplace `mainnet` in the `./scripts/utils.ts` file by your desired network.
