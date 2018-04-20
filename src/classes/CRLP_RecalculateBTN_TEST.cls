/*
    Copyright (c) 2018, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
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
* @author Salesforce.org
* @date 2018
* @group Selectors
* @description Unit Test for the Account/Contact Recalculate Rollups button controller
*/
@isTest
private class CRLP_RecalculateBTN_TEST {

    /**
     * @description Test Setup: Insert a dummy contact and let it create an Account. The Opportunity data has to
     * be created in the actual unit test to allow for the trigger test to run
     */
    @TestSetup
    private static void setupBaseTestData() {

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        General_Accounting_Unit__c gau = new General_Accounting_Unit__c(Name = 'UNITTEST');
        insert gau;
    }

    /**
     * @description Validate that a User with no update permissions to the Contact object gets a pageMessage
     * error when the recalculate controller constructor is executed.
     */
    static testMethod void test_nopermissions() {
        // Retrieve the dummy Contact
        Contact c = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];

        // Find the ReadOnly profile (a Salesforce standard profile) and create a dummy User with that Profile
        Id roProfileId = [SELECT Id FROM Profile WHERE Name = 'Read Only' LIMIT 1].Id;
        User roUser = new User(
                FirstName = 'UNITTEST', LastName = 'UNITTEST', Alias = 'UNITTEST',
                Email = 'UNITTEST@NOWHERE.NET', UserName = 'UNITTEST@NOWHERE.NET',
                ProfileId = roProfileId,  TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US', LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'ISO-8859-1'
        );

        // Verify that controller detects the User doesn't have update permissions on the Contact object
        Test.startTest();
        System.runAs(roUser) {
            CRLP_RecalculateBTN_CTRL ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(c));
            System.assertEquals(true, ctlr.hasError, 'The controller constructor should have generated an error ' +
                    'because the Read Only user does not have update permissions to the Contact object');
        }
        Test.stopTest();
    }

    /**
     * @description Simple validation of clicking the button when legacy rollups are enabled.
     */
    static testMethod void test_legacy_rollups() {

        // Ensure that Customizable Rollups are disabled
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                        Customizable_Rollups_Enabled__c = false
                ));

        // Retrieve the dummy Contact
        Contact c = [SELECT Id, FirstName, LastName, AccountId FROM Contact LIMIT 1];
        General_Accounting_Unit__c gau = [SELECT Id FROM General_Accounting_Unit__c LIMIT 1];

        Test.startTest();

        CRLP_RecalculateBTN_CTRL ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(c));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(gau));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        Test.stopTest();
        // There's no way to test that an @future method executed other than to look for a change to the record
        // which there won't be here.
    }

    /**
     * @description Simple validation of clicking the button when the new customizable rollups are enabled
     */
    static testMethod void test_new_rollups() {

        // Start by enabling Customizable Rollups (which disables all legacy rollup operations)
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c(
                        Customizable_Rollups_Enabled__c = true,
                        Rollups_Limit_on_Attached_Opps_for_Skew__c = 200,
                        Rollups_Account_SkewMode_Batch_Size__c = 200,
                        Rollups_Contact_SkewMode_Batch_Size__c = 200,
                        Rollups_Contact_Soft_Credit_Batch_Size__c = 200,
                        Rollups_Account_Soft_Credit_Batch_Size__c = 200,
                        Rollups_Account_Batch_Size__c = 20,
                        Rollups_Contact_Batch_Size__c = 20,
                        Rollups_GAU_Batch_Size__c = 400
                ));

        // Retrieve the dummy Contact
        Contact c = [SELECT Id, FirstName, LastName, AccountId, Account.Id FROM Contact LIMIT 1];
        Account a = c.Account;
        General_Accounting_Unit__c gau = [SELECT Id FROM General_Accounting_Unit__c LIMIT 1];

        System.assertEquals(0, [SELECT Count() FROM AsyncApexJob WHERE ApexClass.Name LIKE 'CRLP%'],
                'Zero jobs should be currently scheduled');

        Test.startTest();

        Integer expectedJobCount = 0;

        CRLP_RecalculateBTN_CTRL ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(c));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');

        ctlr.buttonClick();

        expectedJobCount++;
        if (CRLP_Rollup_SVC.hasActiveSoftCreditRollupsForSObject(Contact.SObjectType)) {
            expectedJobCount++;
        }
        System.assertEquals(expectedJobCount, [SELECT Count() FROM AsyncApexJob WHERE ApexClass.Name LIKE 'CRLP%'],
                expectedJobCount + ' jobs should been queued');

        ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(a));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();

        expectedJobCount++;
        if (CRLP_Rollup_SVC.hasActiveSoftCreditRollupsForSObject(Account.SObjectType)) {
            expectedJobCount++;
        }
        System.assertEquals(expectedJobCount, [SELECT Count() FROM AsyncApexJob WHERE ApexClass.Name LIKE 'CRLP%'],
                expectedJobCount + ' jobs should been queued');

        ctlr = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(gau));
        System.assertEquals(false, ctlr.hasError, 'The controller constructor should have not generated an error');
        ctlr.buttonClick();
        expectedJobCount++;

        // validate that both the standard and the partial soft credit jobs were submitted
        System.assertEquals(expectedJobCount, [SELECT Count() FROM AsyncApexJob WHERE ApexClass.Name LIKE 'CRLP%'],
                expectedJobCount + ' jobs should been queued');

        Test.stopTest();
    }

    /*********************************************************************************************************
    * @description Given Household Setting → Always Rollup To Primary Contact = FALSE, and a Household Contact
    * donates a gift, and his organization matches the gift, when the Recalculate Rollup logic runs,
    * Soft Credit (Amount equals to Organization match) should be given to the Contact.
    */
    @isTest static void test_CalculateContactSoftCredit_AlwaysRollupToPrimaryContactIsFalse() {
        String role = 'Soft Credit';
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (
            npo02__Always_Rollup_to_Primary_Contact__c = false,
            npo02__Soft_Credit_Roles__c = role
        ));
        deactivateTriggers();

        Account household = new Account(
            Name = 'TEST_HOUSEHOLD',
            npe01__SYSTEMIsIndividual__c = true
        );
        Account organization = new Account(
            Name = 'TEST_ORGANIZATION',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert new List<Account>{household, organization};

        Contact contact = new Contact(
            LastName = 'TEST_CONTACT',
            AccountId = household.Id
        );
        insert contact;

        // Create the Contact Household and the Organization donation
        Opportunity householdContactDonation = new Opportunity(
            Name = 'TEST_CONTACT_DONATION',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = Date.today(),
            Amount = 100,
            AccountId = household.Id,
            Primary_Contact__c = contact.Id
        );
        Opportunity organizationDonation = new Opportunity(
            Name = 'TEST_ORGANIZATION_DONATION',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = Date.today(),
            Amount = 100,
            AccountId = organization.Id,
            Primary_Contact__c = contact.Id
        );
        insert new List<Opportunity>{householdContactDonation, organizationDonation};

        // Make the Contact as Primary Contact on both donations.
        List<OpportunityContactRole> contactOCRs = new List<OpportunityContactRole>{
            new OpportunityContactRole(
                OpportunityId = householdContactDonation.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = role
            ),
            new OpportunityContactRole(
                OpportunityId = organizationDonation.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = role
            )
        };
        insert contactOCRs;

        activateTriggers();
        
        Test.startTest();
        CRLP_RecalculateBTN_CTRL controller = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(contact));
        controller.buttonClick();
        Test.stopTest();

        List<Contact> updatedContact = [
            SELECT npo02__Soft_Credit_Total__c
            FROM Contact
            WHERE Id = :contact.Id
        ];
        System.assertEquals(
          organizationDonation.Amount, 
          updatedContact[0].npo02__Soft_Credit_Total__c, 
          'The Soft Credit Amount should be equal to the Organization Donation, because "Always Rollup To Primary Contact" is false');
    }

    /*********************************************************************************************************
    * @description Given Household Setting → Always Rollup To Primary Contact = FALSE, and a Household Contact
    * donates a gift, and his organization matches the gift, and the Contact has a Partial Soft Credit applied 
    * to the Organization gift, when the Recalculate Rollup logic runs, Soft Credit should be given to the Contact, 
    * and the amount should be equal to the Partial Soft Credit amount.
    */
    @isTest static void test_CalculateContactPartialSoftCredit_AlwaysRollupToPrimaryContactIsFalse() {
        String role = 'Soft Credit';
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (
            npo02__Always_Rollup_to_Primary_Contact__c = false,
            npo02__Soft_Credit_Roles__c = role
        ));
        deactivateTriggers();

        Account household = new Account(
            Name = 'TEST_HOUSEHOLD',
            npe01__SYSTEMIsIndividual__c = true
        );
        Account organization = new Account(
            Name = 'TEST_ORGANIZATION',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert new List<Account>{household, organization};

        Contact contact = new Contact(
            LastName = 'TEST_CONTACT',
            AccountId = household.Id
        );
        insert contact;

        // Create the Contact Household and the Organization donation
        Opportunity householdContactDonation = new Opportunity(
            Name = 'TEST_CONTACT_DONATION',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = Date.today(),
            Amount = 100,
            AccountId = household.Id,
            Primary_Contact__c = contact.Id
        );
        Opportunity organizationDonation = new Opportunity(
            Name = 'TEST_ORGANIZATION_DONATION',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = Date.today(),
            Amount = 100,
            AccountId = organization.Id,
            Primary_Contact__c = contact.Id
        );
        insert new List<Opportunity>{householdContactDonation, organizationDonation};

        // Make the Contact as Primary Contact on both donations.
        List<OpportunityContactRole> contactOCRs = new List<OpportunityContactRole>{
          new OpportunityContactRole(
              OpportunityId = householdContactDonation.Id,
              ContactId = contact.Id,
              IsPrimary = true,
              Role = role
          ),
          new OpportunityContactRole(
              OpportunityId = organizationDonation.Id,
              ContactId = contact.Id,
              IsPrimary = false,
              Role = role
          )
        };
        insert contactOCRs;

        Partial_Soft_Credit__c contactPartialSoftCredit = new Partial_Soft_Credit__c(
            Amount__c = 75,
            Contact_Role_ID__c = contactOCRs[1].Id,
            Contact__c = contactOCRs[1].ContactId,
            Opportunity__c = contactOCRs[1].OpportunityId,
            Role_Name__c = contactOCRs[1].Role
        );
        insert contactPartialSoftCredit;

        activateTriggers();

        Test.startTest();
        CRLP_RecalculateBTN_CTRL controller = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(contact));
        controller.buttonClick();
        Test.stopTest();

        List<Contact> updatedContact = [
            SELECT npo02__Soft_Credit_Total__c
            FROM Contact
            WHERE Id = :contact.Id
        ];
        System.assertEquals(
          contactPartialSoftCredit.Amount__c, 
          updatedContact[0].npo02__Soft_Credit_Total__c, 
          'The Soft Credit Amount should be equal to the the Contact Partial Soft Credit on Organization Donation, because "Always Rollup To Primary Contact" is false');
    }

    /*********************************************************************************************************
    * @description Given Household Setting → Always Rollup To Primary Contact = TRUE, and a Household Contact
    * donates a gift, and his organization matches the gift, when the Recalculate Rollup logic runs,
    * no Soft Credit should be given to the Contact.
    */
    @isTest static void test_CalculateContactSoftCredit_AlwaysRollupToPrimaryContactIsTrue() {
        String role = 'Soft Credit';
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (
            npo02__Always_Rollup_to_Primary_Contact__c = true,
            npo02__Soft_Credit_Roles__c = role
        ));
        deactivateTriggers();

        Account household = new Account(
            Name = 'TEST_HOUSEHOLD',
            npe01__SYSTEMIsIndividual__c = true
        );
        Account organization = new Account(
            Name = 'TEST_ORGANIZATION',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert new List<Account>{household, organization};

        Contact contact = new Contact(
            LastName = 'TEST_CONTACT',
            AccountId = household.Id
        );
        insert contact;

        Opportunity householdContactDonation = new Opportunity(
            Name = 'TEST_CONTACT_DONATION',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = Date.today(),
            Amount = 100,
            AccountId = household.Id,
            Primary_Contact__c = contact.Id
        );
        Opportunity organizationDonation = new Opportunity(
            Name = 'TEST_ORGANIZATION_DONATION',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = Date.today(),
            Amount = 100,
            AccountId = organization.Id,
            Primary_Contact__c = contact.Id
        );
        insert new List<Opportunity>{householdContactDonation, organizationDonation};

        List<OpportunityContactRole> contactOCRs = new List<OpportunityContactRole>{
            new OpportunityContactRole(
                OpportunityId = householdContactDonation.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = role
            ),
            new OpportunityContactRole(
                OpportunityId = organizationDonation.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = role
            )
        };
        insert contactOCRs;

        activateTriggers();
        
        Test.startTest();
        CRLP_RecalculateBTN_CTRL controller = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(contact));
        controller.buttonClick();
        Test.stopTest();

        List<Contact> updatedContact = [
            SELECT npo02__Soft_Credit_Total__c
            FROM Contact
            WHERE Id = :contact.Id
        ];
        System.assertEquals(0, updatedContact[0].npo02__Soft_Credit_Total__c, 'The Soft Credit Amount should be 0, because "Always Rollup To Primary Contact" is true');
    }

    /*********************************************************************************************************
    * @description Given Household Setting → Always Rollup To Primary Contact = TRUE, and a Household Contact
    * donates a gift, and his organization matches the gift, and the Contact has a Partial Soft Credit applied 
    * to the Organization gift, when the Recalculate Rollup logic runs, Soft Credit should be given to the Contact, 
    * and the amount should be equal to the Partial Soft Credit amount.
    */
    @isTest static void test_CalculateContactPartialSoftCredit_AlwaysRollupToPrimaryContactIsTrue() {
        String role = 'Soft Credit';
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(new npo02__Households_Settings__c (
            npo02__Always_Rollup_to_Primary_Contact__c = true,
            npo02__Soft_Credit_Roles__c = role
        ));
        deactivateTriggers();

        Account household = new Account(
            Name = 'TEST_HOUSEHOLD',
            npe01__SYSTEMIsIndividual__c = true
        );
        Account organization = new Account(
            Name = 'TEST_ORGANIZATION',
            npe01__SYSTEMIsIndividual__c = false
        );
        insert new List<Account>{household, organization};

        Contact contact = new Contact(
            LastName = 'TEST_CONTACT',
            AccountId = household.Id
        );
        insert contact;

        // Create the Contact Household and the Organization donation
        Opportunity householdContactDonation = new Opportunity(
            Name = 'TEST_CONTACT_DONATION',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = Date.today(),
            Amount = 100,
            AccountId = household.Id,
            Primary_Contact__c = contact.Id
        );
        Opportunity organizationDonation = new Opportunity(
            Name = 'TEST_ORGANIZATION_DONATION',
            StageName = UTIL_UnitTestData_TEST.getClosedWonStage(),
            CloseDate = Date.today(),
            Amount = 100,
            AccountId = organization.Id,
            Primary_Contact__c = contact.Id
        );
        insert new List<Opportunity>{householdContactDonation, organizationDonation};

        // Make the Contact as Primary Contact on both donations.
        List<OpportunityContactRole> contactOCRs = new List<OpportunityContactRole>{
            new OpportunityContactRole(
                OpportunityId = householdContactDonation.Id,
                ContactId = contact.Id,
                IsPrimary = true,
                Role = role
            ),
            new OpportunityContactRole(
                OpportunityId = organizationDonation.Id,
                ContactId = contact.Id,
                IsPrimary = false,
                Role = role
            )
        };
        insert contactOCRs;

        Partial_Soft_Credit__c contactPartialSoftCredit = new Partial_Soft_Credit__c(
            Amount__c = 75,
            Contact_Role_ID__c = contactOCRs[1].Id,
            Contact__c = contactOCRs[1].ContactId,
            Opportunity__c = contactOCRs[1].OpportunityId,
            Role_Name__c = contactOCRs[1].Role
        );
        insert contactPartialSoftCredit;

        activateTriggers();

        Test.startTest();
        CRLP_RecalculateBTN_CTRL controller = new CRLP_RecalculateBTN_CTRL(new ApexPages.StandardController(contact));
        controller.buttonClick();
        Test.stopTest();

        List<Contact> updatedContact = [
            SELECT npo02__Soft_Credit_Total__c
            FROM Contact
            WHERE Id = :contact.Id
        ];
        System.assertEquals(contactPartialSoftCredit.Amount__c, updatedContact[0].npo02__Soft_Credit_Total__c);
    }

    /*******************************************************************************************************
    * @description Deactivates all the Triggers.
    * @return void.
    ********************************************************************************************************/
    private static void deactivateTriggers() {
        for (Trigger_Handler__c triggerHandler : TDTM_Config_API.getCachedRecords()) {
            triggerHandler.Active__c = false;
        }
    }

    /*******************************************************************************************************
    * @description Activates all the Triggers.
    * @return void.
    ********************************************************************************************************/
    private static void activateTriggers() {
        for (Trigger_Handler__c triggerHandler : TDTM_Config_API.getCachedRecords()) {
            triggerHandler.Active__c = true;
        }
    }
}