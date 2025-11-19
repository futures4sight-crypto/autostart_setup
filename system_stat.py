#!/usr/bin/env python3
import psutil
import time
import requests
from datetime import datetime

# ---- CONFIG ----
CPU_THRESHOLD = 30        # %
RAM_THRESHOLD = 50        # %
MINUTES_REQUIRED = 15
CHECK_INTERVAL = 60       # seconds

TELEGRAM_TOKEN = "8273442017:AAF19yy27wjBiB8zx5vuJewA0drew51TYaM"
TELEGRAM_CHAT_ID = "5071830753"

def send_telegram(msg):
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    requests.post(url, data={"chat_id": TELEGRAM_CHAT_ID, "text": msg})

cpu_low_minutes = 0
ram_low_minutes = 0

while True:
    cpu = psutil.cpu_percent(interval=1)
    ram = psutil.virtual_memory().percent

    # Heartbeat for watchdog
    with open("/tmp/monitor_heartbeat.txt", "w") as f:
        f.write(str(time.time()))

    # CPU check
    if cpu < CPU_THRESHOLD:
        cpu_low_minutes += 1
        if cpu_low_minutes >= MINUTES_REQUIRED:
            send_telegram(f"⚠️ CPU is below {CPU_THRESHOLD}% for {MINUTES_REQUIRED} minutes! Current: {cpu}%")
            cpu_low_minutes = 0
    else:
        cpu_low_minutes = 0

    # RAM check
    if ram < RAM_THRESHOLD:
        ram_low_minutes += 1
        if ram_low_minutes >= MINUTES_REQUIRED:
            send_telegram(f"⚠️ RAM is below {RAM_THRESHOLD}% for {MINUTES_REQUIRED} minutes! Current: {ram}%")
            ram_low_minutes = 0
    else:
        ram_low_minutes = 0

    time.sleep(CHECK_INTERVAL)
