import { submit } from './utils/submitTx';
import transactionJson from '../scripts/foundry/transaction.json';

async function main() {
  const chainId = transactionJson['chainId'];
  delete transactionJson['additionalData'];
  console.log(transactionJson);
  const safeAddress = transactionJson['safe'];
  if(!safeAddress) throw new Error('Safe address not found');

  await submit(transactionJson, 52, chainId, safeAddress);
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});
