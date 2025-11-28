#!/bin/bash
# ======================================================
# swarm_watchdog.sh
# Automatski nadzor i restart RL-Swarm, Ollama i Clash Verge
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
echo " - Clash Verge: restart u slučaju restartovanja Swarma ili mrežnih grešaka"
echo "======================================================"

while true; do
    current_time=$(date +%s)
    restart_needed=0
    clash_restart_required=0

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

            # Ako log predugo nije ažuriran
            if [ "$time_diff" -gt "$STALE_LOG_THRESHOLD" ]; then
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] Upozorenje: RL-Swarm log nije ažuriran!"
                restart_needed=1
            fi

            # ------------------------------------------------------
            # Detekcija ConnectionRefusedError
            # ------------------------------------------------------
            if tail -n 60 "$LOG_FILE" | grep -q -E "ConnectionRefusedError|\[Errno 111\] Connection refused"; then
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] Detektovan ConnectionRefusedError!"
                restart_needed=1
                clash_restart_required=1
            fi

            # ------------------------------------------------------
            # Detekcija kritičnih grešaka → odmah restart
            # ------------------------------------------------------
            if tail -n 100 "$LOG_FILE" | grep -q -E \
                "\[Errno 101\] Network is unreachable|Failed to establish a new connection|Shutting down trainer|No such process|\[Errno -2\] Name or service not known"; then
                
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] Detektovana kritična mrežna greška/trainer pad!"
                restart_needed=1
                clash_restart_required=1
            fi

        else
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Log fajl ne postoji! (restartujem)"
            restart_needed=1
        fi
    fi

    # ------------------------------------------------------
    # 2) Provera Ollama kontejnera
    # ------------------------------------------------------
    if ! docker ps --filter "name=^/${OLLAMA_CONTAINER}$" --format '{{.Names}}' | grep -q "$OLLAMA_CONTAINER"; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Ollama je zaustavljena!"
        restart_needed=1
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Ollama radi normalno."
    fi

    # ------------------------------------------------------
    # 3) Ako RL-Swarm ide u restart → obavezno restart Clash Verge
    # ------------------------------------------------------
    if [ "$restart_needed" -eq 1 ]; then
        clash_restart_required=1
    fi

    # ------------------------------------------------------
    # 4) Restart procedura
    # ------------------------------------------------------
    if [ "$restart_needed" -eq 1 ]; then

        echo "======================================================"
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Restartujem SVE kontejere!"
        echo "======================================================"

        # --- Restart Clash Verge ---
        if [ "$clash_restart_required" -eq 1 ]; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Restartujem Clash Verge…"

            pkill -f "Clash Verge"
            sleep 2
            open -a "Clash Verge"

            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Clash Verge restartovan."
        fi

        # --- Restart RL-Swarm / Ollama ---
        docker stop "$SWARM_CONTAINER" &>/dev/null
        docker stop "$OLLAMA_CONTAINER" &>/dev/null

        docker start "$OLLAMA_CONTAINER"
        docker start "$SWARM_CONTAINER"
    fi

    sleep "$CHECK_INTERVAL"
done
