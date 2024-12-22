#!/bin/bash

# Verify Terraform Action is apply or destroy

if [[ "$1" =~ ^(apply|destroy)$ ]]; then
    echo "Terraform action is valid."
else
    echo "Terraform action is invalid. Please input either an apply or destroy command (case sensitive)."
    exit 1
fi