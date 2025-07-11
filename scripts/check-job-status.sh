#!/usr/bin/env bash
# Usage: ./check-job-status.sh <job_result_1> <job_result_2> ...

for status in "$@"; do
  if [[ "$status" == "failure" || "$status" == "cancelled" ]]; then
    echo "A required upstream job failed or was cancelled: $status"
    exit 78  # GitHub Actions: neutral/skip
  fi
done

# If we get here, no failures or cancellations were found.
echo "All required upstream jobs succeeded or were skipped. Continuing."
exit 0