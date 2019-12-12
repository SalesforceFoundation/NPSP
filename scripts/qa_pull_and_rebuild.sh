#!/usr/bin/env bash

# Script to be used by qa to rebuild a scratch environment.
# To run paste into command line "bash scripts/qa_rebuild_script.sh <orgname> <branch>"
# For example "bash scripts/qa_rebuild_script.sh W-037818 feature/RD2__rad-data-migration-display-errors"

# ***IMPORTANT*** This script will rollback any modifications to files and delete a scratch org with the same name.

# Remove any existing modified files so a pull can take place
git checkout -- .

# Switch to desired branch
git checkout $2

# Pull most recent changes
git pull

# Delete exisiting scratch org if one exists with provided name
cci org scratch_delete $1

# Rebuild org with qa flow
cci flow run qa_org --org $1

# Mark org as default
cci org default $1

# Open newly created org
cci org browser $1