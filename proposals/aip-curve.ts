import { ethers } from 'ethers'
import {
  CONTRACTS_ADDRESSES,
  ChainId,
  Interfaces,
  parseAmount,
} from '@angleprotocol/sdk'
import Web3 from 'web3'

const timelockAddress = CONTRACTS_ADDRESSES[ChainId.MAINNET].Timelock
const deployerAddress = '0x2Acd062Cf718c87c9A58382f01C5b51a0f287C8D'

// Define here the required contracts
const ANGLE = new ethers.Contract(
  CONTRACTS_ADDRESSES[ChainId.MAINNET]?.ANGLE as string,
  Interfaces.ANGLE_Interface,
)

const core = new ethers.Contract(
  CONTRACTS_ADDRESSES[ChainId.MAINNET]?.Core as string,
  Interfaces.Core_Interface,
)

const proxyAdmin = new ethers.Contract(
  CONTRACTS_ADDRESSES[ChainId.MAINNET]?.ProxyAdmin as string,
  Interfaces.ProxyAdmin_Interface,
)

const oracleDAI = new ethers.Contract(
  CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals!.DAI?.Oracle as string,
  Interfaces.OracleMulti_Interface,
)

const oracleFEI = new ethers.Contract(
  CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals!.FEI?.Oracle as string,
  Interfaces.OracleMulti_Interface,
)

const oracleFRAX = new ethers.Contract(
  CONTRACTS_ADDRESSES[ChainId.MAINNET].agEUR.collaterals!.FRAX
    ?.Oracle as string,
  Interfaces.OracleMulti_Interface,
)

const GuardianRoleHash = Web3.utils.soliditySha3('GUARDIAN_ROLE')
const multiSigAddress = CONTRACTS_ADDRESSES[ChainId.MAINNET].GovernanceMultiSig
const balanceAngleTimelock = parseAmount.ether(180_000_000).toString()

// Define the required calls

export const calls: { target: string; value: number; callData: string }[] = [
  {
    target: ANGLE.address,
    value: 0,
    callData: ANGLE.interface.encodeFunctionData('transfer', [
      multiSigAddress,
      balanceAngleTimelock,
    ]),
  },
  {
    target: ANGLE.address,
    value: 0,
    callData: ANGLE.interface.encodeFunctionData('setMinter', [
      multiSigAddress,
    ]),
  },
  {
    target: core.address,
    value: 0,
    callData: core.interface.encodeFunctionData('addGovernor', [
      multiSigAddress,
    ]),
  },
  {
    target: core.address,
    value: 0,
    callData: core.interface.encodeFunctionData('removeGovernor', [
      timelockAddress,
    ]),
  },
  {
    target: proxyAdmin.address,
    value: 0,
    callData: proxyAdmin.interface.encodeFunctionData('transferOwnership', [
      deployerAddress,
    ]),
  },
  {
    target: oracleDAI.address,
    value: 0,
    callData: oracleDAI.interface.encodeFunctionData('grantRole', [
      GuardianRoleHash,
      multiSigAddress,
    ]),
  },
  {
    target: oracleDAI.address,
    value: 0,
    callData: oracleDAI.interface.encodeFunctionData('revokeRole', [
      GuardianRoleHash,
      timelockAddress,
    ]),
  },
  {
    target: oracleFEI.address,
    value: 0,
    callData: oracleFEI.interface.encodeFunctionData('grantRole', [
      GuardianRoleHash,
      multiSigAddress,
    ]),
  },
  {
    target: oracleFEI.address,
    value: 0,
    callData: oracleFEI.interface.encodeFunctionData('revokeRole', [
      GuardianRoleHash,
      timelockAddress,
    ]),
  },
  {
    target: oracleFRAX.address,
    value: 0,
    callData: oracleFRAX.interface.encodeFunctionData('grantRole', [
      GuardianRoleHash,
      multiSigAddress,
    ]),
  },
  {
    target: oracleFRAX.address,
    value: 0,
    callData: oracleFRAX.interface.encodeFunctionData('revokeRole', [
      GuardianRoleHash,
      timelockAddress,
    ]),
  },
]

const description = 'ANGLE Tokenomics Improvement'

// Exporting the correct values
const aip = {
  targets: calls.map((call) => call.target),
  values: calls.map((call) => call.value),
  callDatas: calls.map((call) => call.callData),
  description,
}

export default aip
