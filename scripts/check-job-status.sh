#!/usr/bin/env bash
# filepath: scripts/check-job-status.sh

status="$1"

if [[ "$status" == "failure" ]]; then
  echo "Previous job failed. Skipping this job."
  exit 78
elif [[ "$status" == "skipped" ]]; then
  echo "Previous job was skipped due to a spoke environment being destroyed. Continuing."
else
  echo "Previous job succeeded. Continuing."
fi