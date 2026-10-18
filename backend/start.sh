#!/bin/sh
# MySun backend: installs libraries once, then starts the API on port 8090
# and restarts it if it stopped. Run by a cron job every minute. Safe to run repeatedly.
# For hosts with no SSH/root where a cron job is the only way to run commands.
# On a normal Linux server use the systemd setup in README.md instead.
cd "$(dirname "$0")" || exit 1

if [ ! -f .env ]; then
  echo "$(date) .env is missing - upload it next to this script" >> run.log
  exit 1
fi

if [ ! -f installed.flag ]; then
  mkdir .install.lock 2>/dev/null || exit 0   # another run is installing
  PY=$(command -v python3.12 || command -v python3)
  if "$PY" -m venv .venv && .venv/bin/pip install -r requirements.txt > setup.log 2>&1; then
    touch installed.flag
  fi
  rmdir .install.lock
  [ -f installed.flag ] || exit 1
fi

pgrep -u "$(id -u)" -f "[u]vicorn app.main:app" > /dev/null && exit 0
nohup .venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8090 --workers 2 --proxy-headers >> run.log 2>&1 &
