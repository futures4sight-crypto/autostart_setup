#!/bin/bash
# ======================================================
# swarm_watchdog.sh
# Automatski nadzor i restart RL-Swarm i Ollama kontejnera
# ======================================================

SWARM_CONTAINER="rl-swarm-swarm-cpu-1"
OLLAMA_CONTAINER="rl-swarm-ollama-1"

LOG_FILE="swarm_launcher.log"

CHECK_INTERVAL=180
STALE_LOG_THRESHOLD=900

# Detekcija OS-a
if [[ "$(uname)" == "Darwin" ]]; then
    STAT_CMD="stat -f %m"
else
    STAT_CMD="stat -c %Y"
fi

echo "======================================================"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Pokrećem nadzor:"
echo " - RL-Swarm: $SWARM_CONTAINER (prati log)"
echo " - Ollama:   $OLLAMA_CONTAINER (bez log praćenja)"
echo "======================================================"

while true; do
    current_time=$(date +%s)
    restart_needed=0

    # ------------------------------------------------------
    # 1) Provera RL-Swarm kontejnera + njegov log
    # ------------------------------------------------------
    if ! docker ps --filter "name=^/${SWARM_CONTAINER}$" --format '{{.Names}}' | grep -q "$SWARM_CONTAINER"; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] RL-Swarm kontejner je zaustavljen!"
        restart_needed=1
    else
        if [ -f "$LOG_FILE" ]; then
            log_mtime=$($STAT_CMD "$LOG_FILE")
            time_diff=$((current_time - log_mtime))

            echo "[$(date +'%Y-%m-%d %H:%M:%S')] RL-Swarm radi – log update pre $time_diff sekundi"

            if [ "$time_diff" -gt "$STALE_LOG_THRESHOLD" ]; then
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] Upozorenje: RL-Swarm log nije ažuriran!"
                restart_needed=1
            fi
        else
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Log fajl $LOG_FILE ne postoji! (restartujem)"
            restart_needed=1
        fi
    fi

    # ------------------------------------------------------
    # 2) Provera da li Ollama kontejner radi (bez loga)
    # ------------------------------------------------------
    if ! docker ps --filter "name=^/${OLLAMA_CONTAINER}$" --format '{{.Names}}' | grep -q "$OLLAMA_CONTAINER"; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Ollama je zaustavljena!"
        restart_needed=1
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Ollama radi normalno."
    fi

    # ------------------------------------------------------
    # 3) Ako bilo šta zakaže → restart oba kontejnera
    # ------------------------------------------------------
    if [ "$restart_needed" -eq 1 ]; then
        echo "======================================================"
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Restartujem SVE kontejere!"
        echo "======================================================"

        docker stop "$SWARM_CONTAINER" &>/dev/null
        docker stop "$OLLAMA_CONTAINER" &>/dev/null

        docker start "$OLLAMA_CONTAINER"
        docker start "$SWARM_CONTAINER"
    fi

    sleep "$CHECK_INTERVAL"
done
