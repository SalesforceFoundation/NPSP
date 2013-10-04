Cumulus
=======

ducking-octo-happiness, laughing-archer

[![Build Status](http://ec2-23-20-64-21.compute-1.amazonaws.com/buildStatus/icon?job=Cumulus_feature)](http://ec2-23-20-64-21.compute-1.amazonaws.com/job/Cumulus_feature/)

**Contributor Install Instructions**

* Create a new DE org by going to developer.force.com
* Login to your DE Org. 
* Create an Opportunity Sales Process (Setup | Customize | Opportunity | Sales Process)
* Create an Opportunity Record Type (Setup | Customize | Opportunity | Record Type)
* Install the 4 required Nonprofit Starter Pack Packages  
  
<a href="http://foundation.force.com/packages/contactsandorganizations" target="_blank">Contacts and Organizations</a>  
<a href="http://foundation.force.com/packages/recurringdonations" target="_blank">Recurring Donations</a>  
<a href="http://foundation.force.com/packages/relationships" target="_blank">Relationships</a>  
<a href="http://foundation.force.com/packages/affiliations" target="_blank">Affiliations</a>  

NOTE: For now, you will need to use the following links to install the unreleased NPSP packages with classes and triggers removed:
<a href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000cZtq">Affiliations (2.9)</a>
<a href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000pXSe">Recurring Donations (2.9)</a>
<a href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04t80000000pY9P">Relationships (2.9)</a>
  
* Fork this repository 'dev' branch
* Clone your fork to your local machine
```
$ git clone https://github.com/*username*/Cumulus.git
```
* In your IDE of your choice, create a new project based on your cloned report. Associate the project with the force.com nature, but *do not refresh from server*.
* Select the labels and objects folders, and select 'Save to Server', not deploy
* Select remaining folders and 'Save to Server'
