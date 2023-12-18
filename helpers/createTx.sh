#! /bin/bash

function chain_to_uri {
  chain=$1

  case $chain in
    "1")
      echo $ETH_NODE_URI_MAINNET
      ;;
    "2")
      echo $ETH_NODE_URI_ARBITRUM
      ;;
    "3")
      echo $ETH_NODE_URI_POLYGON
      ;;
    "4")
      echo $ETH_NODE_URI_GNOSIS
      ;;
    "5")
      echo $ETH_NODE_URI_AVALANCHE
      ;;
    "6")
      echo $ETH_NODE_URI_BASE
      ;;
    "7")
        echo $ETH_NODE_URI_BSC
        ;;
    "8")
        echo $ETH_NODE_URI_CELO
        ;;
    "9")
        echo $ETH_NODE_URI_POLYGON_ZKEVM
        ;;
    "10")
        echo $ETH_NODE_URI_OPTIMISM
        ;;
    *)
      ;;
  esac
}

function chain_to_chainId {
  chain=$1

  case $chain in
    "1")
      echo "1"
      ;;
    "2")
      echo "42161"
      ;;
    "3")
      echo "137"
      ;;
    "4")
      echo "100"
      ;;
    "5")
      echo "43114"
      ;;
    "6")
      echo "8453"
      ;;
    "7")
        echo "56"
        ;;
    "8")
        echo "42220"
        ;;
    "9")
        echo "1101"
        ;;
    "10")
        echo "10"
        ;;
    *)
      ;;
  esac
}

function main {
    if [ ! -f .env ]; then
        echo ".env not found!"
        exit 1
    fi
    source .env

    echo ""
    echo "What script would you like to run ?"

    read script

    if [ -z "$script" ]; then
        echo "No script provided"
        exit 1
    fi

    echo ""

    echo "Which chain(s) would you like to run the script on ? (separate with commas)"
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

    read chains

    if [ -z "$chains" ]; then
        echo "No chain provided"
        exit 1
    fi

    for chain in $(echo $chains | sed "s/,/ /g")
    do
        echo ""
        echo "Running on chain $chain"
        uri=$(chain_to_uri $chain)
        export CHAIN_ID=$(chain_to_chainId $chain)
        forge script $script --fork-url $uri
        yarn submit:foundry
    done
}

main
