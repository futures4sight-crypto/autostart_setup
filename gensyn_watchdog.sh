#!/bin/bash
# ============================================================
# 🧠 GENSYN WATCHDOG (macOS local version - stable auto expect)
# Monitors RL-Swarm log, restarts if frozen, auto-answers prompts
# ============================================================

LOG_FILE="$HOME/rl-swarm/logs/swarm_launcher.log"   # <-- update ako je folder "log" umesto "logs"
CHECK_INTERVAL=300           # check every 5 minutes
STALE_THRESHOLD=900          # restart if log older than 15 minutes
HISTORY_FILE="$HOME/autostart_setup/watchdog_history.log"
DATEFMT="+%Y-%m-%d %H:%M:%S"
RUN_SCRIPT="$HOME/rl-swarm/run_rl_swarm.sh"

echo "[$(date "$DATEFMT")] 🧠 Gensyn watchdog started..."
echo "[$(date "$DATEFMT")] Monitoring log: $LOG_FILE" | tee -a "$HISTORY_FILE"

while true; do
  # 🧩 Check if RL-Swarm is already running
  running_pid=$(pgrep -f "run_rl_swarm.sh")
  if [ -n "$running_pid" ]; then
    echo "[$(date "$DATEFMT")] ⚙️  RL-Swarm already running (PID=$running_pid)" | tee -a "$HISTORY_FILE"
    sleep $CHECK_INTERVAL
    continue
  fi

  # 🧩 Check log freshness
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

  # 🔪 Kill any previous RL-Swarm or hung processes
  swarm_pid=$(pgrep -f "run_rl_swarm.sh")
  if [ -n "$swarm_pid" ]; then
    echo "[$(date "$DATEFMT")] Killing RL-Swarm PID=$swarm_pid" | tee -a "$HISTORY_FILE"
    kill -9 "$swarm_pid" 2>/dev/null
  fi

  # 🧹 Close old Terminal windows named rl-swarm
  osascript -e 'tell application "Terminal" to close (every window whose name contains "rl-swarm")' 2>/dev/null
  sleep 2

  # 🚀 Launch new Terminal and auto-answer prompts
  echo "[$(date "$DATEFMT")] 🚀 Launching new Terminal session..." | tee -a "$HISTORY_FILE"
  osascript -e '
    tell application "Terminal"
        do script "cd ~/rl-swarm && source .venv/bin/activate && \
        expect -c \"log_user 1; \
        spawn bash run_rl_swarm.sh; \
        expect \\\">> Would you like to push models you train in the RL swarm to the Hugging Face Hub?*\\\" { send \\\"n\\\\r\\\" }; \
        expect \\\">> Enter the name of the model you want to use in huggingface repo/name format,*\\\" { send \\\"\\\\r\\\" }; \
        expect \\\">> Would you like your model to participate in the AI Prediction Market?*\\\" { send \\\"n\\\\r\\\" }; \
        interact\""
        set custom title of front window to "rl-swarm"
        activate
    end tell
  '

  echo "[$(date "$DATEFMT")] ✅ Restart executed successfully." | tee -a "$HISTORY_FILE"
  sleep $CHECK_INTERVAL
done
