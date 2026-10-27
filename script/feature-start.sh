#!/bin/bash

# Get the feature name from the first command-line argument.
FEATURE_NAME=$1

# Stop if no feature name was provided.
if [ -z "$FEATURE_NAME" ]; then
    echo "Usage: ./scripts/feature-start.sh <feature-name>"
    exit 1
fi

# Build the feature branch name.
BRANCH_NAME="feature/$FEATURE_NAME"

# Create the branch and switch to it.
git switch -c "$BRANCH_NAME"

# Check whether branch creation/switching succeeded.
if [ $? -ne 0 ]; then
    echo "Failed to create feature branch."
    exit 1
fi

# Confirm the branch that was created.
echo "Feature branch created successfully!"
echo "Current branch: $BRANCH_NAME"