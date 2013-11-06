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
 
[Affiliations](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000cZtq)
[Contacts_and_Organizations](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000cd2w)
[Recurring_Donations](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000pZK6)
[Relationships](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000pY9P)

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
