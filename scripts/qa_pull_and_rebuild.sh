#!/usr/bin/env bash

# Script to be used by qa to rebuild a scratch environment.

echo This script is to be used by qa to rebuild a scratch environment.
echo ***WARNING*** This script will rollback any modifications to files and delete a scratch org with the same name given. Please commit any file changes before running this script. ***WARNING***

read -p "Are you sure? [Y/n]" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then

echo What branch would you like to pull most recent changes from?? [example: W-123456]
read 1

echo What would you like to name your org? [example: W-123456]
read 2


# Remove any existing modified files so a pull can take place
git checkout -- .

# Switch to desired branch
git checkout $1

# Pull most recent changes
git pull

# Delete exisiting scratch org if one exists with provided name
cci org scratch_delete $2

# Rebuild org with qa flow
cci flow run qa_org --org $2

# Mark org as default
cci org default $2

# Open newly created org
cci org browser $2

fi