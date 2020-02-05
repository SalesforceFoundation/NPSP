/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2019
* @group Recurring Donations
* @description Recurring Donations Validation Service tests
*
*/
@isTest(IsParallel=true)
private with sharing class RD2_ValidationService_TEST {
    private static final Date START_DATE = Date.newInstance(2019, 9, 15);
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();

    /****
     * @description Creates data required for unit tests
     */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.createMultipleTestContacts(2);
    }

    /***
    * @description Verifies if it displays error message when there is no account and contact
    */
    @isTest
    private static void shouldFailWhenNoDonorIsSpecified() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder().build();

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(errMessage.contains(System.Label.RD_DonorIsRequired));

    }

    /***
    * @description Verifies if it displays error message when there is no contact for Household account
    */
    @isTest
    private static void shouldFailWhenNoContactIsSpecifiedForHHAccount() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Account acc = UTIL_UnitTestData_TEST.buildHouseholdAccount();
        insert acc;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withAccount(acc.Id)
            .build();
        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(errMessage.contains(System.Label.RD_ContactMustBelongToAccount));

    }

    /***
    * @description Verifies if it displays error message when the contact do not belong to the selected HouseHold account.
    */
    @isTest
    private static void shouldFailWhenContactDoesNotBelongToHHAccount() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Account acc = UTIL_UnitTestData_TEST.buildHouseholdAccount();
        insert acc;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withAccount(acc.Id)
            .withContact(getContact().Id)
            .build();
        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(errMessage.contains(System.Label.RD_ContactMustBelongToAccount));
    }

    /**
    * @description Should fail when there is an invalid contact for the account in the Recurring Donations list.
    */
    @isTest
    private static void shouldFailOnlyInvalidRecurringDonations() {

        String errMessage ='';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        List<Contact> contacts = getContacts();

        List<npe03__Recurring_Donation__c> rds = getRecurringDonationBuilder()
            .withAccount(contacts[0].AccountId)//only RD for one Contact will be valid
            .withInstallmentPeriodYearly()
            .build(contacts);

        List<Database.SaveResult> results = Database.insert(rds, false);
        npe03__Recurring_Donation__c rd = [
            SELECT id, npe03__Contact__c
            FROM npe03__Recurring_Donation__c
        ];

        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult result = results[i];
            if (result.isSuccess()) {
                System.assertEquals(contacts[0].Id, rd.npe03__Contact__c, 'Insert should succeed when Contact belongs to the Household.');
            } else {
                System.assert(result.getErrors()[0].getMessage().contains(System.Label.RD_ContactMustBelongToAccount));
            }
        }
    }

    /***
    * @description Verifies if it creates Recurring donations for a single household contact without an account.
    */
    @isTest
    private static void shouldCreateRDSForHouseholdContact() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withInstallmentPeriodYearly()
            .build();

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(String.isBlank(errMessage), 'Recurring Donation should be created successfully: ' + errMessage);

    }

    /***
    * @description Should create Recurring donations for organization accounts without validation errors
    */
    @isTest
    private static void shouldCreateRDSForOrganizationAccounts() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Account acc = UTIL_UnitTestData_TEST.buildOrganizationAccount();
        insert acc;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withAccount(acc.Id)
            .withInstallmentPeriodYearly()
            .build();

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(String.isBlank(errMessage), 'Recurring Donation should be created successfully: ' + errMessage);
    }

    /***
    * @description Verifies an exception is thrown when Amount is not specified,
    * zero or a negative number on an Active Recurring Donation.
    */
    @isTest
    private static void shouldNotCreateActiveRDWhenAmountIsNotValid() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        TEST_RecurringDonationBuilder rdBuilder = getRecurringDonationBuilder()
            .withContact(getContact().Id);

        for (Decimal amount : new Set<Decimal>{
            null,
            0,
            -10
        }) {
            npe03__Recurring_Donation__c rd = rdBuilder
                .withAmount(amount)
                .build();

            String errMessage = '';
            try {
                insert rd;
            } catch (Exception e) {
                errMessage = e.getMessage();
            }
            System.assert(errMessage.contains(System.Label.RD2_AmountMustBeValid),
                'Amount validation error should be expected: ' + errMessage);
        }
    }

    /***
    * @description Verifies if it creates Recurring donations for closed status when invalid amount is specified.
    */
    @isTest
    private static void shouldCreateRDForClosedRDWhenAmountIsNotValid() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        TEST_RecurringDonationBuilder rdBuilder = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withStatusClosed();

        for (Decimal amount : new Set<Decimal>{
            null,
            0,
            -10
        }) {
            npe03__Recurring_Donation__c rd = rdBuilder
                .withAmount(amount)
                .build();

            String errMessage = '';
            try {
                insert rd;
            } catch (Exception e) {
                errMessage = e.getMessage();
            }
            System.assert(String.isBlank(errMessage), 'Recurring Donation should be created successfully: ' + errMessage);
        }
    }

    /***
    * @description Verifies if it displays error message when installment period is monthly and day of month is blank
    */
    @isTest
    private static void shouldFailWhenDayOfMonthIsBlankForMonthlyInstallmentPeriod() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withDayOfMonth(null)
            .build();

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(errMessage.contains(System.Label.RD2_DayOfMonthIsRequiredForMonthlyInstallment),
            'Should indicate "Day Of Month" cannot be empty: ' + errMessage);
    }

    /***
    * @description Verifies if it displays error message when installment period is not valid
    */
    @isTest
    private static void shouldNotCreateRDWhenInstallmentPeriodIsNotValid() {
        String errMessage = '';
        String customInstallmentPeriod = 'Occasionally';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withInstallmentPeriod(customInstallmentPeriod)
            .build();

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        String expectedMessage = String.format(
            System.Label.RD2_InstallmentPeriodMustBeValid,
            new String[]{ customInstallmentPeriod }
        );
        System.assert(errMessage.contains(expectedMessage),
            'Installment period should be valid: ' + errMessage);
    }

    /***
    * @description Verifies if it displays error message when installment period
    * is monthly and day of month value is not valid
    */
    @isTest
    private static void shouldFailWhenDayOfMonthIsNotValidForMonthlyInstallments() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        TEST_RecurringDonationBuilder rdBuilder = getRecurringDonationBuilder()
            .withContact(getContact().Id);

        for (String day : new Set<String>{
            '29', '30', '31'
        }) {
            npe03__Recurring_Donation__c rd = rdBuilder
                .withDayOfMonth(day)
                .build();

            String errMessage = '';
            try {
                insert rd;
            } catch (Exception e) {
                errMessage = e.getMessage();
            }
            String expectedMessage = String.format(
                System.Label.RD2_DayOfMonthMustBeValid,
                new String[]{day }
            );
            System.assert(errMessage.contains(expectedMessage),
                'Day Of Month should be valid: ' + errMessage);
        }

    }

    /***
    * @description Verifies if it creates RDs when installment period is monthly and day of month value is valid
    */
    @isTest
    private static void shouldCreateRDWhenDayOfMonthIsValid() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        TEST_RecurringDonationBuilder rdBuilder = getRecurringDonationBuilder()
            .withContact(getContact().Id);

        for (String day : new Set<String>{
            '15', '10', '28'
        }) {
            npe03__Recurring_Donation__c rd = rdBuilder
                .withDayOfMonth(day)
                .build();

            String errMessage = '';
            try {
                insert rd;
            } catch (Exception e) {
                errMessage = e.getMessage();
            }
            System.assert(String.isBlank(errMessage), 'Recurring Donation should be created successfully: ' + errMessage);
        }
    }

    /***
    * @description Verifies RD with a closed Opp cannot be updated when changing the household contact
    */
    @isTest
    private static void shouldBlockRdWithClosedOppUpdateWhenChangeHouseholdContact() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        List<Contact> householdContacts = getContacts();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(householdContacts[0].Id)
            .build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withCloseDate(rd.npe03__Next_Payment_Date__c.addMonths(-1))
            .withClosedWonStage()
            .build();

        String errMessage = '';

        try {
            Test.startTest();
            rd.npe03__Contact__c = householdContacts[1].Id;
            update rd;
            Test.stopTest();

        } catch (DmlException e) {
            errMessage = e.getMessage();
        }

        System.assert(errMessage.contains(System.Label.RD2_ContactChangeIsRestricted),
            'The RD update should fail due to existing closed Opp: ' + errMessage);
    }

    /***
    * @description Verifies RD with a closed Opp cannot be updated 
    * when changing from household contact to an organization account
    */
    @isTest
    private static void shouldBlockRdUpdateWithClosedOppWhenChangeDonorFromHouseholdToOrganization() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        List<Contact> householdContacts = getContacts();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(householdContacts[0].Id)
            .build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withCloseDate(rd.npe03__Next_Payment_Date__c.addMonths(-1))
            .withClosedWonStage()
            .build();

        Account organizationAcct = UTIL_UnitTestData_TEST.buildOrganizationAccount();
        insert organizationAcct;

        String errMessage = '';
        try {
            Test.startTest();
            rd.npe03__Organization__c = organizationAcct.Id;
            update rd;
            Test.stopTest();

        } catch (DmlException e) {
            errMessage = e.getMessage();
        }

        System.assert(errMessage.contains(System.Label.RD2_ContactChangeIsRestricted),
            'The RD update should fail due to existing closed Opp: ' + errMessage);
    }

    /***
    * @description Verifies RD having no closed Opp can be updated to different contact
    */
    @isTest
    private static void shouldUpdateRdWithoutClosedOppWhenDonorContactChange() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        List<Contact> householdContacts = getContacts();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(householdContacts[0].Id)
            .build();
        insert rd;

        Test.startTest();
        rd.npe03__Contact__c = householdContacts[1].Id;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(householdContacts[1].Id, rd.npe03__Contact__c,
            'The RD should be successfully updated with new contact');
    }

    /***
    * @description Verifies RD with a closed Opp can be updated to a different organization
    */
    @isTest
    private static void shouldUpdateRdWithClosedOppWhenOrganizationChange() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        List<Account> organizations = UTIL_UnitTestData_TEST.buildOrganizationAccounts(2);
        insert organizations;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withAccount(organizations[0].Id)
            .build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withCloseDate(rd.npe03__Next_Payment_Date__c.addMonths(-1))
            .withClosedWonStage()
            .build();

        Test.startTest();
        rd.npe03__Organization__c = organizations[1].Id;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(organizations[1].Id, rd.npe03__Organization__c,
            'The RD should be successfully updated with new oorganization');

    }

    /***
    * @description Verifies RD with a closed Opp can be updated to different contact 
    * when the RD is under an organization account
    */
    @isTest
    private static void shouldUpdateRdWithClosedOppWhenContactUnderOrganizationChange() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        Contact householdContact = getContact();

        Account organization = UTIL_UnitTestData_TEST.buildOrganizationAccount();
        insert organization;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withAccount(organization.Id)
            .build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withCloseDate(rd.npe03__Next_Payment_Date__c.addMonths(-1))
            .withClosedWonStage()
            .build();

        Test.startTest();
        rd.npe03__Contact__c = householdContact.Id;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(organization.Id, rd.npe03__Organization__c,
            'The RD should be under the same organization');
        System.assertEquals(householdContact.Id, rd.npe03__Contact__c,
            'The RD should have the household contact as its primary contact');
    }



    // Helper Methods
    /////////////////////

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return getContacts()[0];
    }

    /****
    * @description Returns contact records
    * @return Contacts
    */
    private static List<Contact> getContacts() {
        return [
            SELECT FirstName, LastName, AccountId, Account.Name
            FROM Contact
        ];
    }

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @param contactId Contact Id
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder() {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withAmount(100)
            .withPaymentMethod('Check')
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withCalculateNextDonationDate();
    }

    /**
     * @description Instantiate an Opp builder for the specified Recurring Donation
     * @param rd Recurring Donation
     * @return TEST_OpportunityBuilder New Opp builder
     */
    private static TEST_OpportunityBuilder getOpportunityBuilder(npe03__Recurring_Donation__c rd) {
        return new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c)
            .withInstallmentNumber(1);
    }
}