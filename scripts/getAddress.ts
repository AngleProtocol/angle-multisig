const ethers = require('ethers')
import { config } from 'dotenv'

// Utility file to create some addresses with their mnemonic and private keys
async function init() {
  //creating new random mnemonic
  //const mnemonic = await ethers.utils.HDNode.entropyToMnemonic(ethers.utils.randomBytes(16));
  let randomBytes = ethers.utils.randomBytes(128)

  //Get the language
  let language = ethers.wordlists.en
  //generate a mnemonic for the specified language
  let wallet = ethers.Wallet.createRandom({
    extraEntropy: ethers.utils.randomBytes(32),
    locale: language,
  })
  console.log('Wallet', wallet)
  console.log('Address', wallet.address)
  console.log('Private Key', wallet.privateKey)
  console.log('Mnemonic', wallet.mnemonic)
}
config()
// Utility function to check an address from a private key
async function fromPrivateKey() {
  console.log(process.env.PRIVATE_KEY)
  let wallet = new ethers.Wallet(process.env.PRIVATE_KEY.toString())
  // console.log("Wallet",wallet);
  console.log('Address', wallet.address)
  console.log('Private Key', wallet.privateKey)
}

async function fromMnemonic() {
  let mnemonic = 'YOUR MNEMONIC'
  let mnemonicWallet = ethers.Wallet.fromMnemonic(mnemonic)
  console.log(mnemonicWallet.privateKey)
}
init()
// fromPrivateKey()
//fromMnemonic()
