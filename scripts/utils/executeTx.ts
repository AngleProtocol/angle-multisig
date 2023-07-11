import { ethers } from 'hardhat'
import { BigNumber } from 'ethers'

export const executeTx = async (txn: any): Promise<any> => {
  const { deployer } = await ethers.getNamedSigners()

  const safeInterface = new ethers.utils.Interface([
    'function execTransaction(address to, uint256 value, bytes calldata data, uint8 operation, uint256 safeTxGas, uint256 baseGas, uint256 gasPrice, address gasToken, address payable refundReceiver, bytes memory signatures) public payable returns (bool success)',
  ])
  const safeAddress: string = process.env.SAFE
  // const safeAddress = '0x102E1E2ad46eC416E0E01bC5a435538155A35b8D'
  console.log(safeAddress)
  const safeContract = new ethers.Contract(safeAddress, safeInterface, deployer)
  console.log(deployer.address)
  console.log(txn)

  // =============== Simulation code ====================
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
