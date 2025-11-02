#!/bin/bash
LOG_FILE="$HOME/rl-swarm/logs/swarm_launcher.log"
CHECK_INTERVAL=300
STALE_THRESHOLD=900
HISTORY_FILE="$HOME/autostart_setup/watchdog_history.log"
DATEFMT="+%Y-%m-%d %H:%M:%S"

echo "[$(date "$DATEFMT")] 🧠 Gensyn watchdog started..." | tee -a "$HISTORY_FILE"
echo "[$(date "$DATEFMT")] Monitoring log: $LOG_FILE" | tee -a "$HISTORY_FILE"

while true; do
  if [ ! -f "$LOG_FILE" ]; then
    echo "[$(date "$DATEFMT")] ⚠️ Log missing — starting RL-Swarm fresh..." | tee -a "$HISTORY_FILE"
  else
    now=$(date +%s)
    last=$(stat -f %m "$LOG_FILE")
    diff=$((now - last))
    echo "[$(date "$DATEFMT")] Log age ${diff}s"
    if [ $diff -le $STALE_THRESHOLD ]; then
      sleep $CHECK_INTERVAL
      continue
    fi
    echo "[$(date "$DATEFMT")] ❌ Log stale — restarting RL-Swarm..." | tee -a "$HISTORY_FILE"
  fi

  swarm_pid=$(pgrep -f "run_rl_swarm.sh")
  if [ -n "$swarm_pid" ]; then
    kill -9 "$swarm_pid" 2>/dev/null
  fi

  osascript -e 'tell application "Terminal"
      do script "cd ~/rl-swarm && source .venv/bin/activate && expect ~/autostart_setup/gensyn_autostart.exp"
      set custom title of front window to \"Gensyn Watchdog\"
      activate
  end tell'

  echo "[$(date "$DATEFMT")] ✅ Restart executed successfully." | tee -a "$HISTORY_FILE"
  sleep $CHECK_INTERVAL
done
