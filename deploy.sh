#!/bin/sh

# If a command fails then the deploy stops
set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# Build the project.
hugo -t docsy 

vine=$GOPATH/src/github.com/lack-io/vine
if [[ -e "$vine" ]];then
    rm -fr $vine/docs/*
    mv public/* $vine/docs/
    rm -fr public
    echo "update docs to github.com/lack-io/vine"
fi

# Add changes to git.
git add .

# Commit changes.
msg="rebuilding site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg"

# Push source and build repos.
git push -u origin main