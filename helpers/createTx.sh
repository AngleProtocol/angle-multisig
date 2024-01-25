#! /bin/bash

source helpers/common.sh

function usage {
  echo "bash createTx.sh <script> <chain>"
  echo ""
  echo -e "script: path to the script to run"
  echo -e "chain: chain(s) to run the script on (separate with commas)"
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
  echo ""
}

function main {
    command=false
    if [[ $# -ne 2 && $# -ne 0 ]]; then
        usage
        exit 1
    fi
    if [ $# -eq 2 ]; then
        script=$1
        chains=$2
        command=true
    fi

    if [ ! -f .env ]; then
        echo ".env not found!"
        exit 1
    fi
    source .env

    if [ $command != true ]; then
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
        echo "- 11: Linea"

        read chains

        if [ -z "$chains" ]; then
            echo "No chain provided"
            exit 1
        fi
    fi

    # TODO make forks as sometimes we need to do on chain calls
    for chain in $(echo $chains | sed "s/,/ /g")
    do
        echo ""
        echo "Running on chain $chain"
        uri=$(chain_to_uri $chain)

        if [ -z "$uri" ]; then
            echo ""
            echo "Invalid chain"
            continue
        fi

        export CHAIN_ID=$(chain_to_chainId $chain)
        forge script $script --fork-url $uri

        if [ $? -ne 0 ]; then
            echo ""
            echo "Script failed"
            continue
        fi

        testContract="${script}Test"
        echo ""
        echo "Running test"
        FOUNDRY_PROFILE=dev forge test --match-contract $testContract -vvv


        echo ""
        echo "Would you like to execute the script ? (yes/no)"
        read execute

        if [[ $execute == "yes" ]]; then
            yarn submit:foundry
        fi
    done
}

main $@
