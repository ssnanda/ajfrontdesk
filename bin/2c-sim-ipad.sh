#!/usr/bin/env bash
set -e

# AJ Front Desk — iPad simulator launcher
# ----------------------------------
#
# Common runs:
#   ./bin/2c-sim-ipad.sh

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE_ID="742ECF76-F70A-44B7-A614-6785A7AA8B11"
DEVICE_NAME="iPad"
PID_FILE="/tmp/ajfrontdesk_flutter.pid"

usage() {
  cat <<'USAGE'
AJ Front Desk — iPad simulator launcher.

Usage:
  ./bin/2c-sim-ipad.sh [options]

Options:
  --device ID   Simulator UDID (default: configured iPad)
  --help

Hot reload (while Flutter is running in this terminal):
  r   Hot reload  — fast, keeps state
  R   Hot restart — slower, resets state
  q   Quit
USAGE
}

flutter config --no-enable-swift-package-manager 2>/dev/null || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)   DEVICE_ID="${2:-}"; shift 2 ;;
    --help|-h)  usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
done

echo ""
echo "Starting $DEVICE_NAME simulator ($DEVICE_ID)..."

if ! xcrun simctl list devices | grep -q "$DEVICE_ID"; then
  echo "Device $DEVICE_ID not found. Available iPads:"
  xcrun simctl list devices | grep "iPad"
  exit 1
fi

DEVICE_STATE=$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -o "Booted\|Shutdown" || echo "Unknown")

if [[ "$DEVICE_STATE" == "Booted" ]]; then
  echo "Simulator already running."
else
  echo "Booting simulator..."
  xcrun simctl boot "$DEVICE_ID" 2>&1 || true
  sleep 5
fi

echo "Opening Simulator.app..."
open -a Simulator
sleep 3

MAX_ATTEMPTS=30
ATTEMPT=0
while [[ $ATTEMPT -lt $MAX_ATTEMPTS ]]; do
  [[ "$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -o "Booted" || echo "")" == "Booted" ]] && break
  echo "Waiting for boot... ($ATTEMPT/$MAX_ATTEMPTS)"
  sleep 1
  ATTEMPT=$((ATTEMPT+1))
done

[[ $ATTEMPT -eq $MAX_ATTEMPTS ]] && { echo "Simulator failed to boot." >&2; exit 1; }

echo ""
echo "Hot reload: press 'r' in this terminal | Hot restart: press 'R'"
echo ""
cd "$ROOT_DIR"
flutter run -d "$DEVICE_ID" \
  --pid-file "$PID_FILE"
