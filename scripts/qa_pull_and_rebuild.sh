#!/usr/bin/env bash

# Script to be used by qa to rebuild a scratch environment.

echo This script is to be used by qa to rebuild a scratch environment.
echo ***WARNING*** This script will rollback any modifications to files and delete a scratch org with the same name given. Please commit any file changes before running this script. ***WARNING***

read -p "Are you sure? [Y/n]" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then

echo What branch would you like to pull most recent changes from?? [example: feature/julian-qa-rebuild-script]
read branch_name

echo What would you like to name your org? [example: W-123456]
read org_name


# Remove any existing modified files so a pull can take place
git checkout -- .

# Switch to desired branch
git checkout $branch_name

# Pull most recent changes
git pull

# Delete exisiting scratch org if one exists with provided name
cci org scratch_delete $org_name

# Rebuild org with qa flow
cci flow run qa_org --org $org_name

# Mark org as default
cci org default $org_name

# Open newly created org
cci org browser $org_name

fi