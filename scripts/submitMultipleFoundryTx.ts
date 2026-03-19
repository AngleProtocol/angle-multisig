import { submit } from './utils/submitTx';
import { getSafeAPI } from './utils/constants';
import * as fs from 'fs';
import * as path from 'path';

const transactionsJson = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'foundry/transactions.json'), 'utf-8')
);

// Filter to specific chains. Empty array = all chains.
const TARGET_CHAINS: number[] = [
  // 151,      // REDBELLY
  239,      // TAC
  714,      // EDEN
  747,      // FLOW
  1135,     // LISK
  1868,     // SONEIUM
  1923,     // SWELL
  2020,     // RONIN
  4114,     // CITREA
  4217,     // TEMPO
  5064014,  // ETHEREAL
  13371,    // IMMUTABLE
  // 16661,    // ZERO_G — has safe.global API
  21000000, // CORN
  31612,    // MEZO
  33139,    // APECHAIN
  34443,    // MODE
  42793,    // ETHERLINK
  81457,    // BLAST
  167000,   // TAIKO
  685689,   // GENSYN
  747474,   // KATANA
];

const outDir = path.join(__dirname, 'foundry', 'tx-builder');

// Safe UI shortnames for tx-builder URL generation
// Sourced from merkl/packages/sdk/src/constants/merkl/multisigs.ts
const SAFE_UI: Record<number, { base: string; prefix: string }> = {
  1: { base: 'https://app.safe.global', prefix: 'eth' },
  10: { base: 'https://app.safe.global', prefix: 'oeth' },
  30: { base: 'https://safe.rootstock.io', prefix: 'rsk' },
  50: { base: 'https://app.safe.global', prefix: 'xdc' },
  56: { base: 'https://app.safe.global', prefix: 'bnb' },
  100: { base: 'https://app.safe.global', prefix: 'gno' },
  122: { base: 'https://safe.fuse.io', prefix: 'fuse' },
  130: { base: 'https://app.safe.global', prefix: 'unichain' },
  137: { base: 'https://app.safe.global', prefix: 'pol' },
  143: { base: 'https://app.safe.global', prefix: 'monad' },
  146: { base: 'https://app.safe.global', prefix: 'sonic' },
  151: { base: 'https://safeglobal.mainnet.redbelly.network', prefix: 'RBN' },
  169: { base: 'https://safe.manta.network', prefix: 'manta' },
  196: { base: 'https://safe.xlayer.tech', prefix: 'xlayer' },
  239: { base: 'https://safe.tac.build', prefix: 'tac' },
  250: { base: 'https://safe.fantom.network', prefix: 'ftm' },
  252: { base: 'https://safe.mainnet.frax.com', prefix: 'fraxtal' },
  324: { base: 'https://app.safe.global', prefix: 'zksync' },
  480: { base: 'https://app.safe.global', prefix: 'wc' },
  592: { base: 'https://safe.astar.network', prefix: 'astr' },
  714: { base: 'https://edensafe.celestia.org', prefix: 'eden' },
  747: { base: 'https://safe.flow.com', prefix: 'flow-mainnet' },
  988: { base: 'https://app.safe.global', prefix: 'stable' },
  1101: { base: 'https://app.safe.global', prefix: 'zkevm' },
  1135: { base: 'https://safe.optimism.io', prefix: 'lisk' },
  1284: { base: 'https://multisig.moonbeam.network', prefix: 'mbeam' },
  1329: { base: 'https://sei-safe.protofire.io', prefix: 'sei' },
  1868: { base: 'https://safe.optimism.io', prefix: 'soneium' },
  1923: { base: 'https://safe.optimism.io', prefix: 'swell-l2' },
  2020: { base: 'https://ronin.safe.onchainden.com', prefix: 'ronin' },
  4114: { base: 'https://staging.safe.citrea.xyz', prefix: 'citrea-mainnet' },
  4217: { base: 'https://app.test.safe.protofire.io', prefix: 'tempo' },
  5000: { base: 'https://multisig.mantle.xyz', prefix: 'mantle' },
  5064014: { base: 'https://safe.ethereal.trade', prefix: 'ethereal' },
  8453: { base: 'https://app.safe.global', prefix: 'base' },
  13371: { base: 'https://safe.immutable.com', prefix: 'imx' },
  16661: { base: 'https://app.safe.global', prefix: '0g' },
  21000000: { base: 'https://safe.usecorn.com', prefix: 'corn' },
  31612: { base: 'https://safe.mezo.org', prefix: 'mezo' },
  33139: { base: 'https://safe.apechain.com', prefix: 'ape' },
  34443: { base: 'https://safe.optimism.io', prefix: 'mode' },
  42161: { base: 'https://app.safe.global', prefix: 'arb' },
  42220: { base: 'https://app.safe.global', prefix: 'celo' },
  42793: { base: 'https://safe.etherlink.com', prefix: 'etherlink' },
  43111: { base: 'https://safe.hemi.xyz', prefix: 'hemi' },
  43114: { base: 'https://wallet.ash.center', prefix: 'avax' },
  48900: { base: 'https://safe.zircuit.com', prefix: 'zircuit-mainnet' },
  57073: { base: 'https://app.safe.global', prefix: 'ink' },
  59144: { base: 'https://safe.linea.build', prefix: 'linea' },
  60808: { base: 'https://safe.gobob.xyz', prefix: 'bob' },
  80094: { base: 'https://safe.berachain.com', prefix: 'berachain' },
  81457: { base: 'https://app.safe.protofire.io', prefix: 'blastmainnet' },
  167000: { base: 'https://safe.taiko.xyz', prefix: 'tko-mainnet' },
  534352: { base: 'https://app.safe.global', prefix: 'scr' },
  685689: { base: 'https://app.safe.global', prefix: 'gensyn' },
  747474: { base: 'https://safe.katana.network', prefix: 'katana' },
};

function getSafeUIUrl(chainId: number, safeAddress: string): string | null {
  const ui = SAFE_UI[chainId];
  if (!ui) return null;
  return `${ui.base}/apps/open?safe=${ui.prefix}:${safeAddress}&appUrl=https%3A%2F%2Fapps-portal.safe.global%2Ftx-builder`;
}

function findInternalTxIndex(chainId: number, safeAddress: string): string | null {
  for (const [key, val] of Object.entries(transactionsJson.internalTransactions) as [string, any][]) {
    if (val.chainId === chainId && val.safe === safeAddress) return key;
  }
  return null;
}

function writeTxBuilderJson(chainId: number, safeAddress: string): string | null {
  const internalIdx = findInternalTxIndex(chainId, safeAddress);
  if (internalIdx === null) return null;

  const internal = transactionsJson.internalTransactions[internalIdx];
  const txCount = Object.keys(internal.data).length;

  const safeUrl = getSafeUIUrl(chainId, safeAddress);

  const batch = {
    version: '1.0',
    chainId: chainId.toString(),
    createdAt: Math.floor(Date.now() / 1000),
    meta: {
      name: 'Add Signers & Update Threshold',
      description: `Add new signers to Safe ${safeAddress} and update threshold to 4/6`,
      txBuilderVersion: '1.16.5',
      safeUI: safeUrl,
    },
    transactions: Array.from({ length: txCount }, (_, j) => ({
      to: internal.to[j.toString()],
      value: '0',
      data: internal.data[j.toString()],
      contractMethod: {
        name: 'addOwnerWithThreshold',
        payable: false,
        inputs: [
          { name: 'owner', type: 'address', internalType: 'address' },
          { name: '_threshold', type: 'uint256', internalType: 'uint256' },
        ],
      },
      contractInputsValues: null,
    })),
  };

  const filePath = path.join(outDir, `chain_${chainId}.json`);
  fs.writeFileSync(filePath, JSON.stringify(batch, null, 2));
  return filePath;
}

async function main() {
  if (TARGET_CHAINS.length > 0) {
    console.log(`Targeting chains: ${TARGET_CHAINS.join(', ')}\n`);
  }

  fs.mkdirSync(outDir, { recursive: true });

  const manualChains: { chainId: number; file: string; url: string | null }[] = [];
  const processed = new Set<number>();
  const txCount = Object.keys(transactionsJson.transaction.chainId).length;

  for (let i = 0; i < txCount; i++) {
    const idx = i.toString();
    const chainId = transactionsJson.transaction.chainId[idx];

    if (TARGET_CHAINS.length > 0 && !TARGET_CHAINS.includes(chainId)) continue;
    if (processed.has(chainId)) continue;
    processed.add(chainId);

    const safeAddress = transactionsJson.transaction.safe[idx];
    const safeAPI = getSafeAPI(chainId);

    // Try API submission if available
    if (safeAPI) {
      try {
        await submit(
          {
            data: transactionsJson.transaction.data[idx],
            to: transactionsJson.transaction.to[idx],
            value: transactionsJson.transaction.value[idx],
            operation: transactionsJson.transaction.operation[idx],
          },
          0,
          chainId,
          safeAddress,
        );
        console.log(`Chain ${chainId}: submitted successfully`);
        continue;
      } catch (e) {
        console.log(`Chain ${chainId}: API submission failed, falling back to tx-builder JSON`);
      }
    }

    // Fallback: generate tx-builder JSON
    const filePath = writeTxBuilderJson(chainId, safeAddress);
    if (filePath) {
      const safeUrl = getSafeUIUrl(chainId, safeAddress);
      manualChains.push({ chainId, file: filePath, url: safeUrl });
      console.log(`Chain ${chainId}: tx-builder JSON written to ${filePath}`);
    } else {
      console.log(`Chain ${chainId}: no internal transactions found`);
    }
  }

  if (manualChains.length > 0) {
    console.log(`\n=== ${manualChains.length} chains need manual submission via Safe Transaction Builder ===`);
    for (const { chainId, file, url } of manualChains) {
      console.log(`  Chain ${chainId}:`);
      console.log(`    JSON: ${file}`);
      if (url) console.log(`    Safe: ${url}`);
    }
  }
}

main().catch(error => {
  console.error(error);
  process.exit(1);
});
