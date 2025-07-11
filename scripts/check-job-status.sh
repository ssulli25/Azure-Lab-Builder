#!/usr/bin/env bash
# filepath: scripts/check-job-status.sh

for status in "$@"; do
  if [[ "$status" == "failure" ]]; then
    echo "A previous job failed. Skipping this job."
    exit 78
  elif [[ "$status" == "cancelled" ]]; then
    echo "A previous job was cancelled. Skipping this job."
    exit 78
  elif [[ "$status" == "skipped" ]]; then
    echo "A previous job was skipped. Continuing."
  else
    echo "A previous job succeeded. Continuing."
  fi
done