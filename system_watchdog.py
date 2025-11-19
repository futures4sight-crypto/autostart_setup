#!/usr/bin/env python3
import time
import requests
import os

TELEGRAM_TOKEN = "8273442017:AAF19yy27wjBiB8zx5vuJewA0drew51TYaM"
TELEGRAM_CHAT_ID = "5071830753"
THRESHOLD = 900  # 15 minutes

def send_telegram(msg):
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    requests.post(url, data={"chat_id": TELEGRAM_CHAT_ID, "text": msg})

while True:
    try:
        ts = float(open("/tmp/monitor_heartbeat.txt").read().strip())
        if time.time() - ts > THRESHOLD:
            send_telegram("❗ Main monitoring script is not responding for 15 minutes!")
    except:
        send_telegram("❗ Heartbeat file missing — main monitor not running!")

    time.sleep(120)
