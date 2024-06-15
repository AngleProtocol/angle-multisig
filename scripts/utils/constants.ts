import { ChainId } from '@angleprotocol/sdk';

export function getSafeAPI(chainId: number) {
  let chainName = ChainId[chainId].toLowerCase();
  if(chainName === 'gnosis') chainName = 'gnosis-chain';
  if (chainName === 'polygonzkevm') chainName = 'zkevm';
  const safeAPI = `https://safe-transaction-${chainName}.safe.global/api/v1`;
  return safeAPI;
}
