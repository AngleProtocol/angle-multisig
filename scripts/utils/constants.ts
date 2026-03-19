/**
 * Returns the Safe Transaction Service API URL for a given chain.
 * Returns null if the chain has no known Transaction Service.
 *
 * Chain names sourced from: merkl/packages/resources/enums/chainId.ts
 * URLs verified against live endpoints on 2026-03-19.
 */
export function getSafeAPI(chainId: number): string | null {
  // Verified safe.global Transaction Service endpoints
  const safeGlobal: Record<number, string> = {
    1: 'mainnet',         // ETHEREUM
    10: 'optimism',       // OPTIMISM
    50: 'xdc',            // XDC
    56: 'bsc',            // BSC
    100: 'gnosis-chain',  // GNOSIS
    130: 'unichain',      // UNICHAIN
    137: 'polygon',       // POLYGON
    143: 'monad',         // MONAD
    146: 'sonic',         // SONIC
    196: 'xlayer',        // XLAYER
    324: 'zksync',        // ZKSYNC
    480: 'worldchain',    // WORLDCHAIN
    988: 'stable',        // STABLE
    1101: 'zkevm',        // POLYGONZKEVM
    5000: 'mantle',       // MANTLE
    8453: 'base',         // BASE
    42161: 'arbitrum',    // ARBITRUM
    42220: 'celo',        // CELO
    43114: 'avalanche',   // AVALANCHE
    57073: 'ink',         // INK
    59144: 'linea',       // LINEA
    80094: 'berachain',   // BERACHAIN
    534352: 'scroll',     // SCROLL
    16661: '0g',          // ZERO_G
  };

  if (safeGlobal[chainId]) {
    return `https://safe-transaction-${safeGlobal[chainId]}.safe.global/api/v1`;
  }

  // Verified custom Transaction Service endpoints
  const customAPIs: Record<number, string> = {
    30: 'https://transaction.safe.rootstock.io/api/v1',           // ROOTSTOCK
    122: 'https://safe.fuse.io/txs/api/v1',                      // FUSE
    169: 'https://transaction.safe.manta.network/api/v1',         // MANTA
    250: 'https://safe-txservice.fantom.network/api/v1',          // FANTOM
    252: 'https://safe.mainnet.frax.com/txs/api/v1',             // FRAXTAL
    592: 'https://transaction.safe.astar.network/api/v1',         // ASTAR
    1284: 'https://transaction.multisig.moonbeam.network/api/v1', // MOONBEAM
    1329: 'https://sei-safe.protofire.io/txs/api/v1',            // SEI
    43111: 'https://safe-transaction-hemi.safe.global/api/v1',    // HEMI
    48900: 'https://safe.zircuit.com/txs/api/v1',                // ZIRCUIT
    60808: 'https://safe.gobob.xyz/txs/api/v1',                  // BOB
  };

  if (customAPIs[chainId]) {
    return customAPIs[chainId];
  }

  // No public Transaction Service API — use tx-builder JSON + Safe UI
  // Includes chains using Safe Client Gateway only (no direct TX service)
  return null;
}
