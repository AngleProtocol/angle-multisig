import { submit } from './utils/submitTx';
import transactionsJson from './foundry/transactions.json';
import { registry } from '@angleprotocol/sdk';

async function main() {
  for (let i = 0; i < Object.keys(transactionsJson.chainId).length; i++) {
    const chainId = transactionsJson['chainId'][i.toString()];
    const data = transactionsJson['data'][i.toString()];
    const to = transactionsJson['to'][i.toString()];
    const value = transactionsJson['value'][i.toString()];
    const operation = transactionsJson['operation'][i.toString()];
    const safeAddress = transactionsJson['safe'][i.toString()];
    const transaction = {
      chainId,
      data,
      to,
      value,
      operation,
    }
    await submit(transaction, 0, chainId, safeAddress);
  }
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});
