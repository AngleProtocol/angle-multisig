function encodePath(tokenAddresses, fees) {
  const FEE_SIZE = 3

  if (tokenAddresses.length != fees.length + 1) {
    throw new Error('tokenAddresses/fee lengths do not match')
  }

  let encoded = '0x'
  for (let i = 0; i < fees.length; i++) {
    // 20 byte encoding of the address
    encoded += tokenAddresses[i].slice(2)
    // 3 byte encoding of the fee
    encoded += fees[i].toString(16).padStart(2 * FEE_SIZE, '0')
  }
  // encode the final token
  encoded += tokenAddresses[tokenAddresses.length - 1].slice(2)

  console.log(encoded.toLowerCase())

  return encoded.toLowerCase()
}

encodePath(
  [
    '0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9',
    '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
    '0x853d955aCEf822Db058eb8505911ED77F175b99e',
  ],
  [3000, 3000, 500],
)
