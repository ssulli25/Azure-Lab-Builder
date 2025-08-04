#!/usr/bin/env bash
# Usage: ./check-job-status.sh <job1_result> <job2_result> ...

for result in "$@"; do
  if [[ "$result" == "failure" || "$result" == "cancelled" ]]; then
    echo "A required job failed or was cancelled: $result"
    exit 1
  fi
done

# If we reach here, all jobs were either 'success' or 'skipped'
echo "All required jobs succeeded or were skipped. Continuing."
exit 0