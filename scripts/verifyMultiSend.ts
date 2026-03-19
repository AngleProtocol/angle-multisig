import { ethers } from 'ethers';

// eRPC: if ERPC_URL is set, use it as primary RPC for all chains
const ERPC_URL = process.env.ERPC_URL;

// MultiSend addresses to check
const MULTISEND_V141_A = '0x40A2aCCbd92BCA938b02010E17A5b8929b49130D';
const MULTISEND_V141_B = '0xA1dabEF33b3B82c7814B6D82A79e50F4AC44102B';
const MULTISEND_DEFAULT = '0xA238CBeb142c10Ef7Ad8442C6D1f9E89e07e7761';

// Chain ID -> assigned MultiSend in AddSigners.s.sol
function getAssignedMultiSend(chainId: number): string {
  if ([1, 42161, 137, 43114, 100, 56, 1101, 59144, 34443, 81457, 196, 534352].includes(chainId)) {
    return MULTISEND_V141_A;
  }
  if ([10, 8453, 42220, 5000].includes(chainId)) {
    return MULTISEND_V141_B;
  }
  return MULTISEND_DEFAULT;
}

// All chain/safe pairs from AddSigners.s.sol
const CHAIN_SAFES: [number, string][] = [
  [1, '0x529619a10129396a2F642cae32099C1eA7FA2834'],
  [10, '0x17a7F6a839fea3b716b43f9414ffc93131878BD2'],
  [30, '0x8b449bd5936B1A056D89eDe011075fa2906B2F94'],
  [50, '0x496F1674d7E35440931A32548dB1064eef315257'],
  [56, '0x2Dd2290EabdB5654609352Cc267C9BAc82d01877'],
  [100, '0xf4b426A9849933c83041D6554cb39955ddA5c767'],
  [108, '0xb08AB4332AD871F89da24df4751968A61e58013c'],
  [122, '0x167f9bAF9B6C45370E7C5032557E6500cda37328'],
  [130, '0xEa4d19e9c2A3FAf206cf7BB1A29B9AAE8E9FAA3d'],
  [137, '0xc0c07644631543c3af2fA7230D387C5fA418a131'],
  [143, '0xa493b938a3C6F5a4801861397D76AF4cD09a2d91'],
  [146, '0x3B1CE275D2de4F82cE0d7487571EA047EC86dBF3'],
  [151, '0x5445006E0117fd0fA2f795Cc1b99557Edfc17d8D'],
  [169, '0x9A40Ed6Af46EdFccBAf26425E6c8E23590C4762B'],
  [196, '0xAFebb5bA21a29a8C0Cf78e3CdE2552DFD4a6cc3E'],
  [239, '0x4D5cd2a35e7B55397c912104671d61274653FddF'],
  [250, '0x8b449bd5936B1A056D89eDe011075fa2906B2F94'],
  [252, '0xEa4d19e9c2A3FAf206cf7BB1A29B9AAE8E9FAA3d'],
  [314, '0x916685b590233bA10C0B52b3FAE6B0e75e9Ab477'],
  [324, '0x3d3Fd37af3aEaBD0154230AdcfC9C177E13142c8'],
  [480, '0xC760C15AeCB840084F2eb4906E3E5A8dbA667742'],
  [592, '0x15416200C0846a58C0a494fEd93362853dC90907'],
  [714, '0xb9d5A0e3aD4892A8c1672a3365c27cf63F19d086'],
  [747, '0xA03Dc150972D555939E1c22860F56e9C19F33264'],
  [988, '0x4Fa58741a0cc2b166D589Ad6B0825Bf04c3dC7B0'],
  [999, '0xb08AB4332AD871F89da24df4751968A61e58013c'],
  [1101, '0x9439B96E39dA5AD7EAA75d7a136383D1D9737055'],
  [1116, '0xb08AB4332AD871F89da24df4751968A61e58013c'],
  [1135, '0x4D5cd2a35e7B55397c912104671d61274653FddF'],
  [1284, '0x8b449bd5936B1A056D89eDe011075fa2906B2F94'],
  [1329, '0x8b449bd5936B1A056D89eDe011075fa2906B2F94'],
  [1868, '0xf30cfD00fA4c48B42ED41f4284a15aCec6755839'],
  [1923, '0x83bbEF66a3E6732bF8d1AD55F016c02D876464eA'],
  [2020, '0x8b449bd5936B1A056D89eDe011075fa2906B2F94'],
  [4114, '0x4D5cd2a35e7B55397c912104671d61274653FddF'],
  [4217, '0x4D5cd2a35e7B55397c912104671d61274653FddF'],
  [4326, '0xb08AB4332AD871F89da24df4751968A61e58013c'],
  [5000, '0xe5cFa764F35eB0Ce24b4599EDd50882C1833d20F'],
  [5464, '0xb08AB4332AD871F89da24df4751968A61e58013c'],
  [6900, '0xb08AB4332AD871F89da24df4751968A61e58013c'],
  [8453, '0x19c41F6607b2C0e80E84BaadaF886b17565F278e'],
  [9745, '0xb08AB4332AD871F89da24df4751968A61e58013c'],
  [10242, '0xb08AB4332AD871F89da24df4751968A61e58013c'],
  [13371, '0xA82cc51D3d5723c0534C8A8476d740d0288099cb'],
  [16661, '0xa493b938a3C6F5a4801861397D76AF4cD09a2d91'],
  [31612, '0x496F1674d7E35440931A32548dB1064eef315257'],
  [33139, '0x4848C097AC3f84D06870438F9D17016AbDe90FB4'],
  [34443, '0x222D18309000BDCB4261F746Af48C9Ea84B8c532'],
  [42161, '0x3350bef226F7BdCA874C5561320aB7EF9DC89E70'],
  [42220, '0xEa4d19e9c2A3FAf206cf7BB1A29B9AAE8E9FAA3d'],
  [42793, '0x1D4Bb009e38411d8621caa51CFe774725fF0049c'],
  [43111, '0xf30cfD00fA4c48B42ED41f4284a15aCec6755839'],
  [43114, '0xC493c5Fec851768deEB8F5ecba213e204A7256b6'],
  [48900, '0x496F1674d7E35440931A32548dB1064eef315257'],
  [57073, '0x2c1D5ab89D636d8D6a3B9aA05D0A1ff7eAbd31A7'],
  [59144, '0x65e043c894F15A899FD18d454BeeAd577e792B81'],
  [60808, '0xEa4d19e9c2A3FAf206cf7BB1A29B9AAE8E9FAA3d'],
  [80094, '0x97e7BD8342C171212FEfD2C236F0f10Be0736243'],
  [81457, '0xb2846F05b58c8e29Aa971297A04aA947CF89cC46'],
  [98866, '0xb08AB4332AD871F89da24df4751968A61e58013c'],
  [167000, '0xEa4d19e9c2A3FAf206cf7BB1A29B9AAE8E9FAA3d'],
  [534352, '0x700714a7Dc596295aACC7b09D4b9BcE2c3A1Ec2C'],
  [685689, '0x3F12CB2F811F61e3425C3DE180975F9ED683FD55'],
  [747474, '0x496F1674d7E35440931A32548dB1064eef315257'],
  [1440000, '0xb08AB4332AD871F89da24df4751968A61e58013c'],
  [5064014, '0x4D5cd2a35e7B55397c912104671d61274653FddF'],
  [21000000, '0x5375C79ffB31981b92defAF334AA382704E24fFf'],
  [2046399126, '0xb08AB4332AD871F89da24df4751968A61e58013c'],
];

// Public RPC endpoints by chain ID
const PUBLIC_RPCS: Record<number, string> = {
  1: 'https://eth.llamarpc.com',
  10: 'https://mainnet.optimism.io',
  30: 'https://public-node.rsk.co',
  50: 'https://rpc.xinfin.network',
  56: 'https://bsc-dataseed.binance.org',
  100: 'https://rpc.gnosischain.com',
  108: 'https://mainnet-rpc.thundercore.com',
  122: 'https://rpc.fuse.io',
  130: 'https://mainnet.unichain.org',
  137: 'https://polygon-rpc.com',
  143: 'https://mainnet.tracing.ternoa.dev',
  146: 'https://rpc.soniclabs.com',
  151: 'https://mainnet.redbelly.network/rpc',
  169: 'https://pacific-rpc.manta.network/http',
  196: 'https://rpc.xlayer.tech',
  239: 'https://rpc.linea.build',
  250: 'https://rpc.ftm.tools',
  252: 'https://rpc.frax.com',
  314: 'https://api.node.glif.io',
  324: 'https://mainnet.era.zksync.io',
  480: 'https://worldchain-mainnet.g.alchemy.com/public',
  592: 'https://rpc.astar.network:8545',
  714: 'https://mainnet-rpc.shentu.org',
  747: 'https://mainnet.flow.com/v1',
  988: 'https://mainnet.mezo.org/rpc',
  999: 'https://mainnet-rpc.zeta.network',
  1101: 'https://zkevm-rpc.com',
  1116: 'https://rpc.coredao.org',
  1135: 'https://rpc.lisk.com',
  1284: 'https://rpc.api.moonbeam.network',
  1329: 'https://evm-rpc.sei-apis.com',
  1868: 'https://rpc.superposition.so',
  1923: 'https://rpc.swell.network',
  2020: 'https://api.roninchain.com/rpc',
  4114: 'https://rpc.eden.celestia.org',
  4217: 'https://rpc.ethereal.trade',
  4326: 'https://tac-mainnet.rpc.caldera.xyz/http',
  5000: 'https://rpc.mantle.xyz',
  5464: 'https://rpc.mainnet.gensyn.ai',
  6900: 'https://rpc.mainnet.katana.network',
  8453: 'https://mainnet.base.org',
  9745: 'https://rpc.megaeth.com',
  10242: 'https://node.mainnet.etherlink.com',
  13371: 'https://mainnet.immutable.com',
  16661: 'https://rpc.citrea.xyz',
  31612: 'https://rpc.mainnet.monad.xyz',
  33139: 'https://rpc.apechain.com',
  34443: 'https://mainnet.mode.network',
  42161: 'https://arb1.arbitrum.io/rpc',
  42220: 'https://forno.celo.org',
  42793: 'https://rpc.etherlink.com',
  43111: 'https://rpc.hemi.network/rpc',
  43114: 'https://api.avax.network/ext/bc/C/rpc',
  48900: 'https://rpc.zircuit.com',
  57073: 'https://rpc.ink.xyz',
  59144: 'https://rpc.linea.build',
  60808: 'https://rpc.gobob.xyz',
  80094: 'https://bera-rpc.publicnode.com',
  81457: 'https://rpc.blast.io',
  98866: 'https://rpc.stable.money',
  167000: 'https://rpc.taiko.xyz',
  534352: 'https://rpc.scroll.io',
  685689: 'https://rpc.zero.network',
  747474: 'https://rpc.mainnet.tempo.xyz',
  1440000: 'https://rpc.xrplevm.org',
  5064014: 'https://rpc-zero.0g.ai',
  21000000: 'https://rpc.corechain.com',
  2046399126: 'https://mainnet.skalenodes.com/v1/europa',
};

async function checkCode(provider: ethers.providers.JsonRpcProvider, address: string): Promise<boolean> {
  try {
    const code = await provider.getCode(address);
    return code !== '0x' && code !== '0x0' && code.length > 2;
  } catch {
    return false;
  }
}

async function checkChain(chainId: number, safeAddress: string): Promise<{
  chainId: number;
  rpcOk: boolean;
  safeOk: boolean;
  multiSendAddress: string;
  multiSendOk: boolean;
  alternates: string[];
}> {
  // Prefer eRPC if available, fallback to public RPCs
  const rpcUrl = ERPC_URL ? `${ERPC_URL}/${chainId}` : PUBLIC_RPCS[chainId];
  const multiSendAddress = getAssignedMultiSend(chainId);
  const result = {
    chainId,
    rpcOk: false,
    safeOk: false,
    multiSendAddress,
    multiSendOk: false,
    alternates: [] as string[],
  };

  if (!rpcUrl) {
    return result;
  }

  const provider = new ethers.providers.JsonRpcProvider({ url: rpcUrl, timeout: 10000 });

  try {
    // Check safe has code (validates RPC + safe exists)
    result.safeOk = await checkCode(provider, safeAddress);
    result.rpcOk = true;
  } catch {
    return result;
  }

  // Check assigned MultiSend
  result.multiSendOk = await checkCode(provider, multiSendAddress);

  // If assigned doesn't work, check all 3 addresses
  if (!result.multiSendOk) {
    const all = [MULTISEND_V141_A, MULTISEND_V141_B, MULTISEND_DEFAULT];
    for (const addr of all) {
      if (addr !== multiSendAddress) {
        const ok = await checkCode(provider, addr);
        if (ok) result.alternates.push(addr);
      }
    }
  }

  return result;
}

async function main() {
  console.log('Verifying MultiSend deployments on all chains...\n');

  // Process in batches of 10 to avoid overwhelming
  const batchSize = 10;
  const allResults: Awaited<ReturnType<typeof checkChain>>[] = [];

  for (let i = 0; i < CHAIN_SAFES.length; i += batchSize) {
    const batch = CHAIN_SAFES.slice(i, i + batchSize);
    const results = await Promise.all(batch.map(([chainId, safe]) => checkChain(chainId, safe)));
    allResults.push(...results);
    process.stdout.write(`  checked ${Math.min(i + batchSize, CHAIN_SAFES.length)}/${CHAIN_SAFES.length} chains\r`);
  }

  console.log('\n');

  // Report
  const ok: number[] = [];
  const noRpc: number[] = [];
  const noSafe: number[] = [];
  const wrongMultiSend: { chainId: number; assigned: string; alternates: string[] }[] = [];
  const noMultiSend: number[] = [];

  for (const r of allResults) {
    if (!r.rpcOk) {
      noRpc.push(r.chainId);
    } else if (!r.safeOk) {
      noSafe.push(r.chainId);
    } else if (r.multiSendOk) {
      ok.push(r.chainId);
    } else if (r.alternates.length > 0) {
      wrongMultiSend.push({ chainId: r.chainId, assigned: r.multiSendAddress, alternates: r.alternates });
    } else {
      noMultiSend.push(r.chainId);
    }
  }

  console.log(`OK (${ok.length}): ${ok.join(', ')}`);
  console.log('');

  if (noRpc.length > 0) {
    console.log(`NO RPC / RPC FAILED (${noRpc.length}): ${noRpc.join(', ')}`);
    console.log('');
  }

  if (noSafe.length > 0) {
    console.log(`SAFE NOT FOUND (${noSafe.length}): ${noSafe.join(', ')}`);
    console.log('');
  }

  if (wrongMultiSend.length > 0) {
    console.log(`WRONG MULTISEND ADDRESS (${wrongMultiSend.length}):`);
    for (const w of wrongMultiSend) {
      console.log(`  Chain ${w.chainId}: assigned ${w.assigned}, but found at: ${w.alternates.join(', ')}`);
    }
    console.log('');
  }

  if (noMultiSend.length > 0) {
    console.log(`NO MULTISEND FOUND AT ANY ADDRESS (${noMultiSend.length}): ${noMultiSend.join(', ')}`);
    console.log('');
  }
}

main().catch(console.error);
