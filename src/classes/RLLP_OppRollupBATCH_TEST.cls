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
* @date 2011
* @description test the batchable wrapper for Opportunity Rollup functionality
*/

@isTest
private class RLLP_OppRollupBATCH_TEST {

    static testMethod void testBatch() {
        String giftRecordTypeNameForTests = UTIL_RecordTypes.getRecordTypeNameForGiftsTests('Opportunity');
        if(giftRecordTypeNameForTests!=''){
            npo02__Households_Settings__c householdSettingsForTests = HH_Households.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c (
                    npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR,
                    npo02__Always_Rollup_to_Primary_Contact__c = true,
                    npo02__Enable_Opp_Rollup_Triggers__c = true,
                    npo02__Excluded_Account_Opp_Rectypes__c = null,
                    npo02__Excluded_Account_Opp_Types__c = null,
                    npo02__Excluded_Contact_Opp_Rectypes__c = null,
                    npo02__Excluded_Contact_Opp_Types__c = null,
                    npo02__Membership_Record_Types__c = null
                ));
            
            npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (
                npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR,
                npe01__Enable_Opportunity_Contact_Role_Trigger__c = true,
                npe01__Opportunity_Contact_Role_Default_role__c = 'Donor'
            ));
            
            Date datClose = System.Today();
                
            // create & insert contact(s)
            Contact[] TestCons = new contact[]{ new contact(
                FirstName= CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName= CAO_Constants.CONTACT_LASTNAME_FOR_TESTS,
                npe01__Private__c=false,
                npe01__WorkEmail__c = CAO_Constants.CONTACT_EMAIL_FOR_TESTS, 
                npe01__Preferred_Email__c = CAO_Constants.CONTACT_PREFERRED_EMAIL_FOR_TESTS,
                npe01__WorkPhone__c = CAO_Constants.CONTACT_PHONE_FOR_TESTS,
                npe01__PreferredPhone__c = CAO_Constants.CONTACT_PREFERRED_PHONE_FOR_TESTS
            ) };
            insert TestCons;
            
            Contact insertedContact = [select accountid from Contact where id IN :TestCons];

            // create new opps
            Opportunity[] newOpps = UTIL_UnitTestData_TEST.OppsForContactList ( TestCons, null, UTIL_UnitTestData_TEST.getClosedWonStage(), datClose, 100 , giftRecordTypeNameForTests ,null);
            String contactAccountId = insertedContact.accountid;
        
            RLLP_OppAccRollup_BATCH batch = new RLLP_OppAccRollup_BATCH();
             
            Test.StartTest(); 
            id batchProcessId = database.executeBatch(batch);
            Test.StopTest(); 
        }
    }

}