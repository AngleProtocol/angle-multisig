import { submit } from './utils/submitTx';
import transactionJson from '../scripts/foundry/transaction.json';
import { registry } from '@angleprotocol/sdk';

async function main() {
  const chainId = transactionJson['chainId'];
  delete transactionJson['additionalData'];
  console.log(transactionJson);
  // TODO need to change the destination safe
  const safeAddress = transactionJson['safe'] ?? registry(chainId).Governor;
  await submit(transactionJson, 0, chainId, safeAddress);
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});
