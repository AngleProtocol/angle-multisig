#!/usr/bin/env bash
# Wrapper to load 1Password secrets and run commands.
# Usage: ./op-run.sh -e <profile> <command...>
# Example: ./op-run.sh -e multisig yarn submit:multiple:foundry

PROFILE=""
COMMAND=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -e)
      PROFILE="$2"
      shift 2
      ;;
    *)
      COMMAND+=("$1")
      shift
      ;;
  esac
done

if [ -z "$PROFILE" ]; then
  echo "Error: Profile required"
  echo "Usage: ./op-run.sh -e <profile> <command...>"
  echo "Example: ./op-run.sh -e multisig yarn submit:multiple:foundry"
  exit 1
fi

if [ ${#COMMAND[@]} -eq 0 ]; then
  echo "Error: Command required"
  echo "Usage: ./op-run.sh -e <profile> <command...>"
  exit 1
fi

export PROFILE="$PROFILE"

op run --env-file="./profiles/.env.$PROFILE" -- "${COMMAND[@]}"
