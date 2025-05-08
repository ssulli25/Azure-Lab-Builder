#!/bin/bash

# Verify Deployment of Architecture

if [ "${{ github.event.inputs.architecture }}" = "false" ]; then
    echo "Deployment is not needed. Exiting pipeline."
    exit 0
else
    echo "Deployment is enabled. Proceeding with pipeline."
fi
