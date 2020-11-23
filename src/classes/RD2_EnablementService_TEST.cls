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
* @description Enhanced Recurring Donations Enablement Service class
*
*/
@isTest//(IsParallel=true) Cannot execute in parallel due to Account/Contact insert and exclusive lock error
public with sharing class RD2_EnablementService_TEST {

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }


    /****
    * @description Verifies a new Opportunity is created on Recurring Donations insert
    * when Enhanced Recurring Donations are not enabled and that no RD Schedule Records are
    * created which ensures that the RD2 trigger is not executing.
    */
    @isTest
    private static void shouldCreateNewOppOnInsertWhenEnhancementIsNotEnabled() {
        setRecurringDonations2Disabled();

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withContact(getContact().Id)
            .withAmount(100)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should be created on RD insert: ' + opps);

        System.assertEquals(0, [SELECT Count() FROM RecurringDonationSchedule__c],
            'There should be no RD Schedule Records Created');
    }

    /****
    * @description Verifies a new Opportunity is not created on Recurring Donations insert
    * when enhanced Recurring Donations are enabled and the RD2 Trigger has been disabled.
    * This verifies that RD2 functionality is isolated from RD1 functionality.
    */
    @isTest
    private static void shouldNotCreateNewOppOnInsertWhenRD2TriggerIsDisabledAndEnhancedRDIsEnabled() {
        setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withContact(getContact().Id)
            .withAmount(100)
            .build();

        disableRD2Trigger();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(true, opps.isEmpty(), 'No Opp should be created on RD insert: ' + opps);
    }

    /****
    * @description Verifies a new Opportunity is created or existing updated on Recurring Donation update
    * when enhanced Recurring Donations are not enabled
    */
    @isTest
    private static void shouldCreateOrUpdateOppOnUpdateWhenEnhancementIsNotEnabled() {
        setRecurringDonations2Disabled();

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withContact(getContact().Id)
            .withAmount(100)
            .build();
        insert rd;

        Test.startTest();
        rd.npe03__Amount__c += 100;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An Opp should be created on RD update: ' + opps);
        System.assertEquals(200, opps[0].Amount, 'Opportunity Amount should be updated');
    }

    /****
    * @description Verifies no new Opportunity is created or existing updated on Recurring Donation update
    * when enhanced Recurring Donations are enabled and the RD2 Trigger has been disabled.
    * This verifies that RD2 functionality is isolated from RD1 functionality.
    */
    @isTest
    private static void shouldNotCreateOrUpdateOppOnUpdateWhenRD2TriggerIsDisabledAndEnhancedRDIsEnabled() {
        setRecurringDonations2Enabled();

        Contact contact = getContact();

        disableRD2Trigger();

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withContact(contact.Id)
            .withAmount(100)
            .withDefaultValues()
            .build();
        insert rd;

        insert buildOpportunity(rd.Id, contact.AccountId);

        Test.startTest();
        rd.npe03__Amount__c += 100;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'No new Opp should be created due to disabled RD2 triggers: ' + opps);
        System.assertEquals(100, opps[0].Amount, 'Existing Opp Amount should be unchanged');
    }

    /****
    * @description Verifies name is auto-generated when enhanced Recurring Donations are not enabled
    */
    @isTest
    private static void shouldAutogenerateNameWhenEnhancementIsNotEnabled() {
        setRecurringDonations2Disabled();

        verifyAutomatedNaming();
    }

    /****
    * @description Verifies name is auto-generated when enhanced Recurring Donations are enabled
    */
    @isTest
    private static void shouldAutogenerateNameWhenEnhancementIsEnabled() {
        setRecurringDonations2Enabled();

        verifyAutomatedNaming();
    }

    /****
    * @description Creates Recurring Donation record when automatic naming is enabled
    */
    private static void verifyAutomatedNaming() {
        RD2_NamingService_TEST.enableAutomaticNaming();

        Contact contact = getContact();

        npe03__Recurring_Donation__c rd = new TEST_RecurringDonationBuilder()
            .withContact(contact.Id)
            .withAmount(100)
            .withDefaultValues()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(RD2_NamingService_TEST.getDefaultExpectedName(contact, '100', null), rd.Name, 'Name should match');
    }

    /****
    * @description Verifies enhanced Recurring Donations are not ready for enablement
    * when Customizable Rollups are not enabled
    */
    @isTest
    private static void shouldNotActivateEnhancementWhenCustomizableRollupsAreNotEnabled() {
        RD2_EnablementService service = new RD2_EnablementService();
        setCustomizableRollups(false);
        RD2_EnablementService.isUserRunningLightning = true;

        System.assertEquals(false, service.isRecurringDonations2Ready(), 'Enhancement should not be ready');
    }

    /****
    * @description Verifies enhanced Recurring Donations are not ready for enablement
    * when LEX is not enabled
    */
    @isTest
    private static void shouldNotActivateEnhancementWhenLEXIsNotEnabled() {
        RD2_EnablementService service = new RD2_EnablementService();

        setCustomizableRollups(true);
        RD2_EnablementService.isUserRunningLightning = false;

        System.assertEquals(false, service.isRecurringDonations2Ready(), 'Enhancement should not be ready');
    }

    /****
    * @description Verifies enhanced Recurring Donations can be enabled
    * when Customizable Rollups are enabled
    * and LEX is enabled
    */
    @isTest
    private static void shouldActivateEnhancementWhenAllDependenciesAreCompleted() {
        RD2_EnablementService service = new RD2_EnablementService();

        setCustomizableRollups(true);
        RD2_EnablementService.isUserRunningLightning = true;

        System.assertEquals(true, service.isRecurringDonations2Ready(), 'Enhancement should be ready');
    }

    /****
    * @description Verifies enhanced Recurring Donations are ready for enablement
    * when PilotEnabled feature parameter is false
    */
    @isTest
    private static void shouldActivateEnhancementWhenPilotEnabledIsFalse() {
        RD2_EnablementService service = new RD2_EnablementService();

        setCustomizableRollups(true);
        RD2_EnablementService.isUserRunningLightning = true;
        UTIL_FeatureEnablement_TEST.setPilotEnabledParameter(false);

        System.assertEquals(true, service.isRecurringDonations2Ready(),
            'Enhancement should be ready for enablement regardless of the PilotEnabled value');
    }

    /****
    * @description Verifies enhanced Recurring Donations can be enabled
    * when PilotEnabled feature parameter is false
    */
    @isTest
    private static void shouldEnableEnhancementWhenPilotEnabledIsFalse() {
        UTIL_FeatureEnablement_TEST.setPilotEnabledParameter(false);
        configureRecurringDonations2Enabled();

        System.assertEquals(true, RD2_EnablementService.isRecurringDonations2Enabled, 'Enhancement should be enabled');
    }


    // Helpers
    ///////////////


    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId
            FROM Contact
            LIMIT 1
        ];
    }

    /****
    * @description Builds an Opportunity for the Recurring Donation record
    * @param rdId Recurring Donation Id
    * @param accountId Account Id
    * @return Opportunity
    */
    private static Opportunity buildOpportunity(Id rdId, Id accountId) {
        return new TEST_OpportunityBuilder()
            .withAmount(100)
            .withAccount(accountId)
            .withClosedWonStage()
            .withCloseDate(Date.today())
            .withRecurringDonation(rdId)
            .build();
    }

    /***
    * @description Enables or disables customizable rollups for testing
    * @param isEnabled Indicates if the CRLP should be enabled in the custom settings
    * @param none
    */
    public static void setCustomizableRollups(Boolean isEnabled) {
        UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c(
            Customizable_Rollups_Enabled__c = isEnabled
        ));
    }

    /***
    * @description Stubs custom settings configuration to enable enhanced Recurring Donations
    * @return none
    */
    public static void configureRecurringDonations2Enabled() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                IsRecurringDonations2Enabled__c = true,
                npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name()
            )
        );
    }

    /***
    * @description Stubs enhanced Recurring Donations as not enabled
    * @return none
    */
    public static void setRecurringDonations2Disabled() {
        RD2_EnablementService.enablementService = (RD2_EnablementService) Test.createStub(
            RD2_EnablementService.class, new Stub()
        );
    }

    /***
    * @description Disable the Enhanced Recurring Donations trigger in TDTM
    * @return none
    */
    private static void disableRD2Trigger() {
        TDTM_ProcessControl.toggleTriggerState('npe03__Recurring_Donation__c', 'RD2_RecurringDonations_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'RD2_RecurringDonationsOpp_TDTM', false);
    }

    /***
    * @description Stubs enhanced Recurring Donations as enabled
    * @return none
    */
    public static void setRecurringDonations2Enabled() {
        RD2_EnablementService.enablementService = (RD2_EnablementService) Test.createStub(
            RD2_EnablementService.class, new Stub().withRecurringDonations2Enabled()
        );
        RD2_EnablementService.isMetadataDeployed = true;
    }

    /***
    * @description Stub for the enablement service instance
    */
    public class Stub implements System.StubProvider {
        private Boolean isRecurringDonations2Ready = false;
        private Boolean isRecurringDonations2Enabled = false;

        /***
        * @description Sets enhanced Recurring Donation ready to be enabled
        */
        public Stub withRecurringDonations2Ready() {
            isRecurringDonations2Ready = true;
            return this;
        }
        /***
        * @description Sets enhanced Recurring Donation as enabled
        */

        public Stub withRecurringDonations2Enabled() {
            isRecurringDonations2Enabled = true;
            return this;
        }

        /***
        * @description Stubs class methods
        */
        public Object handleMethodCall(
            Object stubbedObject,
            String methodName,
            Type returnType,
            List<Type> paramTypes,
            List<String> paramNames,
            List<Object> args
        ) {
            switch on methodName {
                when 'isRecurringDonations2Ready' {
                    return isRecurringDonations2Ready;

                } when 'isRecurringDonations2Enabled' {
                    return isRecurringDonations2Enabled;

                } when else {
                    return null;
                }
            }
        }
    }

}