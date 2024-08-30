#! /bin/bash

source lib/utils/helpers/common.sh

function usage {
  echo "bash createAngleSideChainMultiBridge.sh <chain> <totalLimit> <hourlyLimit> <chainTotalHourlyLimit> <mock> <?expectedAddress>"
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
  echo -e "\t14: XLayer"
  echo -e "totalLimit: total limit for the token"
  echo -e "hourlyLimit: hourly limit for the token"
  echo -e "chainTotalHourlyLimit: total hourly limit for the chain"
  echo -e "mock: mock deployment (true/false)"
  echo -e "expectedAddress: expected address for the token (optional)"
  echo ""
}

function main {
    if [[ $# -ne 5 && $# -ne 6 ]]; then
        usage
        exit 1
    fi
    chain=$1
    totalLimit=$2
    hourlyLimit=$3
    chainTotalHourlyLimit=$4
    mock=$5
    expectedAddress=$6

    if [ -z "$chain" ] || [ -z "$totalLimit" ] || [ -z "$hourlyLimit" ] || [ -z "$chainTotalHourlyLimit" ] || [ -z "$mock" ]; then
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
    # Check if totalLimit is a positive or null integer
    if ! [[ $totalLimit =~ ^[0-9]+$ ]]; then
        echo "Total limit must be a positive integer"
        exit 1
    fi
    # Check if hourlyLimit is a positive or null integer
    if ! [[ $hourlyLimit =~ ^[0-9]+$ ]]; then
        echo "Hourly limit must be a positive integer"
        exit 1
    fi
    # Check if chainTotalHourlyLimit is a positive or null integer
    if ! [[ $chainTotalHourlyLimit =~ ^[0-9]+$ ]]; then
        echo "Chain total hourly limit must be a positive integer"
        exit 1
    fi
    # check if mock is a boolean
    if [[ "$mock" != "true" && "$mock" != "false" ]]; then
        echo "Mock must be true or false"
        exit 1
    fi

    mainnet_uri=$(chain_to_uri 1)

    if [[ ! -z "$expectedAddress" ]]; then
       export EXPECTED_ADDRESS=$expectedAddress
    fi
    if [[ "$mock" == "true" ]]; then
        export MOCK=true
    fi

    export CHAIN_ID=$chainId
    export TOTAL_LIMIT=$totalLimit
    export HOURLY_LIMIT=$hourlyLimit
    export CHAIN_TOTAL_HOURLY_LIMIT=$chainTotalHourlyLimit

    if [[ "$mock" == "true" ]]; then
        echo ""
        echo "Change governor ? (yes/no)"
        read changeGovernor

        if [[ $changeGovernor == "yes" ]]; then
            export FINALIZE=true
        fi
    fi

    echo ""
    echo "Running deployment on chain $chainId with total limit: $totalLimit, hourly limit: $hourlyLimit and chain total hourly limit: $chainTotalHourlyLimit"

    cd lib/angle-tokens && forge script DeployAngleSideChainMultiBridge --fork-url $chainUri --broadcast --verify && cd ../.
    if [ $? -ne 0 ]; then
        echo ""
        echo "Deployment failed"
        exit 1
    fi

    echo ""
    echo "Deployment successful"

    echo ""
    echo "Would you like to create the multisig transaction for the angle side chain multi bridge ? (yes/no)"

    read createTransaction

    if [[ $createTransaction == "yes" ]]; then

        forge script ConnectAngleSideChainMultiBridge --fork-url $mainnet_uri
        if [ $? -ne 0 ]; then
            echo ""
            echo "Transaction creation failed"
            exit 1
        fi

        echo ""
        echo "Transaction created successfully"

        forge test --match-contract ConnectAngleSideChainMultiBridgeTest
        if [ $? -ne 0 ]; then
            echo ""
            echo "Transaction tests failed"
            exit 1
        fi

        echo ""
        echo "Transaction tests successful"

        echo ""
        echo "Would you like to execute the transaction ? (yes/no)"
        read execute

        if [[ $execute == "yes" ]]; then
            yarn submit-multiple:foundry
        fi
    fi
}

main $@
