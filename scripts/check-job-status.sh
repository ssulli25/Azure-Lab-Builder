#!/usr/bin/env bash

set -e

echo "Checking upstream job results: $*"

for status in "$@"; do
  case "$status" in
    failure)
      echo "Upstream job failed. Skipping this job."
      exit 78
      ;;
    cancelled)
      echo "Upstream job was cancelled. Skipping this job."
      exit 78
      ;;
    success)
      echo "Upstream job succeeded."
      ;;
    skipped)
      echo "Upstream job was skipped."
      ;;
    *)
      echo "Unknown job status: $status"
      exit 1
      ;;
  esac
done

echo "All required upstream jobs succeeded or were skipped. Continuing."