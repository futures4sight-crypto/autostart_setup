#!/bin/bash

# Full auto-setup for Mac Mini: installs dependencies, Gensyn/Nexus/Inference, sets LaunchAgents

echo "Starting full auto-setup..."

# 1. Install Homebrew if missing
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "Homebrew already installed."
fi

# 2. Install required packages
brew install --cask firefox
brew install --cask docker
brew install --cask clash-verge
brew install expect wget git

# 3. Start Docker
open -a Docker
sleep 10

# 4. Create LaunchAgents folder
mkdir -p ~/Library/LaunchAgents

# 5. Install Nexus CLI if missing
if ! command -v nexus-cli &>/dev/null; then
    echo "Installing Nexus CLI..."
    curl -fsSL https://cli.nexus.xyz/ | sh
else
    echo "Nexus CLI already installed."
fi

# 6. Install Inference CLI if missing
if ! command -v inference &>/dev/null; then
    echo "Installing Inference CLI..."
    curl -fsSL https://devnet.inference.net/install.sh | sh
else
    echo "Inference CLI already installed."
fi

# 7. Clone or update Gensyn RL-Swarm repo
if [ -d ~/autostart_setup/rl-swarm ]; then
    echo "Updating existing Gensyn RL-Swarm repo..."
    cd ~/autostart_setup/rl-swarm && git pull
else
    echo "Cloning Gensyn RL-Swarm repo..."
    git clone https://github.com/gensyn-ai/rl-swarm.git ~/autostart_setup/rl-swarm
fi

# 8. Set execution permissions
chmod +x ~/autostart_setup/*.sh
chmod +x ~/autostart_setup/*.exp

# 9. Copy LaunchAgents
cp ~/autostart_setup/com.*.plist ~/Library/LaunchAgents/

# 10. Load LaunchAgents
launchctl load -w ~/Library/LaunchAgents/com.inference.node.plist
launchctl load -w ~/Library/LaunchAgents/com.nexus.node.plist
launchctl load -w ~/Library/LaunchAgents/com.gensyn.node.plist

# 11. Add user to docker group
sudo dseditgroup -o edit -a "$USER" -t user docker

# 12. Check if Docker is ready
if ! docker info >/dev/null 2>&1; then
    echo "Docker not ready yet. Please wait for Docker to finish initializing."
else
    echo "Docker is ready."
fi

echo "Auto-setup complete. Nodes will start automatically on next login."
