const { registry } = require('@angleprotocol/sdk');
const { ethers } = require('ethers');

// Ensure an argument has been provided
if (process.argv.length < 3) {
  console.error('Please provide a chain input as an argument.');
  process.exit(1);
}

// Get the argument from the command line input
// process.argv[0] is the node command
// process.argv[1] is the path to the runner.js file
// process.argv[2] is the first argument provided by the user
const chainInput = process.argv[2];

// Try to parse the input as a number if possible
if(isNaN(Number(chainInput))) process.exit(1);

const parsedInput = Number(chainInput);
const angleMiddleman = registry(parsedInput)?.Middleman;

if(!angleMiddleman) process.exit(1);
// Call the function with the input
const result = ethers.utils.getAddress(angleMiddleman)?.toString()?.slice(2);
console.log(result);
