/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/

/**
* @author Salesforce.com Foundation
* @date 2014
* @description Class where elements of the package to expose externaly are centralized. 
*/
global with sharing class UTIL_GlobalProxy {
	
	/*******************************************************************************************************
    * @description Enum used to categorize errors as coming from specific functionality. Each enum value matches 
    *              one of the prefixes used throughout the package.
    */
    global enum ErrorContext { ADDR, AFFL, BDI, ALLO, BDE, CON, CONV, HH, LD, OPP, PMT, REL, RD, RLLP, SCH, STTG, TDTM }

    /*******************************************************************************************************
    * @description Returns the default TDTM configuration. 
    * @return List<Trigger_Handler__c> a list of trigger handler records with the default values.
    */
    global List<Trigger_Handler__c> getDefaultTdtmConfig() {
    	return TDTM_DefaultConfig.getDefaultRecords();
    }
    
    /*******************************************************************************************************
    * @description Returns the default Contacts and Orgs settings. 
    * @return Custom settings record for Contacts and Orgs configuration. At the org level, if no user level
    *         settings are defined.
    */
    global npe01__Contacts_And_Orgs_Settings__c getContactsSettings() {
    	return UTIL_CustomSettingsFacade.getContactsSettings();
    }
    
    /*******************************************************************************************************
    * @description Returns the default Households settings. 
    * @return Custom settings record for Households configuration. At the org level, if no user level
    *         settings are defined.
    */
    global npo02__Households_Settings__c getHouseholdsSettings() {
        return UTIL_CustomSettingsFacade.getHouseholdsSettings();
    }
    
    /*******************************************************************************************************
    * @description Returns the default Recurring Donations settings. 
    * @return Custom settings record for Recurring Donations configuration. At the org level, if no user level
    *         settings are defined.
    */
    global npe03__Recurring_Donations_Settings__c getRecurringDonationsSettings() {
        return UTIL_CustomSettingsFacade.getRecurringDonationsSettings();
    }
    
    /*******************************************************************************************************
    * @description Returns the default Relationships settings. 
    * @return Custom settings record for Relationships configuration. At the org level, if no user level
    *         settings are defined.
    */
    global npe4__Relationship_Settings__c getRelationshipSettings() {
        return UTIL_CustomSettingsFacade.getRelationshipSettings();
    }
    
    /*******************************************************************************************************
    * @description Returns the default Affiliations settings. 
    * @return Custom settings record for Affiliations configuration. At the org level, if no user level
    *         settings are defined.
    */
    global npe5__Affiliations_Settings__c getAffiliationsSettings() {
        return UTIL_CustomSettingsFacade.getAffiliationsSettings();
    }
    
    /*******************************************************************************************************
    * @description Returns the default Error Handling settings. 
    * @return Custom settings record for Error Handling configuration. At the org level, if no user level
    *         settings are defined.
    */
    global Error_Settings__c getErrorSettings() {
        return UTIL_CustomSettingsFacade.getErrorSettings();
    }
    
    /*******************************************************************************************************
    * @description Returns the default Batch Data Entry settings. 
    * @return Custom settings record for Batch Data Entry configuration. At the org level, if no user level
    *         settings are defined.
    */
    global Batch_Data_Entry_Settings__c getBDESettings() {
        return UTIL_CustomSettingsFacade.getBDESettings();
    }
    
    /*******************************************************************************************************
    * @description Returns the default Address Verification settings. 
    * @return Custom settings record for Address Verification configuration. At the org level, if no user level
    *         settings are defined.
    */
    global Addr_Verification_Settings__c getAddressVerificationSettings() {
        return UTIL_CustomSettingsFacade.getAddressVerificationSettings();
    }
    
    /*******************************************************************************************************
    * @description Returns the default Household Naming settings. 
    * @return Custom settings record for Household Naming configuration. At the org level, if no user level
    *         settings are defined.
    */
    global Household_Naming_Settings__c getHouseholdNamingSettings() {
        return UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
    }
    
    /*******************************************************************************************************
    * @description Returns the default Allocations settings. 
    * @return Custom settings record for Allocations configuration. At the org level, if no user level
    *         settings are defined.
    */
    global Allocations_Settings__c getAllocationsSettings() {
        return UTIL_CustomSettingsFacade.getAllocationsSettings();
    }
    
    /*******************************************************************************************************
    * @description Creates an error record from an exception, stores it in the database (if enabled), and sends error
    *              notifications (if enabled).
    * @param e Exception to create error record from.
    * @return context The context the exception was raised on.
    */
    global void processError(Exception e, UTIL_GlobalProxy.ErrorContext context) {
    	ERR_Handler.processError(e, context);
    }
    
    /*******************************************************************************************************
    * @description Prints a debug message to the debug log, if debugging is enabled or a test is being run.
    * @param message The message to print.
    * @return void
    */
    global static void debug(string message) {
    	UTIL_Debug.debug(message);
    }
    
   /*******************************************************************************************************
    * @description Prints a debug message to the debug log, if debugging is enabled or a test is being run, at the specified
    *              logging level.
    * @param message The message to print.
    * @param level The level to output the message at.
    * @return void
    */
    global static void debug(System.LoggingLevel level, string message) {
    	UTIL_Debug.debug(level, message);
    }
    
    /*******************************************************************************************************
    * @description Prints a debug message to the debug log, if debugging enabled or a test is being run, with additional info, 
                   such as heap, cpu, query, and rows usage.
    * @param message The message to print.
    * @return void
    */
    global static void debugWithInfo(string message) {
     	UTIL_Debug.debugWithInfo(message);
    }
    
    /*******************************************************************************************************
    * @description Prints a debug message to the debug log, if debugging is enabled or a test is being run, at the specified logging
    *              level, with additional info, such as heap, cpu, query, and rows usage.
    * @param message The message to print.
    * @param level The level to output the message at.
    * @return void
    */
    global static void debugWithInfo(System.LoggingLevel level, string message) {
    	UTIL_Debug.debugWithInfo(level, message);
    }
    
    /*******************************************************************************************************
    * @description Returns object describe data.
    * @param objectName The name of the object to lookup. 
    * @return Schema.DescribeSObjectResult Object that contains methods for describing the SObject.
    */
    global static Schema.DescribeSObjectResult getObjectDescribe(String objectName) {
    	return UTIL_Describe.getObjectDescribe(objectName);
    }
    
    /*******************************************************************************************************
    * @description Returns all field describe data.
    * @param objectName The name of the object to look up.
    * @return Map<String, Schema.DescribeFieldResult> A map of object names to describe file results.
    */  
    global static Map<String, Schema.DescribeFieldResult> getAllFieldsDescribe(String objectName) {
    	return UTIL_Describe.getAllFieldsDescribe(objectName);
    }
    
    /*******************************************************************************************************
    * @description Tells us if we are running the managed or the unmanaged version of the NPSP.
    * @return Boolean True if we are in the managed package, False otherwise.
    */
    global static Boolean inManagedPackage() {
        return UTIL_Namespace.inManagedPackage;	
    }
}