# Angle Multisig

This repo contains the scripts that can be used to push transaction to the multisig on Gnosis

The `addDelegate.py` file helps to add a delegate to a Gnosis Safe. A delegate is an address that can propose transactions to a Gnosis Safe, it does not have any on-chain right. The delegate address just has the right to mess up with the portal of waiting transactions associated to a safe. There are some other utility functions in this file.

The reason for introducing a delegate is that the address of the delegate can be unsafe and its private key can be stored in clear (because it never directly interacts with the blockchain). In the multisig, most addresses are going to be Ledger for which you do not want to store the private key, even on a GitHub repo.

The file to execute to push transactions on Gnosis is `scripts/main.ts` through the `yarn execute` command.

Data should be modified at the main in the `main.ts` file to pass the transactions of your choice.

If you just want to look at the data of a transaction without pushing the transaction on Gnosis, you should comment the `submitTx` line in `main.ts`.
