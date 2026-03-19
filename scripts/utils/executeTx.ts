import { ethers, BigNumber } from 'ethers'

export const executeTx = async (txn: any): Promise<any> => {
  const provider = new ethers.providers.JsonRpcProvider(process.env.ETH_NODE_URI_FORK || process.env.ERPC_URL);
  const deployer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

  const safeInterface = new ethers.utils.Interface([
    'function execTransaction(address to, uint256 value, bytes calldata data, uint8 operation, uint256 safeTxGas, uint256 baseGas, uint256 gasPrice, address gasToken, address payable refundReceiver, bytes memory signatures) public payable returns (bool success)',
  ])
  const safeAddress: string = process.env.SAFE
  console.log(safeAddress)
  const safeContract = new ethers.Contract(safeAddress, safeInterface, deployer)
  console.log(deployer.address)
  console.log(txn)

  const returnVar = await (
    await safeContract
      .connect(deployer)
      .execTransaction(
        txn.to,
        BigNumber.from(txn.value),
        txn.data,
        parseInt(txn.operation),
        parseInt(txn.safeTxGas),
        txn.baseGas,
        txn.gasPrice,
        txn.gasToken,
        txn.refundReceiver,
        txn.signature,
      )
  ).wait()
  console.log(returnVar)
  console.log('Success')
}
