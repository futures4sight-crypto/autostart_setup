#!/bin/bash
# ======================================================
# prepare.sh – Environment bootstrap for RL-Swarm (macOS)
# Author: Dimitrije Veselinov
# ======================================================
DATEFMT="+%Y-%m-%d %H:%M:%S"
log() { echo "[$(date "$DATEFMT")] $1"; }

log "🚀 Starting setup..."

# ======================================================
# 🧰 Homebrew
# ======================================================
if ! command -v brew &>/dev/null; then
  log "⬇️ Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  log "✅ Homebrew already installed."
fi

# ======================================================
# 🐍 Python 3.10
# ======================================================
log "🐍 Installing Python 3.10..."
if ! brew list python@3.10 &>/dev/null; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install python@3.10 || {
    log "⚠️ Could not fetch bottles online, trying cached reinstall..."
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

# ======================================================
# 📦 Node.js
# ======================================================
log "📦 Installing Node.js..."
if ! brew list node &>/dev/null; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew install node || {
    log "⚠️ Node install via brew failed; retrying cached reinstall..."
    HOMEBREW_NO_AUTO_UPDATE=1 brew reinstall node
  }
else
  log "✅ Node.js already installed."
fi

# ======================================================
# ⚙️ Corepack & Yarn
# ======================================================
log "⚙️ Enabling Corepack + Yarn..."
sudo npm install -g corepack >/dev/null 2>&1
corepack enable
corepack prepare yarn@1.22.19 --activate
export PATH="$(corepack home)/bin:$PATH"

if ! command -v yarn &>/dev/null; then
  log "❌ Yarn not found in PATH — forcing manual install..."
  sudo npm install -g yarn@1.22.19
fi

log "✅ Yarn ready: $(yarn -v 2>/dev/null || echo 'not detected')"

# ======================================================
# 🧭 PATH Persistence
# ======================================================
if ! grep -q "/opt/homebrew/opt/python@3.10/libexec/bin" ~/.zshrc; then
  echo 'export PATH="/opt/homebrew/bin:/opt/homebrew/opt/python@3.10/libexec/bin:$PATH"' >> ~/.zshrc
  echo 'export PATH="$(corepack home)/bin:$PATH"' >> ~/.zshrc
  log "✅ PATH updated and saved to ~/.zshrc"
fi

# ======================================================
# 🔍 Final version check
# ======================================================
log "🔍 Final version check:"
python3 --version
pip3 --version
node -v
yarn -v

# ======================================================
# 🧱 Virtual Environment
# ======================================================
log "🧱 Setting up Python 3.10 virtual environment for RL-Swarm..."
cd ~/rl-swarm || { log "❌ Folder ~/rl-swarm not found!"; exit 1; }

if [ -d ".venv" ]; then
  log "🧹 Removing old virtual environment (wrong Python version)..."
  rm -rf .venv
fi

/opt/homebrew/bin/python3.10 -m venv .venv
source .venv/bin/activate
python --version
python -m ensurepip --upgrade
python -m pip install --upgrade pip setuptools wheel
log "✅ Virtual environment created using Python 3.10."

log "✅ Environment setup completed successfully!"
