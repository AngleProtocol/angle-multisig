#! /bin/bash

source lib/utils/helpers/common.sh

function usage {
  echo "bash createSavings.sh <chain> <stableName>"
  echo ""
  echo -e "chain: chain to deploy on"
  echo -e "\t0: Fork"
  echo -e "\t1: Ethereum Mainnet"
  echo -e "\t2: Arbitrum"
  echo -e "\t3: Polygon"
  echo -e "\t4: Gnosis"
  echo -e "\t5: Avalanche"
  echo -e "\t6: Base"
  echo -e "\t7: Binance Smart Chain"
  echo -e "\t8: Celo"
  echo -e "\t9: Polygon ZkEvm"
  echo -e "\t10: Optimism"
  echo -e "\t11: Linea"
  echo -e "\t12: Mode"
  echo -e "\t13: Blast"
  echo -e "stableName: name of the stable token (ex: EUR)"
  echo ""
}

function main {
    if [[ $# -ne 2 ]]; then
        usage
        exit 1
    fi
    chain=$1
    stableName=$2

    if [ -z "$chain" ] || [ -z "$stableName" ]; then
        echo "Missing arguments"
        exit 1
    fi

    if [ ! -f .env ]; then
        echo ".env not found!"
        exit 1
    fi
    source .env

    cp .env lib/angle-tokens/.env

    chainUri=$(chain_to_uri $chain)
    chainId=$(chain_to_chainId $chain)
    if [[ -z "$chainUri" || -z "$chainId" ]]; then
        echo "Invalid chain"
        exit 1
    fi

    mainnet_uri=$(chain_to_uri 1)

    export CHAIN_ID=$chainId
    export STABLE_NAME=$stableName

    echo ""
    echo "Running deployment on chain $chainId for stable token $stableName"

    cd lib/angle-tokens && forge script DeploySavings --fork-url $chainUri --broadcast --verify && cd ../..

    if [ $? -ne 0 ]; then
        echo ""
        echo "Deployment failed"
        exit 1
    fi

    echo ""
    echo "Deployment successful"
}

main $@
