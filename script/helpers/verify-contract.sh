#!/bin/bash
# Run the forge command and capture its output
output=$(forge verify-contract \
    --rpc-url https://rpc.sepolia-api.lisk.com \
    --verifier blockscout \
    --verifier-url https://sepolia-blockscout.lisk.com/api \
    --optimizer-runs 200 \
    "$1" "$2" 2>&1)

# Emit the captured output after the command finishes
echo "$output"