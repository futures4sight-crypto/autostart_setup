#!/bin/bash
# ============================================================
# GENSYN WATCHDOG (macOS local - clean & updated log path)
# Monitors ~/rl-swarm/log/swarm_launcher.log
# Restarts RL-Swarm if log is stale (>15min)
# ============================================================

LOG_FILE="$HOME/rl-swarm/log/swarm_launcher.log"
CHECK_INTERVAL=300        # every 5 minutes
STALE_THRESHOLD=900        # restart if older than 15 min
HISTORY_FILE="$HOME/autostart_setup/watchdog_history.log"
DATEFMT="+%Y-%m-%d %H:%M:%S"

echo "[$(date "$DATEFMT")] 🧠 Gensyn watchdog started..."
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

  # Kill any running RL-Swarm processes
  swarm_pid=$(pgrep -f "run_rl_swarm.sh")
  if [ -n "$swarm_pid" ]; then
    echo "[$(date "$DATEFMT")] Killing RL-Swarm PID=$swarm_pid" | tee -a "$HISTORY_FILE"
    kill -9 "$swarm_pid" 2>/dev/null
  fi

  # Close old Terminal windows with "Gensyn RL-Swarm" in title
  osascript -e 'tell application "Terminal" to close (every window whose name contains "Gensyn RL-Swarm")' 2>/dev/null
  sleep 2

  # Start new terminal session
  echo "[$(date "$DATEFMT")] 🚀 Launching new Terminal session..." | tee -a "$HISTORY_FILE"
  osascript -e '
    tell application "Terminal"
        do script "cd ~/rl-swarm && source .venv/bin/activate && ~/autostart_setup/autostart_gensyn.exp"
        set custom title of front window to \"Gensyn RL-Swarm\"
        activate
    end tell
  '

  echo "[$(date "$DATEFMT")] ✅ Restart executed successfully." | tee -a "$HISTORY_FILE"
  sleep $CHECK_INTERVAL
done
