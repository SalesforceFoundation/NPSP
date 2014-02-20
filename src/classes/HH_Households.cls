/*
    Copyright (c) 2009, Salesforce.com Foundation
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
* @date 2011 (2.0)
* @description Handles creation, deleting and moving of Households between Contacts 
*/
global without sharing class HH_Households { 
    
    //One-to-One value for system processor field
    public static String ALL_PROCESSOR = 'All New or Edited Contacts';
    public static String ALL_INDIVIDUALS_PROCESSOR = 'All Individual Contacts';
    public static String NO_HOUSEHOLDS_PROCESSOR = 'No Contacts';
    
    public static npo02__Households_Settings__c householdsSettings;
    
    //get the settings. handles the case where the managed value doesn't exist yet
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
                   // system.debug(pe.getValue() + ' : ' + pe.isDefaultValue());
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
    
    public static npo02__Households_Settings__c getHouseholdsSettingsForTests(npo02__Households_Settings__c mySettings) {
        
        //clear out whatever settings exist
        delete [select id from npo02__Households_Settings__c]; 
         
        //create our own based on what's passed in from the test
        householdsSettings = new npo02__Households_Settings__c (
            npo02__Household_Rules__c = mySettings.npo02__Household_Rules__c,
            npo02__Household_Contact_Roles_On__c = mySettings.npo02__Household_Contact_Roles_On__c,
            npo02__Household_Member_Contact_Role__c = mySettings.npo02__Household_Member_Contact_Role__c,
            npo02__Always_Rollup_to_Primary_Contact__c = mySettings.npo02__Always_Rollup_to_Primary_Contact__c,
            npo02__Enable_Opp_Rollup_Triggers__c = mySettings.npo02__Enable_Opp_Rollup_Triggers__c,
            npo02__Excluded_Account_Opp_Rectypes__c = mySettings.npo02__Excluded_Account_Opp_Rectypes__c,
            npo02__Excluded_Account_Opp_Types__c = mySettings.npo02__Excluded_Account_Opp_Types__c,
            npo02__Excluded_Contact_Opp_Rectypes__c = mySettings.npo02__Excluded_Contact_Opp_Rectypes__c,
            npo02__Excluded_Contact_Opp_Types__c = mySettings.npo02__Excluded_Contact_Opp_Types__c,
            npo02__Membership_Grace_Period__c = mySettings.npo02__Membership_Grace_Period__c,
            npo02__Rollup_N_Day_Value__c = mySettings.npo02__Rollup_N_Day_Value__c, 
            npo02__Membership_Record_Types__c = mySettings.npo02__Membership_Record_Types__c,
            npo02__Advanced_Household_Naming__c = mySettings.npo02__Advanced_Household_Naming__c,
            npo02__Enable_Soft_Credit_Rollups__c = mySettings.npo02__Enable_Soft_Credit_Rollups__c,
            npo02__Soft_Credit_Roles__c = mySettings.npo02__Soft_Credit_Roles__c,        
            npo02__Household_OCR_Excluded_Recordtypes__c = mySettings.npo02__Household_OCR_Excluded_Recordtypes__c, 
            npo02__Household_Creation_Excluded_Recordtypes__c = mySettings.npo02__Household_Creation_Excluded_Recordtypes__c,
            npo02__Schedule_Job_Limit__c = 25
            );
        insert householdsSettings;
 
        // if the caller explicitly is testing Household objects, make sure we have HH Accounts turned off.
        if (householdsSettings.npo02__Household_Rules__c != NO_HOUSEHOLDS_PROCESSOR) {
        	npe01__Contacts_and_Orgs_Settings__c ContactsSettings = CAO_Constants.getContactsSettings();
            if (ContactsSettings.npe01__Account_Processor__c == CAO_Constants.HH_ACCOUNT_PROCESSOR) {
                ContactsSettings.npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR;
                upsert ContactsSettings;	
            }	
        }           
        return householdsSettings;
    }

}