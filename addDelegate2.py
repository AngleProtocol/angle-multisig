import time
import requests
import click

from web3 import Web3


def create_message(delegate_address):
    totp = int(time.time()) // 3600
    return delegate_address + str(totp)


def ask_address(msg: str) -> str:
    while True:
        address = click.prompt(msg, type=str)
        if Web3.isAddress(address):
            return address
        print('Invalid input. Need a checksummed Ethereum address.')


def main():
    safe_address = ask_address('Enter the Safe address')
    delegate_address = ask_address('Enter the delegate address')
    delegate_label = click.prompt(
        'Enter the label for this delegate', type=str)

    # Create hash
    message = create_message(delegate_address)
    print('SIGN')
    print('  > message:', message)
    print('VERIFY')
    print('  > message-hash:', Web3.keccak(text=message).hex())

    # Get signature
    signature = click.prompt('Enter the signature for the message')

    # Add the delegate
    add_payload = {
        'safe': safe_address,
        'delegate': delegate_address,
        'signature': signature,
        'label': delegate_label
    }
    r = requests.post(f'https://safe-transaction.mainnet.gnosis.io/api/v1/safes/{safe_address}/delegates/',
                      json=add_payload, headers={'Content-type': 'application/json'})
    print(r.text)


if __name__ == '__main__':
    main()