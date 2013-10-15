h1. Cumulus Scripts
This folder contains scripts useful in working with the Cumulus package and code.

h2. cumulus.cfg

This config file contains common values used by the scripts such as version numbers and installation urls.

h2. set_dependent_versions.py

This script uses the values in scripts/cumulus.cfg to ensure all \*-meta.xml files require the correct dependent package versions.  The script will list all the files it examines and any changes it makes to those files

`python scripts/set_dependent_versions.py`

h2. setup_dev_org.py

This script uses Selenium to automate the browser based tasks of setting up a new Developer Edition org to handle deployment of the Cumulus code into the organization passing all tests.  In order to run this, you will need to have a working version of Python, selenium, and Firefox.  On OS X, you can use the built in system python and use the following command to install selenium if not already installed:

`sudo easy_install selenium`

To run the script from the root of the repository, run the following command and provide the credentials to the target org when prompted:

`python scripts/setup_dev_org.py`
