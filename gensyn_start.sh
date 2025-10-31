#!/bin/bash

# Idi u RL Swarm folder
cd ~/rl-swarm || exit 1

# Povuci najnoviji kod (možeš i izbaciti ako ne treba)
git pull

# Sačekaj da Docker postane spreman
echo "⏳ Checking Docker daemon..."
RETRIES=30
until docker info >/dev/null 2>&1; do
    echo "⏳ Waiting for Docker to start..."
    sleep 30
    RETRIES=$((RETRIES - 1))
    if [ $RETRIES -le 0 ]; then
        echo "Docker not responding after 90 seconds. Aborting..."
        exit 1
    fi
done

echo "Docker is ready. Starting Expect script..."
sleep 2

# Pokreni expect
expect ~/autostart_setup/gensyn_autostart.exp
