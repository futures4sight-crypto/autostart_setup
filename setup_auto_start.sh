#!/bin/bash

# === ENABLE / DISABLE pojedinačnih projekata ===
INSTALL_GENSYN=true
INSTALL_NEXUS=true
INSTALL_INFERENCE=true

echo "Starting full auto-setup..."

# 1. Install Homebrew if missing
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
    read -p "Homebrew instaliran. Pritisni Enter za nastavak..."
else
    echo "Homebrew already installed."
fi

# 2. Install required packages
brew install --cask firefox
brew install --cask docker
brew install --cask clash-verge-rev
sudo xattr -r -d com.apple.quarantine /Applications/Clash\ Verge.app
brew install expect wget git
read -p "Svi paketi instalirani. Pritisni Enter..."

# 3. Start Docker
open -a Docker
sleep 10
read -p "Docker pokrenut. Pritisni Enter..."

# 4. Create LaunchAgents folder
mkdir -p ~/Library/LaunchAgents
read -p "LaunchAgents folder kreiran. Pritisni Enter..."

# 5. Nexus installation
if [ "$INSTALL_NEXUS" = true ]; then
    if ! command -v nexus-cli &>/dev/null; then
        echo "Installing Nexus CLI..."
        curl -fsSL https://cli.nexus.xyz/ | sh
        read -p "Nexus CLI instaliran. Pritisni Enter..."
    else
        echo "Nexus CLI already installed."
    fi

    if [ ! -f ~/autostart_setup/nexus_wallets.csv ]; then
        echo "nexus_wallets.csv not found!"
    fi

    NEXUS_WALLET=$(grep "^$(hostname)," ~/autostart_setup/nexus_wallets.csv | cut -d',' -f2)
    if [ -n "$NEXUS_WALLET" ]; then
        echo "Registering Nexus node with wallet: $NEXUS_WALLET"
        nexus-cli register-user --wallet-address "$NEXUS_WALLET"
        read -p "Registracija završena. Pritisni Enter..."
        nexus-cli initialize
        read -p "Inicijalizacija završena. Pritisni Enter..."
    else
        echo "No Nexus wallet found for hostname: $(hostname)"
    fi
else
    echo "Nexus instalacija preskočena."
fi

# 6. Inference installation
if [ "$INSTALL_INFERENCE" = true ]; then
    if ! command -v inference &>/dev/null; then
        echo "Installing Inference CLI..."
        curl -fsSL https://devnet.inference.net/install.sh | sh
        read -p "Inference CLI instaliran. Pritisni Enter..."
    else
        echo "Inference CLI already installed."
    fi

    if [ ! -f ~/autostart_setup/inference_codes.csv ]; then
        echo "inference_codes.csv not found!"
    fi

    INFERENCE_CODE=$(grep "^$(hostname)," ~/autostart_setup/inference_codes.csv | cut -d',' -f2)

    if [ -f ~/autostart_setup/inference_start.sh ]; then
        if [ -n "$INFERENCE_CODE" ]; then
            echo "Updating inference_start.sh with code: $INFERENCE_CODE"
            sed -i '' "s/--code .*/--code $INFERENCE_CODE/" ~/autostart_setup/inference_start.sh
            read -p "Kod ažuriran. Pritisni Enter..."
        else
            echo "No Inference code found for hostname: $(hostname)"
        fi
    else
        echo "inference_start.sh not found!"
    fi
else
    echo "Inference instalacija preskočena."
fi

# 7. Gensyn RL-Swarm
if [ "$INSTALL_GENSYN" = true ]; then
    if [ -d ~/autostart_setup/rl-swarm ]; then
        echo "Updating existing Gensyn RL-Swarm repo..."
        cd ~/autostart_setup/rl-swarm && git pull
    else
        echo "Cloning Gensyn RL-Swarm repo..."
        git clone https://github.com/gensyn-ai/rl-swarm.git ~/autostart_setup/rl-swarm
    fi
    read -p "Gensyn repo spreman. Pritisni Enter..."
else
    echo "Gensyn instalacija preskočena."
fi

# 8. Set execution permissions
chmod +x ~/autostart_setup/*.sh
chmod +x ~/autostart_setup/*.exp
read -p "Dozvole postavljene. Pritisni Enter..."

# 9. Copy LaunchAgents
cp ~/autostart_setup/com.*.plist ~/Library/LaunchAgents/
read -p "LaunchAgents plist fajlovi kopirani. Pritisni Enter..."

# 10. Load LaunchAgents
[ "$INSTALL_INFERENCE" = true ] && launchctl load -w ~/Library/LaunchAgents/com.inference.node.plist
[ "$INSTALL_NEXUS" = true ] && launchctl load -w ~/Library/LaunchAgents/com.nexus.node.plist
[ "$INSTALL_GENSYN" = true ] && launchctl load -w ~/Library/LaunchAgents/com.gensyn.node.plist
read -p "Launchd servisi aktivirani. Pritisni Enter..."

# 11. Add user to docker group
sudo dseditgroup -o edit -a "$USER" -t user docker
read -p "User dodat u docker grupu. Pritisni Enter..."

# 12. Check if Docker is ready
if ! docker info >/dev/null 2>&1; then
    echo "Docker not ready yet. Please wait for Docker to finish initializing."
else
    echo "Docker is ready."
fi

echo "Auto-setup complete. Nodes will start automatically on next login."
