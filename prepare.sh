#!/bin/bash
# =====================================================
# Mac setup script for Gensyn environment (Python + Node + Yarn)
# =====================================================
DATEFMT="+%Y-%m-%d %H:%M:%S"

echo "[$(date "$DATEFMT")] 🚀 Starting setup..."

# --- Install Homebrew if missing ---
if ! command -v brew >/dev/null 2>&1; then
  echo "[$(date "$DATEFMT")] 🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "[$(date "$DATEFMT")] ✅ Homebrew already installed."
fi

# --- Install Python 3.10 ---
if ! brew list python@3.10 >/dev/null 2>&1; then
  echo "[$(date "$DATEFMT")] 🐍 Installing Python 3.10..."
  brew install python@3.10
else
  echo "[$(date "$DATEFMT")] ✅ Python 3.10 already installed."
fi

# Link Python 3.10 as default python3
echo "[$(date "$DATEFMT")] 🔗 Linking Python 3.10..."
brew unlink python >/dev/null 2>&1
brew link python@3.10 --force --overwrite

# Verify Python version
echo "[$(date "$DATEFMT")] 🧩 Python version check:"
python3 --version

# --- Install Node.js ---
if ! command -v node >/dev/null 2>&1; then
  echo "[$(date "$DATEFMT")] 📦 Installing Node.js..."
  brew install node
else
  echo "[$(date "$DATEFMT")] ✅ Node.js already installed."
fi

# --- Enable Corepack or install manually ---
echo "[$(date "$DATEFMT")] ⚙️ Enabling Corepack..."
if ! command -v corepack >/dev/null 2>&1; then
  echo "[$(date "$DATEFMT")] ❌ Corepack not found, installing manually..."
  npm install -g corepack
else
  echo "[$(date "$DATEFMT")] ✅ Corepack available."
fi

corepack enable || npm install -g corepack

# --- Prepare Yarn (specific version 1.22.19) ---
echo "[$(date "$DATEFMT")] 🧶 Setting up Yarn 1.22.19..."
corepack prepare yarn@1.22.19 --activate || npm install -g yarn@1.22.19

# --- Final checks ---
echo "[$(date "$DATEFMT")] 🔍 Final version check:"
python3 --version
node --version
yarn --version

echo "[$(date "$DATEFMT")] ✅ Environment setup completed!"
