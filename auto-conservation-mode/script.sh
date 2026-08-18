#!/usr/bin/env bash
set -euo pipefail

THRESHOLD="${THRESHOLD:-95}"
INTERVAL="${INTERVAL:-30}"
POWER_SUPPLY_ROOT="${POWER_SUPPLY_ROOT:-/sys/class/power_supply}"
IDEAPAD_DRIVER_ROOT="${IDEAPAD_DRIVER_ROOT:-/sys/bus/platform/drivers/ideapad_acpi}"

CONSERVATION_PATH=""
BATTERY=""
declare -a AC_SUPPLIES=()

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

discover_devices() {
  local supply supply_type supply_scope
  local -a conservation_paths

  # The ACPI device name is firmware-specific, so do not assume VPC2004:00.
  shopt -s nullglob
  conservation_paths=("$IDEAPAD_DRIVER_ROOT"/*/conservation_mode)
  shopt -u nullglob
  CONSERVATION_PATH="${conservation_paths[0]:-}"

  BATTERY=""
  AC_SUPPLIES=()
  for supply in "$POWER_SUPPLY_ROOT"/*; do
    [[ -r "$supply/type" ]] || continue
    supply_type="$(<"$supply/type")"
    supply_scope=""
    [[ ! -r "$supply/scope" ]] || supply_scope="$(<"$supply/scope")"

    if [[ -z "$BATTERY" && "$supply_type" == "Battery" &&
          "$supply_scope" != "Device" && -r "$supply/capacity" ]]; then
      # Device-scoped batteries belong to peripherals such as wireless mice.
      BATTERY="$supply"
    elif [[ "$supply_type" != "Battery" && -r "$supply/online" ]]; then
      AC_SUPPLIES+=("$supply")
    fi
  done
}

if [[ ! "$THRESHOLD" =~ ^[0-9]+$ ]] || ((THRESHOLD < 1 || THRESHOLD > 100)); then
  log "THRESHOLD must be an integer from 1 to 100 (got: $THRESHOLD)"
  exit 2
fi

if [[ ! "$INTERVAL" =~ ^[0-9]+$ ]] || ((INTERVAL < 1)); then
  log "INTERVAL must be a positive integer (got: $INTERVAL)"
  exit 2
fi

while true; do
  # Re-scan because docks and USB-C power supplies can appear or disappear.
  discover_devices

  if [[ -z "$CONSERVATION_PATH" || ! -w "$CONSERVATION_PATH" ]]; then
    log "No writable Lenovo conservation_mode interface found"
    sleep "$INTERVAL"
    continue
  fi

  if [[ -z "$BATTERY" || ${#AC_SUPPLIES[@]} -eq 0 ]]; then
    log "Could not find both a laptop battery and an online-capable AC supply"
    sleep "$INTERVAL"
    continue
  fi

  capacity="$(<"$BATTERY/capacity")"
  ac_online=0
  for supply in "${AC_SUPPLIES[@]}"; do
    if [[ "$(<"$supply/online")" == "1" ]]; then
      ac_online=1
      break
    fi
  done

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
