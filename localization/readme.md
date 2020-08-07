# NPSP Localization

* NPSP Localization Quip Doc: https://salesforce.quip.com/l9iMAjlIUuui

## The Problem With Translated Metadata

The objectTranslation and translation metadata files as provided by the Core Translation team has some formatting issues that prevent it from being merged directly into our SFDO repositories:

* The sequence of Metadata elements is changed from what is currently in the repository and what the default sequencing is as returned by any form of metadata retrieve. This creates a huge and very difficult to read “diff” in GitHub because it effectively shows that everything has been changed, making an actual review of changes impossible.
* In some cases, the Translation tooling may strip out existing translations due to issues in our existing metadata. The root issue here is not with the tooling used by the Translation Team, but instead some occasional and previously unknown issues with the metadata into the repo that up until now has not really mattered. Going back to the first bullet, if the diff is unreadable because everything has changed then it’s impossible to identify these and fix.

## The “Fix”

The effective fix for the above scenarios is to do the following, all of which is handled by the bash script in this folder:

1. Push the Translation Metadata [branch] into a Scratch Org
2. Use the retrieve_unpackaged cci task to pull down the metadata from the scratch org in the “correct” format.
3. Clean the metadata using a CCI task
4. Commit the changes to the branch

## Script in this folder

The localization folder contains a `translation-cleanup.sh` bash script file that will perform the first 3 steps above.

After executing the script, review the pending changes using an IDE such as VSCode before committing.

**ONLY changes to the 'objectTranslation' and 'translation' files should be commited to the repository. ALL OTHER CHANGED FILES SHOULD BE IGNORED.**
