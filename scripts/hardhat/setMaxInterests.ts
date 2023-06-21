import { generic } from "../utils";
import { parseAmount } from "./bignumber";
import { submit } from "../utils/submitTx";

import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from "@angleprotocol/sdk";
import { BigNumber } from "ethers";

async function main() {
  const collaterals = ["USDC", "DAI"] as const;
  const MAX_UINT = BigNumber.from("2")
    .pow(BigNumber.from("256"))
    .sub(BigNumber.from("1"));
  console.log(`Max uint ${MAX_UINT}`);
  const stableMasterInterface = Interfaces.StableMasterFront_Interface;
  const stableMasterAddress =
    CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.StableMaster;
  const functionName = "setCapOnStableAndMaxInterests";

  let nonce = 19;
  for (const col of collaterals) {
    const maxInterests = parseAmount[col.toLowerCase()](1000);
    console.log(`Max interest for ${col} will be set to ${maxInterests}`);
    const poolManagerAddress =
      CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals[col].PoolManager;
    console.log(`Preparing transaction to set max interest ${col}`);
    const baseTxnUpdateMaxInterest = await generic(
      stableMasterAddress,
      stableMasterInterface,
      functionName,
      [MAX_UINT, maxInterests, poolManagerAddress]
    );
    console.log("");
    console.log("------------------------------------------------");
    console.log("");

    console.log(`Submitting transaction to set max interest for ${col}`);
    await submit(baseTxnUpdateMaxInterest, nonce);
    nonce += 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
