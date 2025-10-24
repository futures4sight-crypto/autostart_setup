#!/bin/bash
sleep 20

SCRIPT_DIR=~/autostart_setup
NODE_NAME=$(hostname)

CODE=$(grep "^$NODE_NAME," "$SCRIPT_DIR/inference_codes.csv" | cut -d',' -f2)

if [ -z "$CODE" ]; then
    echo "ERROR: Inference code not found for $NODE_NAME in inference_codes.csv"
    exit 1
fi

echo "Starting inference node for $NODE_NAME with code: $CODE"
/usr/local/bin/inference node start --code "$CODE"