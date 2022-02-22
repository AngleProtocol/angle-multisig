import requests
import eth_account
import time
from web3 import Web3
from hexbytes import HexBytes

# This file is here to add a delegate to a Gnosis
# Being a delegate means that this address will get the right to submit transactions
# that will appear in the Gnosis Safe App. A delegate is needed for us to push transactions
# without revealing our private keys on a script
# This will enable us to easily build guardian scripts

# TODO: Before doing this, a new owner should be added to the Safe (an owner for which we have the private key)
# We can then revoke the owner

# Parameters should be changed
SAFE_ADDRESS = '0xdC4e6DFe07EFCa50a197DF15D9200883eF4Eb1c8'
DELEGATE_ADDRESS = '0x2AC60687b23590F56F540f31625dD8b9232971da'
TX_SERVICE_BASE_URL = 'https://safe-transaction.mainnet.gnosis.io'
MNEMONIC = ""
PRIVATE_KEY = ''

def view_existing_delegates():
    list_response = requests.get(f'{TX_SERVICE_BASE_URL}/api/v1/safes/{SAFE_ADDRESS}/delegates')
    print(list_response.text)
    print(list_response.status_code)
    return

def get_hash_to_sign():
    totp = int(time.time()) // 3600
    
    hash_to_sign = Web3.keccak(text = DELEGATE_ADDRESS + str(totp))
    return hash_to_sign

def get_address():
    eth_account.Account.enable_unaudited_hdwallet_features()
    for i in range(0,10):
        for j in range(0,10):
            acct = eth_account.Account.from_mnemonic(MNEMONIC,account_path = "m/44'/60'/{}'/0/{}".format(i,j))
            #print(acct.address)
    return eth_account.Account.from_mnemonic(MNEMONIC,account_path = "m/44'/60'/0'/0/0".format(i,j))

def get_signature():
    contract_transaction_hash = HexBytes('0xafdc9d7b4995251ec8ee8ef96d8bbe6f7d2ffc841b4e12d21f262b9cf7160baf')
    account = eth_account.Account.from_key(PRIVATE_KEY)
    signature = account.signHash(contract_transaction_hash)
    print(signature.signature.hex())

# To get the signature of a message go here: https://www.myetherwallet.com/wallet/sign
# And enter the message you got from get_hash_to_sign
def add_new_delegate():
    totp = int(time.time()) // 3600
    account = get_address()
    hash_to_sign = Web3.keccak(text=DELEGATE_ADDRESS + str(totp))
    print(hash_to_sign.hex())
    print(DELEGATE_ADDRESS+str(totp))
    signature = account.signHash(hash_to_sign)
    print(signature.signature.hex())
    add_payload = {
        "safe": SAFE_ADDRESS,
        "delegate": DELEGATE_ADDRESS,
        "signature": signature.signature.hex(),
        "label": "My new delegate"
    }
    
    add_response = requests.post(f'{TX_SERVICE_BASE_URL}/api/v1/safes/{SAFE_ADDRESS}/delegates/', json=add_payload, headers = {'Content-type': 'application/json'})
    print(add_response.text)
    print(add_response.status_code)
    return
    

if __name__ == "__main__":
    #view_existing_delegates()
    #get_address()
    #get_signature()
    add_new_delegate()
    #view_existing_delegates()
    
    
    