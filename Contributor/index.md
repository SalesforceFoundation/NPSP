---
title: NPSP Code Contributor's Guide: How to Contribute Code to the Nonprofit Starter Pack
layout: default
---
# How to Contribute Code to the Nonprofit Starter Pack

The Nonprofit Starter Pack (NPSP) is an application that integrates directly with Salesforce to help nonprofits and higher ed institutions use Salesforce more effectively. The NPSP is an open-source project that thrives on the generosity of its developer community.

This document outlines everything you need to know to start contributing code to the NPSP. We’ll show you how to set up your development environment, how to develop in the NPSP code base, and how to submit changes to the Salesforce Foundation for review. We're assuming you're using a unix environment, such as Linux or OS X. If you're a windows user, you may need to set up a unix command line such as [Cygwin](https://www.cygwin.com/).

# GIT and Initial Setup

1.  [Set up git and github](Github.html)
    - Create a github account
    - Fork the NPSP repository
    - Set up SSH access to github
    - Copy your forked repository to your local machine
        - ```git clone https://github.com/SalesforceFoundation/Cumulus.git```
    - Create a build.properties file at the root of your git repository, with these lines:
        - ```sf.serverurl=https://login.salesforce.com```
        - ```sf.username=your_de_login@salesforce.com```
        - ```sf.password=passwordAndSecurityToken```
2.  [Set up Salesforce Developer Edition](Developer-Edition-Salesforce-Instance.html)
    - Create a new Salesforce Developer Edition organization
    - Create the Cumulus Unmanaged Package
        - Each time new metadata is added through the UI or created via your IDE, it must be added to the unmanaged package.
        - Note: ANT scripts are not currently configured to handle all metadata types (weblinks and others are not yet supported)
    - Use ant build target to set up your DE org
        - ```ant deployDevOrg```
3. Set up an IDE
    - [Force.com IDE](Force.com-IDE-Setup.html)
    - [Alternate IDEs](Alternate-IDEs.html) (MavensMate, et al.)
4. [Do the work!](Do-the-Work.html)
    - [ApexDoc](http://developer.salesforcefoundation.org/Cumulus/ApexDocumentation/)
    - Coding conventions
    - [TDTM](http://developer.salesforcefoundation.org/index.html#blog/post/2014/11/24/table-driven-trigger-management.html)
    - [Error Handling](http://developer.salesforcefoundation.org/index.html#blog/post/2015/02/03/how-npsp-does-error-handling-on-salesforce.html)
    - Ant build targets
        - To update metadata added through the UI and in the Cumulus unmanaged package:
            - ```ant retrievePackagedToSrc```
            - ```ant updatePackageXml```

        - After a pull, to update your dev environment with any changes pulled down from github:
            - ```ant updatePackageXml```
            - ```ant deployWithoutTest```
5. [Submit the work](Submit-Your-Feature.html)
