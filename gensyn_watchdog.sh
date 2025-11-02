#!/bin/bash
# ============================================================
# GENSYN WATCHDOG (macOS local version - auto expect)
# Monitors log, kills stuck process, restarts with auto answers
# ============================================================

LOG_FILE="$HOME/rl-swarm/user/logs/swarm_launcher.log"
CHECK_INTERVAL=300
STALE_THRESHOLD=900
HISTORY_FILE="$HOME/autostart_setup/watchdog_history.log"
DATEFMT="+%Y-%m-%d %H:%M:%S"
RUN_SCRIPT="$HOME/rl-swarm/run_rl_swarm.sh"

echo "[$(date "$DATEFMT")] 🧠 Gensyn watchdog (auto expect) started..."
echo "[$(date "$DATEFMT")] Monitoring log: $LOG_FILE" | tee -a "$HISTORY_FILE"

while true; do
  if [ ! -f "$LOG_FILE" ]; then
    echo "[$(date "$DATEFMT")] ⚠️  Log missing — starting RL-Swarm..." | tee -a "$HISTORY_FILE"
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

  # 🔪 Kill stuck process
  swarm_pid=$(pgrep -f "run_rl_swarm.sh")
  if [ -n "$swarm_pid" ]; then
    echo "[$(date "$DATEFMT")] Killing RL-Swarm PID=$swarm_pid" | tee -a "$HISTORY_FILE"
    kill -9 "$swarm_pid" 2>/dev/null
  fi

  osascript -e 'tell application "Terminal" to close (every window whose name contains "rl-swarm")' 2>/dev/null
  sleep 2

  # 🚀 Start new terminal and auto-answer with expect
  echo "[$(date "$DATEFMT")] Starting new Terminal session..." | tee -a "$HISTORY_FILE"
  osascript -e '
    tell application "Terminal"
        do script "cd ~/rl-swarm && source .venv/bin/activate && expect -c \"spawn bash run_rl_swarm.sh; expect \\\"Would you like to push models.*\\\" { send \\\"n\\\\r\\\" }; expect \\\"Enter the name.*\\\" { send \\\"\\\\r\\\" }; expect \\\"AI Prediction Market.*\\\" { send \\\"n\\\\r\\\" }; interact\""
        activate
    end tell
  '

  echo "[$(date "$DATEFMT")] ✅ Restart executed and expect injected." | tee -a "$HISTORY_FILE"
  sleep $CHECK_INTERVAL
done
