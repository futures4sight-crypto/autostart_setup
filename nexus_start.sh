#!/bin/bash
sleep 30

export PATH="$HOME/.nexus/bin:/usr/local/bin:/opt/homebrew/bin:$PATH"

# Instalacija Nexus CLI ako nije već instaliran
if ! command -v nexus-cli &> /dev/null; then
    echo "Installing Nexus CLI..."
    curl -fsSL https://cli.nexus.xyz/ | sh
else
    echo "Nexus CLI already installed."
fi

echo "Current PATH: $PATH" >> /Users/mita/logs/path_debug.log

# Startovanje noda
echo "Starting Nexus node..."
nexus-cli start

# Održavanje prozora otvorenim
echo ""
echo "Nexus node is running. Keeping this window open..."
while true; do sleep 3600; done
