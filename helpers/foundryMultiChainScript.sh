#! /bin/bash

function usage {
  echo "bash foundryMultiChainScript.sh <foundry-script-path>"
  echo "Lists all chains where Merkl DistributionCreator is deployed and allows selection"
  echo "Example: bash foundryMultiChainScript.sh scripts/foundry/merkl/UpgradeDistributionCreator.s.sol"
  echo ""
}

# Get list of chain IDs where DistributionCreator is deployed
function get_available_chains() {
    local registry_file="node_modules/@angleprotocol/sdk/dist/src/registry/registry.json"
    if [ ! -f "$registry_file" ]; then
        echo "Registry file not found!"
        exit 1
    fi

    jq -r 'to_entries | .[] | select(.value.Merkl.DistributionCreator != null) | .key' "$registry_file"
}

# Get list of chains to deploy to, handling exclusions
function get_selected_chains() {
    local chain_ids=("$@")
    local selected_chains=()
    local exclude_chain_ids=(314)  # Default exclusions: filecoin, avalanche

    read -p "Do you want to run the script on all chains? (y/n) -- Note: ChainIDs 314 is already excluded by default: " deploy_all

    if [[ "$deploy_all" == "y" ]]; then
        for chain_id in "${chain_ids[@]}"; do
            if [[ ! " ${exclude_chain_ids[@]} " =~ " ${chain_id} " ]]; then
                selected_chains+=("$chain_id")
            fi
        done
    else
        read -p "Enter chain IDs to exclude (space-separated), or press enter to continue: " -a additional_exclude
        exclude_chain_ids+=("${additional_exclude[@]}")

        for chain_id in "${chain_ids[@]}"; do
            if [[ ! " ${exclude_chain_ids[@]} " =~ " ${chain_id} " ]]; then
                selected_chains+=("$chain_id")
            fi
        done
    fi

    printf "%s " "${selected_chains[@]}"
}

# Get verification string for a specific chain
function get_verify_string() {
    local chain_id=$1
    local verify_string=""
    
    local verifier_type_var="VERIFIER_TYPE_${chain_id}"
    local verifier_type=$(eval "echo \$$verifier_type_var")
    
    if [ ! -z "${verifier_type}" ]; then
        verify_string="--verify --verifier ${verifier_type}"
        
        # Add verifier URL if present
        local verifier_url_var="VERIFIER_URL_${chain_id}"
        local verifier_url=$(eval "echo \$$verifier_url_var")
        if [ ! -z "${verifier_url}" ]; then
            verify_string="${verify_string} --verifier-url ${verifier_url}"
        fi
        
        # Add API key if present
        local verifier_api_key_var="VERIFIER_API_KEY_${chain_id}"
        local verifier_api_key=$(eval "echo \$$verifier_api_key_var")
        if [ ! -z "${verifier_api_key}" ]; then
            verify_string="${verify_string} --verifier-api-key ${verifier_api_key}"
        fi
    fi
    
    echo "$verify_string"
}

# Get compilation flags for a specific chain
function get_compile_flags() {
    local chain_id=$1
    
    if [[ "$chain_id" == "30" || "$chain_id" == "122" || "$chain_id" == "592" || "$chain_id" == "1284" || "$chain_id" == "42793" ]]; then
        echo "--evm-version london"
    elif [[ "$chain_id" == "196" || "$chain_id" == "250" || "$chain_id" == "1329" || "$chain_id" == "3776" || "$chain_id" == "480" || "$chain_id" == "2046399126" ]]; then
        echo "--legacy"
    else
        echo ""
    fi
}

function main {
    # Check if script path is provided
    if [ -z "$1" ]; then
        usage
        exit 1
    fi
    
    FOUNDRY_SCRIPT="$1"
    
    # Verify the script exists
    if [ ! -f "$FOUNDRY_SCRIPT" ]; then
        echo "Error: Script file '$FOUNDRY_SCRIPT' not found!"
        exit 1
    fi

    # Path to the registry file
    registry_file="node_modules/@angleprotocol/sdk/dist/src/registry/registry.json"

    if [ ! -f "$registry_file" ]; then
        echo "Registry file not found!"
        exit 1
    fi


    # Store chain IDs in an array
    chain_ids=()
    while IFS= read -r chain_id; do
        chain_ids+=("$chain_id")
    done <<< "$(jq -r 'to_entries | .[] | select(.value.Merkl.DistributionCreator != null) | .key' "$registry_file")"

    # Display all chains
    echo "Chain IDs where Merkl DistributionCreator is deployed: ${chain_ids[@]}"

    echo ""
    selected_chains=($(get_selected_chains "${chain_ids[@]}"))

    source .env
    rm -f scripts/foundry/transaction.json
    echo '{}' > scripts/foundry/transactions.json

    # Initialize arrays for tracking deployment status
    successful_chains=()
    failed_chains=()

    # Prompt user for broadcast and verify options
    read -p "Do you want to broadcast the transaction? (y/n): " broadcast_choice

    # Set flags based on user input
    if [ "$broadcast_choice" == "y" ]; then
        broadcast_flag="--broadcast"
        read -p "Do you want to verify the transaction? (y/n): " verify_choice
    else
        broadcast_flag=""
    fi

    # Run forge script for each selected chain
    for chain_id in "${selected_chains[@]}"; do
        echo "Running forge script for chain ID: $chain_id"
        rpc_url_var="ETH_NODE_URI_${chain_id}"
        rpc_url=$(eval "echo \$$rpc_url_var")
        
        # Verification string based on chain-specific environment variables
        if [ "$verify_choice" == "y" ]; then
            verify_string=$(get_verify_string "$chain_id")
        else
            verify_string=""
        fi

        # Compilation specific flags
        compile_flags=$(get_compile_flags "$chain_id")

        cmd="forge script $FOUNDRY_SCRIPT $broadcast_flag --rpc-url $rpc_url $compile_flags $verify_string"
        echo "Running command: $cmd"
        if eval $cmd && [ -f "scripts/foundry/transaction.json" ]; then
            successful_chains+=("$chain_id")
        else
            failed_chains+=("$chain_id")
        fi

        # Create a new JSON object with chain ID as key and transaction data as value
        if [ -f "scripts/foundry/transaction.json" ]; then
            jq -s '.[0] * {("'$chain_id'"): .[1]}' \
                scripts/foundry/transactions.json \
                scripts/foundry/transaction.json > scripts/foundry/transactions.json.tmp
            
            mv scripts/foundry/transactions.json.tmp scripts/foundry/transactions.json
            rm -f scripts/foundry/transaction.json
        fi
    done

    # Display final deployment status
    if [ ${#successful_chains[@]} -gt 0 ]; then
        echo -e "\n✅ Deployment successful on chains: ${successful_chains[*]}"
    fi
    if [ ${#failed_chains[@]} -gt 0 ]; then
        echo -e "\n❌ Deployment issues on chains: ${failed_chains[*]}"
    fi
}

main "$@"