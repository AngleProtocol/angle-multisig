import { submit } from './utils/submitTx'
import transactionJson from '../scripts/foundry/transaction.json';

async function main() {
  console.log(transactionJson)
  await submit(transactionJson)
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
