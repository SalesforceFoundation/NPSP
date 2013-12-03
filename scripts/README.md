This folder contains scripts useful in working with the Cumulus package and code.

cumulus.cfg
===========

This config file contains common values used by the scripts such as version numbers and installation urls.

set_dependent_versions.py
=========================

This script uses the values in scripts/cumulus.cfg to ensure all references to a dependent package version are correct
- \*-meta.xml files require the correct dependent package versions
- Install links in README.md in the root of the repository
- version.NAMESPACE properties in build.xml

The script will list all the files it examines and any changes it makes to those files.

`python scripts/set_dependent_versions.py`
