#! /bin/bash
source lib/utils/helpers/common.sh

function main {
    if [ ! -f .env ]; then
        echo ".env not found!"
        exit 1
    fi
    source .env

    echo "Which chain would you like to fork ?"
    echo "- 1: Ethereum Mainnet"
    echo "- 2: Arbitrum"
    echo "- 3: Polygon"
    echo "- 4: Gnosis"
    echo "- 5: Avalanche"
    echo "- 6: Base"
    echo "- 7: Binance Smart Chain"
    echo "- 8: Celo"
    echo "- 9: Polygon ZkEvm"
    echo "- 10: Optimism"
    echo "- 11: Linea"
    echo "- 12: Mode"
    echo "- 13: Blast"
    echo "- 14: XLayer"

    read option

    uri=$(chain_to_uri $option)

    echo "Forking $uri"
    anvil --fork-url $uri
}

main
