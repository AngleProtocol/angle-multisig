import requests
import eth_account
import time
from web3 import Web3
from hexbytes import HexBytes
import os
from os.path import join, dirname
from dotenv import load_dotenv

# This file is here to add a delegate to a Gnosis
# Being a delegate means that this address will get the right to submit transactions
# that will appear in the Gnosis Safe App. A delegate is needed for us to push transactions
# without revealing our private keys on a script
# This will enable us to easily build guardian scripts

# TODO: Before doing this, a new owner should be added to the Safe (an owner for which we have the private key)
# We can then revoke the owner

dotenv_path = join(dirname(__file__), '.env')
load_dotenv(dotenv_path)

SAFE = os.environ.get('SAFE')
CHAIN_ID = os.environ.get('CHAIN_ID')
DELEGATE_ADDRESS =  os.environ.get('DELEGATE_ADDRESS')
DELEGATOR_ADDRESS =  os.environ.get('DELEGATOR_ADDRESS')
PRIVATE_KEY = os.environ.get('PRIVATE_KEY_DELEGATOR')

dict = {"1" : 'mainnet', "56" : "bsc", "42161" : "arbitrum", "10" : "optimism",
        "43114" : "avalanche", "137" : "polygon", "1313161554" : "aurora", "100" : "gnosis-chain",
        "5000": "mantle", "59144": "linea", "8453":"base", "42220":"celo", "1101":"zkevm", }

TX_SERVICE_BASE_URL = f'https://safe-transaction-{dict[CHAIN_ID]}.safe.global/api/v1'

def view_existing_delegates():
    list_response = requests.get(f'{TX_SERVICE_BASE_URL}/delegates/?safe={SAFE}')
    print(list_response.text)
    print(list_response.status_code)
    return

def get_hash_to_sign():
    totp = int(time.time()) // 3600
    hash_to_sign = Web3.keccak(text = DELEGATE_ADDRESS + str(totp))
    return hash_to_sign

def get_address():
    return eth_account.Account.from_key(PRIVATE_KEY)

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
    # # You need to sign manually with the delegator
    # signature = "0x269f0aa02dba212dbb90fa04f82ee4bdfc16dedf38abdae323b316c2f7063fa568908a675d853e74c7285891bfc609d279ddbfed7940a014d5729545a2c9b7d101"
    add_payload = {
        "safe": SAFE,
        "delegate": DELEGATE_ADDRESS,
        "delegator": DELEGATOR_ADDRESS,
        "signature": signature.signature.hex(),
        "label": "Delegate Guillaume"
    }
    add_response = requests.post(f'{TX_SERVICE_BASE_URL}/delegates/', json=add_payload, headers = {'Content-type': 'application/json'})
    print(add_response.text)
    print(add_response.status_code)
    view_existing_delegates()
    return


def remove_delegate():
    totp = int(time.time()) // 3600
    account = get_address()
    hash_to_sign = Web3.keccak(text=DELEGATE_ADDRESS + str(totp))
    signature = account.signHash(hash_to_sign)
    # # You need to sign manually with the delegator
    remove_payload = {
        "delegate": DELEGATE_ADDRESS,
        "delegator": DELEGATOR_ADDRESS,
        "signature": signature.signature.hex()
    }
    add_response = requests.delete(f'{TX_SERVICE_BASE_URL}/delegates/{DELEGATE_ADDRESS}', json=remove_payload, headers = {'Content-type': 'application/json'})
    print(add_response.text)
    print(add_response.status_code)
    view_existing_delegates()
    return

if __name__ == "__main__":
    print(get_address().address)
    view_existing_delegates()
    # get_signature()
    # add_new_delegate()
    
    
    