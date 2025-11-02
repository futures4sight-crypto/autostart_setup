#!/bin/bash
# ================================================
# macOS Environment Setup Script
# Python 3.10 + Node.js + Corepack + Yarn
# Tested on macOS Sequoia / Apple Silicon / China network
# ================================================

DATEFMT="+%Y-%m-%d %H:%M:%S"

echo "[$(date "$DATEFMT")] 🚀 Starting environment setup..."

# --- Homebrew ---
if ! command -v brew >/dev/null 2>&1; then
  echo "[$(date "$DATEFMT")] 🧱 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "[$(date "$DATEFMT")] ✅ Homebrew already installed."
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- Python 3.10 ---
if ! brew list python@3.10 >/dev/null 2>&1; then
  echo "[$(date "$DATEFMT")] 🐍 Installing Python 3.10..."
  brew install python@3.10
else
  echo "[$(date "$DATEFMT")] ✅ Python 3.10 already installed."
fi

echo "[$(date "$DATEFMT")] 🔗 Linking Python 3.10..."
brew unlink python >/dev/null 2>&1
brew link python@3.10 --force --overwrite

# --- Force global executables ---
echo "[$(date "$DATEFMT")] 🔧 Forcing Python 3.10 as default..."
sudo ln -sf /opt/homebrew/bin/python3.10 /opt/homebrew/bin/python3
sudo ln -sf /opt/homebrew/bin/python3.10 /opt/homebrew/bin/python
sudo ln -sf /opt/homebrew/bin/pip3.10 /opt/homebrew/bin/pip3
sudo ln -sf /opt/homebrew/bin/pip3.10 /opt/homebrew/bin/pip

echo "[$(date "$DATEFMT")] ✅ Python 3.10 set as default system interpreter."

echo "[$(date "$DATEFMT")] 🧩 Python version check:"
python3 --version
pip3 --version

# --- Node.js ---
if ! command -v node >/dev/null 2>&1; then
  echo "[$(date "$DATEFMT")] 📦 Installing Node.js..."
  brew install node
else
  echo "[$(date "$DATEFMT")] ✅ Node.js already installed."
fi

node -v

# --- Corepack + Yarn ---
echo "[$(date "$DATEFMT")] ⚙️ Installing Corepack + Yarn..."
npm install -g corepack
corepack enable
corepack prepare yarn@1.22.19 --activate
yarn -v

# --- Final check ---
echo "[$(date "$DATEFMT")] 🔍 Final environment versions:"
python3 --version
node -v
corepack -v
yarn -v

echo "[$(date "$DATEFMT")] ✅ Environment setup completed successfully!"
