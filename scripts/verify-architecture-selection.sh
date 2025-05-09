#!/bin/bash

# Verify Deployment of Architecture

if [ "$1" = "false" ]; then
    echo "Deployment is not needed. Exiting pipeline."
    exit 0
else
    echo "Deployment is enabled. Proceeding with pipeline."
fi
