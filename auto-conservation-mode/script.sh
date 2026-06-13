#!/usr/bin/env bash
set -euo pipefail

CONSERVATION_PATH="/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
THRESHOLD=95
INTERVAL=30

BATTERY="$(find /sys/class/power_supply -maxdepth 1 -type l -name 'BAT*' | head -n1)"
AC="$(find /sys/class/power_supply -maxdepth 1 -type l ! -name 'BAT*' | head -n1)"

log() {
  echo "[$(date '+%F %T')] $*"
}

set_conservation() {
  local value="$1"
  local current
  current="$(cat "$CONSERVATION_PATH")"

  if [[ "$current" != "$value" ]]; then
    echo "$value" >"$CONSERVATION_PATH"
    [[ "$value" == "1" ]] && log "Conservation mode: OFF → ON" || log "Conservation mode: ON → OFF"
  fi
}

while true; do
  if [[ ! -e "$CONSERVATION_PATH" ]]; then
    log "Missing conservation path: $CONSERVATION_PATH"
    sleep "$INTERVAL"
    continue
  fi

  capacity="$(cat "$BATTERY/capacity")"
  ac_online="$(cat "$AC/online" 2>/dev/null || echo 0)"

  if [[ "$ac_online" == "1" ]]; then
    if ((capacity >= THRESHOLD)); then
      set_conservation 1
    else
      set_conservation 0
    fi
  else
    if ((capacity < THRESHOLD)); then
      set_conservation 0
    fi
  fi

  sleep "$INTERVAL"
done
