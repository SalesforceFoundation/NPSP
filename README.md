Cumulus
=======

ducking-octo-happiness, laughing-archer

[![Build Status](http://ci.salesforcefoundation.org/buildStatus/icon?job=Cumulus_dev)](http://ci.salesforcefoundation.org/job/Cumulus_dev/)

**Contributor Install Instructions**

* Create a new DE org by going to developer.force.com
* Login to your DE Org. 
* Create an Opportunity Sales Process (Setup | Customize | Opportunity | Sales Process)
* Create an Opportunity Record Type (Setup | Customize | Opportunity | Record Type)
* Install the 5 required Nonprofit Starter Pack Packages  
 
    * [Affiliations](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000cZtq)
    * [Contacts_and_Organizations](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000cd2w)
    * [Households](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000lNu0)
    * [Recurring_Donations](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000pZK6)
    * [Relationships](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000pY9P)

* Fork this repository 'dev' branch
* Clone your fork to your local machine
```
$ git clone https://github.com/*username*/Cumulus.git
```
* In your IDE of your choice, create a new project based on your cloned report (If you checked out the clone in the Eclipse workspace you can just create a standard project with the same name)
* Associate the project with the force.com nature
* Enter your DE org credentials, but *do not refresh from server*
* Select the objects folders, and select 'Save to Server', not deploy
* Select remaining folders and 'Save to Server'

Ant Deployment Instructions
---------------------------

The build.xml file in the root of the repository contains a number of useful build targets for testing and deploying Cumulus code.  To run the deployment, you will need a working copy of ant and a build properties file with the org credentials (see ant migration tool guide for format of the properties file).

You can run the ant targets using the following command syntax:

> ant -propertyfile <PATH_TO_PROP_FILE> <TARGET>

**Build Targets**

* test: Runs a checkOnly deployment of the Cumulus code which runs all tests but never actually deploys the Cumulus code to the target org.  This job also runs the same actions as updateDependentPackages which ensures all dependent packages are the correct version.  This target can only be run against an org which does not have the Cumulus code deployed as the Cumulus code prevents the automated uninstall and reinstall of dependent managed packages.

* deploy: Deploys Cumulus to the target org if all Apex tests pass.  This target requires an org which already has the dependent managed packages installed at the correct version.  If you want to setup an org for this job, run the updateDependentPackages target against the org first

* deploysWithoutTest: Same as deploy but does not execute all Apex tests before deployment.  This is useful if you know the code passes tests and just want to deploy faster.

* updateDependentPackages: Checks that all dependent managed packages are installed and meet the version requirement for Cumulus.  This target will uninstall/reinstall existing packages which are not the correct veersion and install the correct version of packages which are not yet installed in the target org.  Since Cumulus depends on the managed packages, this target will fail if run against an org that has Cumulus deployed.
