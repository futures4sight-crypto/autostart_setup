#!/bin/bash

# Kratko čekanje nakon boota
sleep 20

# Instalacija Nexus CLI-ja i startovanje noda
sudo curl https://cli.nexus.xyz/ | sudo sh
nexus-cli start

# Održavanje terminala otvorenim
echo ""
echo "Nexus node running. This window will stay open."
while true; do sleep 3600; done

