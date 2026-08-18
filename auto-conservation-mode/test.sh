#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf -- "$TEST_ROOT"' EXIT

run_case() {
  local name="$1" capacity="$2" first_ac="$3" second_ac="$4"
  local initial_mode="$5" expected_mode="$6"
  local case_root="$TEST_ROOT/$name"

  mkdir -p "$case_root/power/AAA-peripheral" \
    "$case_root/power/BAT0" "$case_root/power/ADP0" \
    "$case_root/power/USBC" "$case_root/driver/VPC2004:00"

  # This peripheral deliberately sorts before BAT0 and exposes capacity. Its
  # Device scope must keep it from being mistaken for the laptop battery.
  printf 'Battery\n' >"$case_root/power/AAA-peripheral/type"
  printf 'Device\n' >"$case_root/power/AAA-peripheral/scope"
  printf '100\n' >"$case_root/power/AAA-peripheral/capacity"

  printf 'Battery\n' >"$case_root/power/BAT0/type"
  printf '%s\n' "$capacity" >"$case_root/power/BAT0/capacity"

  printf 'Mains\n' >"$case_root/power/ADP0/type"
  printf '%s\n' "$first_ac" >"$case_root/power/ADP0/online"
  printf 'USB_C\n' >"$case_root/power/USBC/type"
  printf '%s\n' "$second_ac" >"$case_root/power/USBC/online"

  printf '%s\n' "$initial_mode" >"$case_root/driver/VPC2004:00/conservation_mode"

  timeout 0.2 env \
    POWER_SUPPLY_ROOT="$case_root/power" \
    IDEAPAD_DRIVER_ROOT="$case_root/driver" \
    INTERVAL=30 \
    bash "$SCRIPT_DIR/script.sh" >/dev/null 2>&1 || {
      status=$?
      [[ "$status" == "124" ]]
    }

  actual_mode="$(<"$case_root/driver/VPC2004:00/conservation_mode")"
  if [[ "$actual_mode" != "$expected_mode" ]]; then
    printf 'FAIL: %s (expected %s, got %s)\n' \
      "$name" "$expected_mode" "$actual_mode" >&2
    return 1
  fi
  printf 'PASS: %s\n' "$name"
}

run_case plugged_below_threshold 94 1 0 1 0
run_case plugged_at_threshold 95 1 0 0 1
run_case unplugged_below_threshold 94 0 0 1 0
run_case unplugged_at_threshold_mode_on 95 0 0 1 1
run_case unplugged_at_threshold_mode_off 95 0 0 0 0
run_case second_ac_supply_online 95 0 1 0 1

if env THRESHOLD=invalid bash "$SCRIPT_DIR/script.sh" >/dev/null 2>&1; then
  echo 'FAIL: invalid threshold was accepted' >&2
  exit 1
else
  status=$?
  [[ "$status" == "2" ]]
  echo 'PASS: invalid threshold rejected'
fi

