#!/bin/bash
# ======================================================
# swarm_watchdog.sh – jednostavan i stabilan nadzor
# ======================================================

SWARM_CONTAINER="rl-swarm-swarm-cpu-1"
OLLAMA_CONTAINER="rl-swarm-ollama-1"

LOG_FILE="swarm_launcher.log"
CHECK_INTERVAL=180
STALE_LOG_THRESHOLD=900   # 15 minuta

# OS detection for stat
if [[ "$(uname)" == "Darwin" ]]; then
    STAT_CMD="stat -f %m"
else
    STAT_CMD="stat -c %Y"
fi

echo "======================================================"
echo "[$(date)] Pokrećem nadzor RL-Swarm + Ollama + Clash Verge"
echo "======================================================"

while true; do
    restart_needed=0
    clash_restart_required=0
    current_time=$(date +%s)

    # ------------------------------------------------------
    # 1) Provera RL-Swarm kontejnera
    # ------------------------------------------------------
    if ! docker ps --format '{{.Names}}' | grep -q "^${SWARM_CONTAINER}$"; then
        echo "[$(date)] RL-Swarm kontejner ne radi!"
        restart_needed=1
        clash_restart_required=1
    else
        echo "[$(date)] RL-Swarm kontejner radi."

        # --------------------------------------------------
        # Ako log postoji → proveri vreme + fatalne greške
        # --------------------------------------------------
        if [ -f "$LOG_FILE" ]; then
            log_mtime=$($STAT_CMD "$LOG_FILE")
            diff=$((current_time - log_mtime))

            echo "[$(date)] RL-Swarm log age: $diff sekundi"

            if [ $diff -gt $STALE_LOG_THRESHOLD ]; then
                echo "[$(date)] Log nije ažuriran više od $STALE_LOG_THRESHOLD sek! Restart!"
                restart_needed=1
                clash_restart_required=1
            fi

            # Fatalne greške → instant restart
            if tail -n 100 "$LOG_FILE" | grep -q -E \
                "ConnectionRefusedError|\[Errno 111\]|Failed to establish a new connection|\[Errno 101\]|Shutting down trainer|No such process|\[Errno -2\]"; then
                
                echo "[$(date)] FATAL ERROR detektovan u RL-Swarm logu!"
                restart_needed=1
                clash_restart_required=1
            fi

        else
            # Log file ne postoji, ali RL-Swarm radi → NE restartuj
            echo "[$(date)] RL-Swarm radi ali log još nije nastao – čekam sledeći ciklus."
        fi
    fi

    # ------------------------------------------------------
    # 2) Provera Ollama kontejnera
    # ------------------------------------------------------
    if ! docker ps --format '{{.Names}}' | grep -q "^${OLLAMA_CONTAINER}$"; then
        echo "[$(date)] Ollama kontejner ne radi!"
        restart_needed=1
    else
        echo "[$(date)] Ollama radi."
    fi

    # ------------------------------------------------------
    # 3) Restart procedura
    # ------------------------------------------------------
    if [ "$restart_needed" -eq 1 ]; then
        echo "======================================================"
        echo "[$(date)] Restartujem sve (RL-Swarm + Ollama + Clash Verge)"
        echo "======================================================"

        # Restart Clash Verge
        if [ "$clash_restart_required" -eq 1 ]; then
            echo "[$(date)] Restartujem Clash Verge..."
            pkill -f "Clash Verge"
            sleep 2
            open -a "Clash Verge"
            echo "[$(date)] Clash Verge restartovan."
        fi

        docker stop "$SWARM_CONTAINER" &>/dev/null
        docker stop "$OLLAMA_CONTAINER" &>/dev/null
        docker start "$OLLAMA_CONTAINER"
        docker start "$SWARM_CONTAINER"
    fi

    sleep $CHECK_INTERVAL
done
