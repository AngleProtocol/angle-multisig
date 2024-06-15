#! /bin/bash

source lib/utils/helpers/common.sh

function usage {
  echo "bash createChain.sh <chain> <mock> <?governor> <?guardian> <?timelock>"
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
  echo -e "mock: mock deployment (true/false)"
  echo -e "governor: address of the governor (optional)"
  echo -e "guardian: address of the guardian (optional)"
  echo -e "timelock: address of the timelock (optional)"
  echo ""
}

function main {
    if [ $# -ne 2 ] && [ $# -ne 5 ]; then
        usage
        exit 1
    fi
    chain=$1
    mock=$2
    governor=$3
    guardian=$4
    timelock=$5

    if [ -z "$chain" ] || [ -z "$mock" ]; then
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
    if [ -z "$chainUri" ] || [ -z "$chainId" ]; then
        echo "Invalid chain"
        exit 1
    fi
    # check if mock is a boolean
    if [[ "$mock" != "true" && "$mock" != "false" ]]; then
        echo "Mock must be true or false"
        exit 1
    fi

    export CHAIN_ID=$chain
    if [ ! -z "$governor" ]; then
        export GOVERNOR=$governor
    fi
    if [ ! -z "$guardian" ]; then
        export GUARDIAN=$guardian
    fi
    if [ ! -z "$timelock" ]; then
        export TIMELOCK=$timelock
    fi
    if [[ "$mock" == "true" ]]; then
        export MOCK=true
    fi

    echo ""
    echo "Running deployment on chain $chain"

    cd lib/angle-tokens && forge script DeployChain --fork-url $chainUri --verify --broadcast && cd ../..

    if [ $? -ne 0 ]; then
        echo ""
        echo "Deployment failed"
        exit 1
    fi

    echo ""
    echo "Deployment successful"
}

main $@
