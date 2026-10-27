#!/bin/bash
# Get the name of the current Git branch.
CURRENT_BRANCH=$(git branch --show-current)

# Stop if Git could not determine the current branch.
if [ -z "$CURRENT_BRANCH" ]; then
    echo "Could not determine current branch."
    exit 1
fi

# Prevent this helper from pushing directly to main.
if [ "$CURRENT_BRANCH" = "main" ]; then
    echo "ERROR: You are on main."
    echo "This script only pushes feature branches."
    exit 1
fi

# Ensure the current branch follows the feature/* naming convention.
if [[ "$CURRENT_BRANCH" != feature/* ]]; then
    echo "ERROR: You are not on a feature branch."
    echo "Current branch: $CURRENT_BRANCH"
    exit 1
fi

# Display the current branch.
echo ""
echo "Current branch: $CURRENT_BRANCH"

# Display modified, untracked, and staged files.
echo ""
echo "Checking changes..."
git status

# Ask for confirmation before staging and pushing anything.
echo ""
read -p "Do you want to add, commit and push these changes? (y/n): " CONFIRM

# Stop if the user does not confirm.
if [ "$CONFIRM" != "y" ]; then
    echo "Operation cancelled."
    exit 0
fi

# Stage all changes in the repository.
echo ""
echo "Adding changes..."
git add .

# Check whether the staging area contains any changes.
git diff --cached --quiet

# Exit if there is nothing to commit.
if [ $? -eq 0 ]; then
    echo "No changes to commit."
    exit 0
fi

# Ask the developer for a commit message.
echo ""
read -p "Enter commit message: " COMMIT_MESSAGE

# Prevent an empty commit message.
if [ -z "$COMMIT_MESSAGE" ]; then
    echo "ERROR: Commit message cannot be empty."
    exit 1
fi

# Create the Git commit.
echo ""
echo "Creating commit..."
git commit -m "$COMMIT_MESSAGE"

# Stop if the commit failed.
if [ $? -ne 0 ]; then
    echo "Commit failed."
    exit 1
fi

# Push the current feature branch to GitHub.
echo ""
echo "Pushing to GitHub..."
git push -u origin "$CURRENT_BRANCH"

# Stop if the push failed.
if [ $? -ne 0 ]; then
    echo "Push failed."
    exit 1
fi

# Confirm successful push.
echo ""
echo "Successfully pushed to $CURRENT_BRANCH"