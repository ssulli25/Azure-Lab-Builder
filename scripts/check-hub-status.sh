#!/usr/bin/env bash

# Usage: ./scripts/check-hub-status.sh <hub_status>
# Exits 78 (skipped) if hub_status is "failure", otherwise continues.

HUB_STATUS="$1"

if [[ "$HUB_STATUS" == "failure" ]]; then
  echo "Hub deployment failed. Skipping spoke job."
  exit 78
fi

echo "Hub deployment succeeded or was skipped. Continuing spoke job."
exit 0