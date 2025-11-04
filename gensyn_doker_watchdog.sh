#!/bin/bash
# ============================================================
# GENSYN DOCKER WATCHDOG (macOS version)
# Restarts RL-Swarm container if log is stale or container dead
# ============================================================

LOG_FILE="$HOME/rl-swarm/user/logs/swarm_launcher.log"
CHECK_INTERVAL=300          # check every 5 minutes
STALE_THRESHOLD=600         # restart if log older than 15 min
HISTORY_FILE="$HOME/autostart_setup/watchdog_history.log"
CONTAINER_NAME="swarm-cpu"
DATEFMT="+%Y-%m-%d %H:%M:%S"

echo "[$(date "$DATEFMT")] 🧠 Docker watchdog started..."
echo "[$(date "$DATEFMT")] Monitoring log: $LOG_FILE" | tee -a "$HISTORY_FILE"

while true; do
  # 🧩 Proveri da li kontejner postoji
  container_id=$(docker ps -q -f name=$CONTAINER_NAME)

  if [ -z "$container_id" ]; then
    echo "[$(date "$DATEFMT")] ⚠️  Container not running — starting fresh..." | tee -a "$HISTORY_FILE"
    osascript -e 'tell application "Terminal"
        do script "cd ~/rl-swarm && docker-compose run --rm -Pit swarm-cpu"
        activate
    end tell'
    sleep $CHECK_INTERVAL
    continue
  fi

  # 🧩 Proveri log
  if [ ! -f "$LOG_FILE" ]; then
    echo "[$(date "$DATEFMT")] ⚠️  Log missing — forcing container restart..." | tee -a "$HISTORY_FILE"
    docker restart "$CONTAINER_NAME" >/dev/null 2>&1
    sleep $CHECK_INTERVAL
    continue
  fi

  now=$(date +%s)
  last=$(stat -f %m "$LOG_FILE")
  diff=$((now - last))
  echo "[$(date "$DATEFMT")] Log age ${diff}s"

  if [ $diff -gt $STALE_THRESHOLD ]; then
    echo "[$(date "$DATEFMT")] ❌ Log stale — restarting container..." | tee -a "$HISTORY_FILE"
    docker restart "$CONTAINER_NAME" >/dev/null 2>&1
    echo "[$(date "$DATEFMT")] ✅ Container restarted successfully." | tee -a "$HISTORY_FILE"
  fi

  sleep $CHECK_INTERVAL
done


