import { submit } from './utils/submitTx'
import transactionJson from '../scripts/foundry/transaction.json';

async function main() {
  const chainId = transactionJson["chainId"];
  delete transactionJson["chainId"];
  console.log(transactionJson);
  await submit(transactionJson,0, chainId)
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
