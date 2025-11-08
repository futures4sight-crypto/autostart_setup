#!/bin/bash
# ============================================
# swarm_watchdog.sh
# Automatski nadzor i restart RL-Swarm kontejnera
# ============================================

CONTAINER_NAME="rl-swarm-swarm-cpu-1"          # ime Docker kontejnera koji se prati
CHECK_INTERVAL=180                  # interval provere (u sekundama) – 3 minuta
LOG_FILE="swarm_launcher.log"       # ime log fajla koji se nadgleda
STALE_LOG_THRESHOLD=900             # prag zastarelosti loga (u sekundama) – 15 minuta

# Odredi koji tip sistema koristimo, jer se "stat" komanda razlikuje
if [[ "$(uname)" == "Darwin" ]]; then
    # macOS / BSD sistem
    STAT_CMD="stat -f %m"
else
    # Linux sistem
    STAT_CMD="stat -c %Y"
fi

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Pokrećem nadzor kontejnera: $CONTAINER_NAME, proveravam svakih $CHECK_INTERVAL sekundi"
echo "[$(date +'%Y-%m-%d %H:%M:%S')] Pratim log fajl: $LOG_FILE – ako se ne ažurira duže od $STALE_LOG_THRESHOLD sekundi, kontejner će biti restartovan"

while true; do
    current_time=$(date +%s)   # trenutni UNIX timestamp (u sekundama)
    restart_needed=0

    # 1️⃣ Provera da li kontejner postoji
    if ! docker inspect "$CONTAINER_NAME" &> /dev/null; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Greška: kontejner $CONTAINER_NAME ne postoji"
        sleep $CHECK_INTERVAL
        continue
    fi

    # 2️⃣ Provera da li kontejner trenutno radi
    if ! docker ps --filter "name=^/${CONTAINER_NAME}$" --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Kontejner $CONTAINER_NAME je zaustavljen – pokrećem ga ponovo..."
        restart_needed=1
    else
        # 3️⃣ Ako kontejner radi, proveri da li se log fajl ažurira
        if [ -f "$LOG_FILE" ]; then
            # vreme poslednje izmene log fajla
            log_mtime=$($STAT_CMD "$LOG_FILE")
            time_diff=$((current_time - log_mtime))

            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Kontejner $CONTAINER_NAME radi – poslednji log update pre $time_diff sekundi"

            # ako je prošlo više od 15 minuta bez ažuriranja loga → restart
            if [ $time_diff -gt $STALE_LOG_THRESHOLD ]; then
                echo "[$(date +'%Y-%m-%d %H:%M:%S')] Upozorenje: log $LOG_FILE nije ažuriran duže od $STALE_LOG_THRESHOLD sekundi"
                restart_needed=1
            fi
        else
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Upozorenje: log fajl $LOG_FILE ne postoji"
            # Ako želiš da restartuje u tom slučaju, otkomentariši sledeću liniju:
            # restart_needed=1
        fi
    fi

    # 4️⃣ Ako je potrebno, izvrši restart
    if [ $restart_needed -eq 1 ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Restartujem kontejner $CONTAINER_NAME..."

        # zaustavi kontejner ako je aktivan
        if docker stop "$CONTAINER_NAME" &> /dev/null; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Kontejner $CONTAINER_NAME je uspešno zaustavljen"
        fi

        # ponovo pokreni kontejner
        if docker start "$CONTAINER_NAME"; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Kontejner $CONTAINER_NAME je uspešno pokrenut"
        else
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Greška: neuspešno pokretanje kontejnera $CONTAINER_NAME"
        fi
    fi

    sleep $CHECK_INTERVAL
done
