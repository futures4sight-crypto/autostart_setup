#!/bin/bash
# ======================================================
# nexus_autostart.sh – jednostavan i jasan setup Nexus node-a
# ======================================================

# Učitaj zsh okruženje ako postoji
if [ -f "$HOME/.zshrc" ]; then
  echo "📂 Učitavam okruženje (~/.zshrc)..."
  source "$HOME/.zshrc"
fi

NODE_FILE="$HOME/.nexus-node-id"
USER_FLAG="$HOME/.nexus-user-registered"
WALLET="0x9Ff501255C9917D11780c050BaEfF9dCc6d71c27"
LOG_FILE="$HOME/nexus_autostart.log"

echo "====================================================="
echo "🚀 Pokrećem Nexus setup..."
echo "📄 Log fajl: $LOG_FILE"
echo "====================================================="

# 1️⃣ Proveri da li postoji nexus-network CLI
if ! command -v nexus-network &>/dev/null; then
  echo "⬇️  Nexus CLI nije pronađen — instaliram..."
  curl -fsSL https://cli.nexus.xyz/ | sh
  source "$HOME/.zshrc" 2>/dev/null || export PATH="$HOME/.local/bin:$HOME/.nexus/bin:$PATH"
else
  echo "✅ Nexus CLI već postoji."
fi

# 2️⃣ Registracija korisnika
if [ ! -f "$USER_FLAG" ]; then
  echo "🆕 Registrujem korisnika..."
  nexus-network register-user --wallet-address "$WALLET" | tee -a "$LOG_FILE"
  if [ $? -eq 0 ]; then
    echo "✅ Korisnik registrovan."
    touch "$USER_FLAG"
  else
    echo "⚠️  Neuspešna registracija korisnika!"
  fi
else
  echo "✅ Korisnik je već registrovan ranije."
fi

# 3️⃣ Registracija node-a
if [ ! -f "$NODE_FILE" ]; then
  echo "🆕 Registrujem node..."
  OUT=$(nexus-network register-node 2>&1 | tee -a "$LOG_FILE")
  NODE_ID=$(echo "$OUT" | grep -oE "id: [a-zA-Z0-9-]+" | awk '{print $2}')
  if [ -n "$NODE_ID" ]; then
    echo "$NODE_ID" > "$NODE_FILE"
    echo "✅ Node registrovan sa ID: $NODE_ID"
  else
    echo "⚠️  Nije pronađen Node ID u izlazu. Pogledaj log."
  fi
else
  echo "✅ Node je već registrovan (ID: $(cat $NODE_FILE))"
fi

# 4️⃣ Pokretanje node-a
echo "▶️  Pokrećem Nexus node..."
sleep 1
nexus-network start | tee -a "$LOG_FILE"

echo "====================================================="
echo "🎯 Završeno! Ako se node pokrenuo uspešno, ID je:"
cat "$NODE_FILE" 2>/dev/null || echo "⚠️ Node ID nije pronađen."
echo "====================================================="
