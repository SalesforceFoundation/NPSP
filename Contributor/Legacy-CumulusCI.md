---
title: Legacy CumulusCI v1.x (Ant-based) instructions
layout: default
---
# [Home](http://developer.salesforcefoundation.org/Cumulus/Contributor/) > Legacy CumulusCI info 

CumulusCI 2 is the recommended way to move metadata in and out of your development environment. It supports a variety of functions not supported in the previous versions of CumulusCI 1.x, which were based on the Force.com Migration Tool, a Java/Ant-based command-line utility for moving metadata between a local directory and a Salesforce org. 

The Cumulus repository is still set up to work with the CumulusCI 1.x, if you already have Ant and the Force.com Migration Tool set up. Here are some instructions for using CumulusCI 1.x, preserved (with some edits) from earlier versions of the Contributor documentation. 

# Get the CumulusCI repository onto your computer

CumulusCI is a continuous integration system that aids in our development process. To set it up, you'll need to clone another github repository onto your local machine, then setup an environment variable so that we know where to find that code.

### Cloning CumulusCI.

In the command line, go to another directory where you'd like to store CumulusCI, and run the following commands to clone the repository, change into your cloned repository's directory, and then checkout the "legacy-1.0" branch that contains the Ant targets. 

~~~
git clone https://github.com/SalesforceFoundation/CumulusCI.git
cd CumulusCI
git checkout legacy1.0
~~~

Make sure to take note of this directory as we'll need it later. We're not creating a fork here as we're not expecting to make any changes to CumulusCI, although if you want to contribute to our continuous integration system, that's more than welcome.

# One last thing...

We need to add the environment variable CUMULUSCI_PATH with the path to our local CumulusCI repository.

First, open your ~/.bash_profile file, creating one first if you don't have one:

~~~
touch ~/.bash_profile
open ~/.bash_profile
~~~

Then, put the following line in your file:

~~~
export CUMULUSCI_PATH=~/Documents/dev/CumulusCI/
~~~

Lastly, back in the command line, run:

~~~
source ~/.bash_profile
~~~ 

# Initial NPSP setup

Once you have cloned your fork of the NPSP git repository in your local machine, create a file in your git directory called build.properties with the following information from your developer instance:

~~~
sf.serverurl=https://login.salesforce.com  
sf.username=your_dev_environment@email.com  
sf.password=your_dev_password_and_security_token  
~~~

Make sure your developer instance is either new or that you don’t care about any of the metadata currently residing in it. The next step will clean your developer instance and install the unmanaged code for NPSP to allow you to do your dev work.

# Ant build scripts

Ant build scripts are predefined actions that are used by our continuous integration system to manage metadata and move it between salesforce environments. Those same tools can run manually from the command line, and can be used by developers to facilitate cleaning and preparing their developer environment, as well as tracking code and metadata changes through git and the command line.

Using these build targets in combination with command line git allows the use of any IDE for contributing code to NPSP.

### Install NPSP to your dev environment

From the command line in your git repository, run:

~~~
ant deployCI
~~~

# Getting ready for a commit and pull request with CumulusCI 1.x:

To get metadata from your org into your local repository:

~~~
ant retrievePackagedToSrc
ant updatePackageXml
~~~

 
# Other CumulusCI 1.x targets

- Create the Cumulus Unmanaged Package
    - Each time new metadata is added through the UI or created via your IDE, it must be added to the unmanaged package.
    - Note: ANT scripts are not currently configured to handle all metadata types (weblinks and others are not yet supported)
- Use ant build target to set up your DE org
    - ```ant deployDevOrg```
- Ant build targets
    - To update metadata added through the UI and in the Cumulus unmanaged package:
        - ```ant retrievePackagedToSrc```
        - ```ant updatePackageXml```

    - After a pull, to update your dev environment with any changes pulled down from github:
        - ```ant updatePackageXml```
        - ```ant deployWithoutTest```
