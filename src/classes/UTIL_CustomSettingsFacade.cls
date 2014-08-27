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
* @description Helper class that retrieves custom settings and sets defaults.
* Needs to be "without sharing" so that the Install Script can run it.
*/
public without sharing class UTIL_CustomSettingsFacade {

    static Error_Settings__c orgErrorSettings;
    static npe01__Contacts_And_Orgs_Settings__c contactsSettings;
    static npo02__Households_Settings__c householdsSettings;
    static npe03__Recurring_Donations_Settings__c recurringDonationsSettings;
	static npe4__Relationship_Settings__c relationshipSettings;
	static npe5__Affiliations_Settings__c affiliationsSettings;
	static Batch_Data_Entry_Settings__c bdeSettings;
	static Addr_Verification_Settings__c addressVerificationSettings;
	static Household_Naming_Settings__c householdNamingSettings;
    
    //zero-arguments method that will set custom setting defaults
    public static npe01__Contacts_and_Orgs_Settings__c getContactsSettings() {
    	if(contactsSettings == null)
    	   return getContactsSettings(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    	return contactsSettings;
    }
 
    //get the settings. handles the case where the managed value doesn't exist yet
    public static npe01__Contacts_and_Orgs_Settings__c getContactsSettings(String accountProcessor) {
        boolean usedToBeOneToOne = false;
        boolean usedToBeBucket = false;
        
        //if no settings exist, create defaults
        if (contactsSettings == null) {
            //first see if we already have settings
            contactsSettings = npe01__Contacts_and_Orgs_Settings__c.getOrgDefaults();
             //this setting does nothing, but needs to be extracted from the tests before removing
            contactsSettings.npe01__Enable_Opportunity_Contact_Role_Trigger__c = false;
            contactsSettings.npe01__Payments_Enabled__c  = true;
            contactsSettings.npe01__Opportunity_Contact_Role_Default_role__c = 'Donor';
            //contactsSettings.Setupownerid = UserInfo.getOrganizationId();
            
            Recordtypeinfo householdAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household Account');
            if(householdAccount != null)
                contactsSettings.npe01__HH_Account_RecordTypeID__c = householdAccount.getRecordTypeId();
        }
            
        if (accountProcessor != null)
            contactsSettings.npe01__Account_Processor__c = accountProcessor;                    

        upsert contactsSettings;
       
        return contactsSettings;
    }

    //zero-arguments method that will set custom setting defaults
    public static npo02__Households_Settings__c getHouseholdsSettings() {
        String oldProcessor = '';
        //if no settings exist, create defaults
        if (householdsSettings == null) {
            //first see if we already have settings
            householdsSettings = npo02__Households_Settings__c.getOrgDefaults();
            
            //modified to check again the Id instead of the object
            if (householdsSettings.Id == null) {
                //get the model they used to be in 
                Schema.DescribeFieldResult F = Schema.sObjectType.Contact.fields.npo02__SystemHouseholdProcessor__c; 
                List<Schema.PicklistEntry> P = F.getPicklistValues();
                
                for(Schema.PicklistEntry pe : P){
                    if (pe.isDefaultValue()){
                        if(pe.getValue() == HH_Households.ALL_PROCESSOR){
                            oldProcessor = HH_Households.ALL_PROCESSOR;
                        } else if(pe.getValue() == HH_Households.ALL_INDIVIDUALS_PROCESSOR){
                            oldProcessor = HH_Households.ALL_INDIVIDUALS_PROCESSOR;
                        } else if(pe.getValue() == HH_Households.NO_HOUSEHOLDS_PROCESSOR){
                            oldProcessor = HH_Households.NO_HOUSEHOLDS_PROCESSOR;
                        }
                        break;
                    }
                }
                //set them up with their old setting in the new settings object
                if(oldProcessor == HH_Households.ALL_PROCESSOR){
                    householdsSettings.npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR;
                } else if(oldProcessor == HH_Households.ALL_INDIVIDUALS_PROCESSOR){
                    householdsSettings.npo02__Household_Rules__c = HH_Households.ALL_INDIVIDUALS_PROCESSOR;
                } else if(oldProcessor == HH_Households.NO_HOUSEHOLDS_PROCESSOR){
                    householdsSettings.npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR;
                } else {
                    householdsSettings.npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR;
                }
 
                householdsSettings.npo02__Household_Member_Contact_Role__c = label.npo02.Household_Member_Contact_Role;
                householdsSettings.npo02__Always_Rollup_to_Primary_Contact__c = false;
                householdsSettings.npo02__Enable_Opp_Rollup_Triggers__c = true;
                householdsSettings.npo02__Excluded_Account_Opp_Rectypes__c = null;
                householdsSettings.npo02__Excluded_Account_Opp_Types__c = null;
                householdsSettings.npo02__Excluded_Contact_Opp_Rectypes__c = null;
                householdsSettings.npo02__Excluded_Contact_Opp_Types__c = null;
                householdsSettings.npo02__Membership_Record_Types__c = null;
                householdsSettings.npo02__Rollup_N_Day_Value__c = 365;
                householdsSettings.npo02__Membership_Grace_Period__c = 30;
                householdsSettings.npo02__Advanced_Household_Naming__c = true;
                householdsSettings.npo02__Async_Household_Naming__c = false;
                //householdsSettings.Setupownerid = UserInfo.getOrganizationId();
                householdsSettings.npo02__Schedule_Job_Limit__c = 25;
                householdsSettings.npo02__Household_OCR_Excluded_Recordtypes__c = null;
                householdsSettings.npo02__Household_Creation_Excluded_Recordtypes__c = null;
                householdsSettings.npo02__Enable_Soft_Credit_Rollups__c = true;
                householdsSettings.npo02__Soft_Credit_Roles__c = 'Soft Credit; Household Member;';
                householdsSettings.npo02__Household_Contact_Roles_On__c = true;
                
                // new HH Account model overrides having HH objects
                if (UTIL_CustomSettingsFacade.getContactsSettings().npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR)
                    householdsSettings.npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR;
            }
        }
        
        // new HH Account model overrides having HH objects
        if (UTIL_CustomSettingsFacade.getContactsSettings().npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR)
            householdsSettings.npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR;

        upsert householdsSettings;
        
        return householdsSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static npe03__Recurring_Donations_Settings__c getRecurringDonationsSettings() {
    	if(recurringDonationsSettings == null)
            return getRecurringDonationsSettings(RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name());
        return recurringDonationsSettings;
    }

    //get the settings. handles the case where the managed value doesn't exist yet
    public static npe03__Recurring_Donations_Settings__c getRecurringDonationsSettings(String defaultBehavior) {
        //if no settings exist, create defaults
        if (recurringDonationsSettings == null) {
            //first see if we already have settings
            recurringDonationsSettings = npe03__Recurring_Donations_Settings__c.getInstance();
            //if the save behavior is null, then we'll need to upsert new settings, otherwise, we have valid settings as its 
            //the only field w/o a default defined
            if (recurringDonationsSettings.npe03__Open_Opportunity_Behavior__c == null){  
                recurringDonationsSettings.npe03__Open_Opportunity_Behavior__c = defaultBehavior;
                recurringDonationsSettings.npe03__Add_Campaign_to_All_Opportunites__c = true;
                recurringDonationsSettings.npe03__Enable_Update_Check__c = true;
                //recurringDonationsSettings.npe03__Error_Email_Notifications__c = 'All Sys Admins'; *This field has been moved to the ERR_Settings__c custom setting
                recurringDonationsSettings.npe03__Maximum_Donations__c = 50;
                recurringDonationsSettings.npe03__Opportunity_Forecast_Months__c = 12;
                recurringDonationsSettings.npe03__Update_Check_Interval__c = 90;
                List<RecordType> oppRecordTypes = [select id from RecordType where sobjecttype = 'Opportunity'];
                if(oppRecordTypes.size() > 0)
                    recurringDonationsSettings.npe03__Record_Type__c = oppRecordTypes[0].id; 
                upsert recurringDonationsSettings;    
            }
        }         
        return recurringDonationsSettings;
    }

    //zero-arguments method that will set custom setting defaults
    public static npe4__Relationship_Settings__c getrelationshipSettings() {
        if (relationshipSettings == null){
            //retrive the lowest level hierachy setting
            relationshipSettings = npe4__Relationship_Settings__c.getOrgDefaults();

            //check for an org wide setting and insert if required
            if (relationshipSettings.Id == null){
                relationshipSettings.npe4__Reciprocal_Method__c = 'List Settings';
                upsert relationshipSettings;
            }
        }
        return relationshipSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static npe5__Affiliations_Settings__c getAffiliationsSettings() {
        if(affiliationsSettings == null)
            return getAffiliationsSettings(true);
        return affiliationsSettings;
    }
    
    //get the settings. handles the case where the managed value doesn't exist yet
    public static npe5__Affiliations_Settings__c getAffiliationsSettings(Boolean automaticAffiliation) {
    	if(affiliationsSettings == null)		
		    affiliationsSettings = npe5__Affiliations_Settings__c.getOrgDefaults();
        
        //if a value is passed  
        if(automaticAffiliation != null) {
            affiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c = automaticAffiliation;        
        }
        //if no value is passed and it had no value
        if(automaticAffiliation == null && affiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c == null) {
        	affiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c = true;        
        }
        //if no value is passed, and it had a value --> we leave it alone
        
        upsert affiliationsSettings;
        
        return affiliationsSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static Error_Settings__c getErrorSettings() {
    	if(orgErrorSettings == null)
            return getErrorSettings(null);
        return orgErrorSettings;
    }
    
    public static Error_Settings__c getErrorSettings(String notificationsTo) {
        if(orgErrorSettings == null)
            orgErrorSettings = Error_Settings__c.getOrgDefaults();   
        
        Boolean needsDml = false;
        if(orgErrorSettings.Id == null) {
            orgErrorSettings.Store_Errors_On__c = true;
            orgErrorSettings.Error_Notifications_On__c = true;
            //orgErrorSettings.Setupownerid = UserInfo.getOrganizationId();
            orgErrorSettings.Error_Notifications_To__c = ERR_Notifier.NotificationOptions.sysAdmins;
            needsDml = true;
        }  
        
        if(notificationsTo != null) {
            orgErrorSettings.Error_Notifications_To__c = notificationsTo;
            needsDml = true;
        }
            
        if(needsDml)
            upsert orgErrorSettings;
        
        return orgErrorSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static Batch_Data_Entry_Settings__c getBDESettings() {
        if(bdeSettings == null) {
            bdeSettings = Batch_Data_Entry_Settings__c.getInstance();      
            bdeSettings.Allow_Blank_Opportunity_Names__c = true;
            bdeSettings.Opportunity_Naming__c = true;
            upsert bdeSettings;
        }
        return bdeSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static Addr_Verification_Settings__c getAddressVerificationSettings() {        
        if(addressVerificationSettings == null) {
        	addressVerificationSettings = Addr_Verification_Settings__c.getInstance();
        	addressVerificationSettings.Using_SmartyStreets__c = false;
            addressVerificationSettings.Address_Verification_Endpoint__c = 'api.smartystreets.com/street-address';
            addressVerificationSettings.Zipcode_Verification_Endpoint__c = 'api.smartystreets.com/zipcode';
            addressVerificationSettings.Class__c = 'ADDR_SmartyStreets_Validator';
            addressVerificationSettings.Enable_Automatic_Verification__c = true;
            addressVerificationSettings.Reject_Ambiguous_Addresses__c = true;
            upsert addressVerificationSettings;
        }
        return addressVerificationSettings;
    }

    //zero-arguments method that will set custom setting defaults
    public static Household_Naming_Settings__c getHouseholdNamingSettings() {        
        if (householdNamingSettings == null) {
            householdNamingSettings = Household_Naming_Settings__c.getInstance();
            householdNamingSettings.Household_Name_Format__c = '{!LastName} ' + label.npo02.DefaultHouseholdName;
            householdNamingSettings.Formal_Greeting_Format__c = '{!{!Salutation} {!FirstName}} {!LastName}';
            householdNamingSettings.Informal_Greeting_Format__c = '{!{!FirstName}}';
            householdNamingSettings.Name_Connector__c = label.npo02.HouseholdNameConnector;
            householdNamingSettings.Name_Overrun__c = label.npo02.HouseholdNameOverrun;
            householdNamingSettings.Contact_Overrun_Count__c = 9;
            householdNamingSettings.Implementing_Class__c = 'HH_NameSpec';
            upsert householdNamingSettings;
        }
        return householdNamingSettings;
    }
    
    public static npe01__Contacts_and_Orgs_Settings__c getContactsSettingsForTests(npe01__Contacts_and_Orgs_Settings__c mySettings) {
        if(contactsSettings == null)
            contactsSettings = npe01__Contacts_and_Orgs_Settings__c.getOrgDefaults();
        
        //create our own based on what's passed in from the test
        contactsSettings.npe01__One_to_One_RecordTypeID__c = mySettings.npe01__One_to_One_RecordTypeID__c;
        contactsSettings.npe01__HH_Account_RecordTypeID__c = mySettings.npe01__HH_Account_RecordTypeID__c;
        contactsSettings.npe01__Account_Processor__c = mySettings.npe01__Account_Processor__c;
        contactsSettings.npe01__Enable_Opportunity_Contact_Role_Trigger__c = mySettings.npe01__Enable_Opportunity_Contact_Role_Trigger__c;
        contactsSettings.npe01__Opportunity_Contact_Role_Default_role__c = mySettings.npe01__Opportunity_Contact_Role_Default_role__c;
        contactsSettings.npe01__Disable_Account_Model_Trigger__c = mySettings.npe01__Disable_Account_Model_Trigger__c;
        contactsSettings.npe01__Payments_Enabled__c = mySettings.npe01__Payments_Enabled__c;
        upsert contactsSettings;
        return contactsSettings;
    }
    
    public static npo02__Households_Settings__c getHouseholdsSettingsForTests(npo02__Households_Settings__c mySettings) {
        if(householdsSettings == null)
            householdsSettings = npo02__Households_Settings__c.getOrgDefaults();
            
        //create our own based on what's passed in from the test
        householdsSettings.npo02__Household_Rules__c = mySettings.npo02__Household_Rules__c;
        householdsSettings.npo02__Household_Contact_Roles_On__c = mySettings.npo02__Household_Contact_Roles_On__c;
        householdsSettings.npo02__Household_Member_Contact_Role__c = mySettings.npo02__Household_Member_Contact_Role__c;
        householdsSettings.npo02__Always_Rollup_to_Primary_Contact__c = mySettings.npo02__Always_Rollup_to_Primary_Contact__c;
        householdsSettings.npo02__Enable_Opp_Rollup_Triggers__c = mySettings.npo02__Enable_Opp_Rollup_Triggers__c;
        householdsSettings.npo02__Excluded_Account_Opp_Rectypes__c = mySettings.npo02__Excluded_Account_Opp_Rectypes__c;
        householdsSettings.npo02__Excluded_Account_Opp_Types__c = mySettings.npo02__Excluded_Account_Opp_Types__c;
        householdsSettings.npo02__Excluded_Contact_Opp_Rectypes__c = mySettings.npo02__Excluded_Contact_Opp_Rectypes__c;
        householdsSettings.npo02__Excluded_Contact_Opp_Types__c = mySettings.npo02__Excluded_Contact_Opp_Types__c;
        householdsSettings.npo02__Membership_Grace_Period__c = mySettings.npo02__Membership_Grace_Period__c;
        householdsSettings.npo02__Rollup_N_Day_Value__c = mySettings.npo02__Rollup_N_Day_Value__c;
        householdsSettings.npo02__Membership_Record_Types__c = mySettings.npo02__Membership_Record_Types__c;
        householdsSettings.npo02__Advanced_Household_Naming__c = mySettings.npo02__Advanced_Household_Naming__c;
        householdsSettings.npo02__Enable_Soft_Credit_Rollups__c = mySettings.npo02__Enable_Soft_Credit_Rollups__c;
        householdsSettings.npo02__Soft_Credit_Roles__c = mySettings.npo02__Soft_Credit_Roles__c;
        householdsSettings.npo02__Household_OCR_Excluded_Recordtypes__c = mySettings.npo02__Household_OCR_Excluded_Recordtypes__c; 
        householdsSettings.npo02__Household_Creation_Excluded_Recordtypes__c = mySettings.npo02__Household_Creation_Excluded_Recordtypes__c;
        householdsSettings.npo02__Household_Mailing_List_ID__c = mySettings.npo02__Household_Mailing_List_ID__c;
        householdsSettings.npo02__Schedule_Job_Limit__c = 25;
        upsert householdsSettings;
 
        // if the caller explicitly is testing Household objects, make sure we have HH Accounts turned off.
        if (householdsSettings.npo02__Household_Rules__c != HH_Households.NO_HOUSEHOLDS_PROCESSOR) {
            if (getContactsSettings().npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR) {
                getContactsSettings().npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR;
                upsert contactsSettings;    
            }   
        }
        return householdsSettings;
    }
}