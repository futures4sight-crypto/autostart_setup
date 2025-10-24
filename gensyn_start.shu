#!/bin/bash

# Duže čekanje jer Docker treba da se stabilizuje
sleep 40

# Ulazak u folder i pokretanje Expect skripte
cd ~/autostart_setup || exit 1
git pull
/opt/homebrew/bin/expect ./gensyn_autostart.exp

