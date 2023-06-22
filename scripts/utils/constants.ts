import { ChainId } from "@angleprotocol/sdk"

const chainName = ChainId[process.env.CHAIN_ID].toLowerCase()

export const SAFE_API = `https://safe-transaction-${chainName}.safe.global/api/v1`