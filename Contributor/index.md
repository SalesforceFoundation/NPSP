---
title: NPSP Code Contributor's Guide: How to Contribute Code to the Nonprofit Success Pack
layout: default
---
# How to Contribute Code to the Nonprofit Success Pack

The Nonprofit Success Pack (NPSP) is an application that integrates directly with Salesforce to help nonprofits and higher ed institutions use Salesforce more effectively. The NPSP is an open-source project that thrives on the generosity of its developer community. Along with the information in these documents, **please read [Contributing to the Nonprofit Success Pack] 

This document outlines everything you need to know to start contributing code to the NPSP. We’ll show you how to set up your development environment, how to develop in the NPSP code base, and how to submit changes to the Salesforce Foundation for review. We're assuming you're using a unix environment, such as Linux or OS X. If you're a windows user, you may need to set up a unix command line such as the new [Windows Subsystem for Linux](https://msdn.microsoft.com/en-us/commandline/wsl/about), aka *Bash on Ubuntu on Windows* (Windows 10 only), or [Cygwin](https://www.cygwin.com/).

# GIT and Initial Setup

1.  [Set up git and github](Github.html)
    - Create a github account
    - Fork the NPSP repository
    - Set up SSH access to github (optional, but recommended)
    - Copy your forked repository to your local machine
        - ```git clone git@github.com:[YourUserName]/Cumulus.git``` (ssh) *or*
        - ```git clone https://github.com/[YourUserName]/Cumulus.git``` (https) 
2. [Set up Salesforce Developer Edition](Developer-Edition-Salesforce-Instance.html)
3. [Set up Cumulus CI](http://cumulusci.readthedocs.io/en/latest/tutorial.html)
    - Install prerequisites and CumulusCI
    - Set CUMULUSCI_KEY environment variable
    - **Skip** Project Initialization steps - the cloned repo is already set up for CumulusCI
    - Create Connected App
    - Connect the Developer Edition org you created in and set as default.
    - Run the ```dev_org``` CCI flow
        - ```cci flow run dev_org```
    - Run the ```test_data_dev_org``` flow to get some NPSP test data in there (optional but recommended)
        - ```cci flow run test_data_dev_org```
4. Set up an IDE
    - [Force.com IDE](Force.com-IDE-Setup.html)
    - [Alternate IDEs](Alternate-IDEs.html) (MavensMate, et al.)
5. [Do the work!](Do-the-Work.html)
    - [ApexDoc](http://developer.salesforcefoundation.org/Cumulus/ApexDocumentation/)
    - Coding conventions
    - [TDTM](http://developer.salesforcefoundation.org/index.html#blog/post/2014/11/24/table-driven-trigger-management.html)
    - [Error Handling](http://developer.salesforcefoundation.org/index.html#blog/post/2015/02/03/how-npsp-does-error-handling-on-salesforce.html)

5. [Submit the work](Submit-Your-Feature.html)

# Legacy CumulusCI 1.x instructions 
    - Create a build.properties file at the root of your git repository, with these lines:
        - ```sf.serverurl=https://login.salesforce.com```
        - ```sf.username=your_de_login@salesforce.com```
        - ```sf.password=passwordAndSecurityToken```
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