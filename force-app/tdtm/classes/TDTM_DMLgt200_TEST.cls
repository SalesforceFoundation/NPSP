/*
    Copyright (c) 2017, Salesforce.org
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
 * @date 2017
 * @group TDTM
 * @group-content ../../ApexDocContent/TDTM.htm
 * @description Test class to validate behavior changes related to TDTM Static Flag handling, primarily focused on
 * dml operations with more than 200 records. Unit tests in this class are generally meant to push limits beyond
 * what most of our unit tests will normally do by inserting more than 200 records at a time. This causes Salesforce
 * to execute each set of triggers twice (once for a block of 200 records and then again for a block of 10 records).
 * These tests validate that all expected functionality completes properly even when the triggers are executed twice
 * as described (i.e., we're testing that our static flag recursion control logic works properly in this scenario).
 *
 * Refactored slightly in Aug 2020 to use different techniques to create data to marginally improve test performance
 **/
@isTest
private class TDTM_DMLgt200_TEST {

    /**
    * @description The number of records to insert for these tests. Inserting more than 200 records at once
    * will cause triggers to be called twice - once for the first group of 200 and then again for the remainder.
    */
    private static final Integer insertCnt = 210;

    /**
    * @description The test zipcode to use for addresses; compatible with the address validation mock
    */
    private static final String testZipCode = '95014';

    /*********************************************************************************************************
    * @description Test creating 200+ Contacts with Affiliations
    *   NOTE: THIS WILL FAIL IN AN ORG WITHOUT THE STATIC FLAG CHANGES
    */
    @isTest
    static void test_contacts_with_affiliations() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        UTIL_Debug.disableDebugLogging();     // Override debug logging for this test because it's an expensive operation
        UTIL_UnitTestData_TEST.disableRelationshipTriggers();
        UTIL_UnitTestData_TEST.disableAddressTriggers();
        UTIL_UnitTestData_TEST.disableMergeTriggers();

        npe5__Affiliations_Settings__c affiliationsSettingsForTests = UTIL_CustomSettingsFacade.getAffiliationsSettingsForTests(
                new npe5__Affiliations_Settings__c(npe5__Automatic_Affiliation_Creation_Turned_On__c = true));

        Account orgAcct = getNewOrgAccount();

        Test.startTest();

        // Create more than 200 Contact records and then validate that all of the Household Accounts were created
        List<Contact> contacts = createMultipleTestContacts(insertCnt);
        insertWithAllowDupes(contacts);

        System.assertEquals(insertCnt, [SELECT Count() FROM Account WHERE npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE],
                'There should be exactly ' + insertCnt.format() + ' Household Account records');

        // Create Affiliation records for every Contact, setting the IsPrimary field to true
        // NOTE: To test a WFR update on this, a WFR to check the IsPrimary field could be used.
        List<npe5__Affiliation__c> affls = new List<npe5__Affiliation__c>();
        for (Contact c : contacts) {
            npe5__Affiliation__c affl = new npe5__Affiliation__c(
                npe5__Organization__c = orgAcct.Id,
                npe5__Contact__c = c.Id,
                npe5__Primary__c = True,
                npe5__Status__c = AFFL_Affiliations_TDTM.DEFAULT_CURRENT_STATUS
            );
            affls.add(affl);
        }
        Database.insert(affls);
        Test.stopTest();
        System.assertEquals(insertCnt, [SELECT Count() FROM npe5__Affiliation__c WHERE npe5__Organization__c = :orgAcct.Id],
            'There should be exactly ' + insertCnt.format() + ' Affiliations records');
        System.assertEquals(insertCnt, [SELECT Count() FROM Contact WHERE Primary_Affiliation__c = :orgAcct.Id],
            'There should be exactly ' + insertCnt.format() + ' Contacts with a Primary Affiliation');
    }


    /*********************************************************************************************************
    * @description Test creating 200+ Contacts with a Primary Affiliations
    */
    @isTest
    static void test_contacts_with_primary_affiliations() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        UTIL_Debug.disableDebugLogging();     // Override debug logging for this test because it's an expensive operation
        UTIL_UnitTestData_TEST.disableRelationshipTriggers();
        UTIL_UnitTestData_TEST.disableAddressTriggers();
        UTIL_UnitTestData_TEST.disableMergeTriggers();

        npe5__Affiliations_Settings__c affiliationsSettingsForTests = UTIL_CustomSettingsFacade.getAffiliationsSettingsForTests(
                new npe5__Affiliations_Settings__c(npe5__Automatic_Affiliation_Creation_Turned_On__c = true));

        Account orgAcct = getNewOrgAccount();

        Test.startTest();

        // Create more than 200 Contact records and then validate that all of the Household Accounts were created
        // as well as all the related Affiliation recorsd
        List<Contact> contacts = createMultipleTestContacts(insertCnt);
        for (Contact c : contacts) {
            c.Primary_Affiliation__c = orgAcct.Id;
        }
        insertWithAllowDupes(contacts);

        Test.stopTest();

        System.assertEquals(insertCnt, [SELECT Count() FROM Account WHERE npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE],
            'There should be exactly ' + insertCnt.format() + ' Household Account records');
        System.assertEquals(insertCnt, [SELECT Count() FROM npe5__Affiliation__c WHERE npe5__Organization__c = :orgAcct.Id],
            'There should be exactly ' + insertCnt.format() + ' Affiliations records');
        System.assertEquals(insertCnt, [SELECT Count() FROM Contact WHERE Primary_Affiliation__c = :orgAcct.Id],
            'There should be exactly ' + insertCnt.format() + ' Contacts with a Primary Affiliation');
    }

    /*********************************************************************************************************
    * @description Test creating 200+ Contacts with Relationships
    */
    @isTest
    static void test_contacts_with_relationships() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        UTIL_Debug.disableDebugLogging();     // Override debug logging for this test because it's an expensive operation
        UTIL_UnitTestData_TEST.disableAffiliationsTriggers();
        UTIL_UnitTestData_TEST.disableAddressTriggers();
        UTIL_UnitTestData_TEST.disableMergeTriggers();

        Test.startTest();

        // Create more than 200 Contact records and then validate that all of the Household Accounts were created
        List<Contact> contacts = createMultipleTestContacts(insertCnt);
        insertWithAllowDupes(contacts);

        System.assertEquals(insertCnt, [SELECT Count() FROM Account WHERE npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE],
                'There should be exactly ' + insertCnt.format() + ' Household Account records');

        // Create Relationships between the Contacts
        List<npe4__Relationship__c> rels =  new List<npe4__Relationship__c>();
        for (Integer n=0; n<insertCnt; n++) {
            Contact c1 = contacts[n];
            Contact c2 = contacts[insertCnt - n - 1];
            npe4__Relationship__c rel = new npe4__Relationship__c(
                npe4__Contact__c = c1.Id,
                npe4__RelatedContact__c = c2.Id,
                npe4__Type__c = 'Spouse',
                npe4__Description__c = 'InsertTest'
            );
            rels.add(rel);
        }
        Database.insert(rels);
        Test.stopTest();

        System.assertEquals(insertCnt*2, [SELECT Count() FROM npe4__Relationship__c
            WHERE npe4__Contact__c IN :contacts AND npe4__Type__c = 'Spouse'],
            'There should be exactly ' + (insertCnt*2).format() + ' Relationships');
    }

    /*********************************************************************************************************
    * @description Test creating 200+ Opportunities with a linked Campaign allocation
    *   NOTE: THIS WILL FAIL IN AN ORG WITHOUT THE STATIC FLAG CHANGES
    */
    @isTest
    static void testBulkOpportunitiesWithCampaignAlloc() {

        UTIL_Debug.disableDebugLogging();     // Override debug logging for this test because it's an expensive operation
        UTIL_UnitTestData_TEST.disableRollupTriggers();
        UTIL_UnitTestData_TEST.disableMergeTriggers();
        UTIL_UnitTestData_TEST.disableAddressTriggers();
        UTIL_UnitTestData_TEST.disableOppNonOCRTriggers();

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;
        c = [SELECT Id, AccountId FROM Contact WHERE Id = :c.Id];

        List<General_Accounting_Unit__c> gaus = UTIL_UnitTestData_TEST.createGAUs(2);
        insert gaus;
        General_Accounting_Unit__c defaultGau = gaus[0];
        General_Accounting_Unit__c campaignGau = gaus[1];

        UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(
            new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id)
        );

        Campaign camp = new Campaign(Name = 'UNITTEST', IsActive = True);
        insert camp;

        Allocation__c campAlloc = new Allocation__c(
            Campaign__c = camp.Id,
            General_Accounting_Unit__c = campaignGau.Id,
            Percent__c = 100
        );
        insert campAlloc;

        Test.startTest();

        // Create 200+ Opportunity Records
        Date closeDate = Date.Today().addMonths(1);
        String closedWonStage = UTIL_UnitTestData_TEST.getClosedWonStage();
        List<Opportunity> opps = new List<Opportunity>();

        for (Integer n = 0; n < insertCnt; n++) {
            opps.add(new Opportunity(
                Name = 'MASS INSERT TEST ' + n,
                Primary_Contact__c = c.Id,
                CampaignId = camp.Id,
                CloseDate = closeDate,
                StageName = closedWonStage
            ));
        }
        Database.insert(opps);

        System.assertEquals(0, [SELECT Count() FROM Allocation__c WHERE Opportunity__c IN :opps],
            'There should be exactly zero Allocations for Opportunities without Amount');

        // Populate the Amount field on the Opportunity to allow the allocations to be applied
        for (Opportunity o : opps) {
            o.Amount = 100;
        }
        Database.update(opps);

        Test.stopTest();

        System.assertEquals(
            insertCnt,
            [SELECT Count() FROM Allocation__c WHERE Opportunity__c IN :opps AND General_Accounting_Unit__c = :campaignGau.Id],
            'There should be exactly ' + insertCnt.format() + ' Campaign related Allocations'
        );

        System.assertEquals(
            0,
            [SELECT Count() FROM Allocation__c WHERE Opportunity__c IN :opps AND General_Accounting_Unit__c = :defaultGau.Id],
            'There should be exactly zero Default Settings Allocations'
        );
    }

    /*********************************************************************************************************
    * @description Test creating 200+ Recurring Donations each with 2 installments.
    *   NOTE: THIS WILL FAIL IN AN ORG WITHOUT THE STATIC FLAG CHANGES
    */
    @isTest
    static void test_recurring_donations() {

        UTIL_Debug.disableDebugLogging();     // Override debug logging for this test because it's an expensive operation
        UTIL_UnitTestData_TEST.disableRollupTriggers();
        UTIL_UnitTestData_TEST.disableMergeTriggers();
        UTIL_UnitTestData_TEST.disableOCRTriggers();
        UTIL_UnitTestData_TEST.disableAddressTriggers();
        UTIL_UnitTestData_TEST.disableOppNonOCRTriggers();

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                npe03__Opportunity_Forecast_Months__c = 6,
                npe03__Maximum_Donations__c = 2,
                npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()
            ));

        Test.startTest();

        // Insert the RecurringDonation records
        List<npe03__Recurring_Donation__c> rds = new TEST_RecurringDonationBuilder()
            .withPlannedInstallments(2)
            .withContact(c.Id)
            .withAmount(100)
            .withInstallmentPeriodMonthly()
            .withDateEstablished(Date.newInstance(1970,6,12))
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusNone()
            .build(insertCnt);

        Database.insert(rds);
        Test.stopTest();

        System.assertEquals(insertCnt*2, [SELECT Count() FROM Opportunity
            WHERE npe03__Recurring_Donation__c IN :rds],
            'There should be exactly ' + (insertCnt*2).format() + ' Installment Opps');
    }

    /*********************************************************************************************************
    * @description Test creating 200+ new Contacts with a full address
    *   NOTE: THIS WILL FAIL IN AN ORG WITHOUT THE STATIC FLAG CHANGES
    */
    @IsTest
    static void shouldInsertMoreThan200ContactsWithAddresses() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        UTIL_CustomSettingsFacade.getErrorSettingsForTests(
            new Error_Settings__c(Respect_Duplicate_Rule_Settings__c = true)
        );

        UTIL_Debug.disableDebugLogging();     // Override debug logging for this test because it's an expensive operation
        UTIL_UnitTestData_TEST.disableAffiliationsTriggers();
        UTIL_UnitTestData_TEST.disableRelationshipTriggers();
        UTIL_UnitTestData_TEST.disableMergeTriggers();
        UTIL_UnitTestData_TEST.disableHHNamingTriggers();
        TDTM_ProcessControl.toggleTriggerState('Contact', 'CON_DoNotContact_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Address__c', 'ADDR_Validator_TDTM', false);

        // Create more than 200 Contact records and then validate that all of the Addresses were verified
        List<Contact> contacts = createMultipleTestContactsWithAddress(insertCnt);
        insertWithAllowDupes(contacts);

        System.assertEquals(insertCnt, [SELECT Count() FROM Contact],
            'There should be exactly ' + insertCnt.format() + ' Contact records');
        System.assertEquals(insertCnt, [SELECT Count() FROM Account WHERE npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE],
            'There should be exactly ' + insertCnt.format() + ' Household Account records');

        Integer counter = 0;
        for (Address__c address : [SELECT MailingPostalCode__c FROM Address__c]) {
            if (address.MailingPostalCode__c == testZipCode) {
                counter++;
            }
        }
        System.assertEquals(insertCnt, counter,
            'There should be exactly ' + insertCnt.format() + ' Address Records');
    }

    /*********************************************************************************************************
    * @description Test creating 200+ new Contacts and validate that all 200+ have their
    * Household Account created.
    */
    @isTest
    static void insertingContactsShouldAutomaticallyCreateHouseholdAccounts() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        // Create more than 200 Contact records and then validate that all of the Household Accounts were created
        List<Contact> contacts = createMultipleTestContacts(insertCnt);
        insertWithAllowDupes(contacts);

        System.assertEquals(insertCnt, [SELECT Count() FROM Account WHERE npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE],
                'There should be exactly ' + insertCnt.format() + ' Accounts');
    }

    /*********************************************************************************************************
    * @description Test that changing the Last Name of Household Contacts
    * prompts a renaming of the Contact's Household Accounts.
    * For performance testing, increase the insert count, or use the class-level insertCnt
    * variable.
    */
    @isTest
    static void changeToHouseholdContactLastNameShouldRenameHouseholdAccount() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        // Arrange
        // Insert Contacts (Default TDTM, Default Account/Contact model, i.e.,
        // Household Account Contacts)
        Integer insertCnt = 10;
        List<Contact> contacts = createMultipleTestContacts(insertCnt);
        insertWithAllowDupes(contacts);

        // Act - rename all the Contacts
        Test.startTest();
        Integer n = 0;
        for (Contact c : contacts) {
            c.LastName = 'ChangedLastName#' + (n++);
        }
        Database.update(contacts);
        Test.stopTest();

        // Assert
        for (Contact c : [
                SELECT Id, FirstName, LastName, Account.Name
                FROM Contact
                WHERE Id IN :contacts
        ]) {
            System.assert(c.Account.Name.contains(c.LastName),
                    'The Account Name should contain the Contacts last name');
        }
    }

    /*********************************************************************************************************
    * @description Create more than 200 Contact records and then validate that all of the Addresses were verified
    *   NOTE: THIS WILL FAIL IN AN ORG WITHOUT THE STATIC FLAG CHANGES
    */
    @IsTest
    static void shouldValidateMoreThan200AddressRecords() {
        //skip the test if Advancement is installed
        if(ADV_PackageInfo_SVC.useAdv()) return;

        UTIL_CustomSettingsFacade.getErrorSettingsForTests(
            new Error_Settings__c(Respect_Duplicate_Rule_Settings__c = true)
        );

        ADDR_Validator_TEST.createDefaultSettings();
        Test.setMock(HttpCalloutMock.class, new ADDR_MockHttpRespGenerator_TEST());

        UTIL_Debug.disableDebugLogging();     // Override debug logging for this test because it's an expensive operation
        UTIL_UnitTestData_TEST.disableAffiliationsTriggers();
        UTIL_UnitTestData_TEST.disableRelationshipTriggers();
        UTIL_UnitTestData_TEST.disableMergeTriggers();
        UTIL_UnitTestData_TEST.disableHHNamingTriggers();
        TDTM_ProcessControl.toggleTriggerState('Contact', 'CON_DoNotContact_TDTM', false);

        // Create more than 200 Contact records and then validate that all of the Addresses were verified
        List<Contact> contacts = createMultipleTestContactsWithAddress(insertCnt);

        Test.startTest();
        insertWithAllowDupes(contacts);
        Test.stopTest();

        // check household created for contacts
        System.assertEquals(insertCnt, [SELECT Count() FROM Account WHERE npe01__SYSTEM_AccountType__c = :CAO_Constants.HH_ACCOUNT_TYPE],
            'There should be exactly ' + insertCnt.format() + ' Household Account records');

        // validate that all address records were validated
        System.assertEquals(insertCnt, [SELECT Count() FROM Address__c WHERE Verification_Status__c = :Label.Addr_Verified],
            'There should be exactly ' + insertCnt.format() + ' Validated Address records');

        // validate that all contact addresses were fixed
        for (Contact record : [SELECT MailingPostalCode FROM Contact WHERE Id IN :contacts]) {
            System.assertEquals(testZipCode + '-2083', record.MailingPostalCode, 'Each contact\'s address should be updated');
        }
    }

    /**
     * @description Tests issue #1960 where changing the number of OpportunityForecastMonths and then executing the
     * RD batch job does not properly create all of the necessary default allocations records.
     *   NOTE: THIS WILL FAIL IN AN ORG WITHOUT THE STATIC FLAG CHANGES
     */
    @isTest
    static void testAllocationsCreatedForManyOpenEndedRecurringDonations() {

        UTIL_Debug.disableDebugLogging();     // Override debug logging for this test because it's an expensive operation
        UTIL_UnitTestData_TEST.disableAddressTriggers();

        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        npe03__Recurring_Donations_Settings__c rdSettings = UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                npe03__Opportunity_Forecast_Months__c = 1,
                npe03__Maximum_Donations__c = 12,
                npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()
            ));

        General_Accounting_Unit__c defaultGau = UTIL_UnitTestData_TEST.createGAUs(1)[0];
        insert defaultGau;

        UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(new Allocations_Settings__c(
            Default_Allocations_Enabled__c = true, Default__c = defaultGau.Id));

        List<npe03__Recurring_Donation__c> rds = new TEST_RecurringDonationBuilder()
            .withContact(c.Id)
            .withAmount(100.0)
            .withInstallmentPeriodMonthly()
            .withOpenEndedStatusOpen()
            .build(20);

        insert rds;

        Test.startTest();

        rdSettings.npe03__Opportunity_Forecast_Months__c = 12;
        STG_PanelRDBatch_CTRL rdBatch = new STG_PanelRDBatch_CTRL();
        rdBatch.runBatch();

        Test.stopTest();

        List<Opportunity> createdOpportunities = [SELECT Id FROM Opportunity WHERE npe03__Recurring_Donation__c IN :rds];

        // Validate that there are 240 (12*20) Opps, Payments and Allocations created by the batch job.
        System.assertEquals(240, createdOpportunities.size(), 'There should be 240 generated Installment Opportunities created');

        System.assertEquals(240, [SELECT Count() FROM npe01__OppPayment__c WHERE npe01__Opportunity__c IN :createdOpportunities],
            'There should be 240 generated payment records');

        System.assertEquals(240, [SELECT Count() FROM Allocation__c WHERE Opportunity__c IN :createdOpportunities],
            'There should be 240 generated default allocations records');
    }

    //////////////////////////////////////////////////////////////////////////
    // Helper Methods
    //////////////////////////////////////////////////////////////////////////

    /**
     * @description Create test contacts. Does not use the UTIL_UnitTestData_TEST.getContact() method to
     * avoid additional (cpu consuming) logic such as unique strings and other fields that aren't needed
     * for this specific set of tests.
     * @param numContactsToCreate
     * @return List<Contact>
     */
    private static List<Contact> createMultipleTestContacts(Integer numContactsToCreate) {
        return createMultipleTestContacts(numContactsToCreate, null, null, null, null);
    }

    /**
     * @description Create test contacts WITH address data.
     * Does not use the UTIL_UnitTestData_TEST.getContact() method to avoid additional (cpu consuming)
     * logic such as unique strings and other fields that aren't needed for this specific set of tests.
     * @param numContactsToCreate
     * @return List<Contact>
     */
    private static List<Contact> createMultipleTestContactsWithAddress(Integer numContactsToCreate) {
        return createMultipleTestContacts(numContactsToCreate,
            'multiple-address',
            'Cupertino',
            'California',
            testZipCode
        );
    }

    /**
     * @description Return a list of Contact SObjects for tests with a unique first and last name
     * @param numContactsToCreate The number of Contact records to create
     * @param streetAddress
     * @param city
     * @param state
     * @param zipcode
     * @return List<Contact>
     */
    private static List<Contact> createMultipleTestContacts(Integer numContactsToCreate, String streetAddress, String city, String state, String zipcode) {

        List<Contact> contacts = new List<Contact>();
        for (Integer counter = 0; counter < numContactsToCreate; counter++) {
            contacts.add(new Contact(
                FirstName = CAO_Constants.CONTACT_FIRSTNAME_FOR_TESTS,
                LastName = CAO_Constants.CONTACT_LASTNAME_FOR_TESTS + '-' + counter.format(),
                Title = 'Test',
                MailingStreet = streetAddress,
                MailingCity = city,
                MailingState = state,
                MailingPostalCode = zipcode,
                MailingCountry = 'United States'
            ));
        }
        return contacts;
    }

    /**
     * @return new Organization Account
     */
    private static Account getNewOrgAccount() {
        Account orgAcct = new Account(Name='TestOrganization');
        insert orgAcct;
        return orgAcct;
    }

    /**
     * @description Insert Contacts with the DML Option to allow duplicates
     * @param contacts List of Contacts to insert
     */
    private static void insertWithAllowDupes(List<Contact> contacts) {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.duplicateRuleHeader.allowSave = true;
        Database.insert(contacts, dml);
    }
}