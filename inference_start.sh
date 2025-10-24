#!/bin/bash

# Kratko čekanje nakon boota
sleep 20

# Instalacija i startovanje Inference noda
curl -fsSL https://devnet.inference.net/install.sh | sh
/usr/local/bin/inference node start --code b4b901af-9b33-4b33-9ecc-13e4ed6dc317

