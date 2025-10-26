#!/bin/bash

# === ENABLE / DISABLE pojedinačnih projekata ===
INSTALL_GENSYN=true
INSTALL_NEXUS=true
INSTALL_INFERENCE=true
# Putanja do foldera sa skriptama (repo kloniran u home)
AUTOSTART_DIR="$HOME/autostart_setup"

echo "Starting full auto-setup..."

## 1. Install Homebrew if missing
# if ! command -v brew &>/dev/null; then
#     echo "Installing Homebrew..."
#     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#     echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
#     eval "$(/opt/homebrew/bin/brew shellenv)"
#     read -p "Homebrew instaliran. Pritisni Enter za nastavak..."
# else
#     echo "Homebrew already installed."
# fi

# 2. Install required packages
# brew install --cask firefox
# brew install --cask docker
# brew install --cask clash-verge-rev
# if Clash Verge app name differs, this will silently fail; it's fine
sudo xattr -r -d com.apple.quarantine /Applications/Clash\ Verge.app 2>/dev/null || true
brew install expect wget git
read -p "Svi paketi instalirani. Pritisni Enter..."

# 2.5 Install ToDesk if missing
if [ -d "/Applications/ToDesk.app" ]; then
    echo "ToDesk je već instaliran. Preskačem instalaciju."
else
    echo "Instalacija ToDesk..."
    TODESK_PKG=~/Downloads/ToDesk.pkg
    curl -L "http://dl.todesk.com/macos/ToDesk_4.8.2.3.pkg" -o "$TODESK_PKG"
    sudo installer -pkg "$TODESK_PKG" -target /
    sudo xattr -r -d com.apple.quarantine /Applications/ToDesk.app 2>/dev/null || true
fi
read -p "ToDesk provera/instalacija završena. Pritisni Enter za nastavak..."

# 3. Start Docker
open -a Docker
sleep 10
read -p "Docker pokrenut (ili u procesu pokretanja). Pritisni Enter..."

# 4. Create LaunchAgents folder
mkdir -p ~/Library/LaunchAgents
read -p "LaunchAgents folder kreiran. Pritisni Enter..."

# 5. Nexus installation
if [ "$INSTALL_NEXUS" = true ]; then
    if ! command -v nexus-cli &>/dev/null; then
        echo "Installing Nexus CLI..."
        curl -fsSL https://cli.nexus.xyz/ | sh
        # reload shell profile so newly exported PATH works in this session (zsh assumed)
        if [ -f ~/.zshrc ]; then
            source ~/.zshrc
        fi
        read -p "Nexus CLI instaliran. Pritisni Enter..."
    else
        echo "Nexus CLI already installed."
    fi

    if [ ! -f "${AUTOSTART_DIR}/nexus_wallets.csv" ]; then
        echo "nexus_wallets.csv not found!"
    fi

    NEXUS_WALLET=$(grep "^$(hostname)," "${AUTOSTART_DIR}/nexus_wallets.csv" | cut -d',' -f2)
    if [ -n "$NEXUS_WALLET" ]; then
        echo "Registering Nexus node with wallet: $NEXUS_WALLET"
        nexus-cli register-user --wallet-address "$NEXUS_WALLET"
        read -p "Registracija završena. Pritisni Enter..."
        nexus-cli register-node
        read -p "Node registrovan. Pritisni Enter..."
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

    if [ ! -f "${AUTOSTART_DIR}/inference_codes.csv" ]; then
        echo "inference_codes.csv not found!"
    fi

    INFERENCE_CODE=$(grep "^$(hostname)," "${AUTOSTART_DIR}/inference_codes.csv" | cut -d',' -f2)

    if [ -f "${AUTOSTART_DIR}/inference_start.sh" ]; then
        if [ -n "$INFERENCE_CODE" ]; then
            echo "Updating inference_start.sh with code: $INFERENCE_CODE"
            # safe in-place replace for macOS sed
            sed -i '' "s/--code .*/--code $INFERENCE_CODE/" "${AUTOSTART_DIR}/inference_start.sh"
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
    if [ -d ~/rl-swarm ]; then
        echo "Updating existing Gensyn RL-Swarm repo..."
        cd ~/rl-swarm && git pull
    else
        echo "Cloning Gensyn RL-Swarm repo..."
        git clone https://github.com/gensyn-ai/rl-swarm.git ~/rl-swarm
    fi
    read -p "Gensyn repo spreman. Pritisni Enter..."
else
    echo "Gensyn instalacija preskočena."
fi

# 8. Set execution permissions
chmod +x "${AUTOSTART_DIR}"/*.sh 2>/dev/null || true
chmod +x "${AUTOSTART_DIR}"/*.exp 2>/dev/null || true
read -p "Dozvole postavljene. Pritisni Enter..."

# 9. Copy LaunchAgents
cp "${AUTOSTART_DIR}"/com.*.plist ~/Library/LaunchAgents/ 2>/dev/null || true
read -p "LaunchAgents plist fajlovi kopirani. Pritisni Enter..."

# 10. Load LaunchAgents
[ "$INSTALL_INFERENCE" = true ] && [ -f ~/Library/LaunchAgents/com.inference.node.plist ] && launchctl load -w ~/Library/LaunchAgents/com.inference.node.plist
[ "$INSTALL_NEXUS" = true ] && [ -f ~/Library/LaunchAgents/com.nexus.node.plist ] && launchctl load -w ~/Library/LaunchAgents/com.nexus.node.plist
[ "$INSTALL_GENSYN" = true ] && [ -f ~/Library/LaunchAgents/com.gensyn.node.plist ] && launchctl load -w ~/Library/LaunchAgents/com.gensyn.node.plist
read -p "Launchd servisi (pokušano) aktivirani. Pritisni Enter..."

# 11. OPTIONAL: create sudoers entry so start scripts and binaries can run without password
# This will require sudo once to write /etc/sudoers.d/autostart_setup
# We will detect binary paths and user scripts and create safe sudoers entry, validate it, then install.
SUDOERS_FILE="/etc/sudoers.d/autostart_setup"
TEMP_SUDOERS="/tmp/autostart_setup_sudoers.$$"
CURRENT_USER="$USER"

# Build a list of absolute command paths to allow NOPASSWD
declare -a SUDO_ALLOW_LIST

# Add start scripts (full paths)
if [ -f "${AUTOSTART_DIR}/nexus_start.sh" ]; then
    SUDO_ALLOW_LIST+=("${AUTOSTART_DIR}/nexus_start.sh")
fi
if [ -f "${AUTOSTART_DIR}/inference_start.sh" ]; then
    SUDO_ALLOW_LIST+=("${AUTOSTART_DIR}/inference_start.sh")
fi

# Detect binaries and add them (nexus-cli, inference, docker) if present
if command -v nexus-cli &>/dev/null; then
    NEXUS_PATH=$(command -v nexus-cli)
    SUDO_ALLOW_LIST+=("${NEXUS_PATH}")
fi
if command -v inference &>/dev/null; then
    INFERENCE_PATH=$(command -v inference)
    SUDO_ALLOW_LIST+=("${INFERENCE_PATH}")
fi
if command -v docker &>/dev/null; then
    DOCKER_PATH=$(command -v docker)
    SUDO_ALLOW_LIST+=("${DOCKER_PATH}")
fi

# If we have at least one path to allow, create sudoers file
if [ ${#SUDO_ALLOW_LIST[@]} -gt 0 ]; then
    echo "Creating sudoers entry to allow start scripts to run without password (will require your sudo once)..."
    # Compose temp sudoers content
    {
        echo "# Autogenerated sudoers for autostart_setup - DO NOT EDIT MANUALLY"
        echo "# Created on $(date -u)"
        # Use syntax: username ALL=(ALL) NOPASSWD: /full/path, /full/path2
        printf "%s ALL=(ALL) NOPASSWD: " "$CURRENT_USER"
        first=true
        for p in "${SUDO_ALLOW_LIST[@]}"; do
            if [ "$first" = true ]; then
                printf "%s" "$p"
                first=false
            else
                printf ", %s" "$p"
            fi
        done
        echo
    } > "$TEMP_SUDOERS"

    # Validate the temp sudoers file
    if sudo visudo -cf "$TEMP_SUDOERS"; then
        # move into /etc/sudoers.d with correct permissions
        sudo cp "$TEMP_SUDOERS" "$SUDOERS_FILE"
        sudo chown root:wheel "$SUDOERS_FILE"
        sudo chmod 440 "$SUDOERS_FILE"
        rm -f "$TEMP_SUDOERS"
        echo "Sudoers file installed at $SUDOERS_FILE"
        read -p "Sudoers update izvršen. Pritisni Enter..."
    else
        echo "Greška pri validaciji sudoers fajla. Neću instalirati. Proveri sadržaj $TEMP_SUDOERS"
        rm -f "$TEMP_SUDOERS"
        read -p "Pritisni Enter za nastavak..."
    fi
else
    echo "Nema komandi za dodati u sudoers listu (nexus-cli / inference / docker / start skripte nisu pronađene)."
fi

# 12. Check if Docker is ready
if ! docker info >/dev/null 2>&1; then
    echo "Docker not ready yet. Please wait for Docker to finish initializing."
else
    echo "Docker is ready."
fi

echo "Auto-setup complete. Nodes will start automatically on next login."
