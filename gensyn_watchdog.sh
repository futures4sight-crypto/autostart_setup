#!/bin/bash
# ============================================================
# GENSYN WATCHDOG (macOS version - fixed AppleScript syntax)
# Restarts local RL-Swarm via Expect automation if log stale
# ============================================================

LOG_FILE="$HOME/rl-swarm/logs/swarm_launcher.log"
CHECK_INTERVAL=200           # check every 2 minutes
STALE_THRESHOLD=400          # restart if log older than 5 min
HISTORY_FILE="$HOME/autostart_setup/watchdog_history.log"
DATEFMT="+%Y-%m-%d %H:%M:%S"

echo "[$(date "$DATEFMT")] 🧠 Gensyn watchdog started..."
echo "[$(date "$DATEFMT")] Monitoring log: $LOG_FILE" | tee -a "$HISTORY_FILE"

while true; do
  if [ ! -f "$LOG_FILE" ]; then
    echo "[$(date "$DATEFMT")] ⚠️  Log missing — starting RL-Swarm fresh..." | tee -a "$HISTORY_FILE"
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

  # 🔪 Kill previous RL-Swarm processes
  swarm_pid=$(pgrep -f "run_rl_swarm.sh")
  if [ -n "$swarm_pid" ]; then
    echo "[$(date "$DATEFMT")] Killing RL-Swarm PID=$swarm_pid" | tee -a "$HISTORY_FILE"
    kill -9 "$swarm_pid" 2>/dev/null
  fi

  # 🧹 Close old Terminal windows with rl-swarm
  osascript -e 'tell application "Terminal" to close (every window whose name contains "rl-swarm")' 2>/dev/null
  sleep 2

  # 🚀 Launch new Terminal and start Expect auto script
  echo "[$(date "$DATEFMT")] 🚀 Launching new Terminal session..." | tee -a "$HISTORY_FILE"
  osascript <<'APPLESCRIPT'
tell application "Terminal"
    if not (exists window 1) then reopen
    do script "cd ~/rl-swarm; source .venv/bin/activate; expect ~/autostart_setup/gensyn_autostart.exp"
    activate
end tell
APPLESCRIPT

  echo "[$(date "$DATEFMT")] ✅ Restart executed successfully." | tee -a "$HISTORY_FILE"
  sleep $CHECK_INTERVAL
done
