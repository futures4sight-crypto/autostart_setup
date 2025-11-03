#!/bin/bash
# =============================================
# GENSYN WATCHDOG (macOS version)
# Restarts swarm node in new Terminal window
# =============================================

LOG_FILE="$HOME/rl-swarm/user/logs/swarm_launcher.log"
CHECK_INTERVAL=300          # check every 5 minutes
STALE_THRESHOLD=900          # restart if log older than 15 min
HISTORY_FILE="$HOME/autostart_setup/watchdog_history.log"
DATEFMT="+%Y-%m-%d %H:%M:%S"

echo "[$(date "$DATEFMT")] 🧠 Gensyn watchdog started..."
echo "[$(date "$DATEFMT")] Monitoring log: $LOG_FILE" | tee -a "$HISTORY_FILE"

while true; do
  container_name=$(docker ps -a --format '{{.Names}}' | grep swarm-cpu | head -n 1)

  if [ -z "$container_name" ]; then
    echo "[$(date "$DATEFMT")] ℹ️  No container found — waiting for you to start one..."
    sleep $CHECK_INTERVAL
    continue
  fi

  if [ ! -f "$LOG_FILE" ]; then
    echo "[$(date "$DATEFMT")] ⚠️  Log file missing — starting node manually in Terminal..." | tee -a "$HISTORY_FILE"
    osascript -e 'tell application "Terminal"
        do script "cd ~/rl-swarm && docker-compose run -Pit swarm-cpu"
    end tell'
    sleep $CHECK_INTERVAL
    continue
  fi

  now=$(date +%s)
  last=$(stat -f %m "$LOG_FILE")  # macOS compatible
  diff=$((now - last))
  echo "[$(date "$DATEFMT")] Log age ${diff}s"

  if [ $diff -gt $STALE_THRESHOLD ]; then
    echo "[$(date "$DATEFMT")] ❌ Log stale — restarting node in new Terminal window..." | tee -a "$HISTORY_FILE"
    osascript -e 'tell application "Terminal"
        do script "cd ~/rl-swarm && docker-compose run -Pit swarm-cpu"
    end tell'
    echo "[$(date "$DATEFMT")] Restart command executed." | tee -a "$HISTORY_FILE"
  fi

  sleep $CHECK_INTERVAL
done
