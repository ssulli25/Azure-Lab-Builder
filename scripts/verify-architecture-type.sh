#!/bin/bash

# Verify the architecture_type workflow input is one of the supported values.
# Usage: verify-architecture-type.sh <architecture_type>
# Allowed values: 3tier | microservices

ARCH="$1"

case "$ARCH" in
    3tier|microservices)
        echo "Architecture type '$ARCH' is valid. Proceeding with pipeline."
        ;;
    "")
        echo "ERROR: No architecture_type provided. Expected '3tier' or 'microservices'."
        exit 1
        ;;
    *)
        echo "ERROR: Invalid architecture_type '$ARCH'. Expected '3tier' or 'microservices'."
        exit 1
        ;;
esac
