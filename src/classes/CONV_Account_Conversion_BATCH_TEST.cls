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
* @description Tests for batch conversion interface for porting 1x1 or Individual Contacts to the Household Account model
*/
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
* @date 2014 (2.0)
* @description Test for the controller for the VF page invoked by using the bulk Account model conversion utility
*/
@isTest
public with sharing class CONV_Account_Conversion_BATCH_TEST {

    public testmethod static void testAccountConversion1to1(){
        //setup 1x1 model and test account creation
        CONV_Account_Conversion_BATCH_TEST.setPreHHAccountModel(true);

        Contact c = new Contact(LastName = 'Contact', FirstName = 'Test');
        insert c;
        system.assertEquals(1, [select count() from Account where Name = 'Test Contact' and npe01__One2OneContact__c = :c.id]);
        String HHName = 'Contact ' + system.label.npo02.DefaultHouseholdName;
        system.assertEquals(1, [select count() from npo02__Household__c where Name = :HHName]);

        //add an oppty to the Contact as well
        Opportunity o = new Opportunity(Name = 'Test Oppty', Amount = 1000, StageName = UTIL_UnitTestData_TEST.getClosedWonStage(), CloseDate = system.today(), npe01__Contact_Id_For_Role__c = c.Id);
        insert o;
        system.assertEquals(1, [select count() from OpportunityContactRole where isPrimary = true and ContactId = :c.Id]);

        //set the HH Account model before entering the batch
        CONV_Account_Conversion_BATCH_TEST.setHHAccountModel();

        Test.StartTest();

        String query = CONV_Account_Conversion_CTRL.getBatchQuery();

        CONV_Account_Conversion_BATCH cacv = new CONV_Account_Conversion_BATCH(query);

        ID batchprocessid = Database.executeBatch(cacv);
        Test.StopTest();

        //get the newly created Household
        Account newHHAccount = [select npo02__TotalOppAmount__c, Id from Account where Name = :HHName];
        system.assertNotEquals(null, newHHAccount);
        system.assertEquals(newHHAccount.id, [select AccountId from Contact where id = :c.id].AccountId);
        system.assertEquals(newHHAccount.npo02__TotalOppAmount__c, 1000.00);
        system.assertEquals(1, [select count() from Opportunity where AccountId = :newHHAccount.Id]);
    }

    public testmethod static void testAccountConversionBucket(){
        //setup 1x1 model and test account creation
        CONV_Account_Conversion_BATCH_TEST.setPreHHAccountModel(false);

        Contact c = new Contact(LastName = 'Contact', FirstName = 'Test');
        insert c;
        Id indID = [select id from Account where Name = 'Individual'].id;

        system.assertEquals(indID, CAO_Constants.GetIndividualAccountId());

        String HHName = 'Contact ' + system.label.npo02.DefaultHouseholdName;
        system.assertEquals(1, [select count() from npo02__Household__c where Name = :HHName]);

        //add an oppty to the Contact as well
        Opportunity o = new Opportunity(Name = 'Test Oppty', Amount = 1000, StageName = UTIL_UnitTestData_TEST.getClosedWonStage(), 
                                        AccountId = indID, CloseDate = system.today(), npe01__Contact_Id_For_Role__c = c.Id);
        insert o;
        system.assertEquals('Individual', [select Account.Name from Opportunity where Name = 'Test Oppty'].Account.Name);
        system.assertEquals(1, [select count() from OpportunityContactRole where isPrimary = true and ContactId = :c.Id]);

        //set the HH Account model before entering the batch
        CONV_Account_Conversion_BATCH_TEST.setHHAccountModel();

        Test.StartTest();

        String query = CONV_Account_Conversion_CTRL.getBatchQuery();

        CONV_Account_Conversion_BATCH cacv = new CONV_Account_Conversion_BATCH(query);

        ID batchprocessid = Database.executeBatch(cacv);
        Test.StopTest();

        //get the newly created Household
        Account newHHAccount = [select npo02__TotalOppAmount__c, Id from Account where Name = :HHName];
        system.assertNotEquals(null, newHHAccount);
        system.assertEquals(newHHAccount.id, [select AccountId from Contact where id = :c.id].AccountId);
        system.assertEquals(newHHAccount.npo02__TotalOppAmount__c, 1000.00);
        system.assertEquals(1, [select count() from Opportunity where AccountId = :newHHAccount.Id]);
    }

    /* Utility methods for setting up and tearing down data and settings */

    public static void setPreHHAccountModel(boolean isOne2One){

        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests;

        npo02__Households_Settings__c householdSettingsForTests = HH_Households.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR, npo02__Enable_Opp_Rollup_Triggers__c = true));

        if (isOne2One)
            contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.ONE_TO_ONE_PROCESSOR));
        else
            contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.BUCKET_PROCESSOR));
        
        system.assert(!CAO_Constants.isHHAccountModel());
        if(isOne2One)
            system.assert(CAO_Constants.isOneToOne());
        else
            system.assert(CAO_Constants.isBucketModel());
    }
    public static void setHHAccountModel(){
        npo02__Households_Settings__c householdSettingsForTests = HH_Households.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (npo02__Household_Rules__c = HH_Households.ALL_PROCESSOR, npo02__Enable_Opp_Rollup_Triggers__c = true));
        npe01__Contacts_and_Orgs_Settings__c contactSettingsForTests = CAO_Constants.getContactsSettingsForTests(new npe01__Contacts_and_Orgs_Settings__c (npe01__Account_Processor__c = CAO_Constants.HH_ACCOUNT_PROCESSOR));
        system.assert(CAO_Constants.isHHAccountModel());
    }
}