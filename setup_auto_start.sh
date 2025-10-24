#!/bin/bash

echo "Setting up auto-start for Inference, Nexus, and Gensyn nodes..."

# 1. Kreiraj folder za LaunchAgents ako ne postoji
mkdir -p ~/Library/LaunchAgents

# 2. Kopiraj plist fajlove u LaunchAgents
echo "Installing .plist files to ~/Library/LaunchAgents..."
cp ./com.*.plist ~/Library/LaunchAgents/

# 3. Dodeli izvršna prava svim skriptama
chmod +x ~/autostart_setup/*.sh
chmod +x ~/autostart_setup/*.exp

# 4. Aktiviraj svaku skriptu kao launch agent
echo "Loading launch agents..."
launchctl load -w ~/Library/LaunchAgents/com.inference.node.plist
launchctl load -w ~/Library/LaunchAgents/com.nexus.node.plist
launchctl load -w ~/Library/LaunchAgents/com.gensyn.node.plist

echo "All nodes are now set to start automatically on login."

