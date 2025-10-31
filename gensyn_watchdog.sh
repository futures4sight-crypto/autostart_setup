#!/bin/bash
LOG_FILE="$HOME/rl-swarm/user/logs/swarm_launcher.log"
CHECK_INTERVAL=300   # svake 5 min
STALE_THRESHOLD=900  # 15 min
DATEFMT="+%Y-%m-%d %H:%M:%S"

echo "[$(date "$DATEFMT")] Starting watchdog..."

while true; do
  if [ ! -f "$LOG_FILE" ]; then
    echo "[$(date "$DATEFMT")] ⚠️ Log file not found — restarting container"
    docker restart $(docker ps -a --format '{{.Names}}' | grep swarm-cpu)
  else
    now=$(date +%s)
    last=$(stat -f %m "$LOG_FILE")
    diff=$((now - last))
    echo "[$(date "$DATEFMT")] Log age ${diff}s"

    if [ $diff -gt $STALE_THRESHOLD ]; then
      echo "[$(date "$DATEFMT")] ❌ Log stale — restarting container"
      docker restart $(docker ps -a --format '{{.Names}}' | grep swarm-cpu)
    fi
  fi
  sleep $CHECK_INTERVAL
done
