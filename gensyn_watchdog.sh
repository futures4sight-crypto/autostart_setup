#!/bin/bash
# Simple Gensyn Watchdog — restarts container if log is stale

LOG_FILE="$HOME/rl-swarm/user/logs/swarm_launcher.log"
CHECK_INTERVAL=300          # check every 5 minutes
STALE_THRESHOLD=900          # restart if log older than 15 min
DATEFMT="+%Y-%m-%d %H:%M:%S"

echo "[$(date "$DATEFMT")] Starting watchdog..."

while true; do
  container_name=$(docker ps -a --format '{{.Names}}' | grep swarm-cpu | head -n 1)

  if [ -z "$container_name" ]; then
    echo "[$(date "$DATEFMT")] ℹ️  No container found (waiting for you to start one)..."
    sleep $CHECK_INTERVAL
    continue
  fi

  if [ ! -f "$LOG_FILE" ]; then
    echo "[$(date "$DATEFMT")] ⚠️ Log file missing — restarting container $container_name"
    docker restart "$container_name"
    sleep $CHECK_INTERVAL
    continue
  fi

  now=$(date +%s)
  last=$(stat -f %m "$LOG_FILE")  # macOS compatible
  diff=$((now - last))
  echo "[$(date "$DATEFMT")] Log age ${diff}s"

  if [ $diff -gt $STALE_THRESHOLD ]; then
    echo "[$(date "$DATEFMT")] ❌ Log stale — restarting container $container_name"
    docker restart "$container_name"
  fi

  sleep $CHECK_INTERVAL
done
