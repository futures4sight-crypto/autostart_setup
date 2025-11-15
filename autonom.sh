#!/bin/bash
# ======================================================
# swarm_watchdog.sh
# Automatski nadzor i restart RL-Swarm i Ollama kontejnera
# ======================================================

# Kontejneri koje nadgledamo
CONTAINERS=(
    "rl-swarm-swarm-cpu-1"
    "rl-swarm-ollama-1"
)

# Log fajlovi koje svaki kontejner treba da generiše
LOG_FILES=(
    "swarm_launcher.log"
    "ollama.log"
)

CHECK_INTERVAL=180          # 3 minuta
STALE_LOG_THRESHOLD=400     # 15 minuta

# Odredi platformu (Linux/macOS)
if [[ "$(uname)" == "Darwin" ]]; then
    STAT_CMD="stat -f %m"
else
    STAT_CMD="stat -c %Y"
fi

echo "======================================================"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Pokrećem nadzor kontejnera:"
for c in "${CONTAINERS[@]}"; do echo " - $c"; done
echo "Interval provere: $CHECK_INTERVAL sekundi"
echo "Prag neaktivnosti logova: $STALE_LOG_THRESHOLD sekundi"
echo "======================================================"

while true; do
    current_time=$(date +%s)
    restart_needed=0

    # ------------------------------------------------------
    # 1) Provera svakog kontejnera pojedinačno
    # ------------------------------------------------------
    for index in "${!CONTAINERS[@]}"; do
        CONTAINER="${CONTAINERS[$index]}"
        LOG_FILE="${LOG_FILES[$index]}"

        # 1.1 – kontejner mora da postoji
        if ! docker inspect "$CONTAINER" &>/dev/null; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Greška: kontejner $CONTAINER ne postoji!"
            restart_needed=1
            continue
        fi

        # 1.2 – da li radi?
        if ! docker ps --filter "name=^/${CONTAINER}$" --format '{{.Names}}' | grep -q "$CONTAINER"; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Kontejner $CONTAINER je zaustavljen!"
            restart_needed=1
        else
            # 1.3 – proveri log
            if [ -f "$LOG_FILE" ]; then
                log_mtime=$($STAT_CMD "$LOG_FILE")
                time_diff=$((current_time - log_mtime))

                echo "[$(date +'%Y-%m-%d %H:%M:%S')] $CONTAINER radi – log update pre $time_diff sekundi"

                if [ "$time_diff" -gt "$STALE_LOG_THRESHOLD" ]; then
                    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Upozorenje: $LOG_FILE nije ažuriran!"
                    restart_needed=1
                fi
            else
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] Log fajl $LOG_FILE ne postoji! (preskačem)"
                continue    # ignoriši, ne restartuj ništa
            fi
        fi
    done

    # ------------------------------------------------------
    # 2) Ako bilo šta zakaže → restartuj SVE kontejere
    # ------------------------------------------------------
    if [ "$restart_needed" -eq 1 ]; then
        echo "======================================================"
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Restartujem SVE kontejere!"
        echo "======================================================"

        for c in "${CONTAINERS[@]}"; do
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Zaustavljam $c..."
            docker stop "$c" &>/dev/null

            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Pokrećem $c..."
            if docker start "$c"; then
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] $c uspešno pokrenut."
            else
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] Greška: $c nije mogao da se pokrene!"
            fi
        done
    fi

    sleep "$CHECK_INTERVAL"
done
