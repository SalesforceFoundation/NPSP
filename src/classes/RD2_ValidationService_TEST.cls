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
@isTest(IsParallel=false)
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

    /***
    * @description Verifies that donation insert fails when metadata not deployed
    */
    @isTest
    private static void shouldFailWhenMetadataNotDeployedOnInsert() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withInstallmentPeriodYearly()
            .build();

        RD2_EnablementService.isMetadataDeployed = false;

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(errMessage.contains(System.Label.RD2_EnablementIncomplete));
    }

    /***
    * @description Verifies that donation update fails when metadata not deployed
    */
    @isTest
    private static void shouldFailWhenMetadataNotDeployedOnUpdate() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withInstallmentPeriodYearly()
            .build();

        insert rd;

        RD2_EnablementService.isMetadataDeployed = false;
        rd.StartDate__c = rd.StartDate__c.addDays(1);

        try {
            update rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(errMessage.contains(System.Label.RD2_EnablementIncomplete));
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
    * @description Verifies if it creates RDs when installment period is monthly and day of month value is valid
    */
    @isTest
    private static void shouldCreateRDWhenDayOfMonthIsValid() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        TEST_RecurringDonationBuilder rdBuilder = getRecurringDonationBuilder()
            .withContact(getContact().Id);

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();
        for (String day : new Set<String>{
            '15', '10', '28', '29', '30'
        }) {
            rds.add(rdBuilder
                .withDayOfMonth(day)
                .build());
        }

        Database.SaveResult[] srs = Database.insert(rds, false);
        for (Database.SaveResult sr : srs) {
            if (!sr.isSuccess()) {
                String errMessage = sr.getErrors()[0].getMessage();
                System.assert(false, 'Recurring Donation should be created successfully: ' + errMessage);
            }
        }

        rds = rdGateway.getRecords();
        System.assertEquals(5, rds.size(), '5 Opportunities should have been created');
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
    * and account is auto populated to the household account of the contact.
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
        rd.npe03__Organization__c = null;
        rd.npe03__Contact__c = householdContacts[1].Id;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(householdContacts[1].Id, rd.npe03__Contact__c,
            'The RD should be successfully updated with new contact');
        System.assertNotEquals(null, rd.npe03__Organization__c,
            'Account in recurring donations should be auto populated from contact');
        System.assertEquals(householdContacts[1].AccountId, rd.npe03__Organization__c,
            'The account on the recurring donations should match the account id on the contact');
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

    /***
    * @description Verifies if it displays error message when a fixed length RD has no value in
    * the NumberOfPlannedInstallments field
    */
    @isTest
    private static void shouldFailWhenFixedLengthWithNoInstallments() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilderFixed()
            .withContact(getContact().Id)
            .withPlannedInstallments(null)
            .build();

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(errMessage.contains(System.Label.RD2_NumberInstallmentsRequiredWhenFixed), errMessage);
    }

    /***
    * @description Verifies if it displays error message when a Open Ended RD has a
    * the NumberOfPlannedInstallments value greater than one
    */
    @isTest
    private static void shouldFailWhenOpenWithInstallmentsGreaterThanOne() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withPlannedInstallments(2)
            .build();

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(errMessage.contains(System.Label.RD2_NumberInstallmentsNotAllowedWhenOpen), errMessage);
    }

    /***
    * @description Verifies if it displays error message when a fixed length RD has a negative value in
    * the NumberOfPlannedInstallments field
    */
    @isTest
    private static void shouldFailWhenFixedLengthInstallmentsNegative() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilderFixed()
            .withContact(getContact().Id)
            .withPlannedInstallments(-1)
            .build();

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(errMessage.contains(System.Label.RD2_NumberInstallmentsRequiredWhenFixed), errMessage);
    }

    /***
    * @description Verifies if it displays error message when a fixed length RD has a NumberOfPlannedInstallments
    * value that is less than the NumberOfPaidInstallments field.
    */
    @isTest
    private static void shouldFailWhenFixedLengthPaidInstallmentsGreaterThanPlanned() {
        String errMessage = '';
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilderFixed()
            .withContact(getContact().Id)
            .withPlannedInstallments(12)
            .withPaidInstallments(13)
            .build();

        try {
            insert rd;
        } catch (Exception e) {
            errMessage = e.getMessage();
        }
        System.assert(errMessage.contains(System.Label.RD2_NumberInstallmentsCannotBeLessThanPaid), errMessage);
    }

    /***
    * @description Verifies DML should fail when installment frequency is updated to null
    */
    @isTest
    private static void shouldBlockRdUpdateWhenInstallmentFrequencyChangesToNull() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withInstallmentFrequency(10)
            .build();
        insert rd;

        rd.InstallmentFrequency__c = null;

        String errMessage = '';

        try {
            Test.startTest();
            update rd;
            Test.stopTest();
        } catch (DmlException e) {
            errMessage = e.getMessage();
        }

        System.assert(errMessage.contains(System.Label.RD2_InstallmentFrequencyMustBeValid),
            'RD update should fail due to invalid Installment Frequency. Actual message: ' + errMessage
        );
    }

    /***
    * @description Verifies DML should fail when installment frequency is updated to a invalid value (greater than twenty)
    */
    @isTest
    private static void shouldBlockRDUpdateWhenInstallmentFrequencyIsOutOfRange() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        List<npe03__Recurring_Donation__c> rds = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withInstallmentFrequency(10)
            .build(3);
        insert rds;

        rds[0].InstallmentFrequency__c = 20;
        rds[1].InstallmentFrequency__c = 0;
        rds[2].InstallmentFrequency__c = 21;

        Test.startTest();
        List<Database.SaveResult> results = Database.update(rds, false);
        Test.stopTest();

        for (Database.SaveResult result : results) {
            if (result.getId() == rds[0].Id) {
                System.assert(result.isSuccess(), 'Recurring Donation record update should succeed when Installment Frequencey is in range');

            } else {
                System.assert(!result.isSuccess(), 'Recurring Donation record update should fail when Installment Frequency is out of range');

                System.assert(
                    result.getErrors()[0].getMessage().contains(System.Label.RD2_InstallmentFrequencyMustBeValid),
                    'RD update should fail due to invalid Installment Frequency. Actual message: ' + result.getErrors()[0].getMessage()
                );
            }
        }
    }

    /***
    * @description Verifies DML update should succeed when installment frequency is valid
    */
    @isTest
    private static void shouldUpdateRDWhenInstallmentFrequencyIsWithinRange() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withInstallmentFrequency(10)
            .build();
        insert rd;

        rd.InstallmentFrequency__c = 20;

        Test.startTest();
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        System.assertEquals(20, rd.InstallmentFrequency__c,
            'Installment Frequency should update when the value change is valid');
    }

    /***
    * @description Verifies user cannot change the RD originated in Elevate
    * when Elevate integration is enabled and user has no permission
    */
    @isTest
    private static void shouldBlockElevateRdUpdateWhenNonElevateUserUpdatesTheRD() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true)
            .withHasIntegrationPermissions(false);
        RD2_ElevateIntegrationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withCommitmentId(RD2_ElevateIntegrationService_TEST.COMMITMENT_ID)
            .build();
        insert rd;

        String errMessage = '';
        try {
            Test.startTest();
            rd.InstallmentFrequency__c = 2;
            update rd;
            Test.stopTest();
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(errMessage.contains(System.Label.RD2_ElevatePermissionRequired),
            'RD update should fail when non-Elevate user attempts to change a restricted field: ' + errMessage
        );
    }

    /***
    * @description Verifies user can change the RD originated in Elevate
    * when Elevate integration is enabled and user has permissions
    */
    @isTest
    private static void shouldUpdateElevateRdWhenElevateUserUpdatesTheRD() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true)
            .withHasIntegrationPermissions(true);
        RD2_ElevateIntegrationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withCommitmentId(RD2_ElevateIntegrationService_TEST.COMMITMENT_ID)
            .build();
        insert rd;

        String errMessage = '';
        try {
            Test.startTest();
            rd.InstallmentFrequency__c = 2;
            update rd;
            Test.stopTest();
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(String.isBlank(errMessage),
            'RD update should succeed when Elevate user attempts to change a restricted field: ' + errMessage
        );
    }

    /**
    * @description Verifies that Elevate RD cannot have amount less than 1 dollar
    */
    @isTest
    private static void shouldNotAllowElevateRDUpdateWhenAmountIsNotValid() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();


        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true)
            .withHasIntegrationPermissions(true);
        RD2_ElevateIntegrationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withCommitmentId(RD2_ElevateIntegrationService_TEST.COMMITMENT_ID)
            .withAmount(0.1)
            .build();

        RD2_ValidationService validationService = new RD2_ValidationService(
            new List<npe03__Recurring_Donation__c>{rd},
            new List<npe03__Recurring_Donation__c>{rd.clone()}
        );

        Test.startTest();
        List<RD2_ValidationService.ErrorRecord> errorRecords = validationService.validate();
        Test.stopTest();

        System.assertEquals(System.Label.RD2_ElevateRDAmountMustBeValid, errorRecords[0].getFirstError(),
            'Elvate RD should not be updated when Amount is less than 1.');
    }

    /**
    * @description Verifies that Elevate RD update will fail when effective date is in the future
    */
    @isTest
    private static void shouldNotAllowElevateRDUpdateWhenEffectiveDateIsInTheFuture() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true)
            .withHasIntegrationPermissions(true);
        RD2_ElevateIntegrationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );

        Date today = START_DATE;
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withCommitmentId(RD2_ElevateIntegrationService_TEST.COMMITMENT_ID)
            .withAmount(10)
            .withStartDate(today.addDays(1))
            .build();

        RD2_ValidationService validationService = new RD2_ValidationService(
            new List<npe03__Recurring_Donation__c>{rd},
            new List<npe03__Recurring_Donation__c>{rd.clone()}
        );

        Test.startTest();
        List<RD2_ValidationService.ErrorRecord> errorRecords = validationService.validate();
        Test.stopTest();

        System.assertEquals(System.Label.RD2_ElevateRDEffectiveDateMustBeValid, errorRecords[0].getFirstError(),
            'Elvate RD cannot update to future Effective Date.');
    }

    /***
    * @description Verifies that RD is inserted successfully when Status is mapped
    */
    @isTest
    private static void shouldCreateRDWhenStatusIsMapped() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_StatusMapper_TEST.Stub mapperStub = new RD2_StatusMapper_TEST.Stub()
            .withDefaultMapping();
            RD2_StatusMapper.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            mapperStub
        );

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withStatusActive()
            .build();

        String errMessage = '';
        try {
            Test.startTest();
            insert rd;
            Test.stopTest();
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(String.isBlank(errMessage),
            'RD insert should succeed when Status is mapped: ' + errMessage
        );
    }

    /***
    * @description Verifies that RD fail to inserted when Status is not mapped
    */
    @isTest
    private static void shouldFailRDInsertWhenStatusIsNotMapped() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_StatusMapper_TEST.Stub mapperStub = new RD2_StatusMapper_TEST.Stub()
            .withMapping(RD2_Constants.STATUS_ACTIVE, RD2_Constants.STATUS_ACTIVE);
        RD2_StatusMapper.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            mapperStub
        );

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withStatusClosed()
            .build();

        String errMessage = '';
        try {
            Test.startTest();
            insert rd;
            Test.stopTest();
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(
            errMessage.contains(formatStatusMappingError(rd.Status__c)),
            'RD should fail to inserted when the status is not mapped:' + errMessage
        );
    }

    /***
    * @description Verifies that RD is updated successfully when Status is mapped
    */
    @isTest
    private static void shouldUpdateRDWhenStatusIsMapped() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_StatusMapper_TEST.Stub mapperStub = new RD2_StatusMapper_TEST.Stub()
            .withDefaultMapping();
            RD2_StatusMapper.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            mapperStub
        );

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withStatusActive()
            .build();
        insert rd;


        String errMessage = '';
        try {
            Test.startTest();
            rd.Status__c = RD2_Constants.STATUS_CLOSED;
            update rd;
            Test.stopTest();
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(String.isBlank(errMessage),
            'RD update should succeed when Status is mapped: ' + errMessage
        );
    }

    /***
    * @description Verifies that RD fail to update when Status is not mapped
    */
    @isTest
    private static void shouldFailRDUpdateWhenStatusIsNotMapped() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_StatusMapper_TEST.Stub mapperStub = new RD2_StatusMapper_TEST.Stub()
            .withMapping(RD2_Constants.STATUS_ACTIVE, RD2_Constants.STATUS_ACTIVE);
        RD2_StatusMapper.statusMapper = (RD2_StatusMapper) Test.createStub(
            RD2_StatusMapper.Class,
            mapperStub
        );

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withStatusActive()
            .build();
        insert rd;


        String errMessage = '';
        try {
            Test.startTest();
            rd.Status__c = RD2_Constants.STATUS_LAPSED;
            update rd;
            Test.stopTest();
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(
            errMessage.contains(formatStatusMappingError(rd.Status__c)),
            'RD update should fail when Status is not mapped: ' + errMessage
        );
    }

    /***
    * @description Verifies that RD fail to update when End Date is before the latest closed won Opp close date.
    */
    @isTest
    private static void shouldFailRDUpdateWhenEndDateIsBeforeOppClosedWonDate() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Date rdEndDate = Date.today().addDays(20);
        RD2_ScheduleService.currentDate = rdEndDate;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .build();
        insert rd;

        insert getOpportunityBuilder(rd)
            .withCloseDate(rdEndDate.addDays(5))
            .withClosedWonStage()
        .build();

        String errMessage = '';
        try {
            Test.startTest();
            rd.EndDate__c = rdEndDate;
            update rd;
            Test.stopTest();
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(
            errMessage.contains(System.Label.RD2_EndDateMustBeLaterThanCloseWonOpp),
            'RD update should fail when Rd End Date is after the opportunity closed won date: ' + errMessage
        );
    }

    /***
    * @description Verifies that Fixed RD fail to Closes when End Date is in the future.
    */
    @isTest
    private static void shouldFailFixedRDUpdateWhenEndDateIsInTheFuture() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Date today = START_DATE;
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withRecurringTypeFixed()
            .build();
        insert rd;

        String errMessage = '';
        try {
            Test.startTest();
            rd.EndDate__c = today.addDays(1);
            rd.Status__c = RD2_Constants.STATUS_CLOSED;
            update rd;
            Test.stopTest();
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(
            errMessage.contains(System.Label.RD2_EndDateMustBeValidForFixedLength),
            'Fixed RD update should fail when Rd End Date is in the future: ' + errMessage
        );
    }

    /**
    * @description Verifies that Elevate RD fail to close when End Date is in the future 
    */
    @isTest
    private static void shouldFailElevateRDUpdateWhenEndDateIsInTheFuture() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Date today = START_DATE;
        RD2_ScheduleService.currentDate = today;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withContact(getContact().Id)
            .withRecurringTypeOpen()
            .withCommitmentId('commitmentId')
            .build();
        insert rd;

        String errMessage = '';
        try {
            Test.startTest();
            rd.EndDate__c = today.addDays(1);
            rd.Status__c = RD2_Constants.STATUS_CLOSED;
            update rd;
            Test.stopTest();
        } catch (Exception e) {
            errMessage = e.getMessage();
        }

        System.assert(
            errMessage.contains(System.Label.RD2_EndDateElevateCannotBeInFuture),
            'Elevate RD update should fail when Rd End Date is in the future: ' + errMessage
        );
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

    private static TEST_RecurringDonationBuilder getRecurringDonationBuilderFixed() {
        return getRecurringDonationBuilder()
            .withRecurringTypeFixed()
            .withPlannedInstallments(12);
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

    /**
    * @description Format the Status Mapping Validation Error
    * @param status Status that will be included in the error message
    */
    private static String formatStatusMappingError(String status) {
        return String.format(
            System.Label.RD2_StatusMustBeMapped + ' ' + System.Label.RD2_StatusMustBeMappedSolution,
            new List<String>{status}
        );
    }
}