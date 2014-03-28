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

    //get the settings. handles the case where the managed value doesn't exist yet
    public static npe01__Contacts_and_Orgs_Settings__c getContactsSettings(npe01__Contacts_And_Orgs_Settings__c ContactsSettings, 
    String HH_ACCOUNT_PROCESSOR) {
        boolean usedToBeOneToOne = false;
        boolean usedToBeBucket = false;
        //if no settings exist, create defaults
        if (ContactsSettings == null) {
            //first see if we already have settings
            ContactsSettings = npe01__Contacts_and_Orgs_Settings__c.getOrgDefaults();
            
            if (ContactsSettings.Id == null) { 
                ContactsSettings.npe01__Account_Processor__c = HH_ACCOUNT_PROCESSOR;                    
                
                //this setting does nothing, but needs to be extracted from the tests before removing
                ContactsSettings.npe01__Enable_Opportunity_Contact_Role_Trigger__c = false;
                ContactsSettings.npe01__Payments_Enabled__c  = true;
                ContactsSettings.npe01__Opportunity_Contact_Role_Default_role__c = 'Donor';
                ContactsSettings.Setupownerid = UserInfo.getOrganizationId();
                
                Recordtypeinfo householdAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household Account');
                if(householdAccount != null)
                    ContactsSettings.npe01__HH_Account_RecordTypeID__c = householdAccount.getRecordTypeId();
                
                //this is not allowed...
                insert ContactsSettings;
            }
        }
        return ContactsSettings;
    }
    
    //get the settings. handles the case where the managed value doesn't exist yet
    public static npo02__Households_Settings__c getHouseholdsSettings(npo02__Households_Settings__c householdsSettings, String ALL_PROCESSOR, 
    String ALL_INDIVIDUALS_PROCESSOR, String NO_HOUSEHOLDS_PROCESSOR) {
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
                        if(pe.getValue()==ALL_PROCESSOR){
                            oldProcessor = ALL_PROCESSOR;
                        } else if(pe.getValue()==ALL_INDIVIDUALS_PROCESSOR){
                            oldProcessor = ALL_INDIVIDUALS_PROCESSOR;
                        } else if(pe.getValue()==NO_HOUSEHOLDS_PROCESSOR){
                            oldProcessor = NO_HOUSEHOLDS_PROCESSOR;
                        }
                        break;
                    }
                }
                householdsSettings = new npo02__Households_Settings__c();
                //set them up with their old setting in the new settings object
                if(oldProcessor==ALL_PROCESSOR){
                    householdsSettings.npo02__Household_Rules__c = ALL_PROCESSOR;
                } else if(oldProcessor==ALL_INDIVIDUALS_PROCESSOR){
                    householdsSettings.npo02__Household_Rules__c = ALL_INDIVIDUALS_PROCESSOR;
                } else if(oldProcessor==NO_HOUSEHOLDS_PROCESSOR){
                    householdsSettings.npo02__Household_Rules__c = NO_HOUSEHOLDS_PROCESSOR;
                } else {
                    householdsSettings.npo02__Household_Rules__c = NO_HOUSEHOLDS_PROCESSOR;
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
                householdsSettings.Setupownerid = UserInfo.getOrganizationId();
                householdsSettings.npo02__Schedule_Job_Limit__c = 25;
                householdsSettings.npo02__Household_OCR_Excluded_Recordtypes__c = null;
                householdsSettings.npo02__Household_Creation_Excluded_Recordtypes__c = null;
                householdsSettings.npo02__Enable_Soft_Credit_Rollups__c = true;
                householdsSettings.npo02__Soft_Credit_Roles__c = 'Soft Credit; Household Member;';
                householdsSettings.npo02__Household_Contact_Roles_On__c = true;
                
                // new HH Account model overrides having HH objects
                if (CAO_Constants.getContactsSettings().npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR)
                    householdsSettings.npo02__Household_Rules__c = NO_HOUSEHOLDS_PROCESSOR;

                insert householdsSettings;
            }
        }
        
        // new HH Account model overrides having HH objects
        if (CAO_Constants.getContactsSettings().npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR)
            householdsSettings.npo02__Household_Rules__c = NO_HOUSEHOLDS_PROCESSOR;

        return householdsSettings;
    }
    
    //get the settings. handles the case where the managed value doesn't exist yet
    public static npe03__Recurring_Donations_Settings__c getRecurringDonationsSettings(npe03__Recurring_Donations_Settings__c recurringDonationsSettings, 
    String defaultBehavior) {
        //if no settings exist, create defaults
        if (recurringDonationsSettings == null) {
            //first see if we already have settings
            recurringDonationsSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();
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
                id myid = [select id from RecordType where sobjecttype = 'Opportunity' limit 1].id;
                recurringDonationsSettings.npe03__Record_Type__c = myid; 
                upsert recurringDonationsSettings;    
                recurringDonationsSettings = npe03__Recurring_Donations_Settings__c.getOrgDefaults();                           
            }
        }         
        return recurringDonationsSettings;
    }
    
    public static npe4__Relationship_Settings__c getRelationshipSettings(npe4__Relationship_Settings__c RelationshipSettings) {
        if (RelationshipSettings == null){
            //retrive the lowest level hierachy setting
            RelationshipSettings = npe4__Relationship_Settings__c.getInstance();

            //check for an org wide setting and insert if required
            if (RelationshipSettings.Id == null){
                npe4__Relationship_Settings__c newRS;
                newRS = npe4__Relationship_Settings__c.getOrgDefaults();
                //will return an empty object is it does not exist
                if (newRS.Id == null){
                    newRS.npe4__Reciprocal_Method__c = 'List Settings';
                    insert newRS;
                }
                RelationshipSettings = newRS;
            }
        }
        return RelationshipSettings;
    }
    
    //get the settings. handles the case where the managed value doesn't exist yet
    public static npe5__Affiliations_Settings__c getAffiliationsSettings(npe5__Affiliations_Settings__c affiliationsSettings) {
        //if no settings exist, create defaults
        if (affiliationsSettings == null) {
            //first see if we already have settings
            affiliationsSettings = npe5__Affiliations_Settings__c.getOrgDefaults();
            system.debug(npe5__Affiliations_Settings__c.getOrgDefaults());
            if (affiliationsSettings.id == null) { 
                //affiliationsSettings = new npe5__Affiliations_Settings__c();
                affiliationsSettings.npe5__Automatic_Affiliation_Creation_Turned_On__c = true;
               
                affiliationsSettings.Setupownerid = UserInfo.getOrganizationId();

                insert affiliationsSettings;
            }
        }
        return affiliationsSettings;
    }
    
    public static Error_Settings__c getErrorSettings(String notificationsTo) {
        Error_Settings__c orgErrorSettings = Error_Settings__c.getOrgDefaults();
        
        if(orgErrorSettings.Id == null) {
            orgErrorSettings.Store_Errors_On__c = true;
            orgErrorSettings.Error_Notifications_On__c = true;
            orgErrorSettings.Error_Notifications_To__c = notificationsTo;
            
            insert orgErrorSettings;
        }
        return orgErrorSettings;
    }
    
    public static Address_Verification_Settings__c getValidationSettings() {        
        Address_Verification_Settings__c settings = Address_Verification_Settings__c.getOrgDefaults();
        if(settings.Id == null) {
        	settings = Address_Verification_Settings__c.getOrgDefaults();
            settings.Address_Verification_Endpoint__c = 'https://api.smartystreets.com/street-address';
            settings.Zipcode_Verification_Endpoint__c = 'https://api.smartystreets.com/zipcode';
            settings.Class__c = 'ADDR_SmartyStreets_Validator';
            settings.Enable_Automatic_Verification__c = true;
            settings.Reject_Ambiguous_Addresses__c = true;
            
            insert settings;
        }
        return settings;
    }
}