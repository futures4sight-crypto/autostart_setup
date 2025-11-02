#!/bin/bash
# ============================================================
# GENSYN WATCHDOG (macOS local version - full restart mode)
# Kills any stuck RL-Swarm, closes Terminal, opens new one
# ============================================================

LOG_FILE="$HOME/rl-swarm/user/logs/swarm_launcher.log"
CHECK_INTERVAL=300           # 5 min
STALE_THRESHOLD=900          # 15 min
HISTORY_FILE="$HOME/autostart_setup/watchdog_history.log"
DATEFMT="+%Y-%m-%d %H:%M:%S"
RUN_SCRIPT="$HOME/rl-swarm/run_rl_swarm.sh"

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
    echo "[$(date "$DATEFMT")] ❌ Log stale — restarting environment..." | tee -a "$HISTORY_FILE"
  fi

  # === Kill existing RL-Swarm process if any ===
  swarm_pid=$(pgrep -f "run_rl_swarm.sh")
  if [ -n "$swarm_pid" ]; then
    echo "[$(date "$DATEFMT")] 🔪 Killing stuck RL-Swarm process (PID=$swarm_pid)" | tee -a "$HISTORY_FILE"
    kill -9 "$swarm_pid" 2>/dev/null
  fi

  # === Close all Terminal windows that are stuck ===
  echo "[$(date "$DATEFMT")] 🧹 Closing old Terminal windows..." | tee -a "$HISTORY_FILE"
  osascript -e 'tell application "Terminal" to close (every window whose name contains "rl-swarm")' 2>/dev/null

  sleep 2

  # === Start fresh in a new Terminal window ===
  echo "[$(date "$DATEFMT")] 🚀 Starting new Terminal for RL-Swarm..." | tee -a "$HISTORY_FILE"
  osascript -e '
      tell application "Terminal"
          do script "cd ~/rl-swarm && source .venv/bin/activate && bash run_rl_swarm.sh"
          activate
      end tell
  '

  echo "[$(date "$DATEFMT")] ✅ Restart command executed successfully." | tee -a "$HISTORY_FILE"
  sleep $CHECK_INTERVAL
done
