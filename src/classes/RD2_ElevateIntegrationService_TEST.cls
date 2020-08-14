/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Recurring Donations
* @description Unit Tests for the Elevate Integration Service
*/
@IsTest
public class RD2_ElevateIntegrationService_TEST {
    private static final String CURRENCY_CAD = 'CAD';
    private static final String CURRENCY_USD = 'USD';
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();

    public static final String COMMITMENT_ID = '0009989378376210918302112371207242332342432';

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;
    }

    /***
    * @description Verifies user can update an RD originated in Elevate when
    * integration is not enabled
    */
    @isTest
    private static void shouldAllowElevateRDUpdateWhenIntegrationIsNotEnabledAndUserHasNoPermission() {
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(false)
            .withHasIntegrationPermissions(false);

        Boolean hasPermission = true;
        testAndAssertPermissionToUpdateElevateRD(configStub, hasPermission);
    }

    /***
    * @description Verifies user can update an RD originated in Elevate when
    * integration is not enabled and user has permissions assigned
    */
    @isTest
    private static void shouldAllowElevateRDUpdateWhenIntegrationIsNotEnabledAndUserHasPermission() {
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(false)
            .withHasIntegrationPermissions(true);

        Boolean hasPermission = true;
        testAndAssertPermissionToUpdateElevateRD(configStub, hasPermission);
    }

    /***
    * @description Verifies user can update an RD originated in Elevate when
    * integration is enabled and user has permissions assigned
    */
    @isTest
    private static void shouldAllowElevateRDUpdateWhenElevateUser() {
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true)
            .withHasIntegrationPermissions(true);

        Boolean hasPermission = true;
        testAndAssertPermissionToUpdateElevateRD(configStub, hasPermission);
    }

    /***
    * @description Verifies user is prevented from updating an RD originated in Elevate when
    * integration is enabled and user does not have permissions assigned
    */
    @isTest
    private static void shouldPreventElevateRDUpdateWhenNonElevateUser() {
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true)
            .withHasIntegrationPermissions(false);

        Boolean hasPermission = false;
        testAndAssertPermissionToUpdateElevateRD(configStub, hasPermission);
    }

    /***
    * @description Verifies user can update an RD originated in Elevate when
    * integration is enabled and user does not have permissions assigned
    * but the changed RD field is unrestricted (unlocked) field
    */
    @isTest
    private static void shouldAllowElevateRDUpdateWhenNonElevateUserChangesUnrestrictedField() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService service = configureNonElevateUserService();

        npe03__Recurring_Donation__c rd = getElevateRecurringDonationBaseBuilder()
            .withPaidInstallments(1)
            .build();
        npe03__Recurring_Donation__c oldRd = getElevateRecurringDonationBaseBuilder()
            .withPaidInstallments(5)
            .build();

        System.assertEquals(true, service.hasUpdatePermissions(rd, oldRd),
            'Non-Elevate user should have permission to update unrestricted field on an Elevate RD');
    }

    /***
    * @description Verifies user cannot update Closed Reason on an active RD originated in Elevate when
    * integration is enabled and user does not have permissions assigned
    */
    @isTest
    private static void shouldPreventActiveElevateRDUpdateWhenNonElevateUserChangesClosedReason() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService service = configureNonElevateUserService();

        npe03__Recurring_Donation__c rd = getElevateRecurringDonationBaseBuilder().build();
        npe03__Recurring_Donation__c oldRd = getElevateRecurringDonationBaseBuilder()
            .withClosedReason('test')
            .build();

        System.assertEquals(false, service.hasUpdatePermissions(rd, oldRd),
            'Non-Elevate user should have not permission to update Closed Reason on an active Elevate RD');
    }

    /***
    * @description Verifies user can update Closed Reason on a closed RD originated in Elevate when
    * integration is enabled and user does not have permissions assigned
    */
    @isTest
    private static void shouldAllowClosedElevateRDUpdateWhenNonElevateUserChangesClosedReason() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService service = configureNonElevateUserService();

        npe03__Recurring_Donation__c rd = getElevateRecurringDonationBaseBuilder()
            .withStatusClosed()
            .build();
        npe03__Recurring_Donation__c oldRd = getElevateRecurringDonationBaseBuilder()
            .withStatusClosed()
            .withClosedReason('test')
            .build();

        System.assertEquals(true, service.hasUpdatePermissions(rd, oldRd),
            'Non-Elevate user should have permission to update Closed Reason on a closed Elevate RD');
    }

    /***
    * @description Verifies user can update Closed Reason on an active RD not originated in Elevate when
    * integration is enabled and user does not have permissions assigned
    */
    @isTest
    private static void shouldAllowActiveNonElevateRDUpdateWhenNonElevateUserChangesClosedReason() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService service = configureNonElevateUserService();

        npe03__Recurring_Donation__c rd = getRecurringDonationBaseBuilder().build();
        npe03__Recurring_Donation__c oldRd = getRecurringDonationBaseBuilder()
            .withClosedReason('test')
            .build();

        System.assertEquals(true, service.hasUpdatePermissions(rd, oldRd),
            'Non-Elevate user should have permission to update Closed Reason on an active RD not originated in Elevate');
    }

    /***
    * @description Verifies user can update an RD not originated in Elevate when
    * integration is enabled and user does not have permissions assigned
    */
    @isTest
    private static void shouldAllowNonElevateRDUpdateWhenNonElevateUser() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService service = configureNonElevateUserService();

        npe03__Recurring_Donation__c rd = getRecurringDonationBaseBuilder().build();
        npe03__Recurring_Donation__c oldRd = getRecurringDonationBaseBuilder()
            .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
            .build();
        System.assertNotEquals(rd.npe03__Contact__c, oldRd.npe03__Contact__c, 'Contact should differ on the RD');

        System.assertEquals(true, service.hasUpdatePermissions(rd, oldRd),
            'Non-Elevate user should have permission to update an RD that is not originated in Elevate');
    }

    /***
    * @description Verifies user cannot update an RD originated in Elevate when
    * RD currency is changed and integration is enabled and user does not have permissions assigned
    */
    @IsTest
    private static void shouldPreventElevateRDUpdateWhenNonElevateUserChangesCurrency() {
        if (!UserInfo.isMultiCurrencyOrganization()) {
            return;
        }

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService service = configureNonElevateUserService();

        npe03__Recurring_Donation__c rd = getElevateRecurringDonationBaseBuilder()
            .withCurrencyIsoCode(CURRENCY_CAD)
            .build();
        npe03__Recurring_Donation__c oldRd = getElevateRecurringDonationBaseBuilder()
            .withCurrencyIsoCode(CURRENCY_USD)
            .build();

        System.assertEquals(false, service.hasUpdatePermissions(rd, oldRd),
            'Non-Elevate user should not have permission to change currency on an Elevate RD');
    }

    /***
    * @description Verifies user can update an RD originated in Elevate when
    * RD currency is changed and integration is enabled and user has permissions assigned
    */
    @IsTest
    private static void shouldAllowElevateRDUpdateWhenElevateUserChangesCurrency() {
        if (!UserInfo.isMultiCurrencyOrganization()) {
            return;
        }

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true)
            .withHasIntegrationPermissions(true);
        RD2_ElevateIntegrationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );
        RD2_ElevateIntegrationService service = new RD2_ElevateIntegrationService();

        npe03__Recurring_Donation__c rd = getElevateRecurringDonationBaseBuilder()
            .withCurrencyIsoCode(CURRENCY_CAD)
            .build();
        npe03__Recurring_Donation__c oldRd = getElevateRecurringDonationBaseBuilder()
            .withCurrencyIsoCode(CURRENCY_USD)
            .build();

        System.assertEquals(true, service.hasUpdatePermissions(rd, oldRd),
            'Elevate user should have permission to change currency on an Elevate RD');
    }

    /***
    * @description Verifies user can update an RD not originated in Elevate when
    * RD currency is changed and integration is enabled and user does not have permissions assigned
    */
    @IsTest
    private static void shouldAllowNonElevateRDUpdateWhenNonElevateUserChangesCurrency() {
        if (!UserInfo.isMultiCurrencyOrganization()) {
            return;
        }

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ElevateIntegrationService service = configureNonElevateUserService();

        npe03__Recurring_Donation__c rd = getRecurringDonationBaseBuilder()
            .withCurrencyIsoCode(CURRENCY_CAD)
            .build();
        npe03__Recurring_Donation__c oldRd = getRecurringDonationBaseBuilder()
            .withCurrencyIsoCode(CURRENCY_USD)
            .build();

        System.assertEquals(true, service.hasUpdatePermissions(rd, oldRd),
            'Non-Elevate user should have permission to change currency on an RD not originated in Elevate');
    }

    /****
    * @description Verifies that any existing Opps are linked to a new RD if the CommitmentId matches
    */
    @isTest
    private static void shouldLinkOppsToRDMatchingCommitmentId() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        List<Opportunity> opps = new List<Opportunity>{
            getOpportunityBaseBuilder()
                .withCommitmentId(COMMITMENT_ID)
                .build(),
            getOpportunityBaseBuilder()
                .withCommitmentId('BAD_ID')
                .build(),
            getOpportunityBaseBuilder()
                .build()
        };
        insert opps;

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>{
            getRecurringDonationBaseBuilder()
                .withCommitmentId(COMMITMENT_ID)
                .build(),
            getRecurringDonationBaseBuilder()
                .withCommitmentId('NOTHING')
                .build(),
            getRecurringDonationBaseBuilder()
                .build()
        };

        Test.startTest();
        insert rds;
        Test.stopTest();

        Set<Id> oppIds = new Map<Id, Opportunity>(opps).keySet();

        for (Opportunity opp : oppGateway.getRecords(oppIds)) {
            if (opp.CommitmentId__c == COMMITMENT_ID) {
                System.assertEquals(rds[0].Id, opp.npe03__Recurring_Donation__c,
                    'The Opp.RecurringDonationId should match the related RD');
            } else {
                System.assertEquals(null, opp.npe03__Recurring_Donation__c,
                    'The RecurringDonationId should be null');
            }
        }

    }

    /***
    * @description Verifies that an Opps already linked to an RD is not re-linked to a different RD
    * if the CommitmentId matches
    */
    @isTest
    private static void shouldNotLinkAlreadyAssignedOppsToRDMatchingCommitmentId() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c otherRd = getRecurringDonationBaseBuilder()
            .build();
        insert otherRd;

        Opportunity opp = getOpportunityBaseBuilder()
            .withCommitmentId(COMMITMENT_ID)
            .withRecurringDonation(otherRd.Id)
            .build();
        insert opp;

        npe03__Recurring_Donation__c newRd = getRecurringDonationBaseBuilder()
            .withCommitmentId(COMMITMENT_ID)
            .build();

        Test.startTest();
        insert newRd;
        Test.stopTest();

        opp = oppGateway.getRecord(opp.Id);
        System.assertEquals(otherRd.Id, opp.npe03__Recurring_Donation__c,
            'The Opp.RecurringDonationId should still be linked to the original RD');

    }

    /***
    * @description Verifies that a new opportunity is linked to an existing RD
    * when the CommitmentId matches and the opportunity is not referencing any RD 
    */
    @isTest
    private static void shouldLinkOppToRDMatchingCommitmentIdOnOppInsert() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBaseBuilder()
            .withCommitmentId(COMMITMENT_ID)
            .build();
        insert rd;

        Opportunity opp = getOpportunityBaseBuilder()
            .withCommitmentId(COMMITMENT_ID)
            .build();

        Test.startTest();
        insert opp;
        Test.stopTest();

        opp = oppGateway.getRecord(opp.Id);
        
        System.assertEquals(rd.Id, opp.npe03__Recurring_Donation__c,
            'The Recurring Donation field on Opp should be linked to the matching RD');
    }

    /***
    * @description Verifies that a new opportunity is not linked to an existing RD
    * when the CommitmentId does not matches and the opportunity is not referencing any RD 
    */
    @isTest
    private static void shouldNotLinkOppToRDWhenCommitmentIdDoesNotMatch() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBaseBuilder()
            .withCommitmentId(COMMITMENT_ID + 'random')
            .build();
        insert rd;

        Opportunity opp = getOpportunityBaseBuilder()
            .withCommitmentId(COMMITMENT_ID)
            .build();

        Test.startTest();
        insert opp;
        Test.stopTest();

        opp = oppGateway.getRecord(opp.Id);
        
        System.assertEquals(null, opp.npe03__Recurring_Donation__c,
            'The Opp should not link to any RD if the Commitment Id field does not match');
    }

    /***
    * @description Verifies that a new opportunity is not linked to an existing RD
    * when the CommitmentId matches and RD2 is not enabled
    */
    @isTest
    private static void shouldNotLinkOppToRDWhenCommitmentIdMatchesAndRD2NotEnabled() {
        npe03__Recurring_Donation__c rd = getLegacyRecurringDonationBuilder()
            .withCommitmentId(COMMITMENT_ID)
            .build();
        insert rd;

        Opportunity opp = getOpportunityBaseBuilder()
            .withCommitmentId(COMMITMENT_ID)
            .build();

        Test.startTest();
        insert opp;
        Test.stopTest();

        opp = oppGateway.getRecord(opp.Id);
        System.assertEquals(null, opp.npe03__Recurring_Donation__c,
            'The Opportunity should not link to any RD through CommitmentId when RD2 is not enabled');
    }

    /***
    * @description Verifies that a new opportunity is not linked to an existing RD
    * when the CommitmentId matches and the opportunity is already referencing an RD 
    */
    @isTest
    private static void shouldNotLinkAlreadyAssignedOppToRDMatchingCommitmentIdOnOppInsert() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>{
            getRecurringDonationBaseBuilder()
                .withCommitmentId(COMMITMENT_ID)
                .build(),
            getRecurringDonationBaseBuilder()
                .build()
        };
        insert rds;

        Opportunity opp = getOpportunityBaseBuilder()
            .withCommitmentId(COMMITMENT_ID)
            .withRecurringDonation(rds[1].Id)
            .build();

        Test.startTest();
        insert opp;
        Test.stopTest();

        opp = oppGateway.getRecord(opp.Id);
        System.assertEquals(rds[1].Id, opp.npe03__Recurring_Donation__c,
            'The Recurring Donation field on Opp should be linked to original RD');
    }

    /***
    * @description Verifies that an existing opportunity is not linked to an RD
    * when the CommitmentId matches on opportunity update
    */
    @isTest
    private static void shouldNotLinkOppToRDWhenCommitmentIdMatchesOnUpdate() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBaseBuilder()
            .withCommitmentId(COMMITMENT_ID)
            .build();
        insert rd;

        Opportunity opp = getOpportunityBaseBuilder().build();
        insert opp;

        Test.startTest();
        opp.CommitmentId__c = COMMITMENT_ID;
        update opp;
        Test.stopTest();

        opp = oppGateway.getRecord(opp.Id);
        
        System.assertEquals(rd.Id, opp.npe03__Recurring_Donation__c,
            'The Opportunity should not link to any RD through CommitmentId on update');
    }

    // Helpers
    ///////////////////

    /****
    * @description Returns Elevate Recurring Donation with default values
    * @return TEST_RecurringDonationBuilder instance
    */
    private static TEST_RecurringDonationBuilder getElevateRecurringDonationBaseBuilder() {
        return getRecurringDonationBaseBuilder()
            .withCommitmentId(COMMITMENT_ID);
    }

    /****
    * @description Returns Recurring Donation with default values
    * @return TEST_RecurringDonationBuilder instance
    */
    private static TEST_RecurringDonationBuilder getRecurringDonationBaseBuilder() {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withContact(getContact().Id)
            .withDefaultValues()
            .withAmount(100)
            .withPaymentMethod('Credit Card')
            .withInstallmentFrequency(1);
    }

    /****
    * @description Returns Recurring Donation with default values
    * @return TEST_RecurringDonationBuilder instance
    */
    private static TEST_OpportunityBuilder getOpportunityBaseBuilder() {
        return new TEST_OpportunityBuilder()
            .withAccount(getContact().AccountId)
            .withAmount(100)
            .withCloseDate(Date.Today())
            .withClosedWonStage();
    }

    /**
     * @description Instantiate a legacy recurring donation
     * @return TEST_RecurringDonationBuilder New Recurring Donation builder
     */
    private static TEST_RecurringDonationBuilder getLegacyRecurringDonationBuilder() {
        return TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withOpenEndedStatusOpen()
            .withContact(getContact().Id)
            .withAmount(100)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1');
    }

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId, Account.Name
            FROM Contact
            LIMIT 1
        ];
    }

    /****
    * @description Sets Elevate Integration service so the integration is enabled but
    * the user does not have Elevate permissions assigned
    * @return RD2_ElevateIntegrationService
    */
    private static RD2_ElevateIntegrationService configureNonElevateUserService() {
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true)
            .withHasIntegrationPermissions(false);

        RD2_ElevateIntegrationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );

        return new RD2_ElevateIntegrationService();
    }

    /****
    * @description Sets Elevate Integration service so the integration is enabled
    */
    public static void enableElevateUserPermissions() {
        PS_IntegrationServiceConfig_TEST.Stub configStub = new PS_IntegrationServiceConfig_TEST.Stub()
            .withIsIntegrationEnabled(true)
            .withHasIntegrationPermissions(true);
        RD2_ElevateIntegrationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );
    }

    /****
    * @description Sets up RD restricted field change and verifies if user is permitted to update it
    * @param configStub Elevate Integration Service stub
    * @param hasPermission Expected output from the service when checking the permission
    * @return void
    */
    private static void testAndAssertPermissionToUpdateElevateRD(PS_IntegrationServiceConfig_TEST.Stub configStub, Boolean hasPermission) {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        RD2_ElevateIntegrationService service = new RD2_ElevateIntegrationService();
        RD2_ElevateIntegrationService.config = (PS_IntegrationServiceConfig) Test.createStub(
            PS_IntegrationServiceConfig.class,
            configStub
        );

        npe03__Recurring_Donation__c rd = getElevateRecurringDonationBaseBuilder().build();
        npe03__Recurring_Donation__c oldRd = getElevateRecurringDonationBaseBuilder()
            .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
            .build();
        System.assertNotEquals(rd.npe03__Contact__c, oldRd.npe03__Contact__c, 'Contact should differ on the RD');

        System.assertEquals(hasPermission, service.hasUpdatePermissions(rd, oldRd),
            'User should ' + (hasPermission ? '' : 'not ') + 'have permission to update Elevate RD: ' + configStub);
    }

}