#!/bin/bash

# Idi u folder gde je docker-compose.yaml
cd ~/rl-swarm || exit 1

sleep 40

# Update projekta (opciono)
git pull

# Pokreni expect skriptu
expect ../autostart_setup/gensyn_autostart.exp
