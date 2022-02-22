import { ethers } from "ethers";
import { CONTRACTS_ADDRESSES, ChainId, Interfaces } from "@angleprotocol/sdk";

// Define here the required contracts
const governor = new ethers.Contract(
  CONTRACTS_ADDRESSES[ChainId.MAINNET].Governor,
  Interfaces.Governor_Interface
);

// Define the required calls
export const calls: { target: string; value: number; callData: string }[] = [
  {
    target: governor.address,
    value: 0,
    callData: governor.interface.encodeFunctionData("setQuorum", [0]),
  },
];

const description = "AIP-0: Example of proposals";

// Exporting the correct values
const aip = {
  targets: calls.map((call) => call.target),
  values: calls.map((call) => call.value),
  callDatas: calls.map((call) => call.callData),
  description,
};

export default aip;
