---
title: NPSP Coding Conventions
layout: default
---
# [Home](http://developer.salesforcefoundation.org/Cumulus/Contributor/) > Coding Conventions 

**This is not a comprehensive list of NPSP Coding Conventions**. This document is a work-in-progress - the items below should help get you started contributing quality code to the NPSP.

# Naming Conventions 

1. File names for Visualforce Pages and Components, and Apex Classes, should start with an all-caps internal 'namespace', followed by a single underscore (prefix). The namespace refers to the area of functionality. Look at existing files and use an existing prefix unless you are adding very new and different functionality.
2. After the prefix, use short but descriptive filenames using CamelCase.
3. Most Apex classes should also have a suffix, preceded by a single underscore:
	- _CTRL for Visualforce controllers or extensions
	- _LCTRL for Lightning Component controllers
	- _TDTM for classes that implement Table-Driven Trigger Management 
	- _BATCH for classes implementing ```Database.Batchable```
	- _SCHED for classes implementing ```System.Schedulable```
	- _UTIL for classes of utility methods called by other classes
	- _TEST for test classes
4. Visualforce pages should have the same name as their controller or extension (except for the _CTRL suffix). Pages invoked by a custom button should end with "BTN", without a preceding underscore.
5. Methods, properties and variables should have descriptive names using lowerCamelCase.

# Code comments and ApexDoc

Please comment your code well! Comments describing what you are doing and the expected outcome will help both those who review your pull request and any future maintainers. 

Classes, methods, and attributes should also include comments at the top that will generate [ApexDoc documentation](http://developer.salesforcefoundation.org/Cumulus/ApexDocumentation/). You can read the full documentation on the [ApexDoc repository](https://github.com/SalesforceFoundation/ApexDoc), but the basics are as follows:

## ApexDoc Comment Blocks
ApexDoc comment blocks must always begin with /** (NPSP standard is to continue the asterisks across the whole line) and can cover multiple lines. Each line must start with * (or whitespace and then *). The comment block ends with */.  Within the block, special tokens, called out with ```@token```, identify the documentation to include for a given class, property, or method. 

### Classes
Classes' ApexDoc block is located in the lines above the class declaration.  The special tokens are all technically optional, but for NPSP contributions, please include ```@author```, ```@date```,  ```@description``` and ```@group```. The ```@group``` value should usually be one of the existing groups - see the left-hand navigation of the [current ApexDocs](http://developer.salesforce.org/Cumulus/ApexDocumentation/). 

| token | description |
|-------|-------------|
| @author | the author of the class |
| @date | the date the class was first implemented |
| @group | a group to display this class under, in the menu hierarchy|
| @group-content | a relative path to a static html file that provides content about the group|
| @description | one or more lines that provide an overview of the class|

Example
```
/**
* @author Salesforce.com Foundation
* @date 2014
*
* @group Accounts
* @group-content ../../ApexDocContent/Accounts.htm
*
* @description Trigger Handler on Accounts that handles ensuring the correct system flags are set on
* our special accounts (Household, One-to-One), and also detects changes on Household Account that requires
* name updating.
*/
public with sharing class ACCT_Accounts_TDTM extends TDTM_Runnable {
```

### Method Comments
In order for ApexDoc to identify class methods, the method line must contain an explicit scope (global, public, private, testMethod, webService).  The comment block is located in the lines above a method.  The special tokens are all technically optional, but for NPSP please include ```@description```, all ```@param```s, and ```@return``` for non-void methods.

| token | description |
|-------|-------------|
| @description | one or more lines that provide an overview of the method|
| @param *param name* | a description of what the parameter does|
| @return | a description of the return value from the method|
| @example | Example code usage. This will be wrapped in <code> tags to preserve whitespace|
Example
```
    /*******************************************************************************************************
    * @description Returns field describe data
    * @param objectName the name of the object to look up
    * @param fieldName the name of the field to look up
    * @return the describe field result for the given field
    * @example
    * Account a = new Account();
    */
    public static Schema.DescribeFieldResult getFieldDescribe(String objectName, String fieldName) {
``` 

### Property Comments
Located in the lines above a property.  The special token is optional, but please include a block and ```@description``` for any ```public``` or ```global``` properties.

| token | description |
|-------|-------------|
| @description | one or more lines that describe the property|

Example
```
    /*******************************************************************************************************
    * @description specifies whether state and country picklists are enabled in this org.
    * returns true if enabled.
    */
    public static Boolean isStateCountryPicklistsEnabled {
        get {
```

# Table-driven Trigger Management (TDTM)

NPSP uses [TDTM](http://developer.salesforcefoundation.org/index.html#blog/post/2014/11/24/table-driven-trigger-management.html) to handle all trigger-based functionality. Please read the blog post and look at existing classes and triggers before starting on any new trigger functionality. The following principles apply:

1. No new triggers should be added for existing objects. 
2. If you are adding a new custom object for which triggers should fire, create a single new ```TDTM_[ObjectName].trigger``` that handles all trigger events. Use an existing trigger as a model.
3. Before adding a new TDTM class, consider whether the trigger functionality would be more appropriate in an existing class. If the function should be able to be en/disabled separately from other trigger functions, that's a good indicator that a new class is needed. This is a good topic to discuss on the Hub or on a GitHub issue before proceeding, though.
4. Consider existing trigger classes on the object, and determine where a new class should go in the load order.
5. Any new TDTM classes should be added to the [TDTM_DefaultConfig.getDefaultRecords() method](http://developer.salesforce.org/Cumulus/ApexDocumentation/TDTM_DefaultConfig.html#getDefaultRecords) so that the necessary Trigger_Handler__c record will be loaded when orgs install or upgrade. 

# Custom Labels

All user-facing text should support translation.
1. Object & field names should always be displayed to users by their Labels.
2. All other user-facing text should be stored in Custom Labels.
	- new Custom Labels should be created in English as the default
	- Name and Short Description should be the same value, using lowerCamelCase. The first word should indicate the general category of functionality. 
	- Observe existing Categories on Custom Labels and apply them as appropriate for easier filtering by end users.
	- Unless there is a specific need, new Custom Labels should not be Protected Components.

# NPSP Settings

If your functionality requires or allows configuration by admins, you'll need to add that ability to NPSP Settings. NPSP Settings is managed through Visualforce pages that are "panels", incorporated by the main STG_SettingsManager page. These pages manipulate Default Organization Level Value records for the hierarchical Custom Settings that NPSP uses, as well as the records in list Custom Settings. Examine existing panels for patterns to replicate. 

# NPSP Utility Classes

The NPSP codebase includes a number of [Utility classes](http://developer.salesforce.org/Cumulus/ApexDocumentation/Utilities.html). Familiarize yourself with them and make use of them in your code.  