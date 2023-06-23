import { ChainId } from '@angleprotocol/sdk';

export function getSafeAPI(chainId: string) {
  const chainName = ChainId[chainId].toLowerCase();
  const safeAPI = `https://safe-transaction-${chainName}.safe.global/api/v1`;
  return safeAPI;

}
