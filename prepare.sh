#!/bin/bash
# ======================================================
# prepare.sh – Environment bootstrap for RL-Swarm (macOS)
# ======================================================
DATEFMT="+%Y-%m-%d %H:%M:%S"

log() { echo "[$(date "$DATEFMT")] $1"; }

log "🚀 Starting setup..."

# --- Ensure Homebrew ---
if ! command -v brew &>/dev/null; then
  log "⬇️ Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log "✅ Homebrew already installed."
fi

# --- Python 3.10 ---
log "🐍 Installing Python 3.10..."
if ! brew list python@3.10 &>/dev/null; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install python@3.10 || {
    log "⚠️  Could not fetch bottles online, using cached Homebrew files if available..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew reinstall python@3.10
  }
else
  log "✅ Python 3.10 already present."
fi

log "🔗 Fixing Python 3.10 symlinks..."
sudo ln -sf /opt/homebrew/bin/python3.10 /opt/homebrew/bin/python3
sudo ln -sf /opt/homebrew/bin/python3.10 /opt/homebrew/bin/python
sudo ln -sf /opt/homebrew/opt/python@3.10/libexec/bin/pip3 /opt/homebrew/bin/pip3
sudo ln -sf /opt/homebrew/opt/python@3.10/libexec/bin/pip3 /opt/homebrew/bin/pip

log "🧩 Python version check:"
python3 --version
pip3 --version

# --- Node.js ---
log "📦 Installing Node.js..."
if ! brew list node &>/dev/null; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install node || {
    log "⚠️  Node install via brew failed; retrying cached reinstall..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew reinstall node
  }
else
  log "✅ Node.js already installed."
fi

# --- Corepack & Yarn ---
log "⚙️ Enabling Corepack..."
if ! command -v corepack &>/dev/null; then
  log "❌ Corepack not found, installing manually..."
  npm install -g corepack
fi

log "🧶 Setting up Yarn 1.22.19..."
corepack prepare yarn@1.22.19 --activate || npm install -g yarn

# --- PATH persistence ---
if ! grep -q "/opt/homebrew/opt/python@3.10/libexec/bin" ~/.zshrc; then
  echo 'export PATH="/opt/homebrew/bin:/opt/homebrew/opt/python@3.10/libexec/bin:$PATH"' >> ~/.zshrc
  source ~/.zshrc
  log "✅ PATH updated and saved to ~/.zshrc"
fi

# --- Final check ---
log "🔍 Final version check:"
python3 --version
pip3 --version
node -v
yarn -v

log "✅ Environment setup completed successfully!"
