import { submit } from './utils/submitTx';
import transactionsJson from './foundry/transactions.json';

async function main() {
  for (let i = 0; i < Object.keys(transactionsJson.transaction.chainId).length; i++) {
    const chainId = transactionsJson.transaction['chainId'][i.toString()];
    const data = transactionsJson.transaction['data'][i.toString()];
    const to = transactionsJson.transaction['to'][i.toString()];
    const value = transactionsJson.transaction['value'][i.toString()];
    const operation = transactionsJson.transaction['operation'][i.toString()];
    const safeAddress = transactionsJson.transaction['safe'][i.toString()];
    const transaction = {
      chainId,
      data,
      to,
      value,
      operation,
    }
    try {
      await submit(transaction, 0, chainId, safeAddress);
    } catch (e) {
      console.log(`Try to submit these txs using the interface: ${chainId}`);
    }
  }
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});
