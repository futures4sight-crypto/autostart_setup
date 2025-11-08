#!/bin/bash
# ======================================================
# nexus_autostart.sh – minimal Nexus setup & start script
# ======================================================

set -e
source ~/.zshrc 2>/dev/null || true  # učitaj okruženje ako postoji

DATEFMT="+%Y-%m-%d %H:%M:%S"
NODE_FILE="$HOME/.nexus-node-id"
LOG_FILE="$HOME/nexus_autostart.log"
USER_FLAG="$HOME/.nexus-user-registered"
WALLET="0x9Ff501255C9917D11780c050BaEfF9dCc6d71c27"

log() { echo "[$(date "$DATEFMT")] $1" | tee -a "$LOG_FILE"; }

log "🚀 Starting Nexus setup..."

# 1️⃣ Install CLI if missing
if ! command -v nexus-network &>/dev/null; then
  log "⬇️ Installing Nexus CLI..."
  curl -fsSL https://cli.nexus.xyz/ | sh
  source ~/.zshrc 2>/dev/null || export PATH="$HOME/.local/bin:$HOME/.nexus/bin:$PATH"
fi

# 2️⃣ Register user if not already done
if [ ! -f "$USER_FLAG" ]; then
  log "🆕 Registering user..."
  nexus-network register-user --wallet-address "$WALLET" | tee -a "$LOG_FILE"
  touch "$USER_FLAG"
else
  log "✅ User already registered."
fi

# 3️⃣ Register node if missing
if [ ! -f "$NODE_FILE" ]; then
  log "🆕 Registering node..."
  OUT=$(nexus-network register-node 2>&1 | tee -a "$LOG_FILE")
  NODE_ID=$(echo "$OUT" | grep -oE "id: [a-zA-Z0-9-]+" | awk '{print $2}')
  if [ -n "$NODE_ID" ]; then
    echo "$NODE_ID" > "$NODE_FILE"
    log "✅ Node registered with ID: $NODE_ID"
  else
    log "⚠️ Could not extract Node ID. Check log."
  fi
else
  log "✅ Node already registered with ID: $(cat $NODE_FILE)"
fi

# 4️⃣ Start node
log "▶️ Starting node..."
nexus-network start | tee -a "$LOG_FILE"
