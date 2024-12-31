#!/bin/bash

# Verify Environment Name is dev, test, or prod

if [[ "$1" =~ ^(dev|test|prod)$ ]]; then
    echo "Environment name is valid."
else
    echo "Environment name is invalid. Please input either dev, test, or prod (case sensitive)."
    exit 1
fi