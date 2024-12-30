#!/bin/bash

# Verify Environment Name is web, app, or data

if [[ "$1" =~ ^(web|app|data)$ ]]; then
    echo "Image build environment name is valid."
else
    echo "Image build environment name is invalid. Please input either web, app, or data (case sensitive)."
    exit 1
fi