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

    //storing them in-memory to avoid trying to isert/update them twice and thus trigger the "duplicate OwnerId" error
    static npe01__Contacts_And_Orgs_Settings__c contactsSettings;
    static npo02__Households_Settings__c householdsSettings;
    static npe03__Recurring_Donations_Settings__c recurringDonationsSettings;
	static npe4__Relationship_Settings__c relationshipsSettings;
	static npe5__Affiliations_Settings__c affiliationsSettings;
	static Error_Settings__c errorSettings;
	static Batch_Data_Entry_Settings__c bdeSettings;
	static Addr_Verification_Settings__c addressVerificationSettings;
	static Household_Naming_Settings__c householdNamingSettings;
	
	//storing them in-memory to avoid slowing down the settings page
	static npe01__Contacts_And_Orgs_Settings__c orgContactsSettings;
    static npo02__Households_Settings__c orgHouseholdsSettings;
    static npe03__Recurring_Donations_Settings__c orgRecurringDonationsSettings;
    static npe4__Relationship_Settings__c orgRelationshipsSettings;
    static npe5__Affiliations_Settings__c orgAffiliationsSettings;
    static Error_Settings__c orgErrorSettings;
    static Batch_Data_Entry_Settings__c orgBdeSettings;
    static Addr_Verification_Settings__c orgAddressVerificationSettings;
    static Household_Naming_Settings__c orgHouseholdNamingSettings;
    
    //method that will set custom setting defaults at the org level. Meant to be called only from settings page and install script
    public static npe01__Contacts_And_Orgs_Settings__c getOrgContactsSettings() {
    	if(orgContactsSettings == null) {
	    	orgContactsSettings = npe01__Contacts_And_Orgs_Settings__c.getOrgDefaults();
	    	if(orgContactsSettings.Id == null) {
		    	configContactsSettings(orgContactsSettings);
		    	orgContactsSettings.Setupownerid = UserInfo.getOrganizationId();
		    	upsert orgContactsSettings;
	    	}
    	}
        return orgContactsSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static npe01__Contacts_And_Orgs_Settings__c getContactsSettings() {
    	if(contactsSettings == null)
    	   return getContactsSettings(CAO_Constants.HH_ACCOUNT_PROCESSOR);
    	return contactsSettings;
    }
 
    //get the settings. handles the case where the managed value doesn't exist yet
    public static npe01__Contacts_And_Orgs_Settings__c getContactsSettings(String accountProcessor) {
    	Boolean needsDml = false;
        //if no settings exist, create defaults
        if (contactsSettings == null) {
            //first see if we already have settings
            contactsSettings = npe01__Contacts_And_Orgs_Settings__c.getInstance();
            if(contactsSettings.Id == null) {
	            configContactsSettings(contactsSettings);
	            needsDml = true;
            }
        }
            
        if (accountProcessor != null) {
            contactsSettings.npe01__Account_Processor__c = accountProcessor;
            needsDml = true;
        }                    

        if(needsDml)
            upsert contactsSettings;
            
        return contactsSettings;
    }
    
    private static void configContactsSettings(npe01__Contacts_And_Orgs_Settings__c cs) {
    	//this setting does nothing, but needs to be extracted from the tests before removing
        cs.npe01__Enable_Opportunity_Contact_Role_Trigger__c = false;
        cs.npe01__Payments_Enabled__c  = true;
        cs.npe01__Opportunity_Contact_Role_Default_role__c = 'Donor';
        cs.npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR;
        Recordtypeinfo householdAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get(CAO_Constants.HH_ACCOUNT_PROCESSOR);
        if(householdAccount != null)
            cs.npe01__HH_Account_RecordTypeID__c = householdAccount.getRecordTypeId();
    }

    //method that will set custom setting defaults at the org level. Meant to be called only from settings page and install script
    public static npo02__Households_Settings__c getOrgHouseholdsSettings() {
    	if(orgHouseholdsSettings == null) {
	    	orgHouseholdsSettings = npo02__Households_Settings__c.getOrgDefaults();
	    	if(orgHouseholdsSettings.Id == null) {
		        configHouseholdSettings(orgHouseholdsSettings);
		        orgHouseholdsSettings.Setupownerid = UserInfo.getOrganizationId();
		        upsert orgHouseholdsSettings;
	    	}
    	}
        return orgHouseholdsSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static npo02__Households_Settings__c getHouseholdsSettings() {
        //if no settings exist, create defaults
        if (householdsSettings == null) {
            //first see if we already have settings
            householdsSettings = npo02__Households_Settings__c.getInstance();
            if(householdsSettings.Id == null) {
	            configHouseholdSettings(householdsSettings);
	            upsert householdsSettings;
            }
        }  
        return householdsSettings;
    }
    
    private static void configHouseholdSettings(npo02__Households_Settings__c hs) {
    	String oldProcessor = '';
    	//modified to check again the Id instead of the object
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
            hs.npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR;
        } else if(oldProcessor == HH_Households.ALL_INDIVIDUALS_PROCESSOR){
            hs.npo02__Household_Rules__c = HH_Households.ALL_INDIVIDUALS_PROCESSOR;
        } else if(oldProcessor == HH_Households.NO_HOUSEHOLDS_PROCESSOR){
            hs.npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR;
        } else {
            hs.npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR;
        }
 
        hs.npo02__Household_Member_Contact_Role__c = label.npo02.Household_Member_Contact_Role;
        hs.npo02__Always_Rollup_to_Primary_Contact__c = false;
        hs.npo02__Enable_Opp_Rollup_Triggers__c = true;
        hs.npo02__Excluded_Account_Opp_Rectypes__c = null;
        hs.npo02__Excluded_Account_Opp_Types__c = null;
        hs.npo02__Excluded_Contact_Opp_Rectypes__c = null;
        hs.npo02__Excluded_Contact_Opp_Types__c = null;
        hs.npo02__Membership_Record_Types__c = null;
        hs.npo02__Rollup_N_Day_Value__c = 365;
        hs.npo02__Membership_Grace_Period__c = 30;
        hs.npo02__Advanced_Household_Naming__c = true;
        hs.npo02__Async_Household_Naming__c = false;
        hs.npo02__Schedule_Job_Limit__c = 25;
        hs.npo02__Household_OCR_Excluded_Recordtypes__c = null;
        hs.npo02__Household_Creation_Excluded_Recordtypes__c = null;
        hs.npo02__Enable_Soft_Credit_Rollups__c = true;
        hs.npo02__Soft_Credit_Roles__c = 'Soft Credit; Household Member;';
        hs.npo02__Household_Contact_Roles_On__c = true;
                
        // new HH Account model overrides having HH objects
        if (UTIL_CustomSettingsFacade.getContactsSettings().npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR)
            hs.npo02__Household_Rules__c = HH_Households.NO_HOUSEHOLDS_PROCESSOR;
    }
    
    //method that will set custom setting defaults at the org level. Meant to be called only from settings page and install script
    public static npe03__Recurring_Donations_Settings__c getOrgRecurringDonationsSettings() {
    	if(orgRecurringDonationsSettings == null) {
	    	orgRecurringDonationsSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
	    	if(orgRecurringDonationsSettings.Id == null) {
		    	configRecurringDonationsSettings(orgRecurringDonationsSettings);
		    	upsert orgRecurringDonationsSettings;
	    	}
    	}
    	return orgRecurringDonationsSettings;
    }
        
    //zero-arguments method that will set custom setting defaults
    public static npe03__Recurring_Donations_Settings__c getRecurringDonationsSettings() {
    	if(recurringDonationsSettings == null)
            return getRecurringDonationsSettings(RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost);
        return recurringDonationsSettings;
    }

    //get the settings. handles the case where the managed value doesn't exist yet
    public static npe03__Recurring_Donations_Settings__c getRecurringDonationsSettings(RD_RecurringDonations.RecurringDonationCloseOptions defaultBehavior) {
        Boolean needsDml = false;
        //if no settings exist, create defaults
        if (recurringDonationsSettings == null) {
            //first see if we already have settings
            recurringDonationsSettings = npe03__Recurring_Donations_Settings__c.getInstance();
            if(recurringDonationsSettings.Id == null) {
	            configRecurringDonationsSettings(recurringDonationsSettings);
	            needsDml = true;
            }
        }
        
        if(defaultBehavior != null) {
            recurringDonationsSettings.npe03__Open_Opportunity_Behavior__c = defaultBehavior.name();
            needsDml = true;
        }
        
        if(needsDml)
            upsert recurringDonationsSettings;
              
        return recurringDonationsSettings;
    }
    
    private static void configRecurringDonationsSettings(npe03__Recurring_Donations_Settings__c rds) {
    	//if the save behavior is null, then we'll need to upsert new settings, otherwise, we have valid settings as its 
        //the only field w/o a default defined
        if (rds.npe03__Open_Opportunity_Behavior__c == null){          
            rds.npe03__Add_Campaign_to_All_Opportunites__c = true;
            rds.npe03__Enable_Update_Check__c = true;
            //rds.npe03__Error_Email_Notifications__c = 'All Sys Admins'; *This field has been moved to the ERR_Settings__c custom setting
            rds.npe03__Maximum_Donations__c = 50;
            rds.npe03__Opportunity_Forecast_Months__c = 12;
            rds.npe03__Update_Check_Interval__c = 90;
            rds.npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name();
            List<RecordType> oppRecordTypes = [select id from RecordType where sobjecttype = 'Opportunity'];
            if(oppRecordTypes.size() > 0)
                rds.npe03__Record_Type__c = oppRecordTypes[0].id;
        }
        
    }

    //method that will set custom setting defaults at the org level. Meant to be called only from settings page and install script
    public static npe4__Relationship_Settings__c getOrgRelationshipSettings() {
        if(orgRelationshipsSettings == null) { 
	        orgRelationshipsSettings = npe4__Relationship_Settings__c.getOrgDefaults();
	        if(orgRelationshipsSettings.Id == null) {
		        configRelationshipsSettings(orgRelationshipsSettings);
		        upsert orgRelationshipsSettings;
	        }
        }
        return orgRelationshipsSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static npe4__Relationship_Settings__c getRelationshipSettings() {
        if (relationshipsSettings == null) {
            //retrive the lowest level hierachy setting
            relationshipsSettings = npe4__Relationship_Settings__c.getInstance();
            if(relationshipsSettings.Id == null) {
	            configRelationshipsSettings(relationshipsSettings);
	            upsert relationshipsSettings;
            }
        }
        return relationshipsSettings;
    }
    
    private static void configRelationshipsSettings(npe4__Relationship_Settings__c rs) {
        rs.npe4__Reciprocal_Method__c = 'List Settings';
    }
    
    //method that will set custom setting defaults at the org level. Meant to be called only from settings page and install script
    public static npe5__Affiliations_Settings__c getOrgAffiliationsSettings() {
        if(orgAffiliationsSettings == null) {
	        orgAffiliationsSettings = npe5__Affiliations_Settings__c.getOrgDefaults();
	        if(orgAffiliationsSettings.Id == null) {
		        configAffiliationsSettings(orgAffiliationsSettings);
		        upsert orgAffiliationsSettings;
	        }
        }
        return orgAffiliationsSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static npe5__Affiliations_Settings__c getAffiliationsSettings() {
        if(affiliationsSettings == null)
            return getAffiliationsSettings(true);
        return affiliationsSettings;
    }
    
    //get the settings. handles the case where the managed value doesn't exist yet
    public static npe5__Affiliations_Settings__c getAffiliationsSettings(Boolean automaticAffiliation) {
    	Boolean needsDml = false;
    	if(affiliationsSettings == null) {		
		    affiliationsSettings = npe5__Affiliations_Settings__c.getInstance();
		    if(affiliationsSettings.Id == null) {
		        configAffiliationsSettings(affiliationsSettings);
	            needsDml = true;
		    }
    	}
    	//if a value is passed --> set to value
        if(automaticAffiliation != null) {
            affiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c = automaticAffiliation; 
            needsDml = true;       
        }
        
        if(needsDml)
            upsert affiliationsSettings;
            
        return affiliationsSettings;
    }
    
    private static void configAffiliationsSettings(npe5__Affiliations_Settings__c afs) {
        afs.npe5__Automatic_Affiliation_Creation_Turned_On__c = true;
    }
    
    //method that will set custom setting defaults at the org level. Meant to be called only from settings page and install script
    public static Error_Settings__c getOrgErrorSettings() {
    	if(orgErrorSettings == null) {
	        orgErrorSettings = Error_Settings__c.getOrgDefaults();
	        if(orgErrorSettings.Id == null) {
		        configErrorSettings(orgErrorSettings, null);
		        orgErrorSettings.Setupownerid = UserInfo.getOrganizationId();
		        upsert orgErrorSettings;
	        }
    	}
        return orgErrorSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static Error_Settings__c getErrorSettings() {
    	if(errorSettings == null)
            return getErrorSettings(null);
        return errorSettings;
    }
    
    public static Error_Settings__c getErrorSettings(String notificationsTo) {
        Boolean needsDml = false;
        if(errorSettings == null) {
            errorSettings = Error_Settings__c.getInstance();
            if(errorSettings.Id == null) {
	            configErrorSettings(errorSettings, notificationsTo);  
	            needsDml = true;
            }
        }
        
        if(notificationsTo != null) {
            errorSettings.Error_Notifications_To__c = notificationsTo;
            needsDml = true;
        }
        
        if(needsDml)
            upsert errorSettings;
            
        return errorSettings;
    }
    
    private static void configErrorSettings(Error_Settings__c es, String notificationsTo) {  	
        es.Store_Errors_On__c = true;
        es.Error_Notifications_On__c = true;
        es.Error_Notifications_To__c = ERR_Notifier.NotificationOptions.sysAdmins;
    }
    
    //method that will set custom setting defaults at the org level. Meant to be called only from settings page and install script
    public static Batch_Data_Entry_Settings__c getOrgBDESettings() {
        if(orgBDESettings == null) {
	        orgBDESettings = Batch_Data_Entry_Settings__c.getOrgDefaults();
	        if(orgBDESettings.Id == null) {
		        configBDESettings(orgBDESettings);
		        upsert orgBDESettings;
	        }
        }
        return orgBDESettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static Batch_Data_Entry_Settings__c getBDESettings() {
        if(bdeSettings == null) {
            bdeSettings = Batch_Data_Entry_Settings__c.getInstance();
            if(bdeSettings.Id == null) {
	            configBDESettings(bdeSettings);
	            upsert bdeSettings;
            }
        }
        return bdeSettings;
    }
    
    private static void configBDESettings(Batch_Data_Entry_Settings__c bds) {
    	bds.Allow_Blank_Opportunity_Names__c = true;
        bds.Opportunity_Naming__c = true;
    }
    
    //method that will set custom setting defaults at the org level. Meant to be called only from settings page and install script
    public static Addr_Verification_Settings__c getOrgAddressVerificationSettings() {
        if(orgAddressVerificationSettings == null) {
	        orgAddressVerificationSettings = Addr_Verification_Settings__c.getOrgDefaults();
	        if(orgAddressVerificationSettings.Id == null) {
		        configAddressVerificationSettings(orgAddressVerificationSettings);
		        upsert orgAddressVerificationSettings;
	        }
        }
        return orgAddressVerificationSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static Addr_Verification_Settings__c getAddressVerificationSettings() {        
        if(addressVerificationSettings == null) {
        	addressVerificationSettings = Addr_Verification_Settings__c.getInstance();
        	if(addressVerificationSettings.Id == null) {
	        	configAddressVerificationSettings(addressVerificationSettings);
	            upsert addressVerificationSettings;
        	}
        }
        return addressVerificationSettings;
    }
    
    private static void configAddressVerificationSettings(Addr_Verification_Settings__c avs) {
    	avs.Using_SmartyStreets__c = false;
        avs.Enable_Automatic_Verification__c = false;
        avs.Reject_Ambiguous_Addresses__c = false;
    }

    //method that will set custom setting defaults at the org level. Meant to be called only from settings page and install script
    public static Household_Naming_Settings__c getOrgHouseholdNamingSettings() {
        if(orgHouseholdNamingSettings == null) {
	        orgHouseholdNamingSettings = Household_Naming_Settings__c.getOrgDefaults();
	        if(orgHouseholdNamingSettings.Id == null) {
		        configHouseholdNamingSettings(orgHouseholdNamingSettings);
		        upsert orgHouseholdNamingSettings;
	        }
        }
        return orgHouseholdNamingSettings;
    }
    
    //zero-arguments method that will set custom setting defaults
    public static Household_Naming_Settings__c getHouseholdNamingSettings() {        
        if (householdNamingSettings == null) {
        	householdNamingSettings = Household_Naming_Settings__c.getInstance();
            if(householdNamingSettings.Id == null) {
	            configHouseholdNamingSettings(householdNamingSettings);
	            upsert householdNamingSettings;
            }
        }
        return householdNamingSettings;
    }
    
    private static void configHouseholdNamingSettings(Household_Naming_Settings__c hns) {
        hns.Household_Name_Format__c = '{!LastName} ' + label.npo02.DefaultHouseholdName;
        hns.Formal_Greeting_Format__c = '{!{!Salutation} {!FirstName}} {!LastName}';
        hns.Informal_Greeting_Format__c = '{!{!FirstName}}';
        hns.Name_Connector__c = label.npo02.HouseholdNameConnector;
        hns.Name_Overrun__c = label.npo02.HouseholdNameOverrun;
        hns.Contact_Overrun_Count__c = 9;
        hns.Implementing_Class__c = 'HH_NameSpec';
    }
    
    public static npe01__Contacts_And_Orgs_Settings__c getContactsSettingsForTests(npe01__Contacts_And_Orgs_Settings__c mySettings) {
        if(contactsSettings == null)
            contactsSettings = npe01__Contacts_And_Orgs_Settings__c.getInstance();
        
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
            householdsSettings = npo02__Households_Settings__c.getInstance();
            
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
    
    public static npe4__Relationship_Settings__c getRelationshipsSettingsForTests(npe4__Relationship_Settings__c mySettings) {
        if(relationshipsSettings == null)
            relationshipsSettings = npe4__Relationship_Settings__c.getInstance();
        
        //create our own based on what's passed in from the test
        relationshipsSettings.npe4__Reciprocal_Method__c = mySettings.npe4__Reciprocal_Method__c;
        relationshipsSettings.npe4__Gender_Field__c = mySettings.npe4__Gender_Field__c;
        upsert relationshipsSettings;
        return relationshipsSettings;
    }
}