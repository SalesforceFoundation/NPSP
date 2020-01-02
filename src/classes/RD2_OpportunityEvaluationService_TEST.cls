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
* @description Unit tests for the Enhanced RD Opportunity Evaluation Services
*
*/
@IsTest(IsParallel=true)
private class RD2_OpportunityEvaluationService_TEST {

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();

    private static final Date START_DATE = Date.newInstance(2019, 9, 15);

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;
    }

    /**
     * @description Verifies that creating a new Open Recurring Donation creates an Installment Opportunity
     */
    @IsTest
    private static void shouldCreateAnInstallmentOpportunity() {
        Contact contact = getContact();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(contact)
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(1, opps.size(), 'The number of returned Opp should match');
        System.assertEquals(rd.npe03__Amount__c, opps[0].Amount, 'The Opportunity Amount does not match the RD Amount');
        System.assertEquals(rd.npe03__Contact__c, opps[0].Primary_Contact__c, 'The Opportunity Contact does not match the RD Contact');
        System.assertEquals(rd.npe03__Next_Payment_Date__c, opps[0].CloseDate, 'The Opportunity CloseDate does not match the RD NextDonationDate');
    }

    /**
     * @description Verifies that inserting a Closed Recurring Donation does not create an Installment Opportunity
     */
    @IsTest
    private static void shouldNotCreateAnInstallmentOpportunityIfClosedWhenCreated() {
        Contact contact = getContact();
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(contact)
            .withStatusClosed()
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(0, opps.size(), 'There should not have been any Installment Opps created for this RD');
    }

    /**
     * @description Verify that the Recurring Donations are NOT eligible to have an installment opportunity created
     */
    @IsTest
    private static void shouldNotBeEligibleForNewInstallmentOpp() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();

        // Closed Recurring Donation
        npe03__Recurring_Donation__c rd1 = getRecurringDonationBuilder()
            .withStatusClosed()
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();
        rd1 = mockRecurringDonationFullQueryResult(rd1, new List<Opportunity>(), scheduleService.getNewSchedules(rd1));

        // Recurring Donation with no Schedule records
        npe03__Recurring_Donation__c rd2 = getRecurringDonationBuilder()
            .withInstallmentPeriodWeekly()
            .withInstallmentFrequency(3)
            .withCalculateNextDonationDate()
            .build();
        rd2 = mockRecurringDonationFullQueryResult(rd2, new List<Opportunity>(), new List<RecurringDonationSchedule__c>());

        // Recurring Donation with an empty NextDonationDate
        npe03__Recurring_Donation__c rd3 = getRecurringDonationBuilder()
            .withInstallmentPeriodYearly()
            .withInstallmentFrequency(1)
            .withStartDate(Date.newInstance(2019, 6, 1))
            .withCalculateNextDonationDate()
            .build();
        rd3.npe03__Next_Payment_Date__c = null;
        rd3 = mockRecurringDonationFullQueryResult(rd3, new List<Opportunity>(), scheduleService.getNewSchedules(rd3));

        RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService();
        evalService.rds = new List<npe03__Recurring_Donation__c>{ rd1, rd2, rd3 };

        System.assertEquals(false, evalService.isNewRecurringDonation(rd1), 'Closed RD should not be eligible for an Installment Opp');
        System.assertEquals(false, evalService.isNewRecurringDonation(rd2), 'RD with no Schedules should not be eligible for an Installment Opp');
        System.assertEquals(false, evalService.isNewRecurringDonation(rd3), 'RD without a Next Donation Date should not be eligible for an Installment Opp');
    }

    /**
     * @description Verify that the Recurring Donations are recognized as "New" if there are no related Opps
     * or "Not New" if there have related Opps.
     */
    @IsTest
    private static void shouldDetermineIfNewOrPreExistingRecurringDonation() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();

        // New Opportunity - Is New RD
        npe03__Recurring_Donation__c rdNew = getRecurringDonationBuilder()
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();
        rdNew = mockRecurringDonationFullQueryResult(rdNew, new List<Opportunity>(), scheduleService.getNewSchedules(rdNew));

        // Old Opportunity (has related Opps) - Not New RD
        npe03__Recurring_Donation__c rdOld = getRecurringDonationBuilder()
            .withInstallmentPeriodWeekly()
            .withInstallmentFrequency(3)
            .withCalculateNextDonationDate()
            .build();

        List<Opportunity> opps = new List<Opportunity>{
            new TEST_OpportunityBuilder()
                .withAccount(rdOld.npe03__Organization__c)
                .withContact(rdOld.npe03__Contact__c)
                .withRecurringDonation(rdOld.Id)
                .withAmount(rdOld.npe03__Amount__c)
                .withOpenStage()
                .withCloseDate(rdOld.npe03__Next_Payment_Date__c)
                .build()
        };
        rdOld = mockRecurringDonationFullQueryResult(rdOld, opps, scheduleService.getNewSchedules(rdOld));

        RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService();
        evalService.rds = new List<npe03__Recurring_Donation__c>{ rdNew, rdOld };

        System.assertEquals(true, evalService.isNewRecurringDonation(rdNew), 
            'RD having Schedules and no related Opp should be eligible for an Installment Opp');

        System.assertEquals(false, evalService.isNewRecurringDonation(rdOld), 
            'RD having Schedules and a related Opp should not be eligible for an Installment Opp');
    }

    /**
     * @description Verifies open Opportunities are marked as Closed Lost when RD is closed and
     * Recurring Donation settings Open Opportunity Behaviour is set to mark open Opps as Closed Lost
     */
    @IsTest
    private static void shouldMarkOpenOppsAsClosedLostWhenRDIsClosed() {        
        String closeAction = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name();

        npe03__Recurring_Donation__c rd = setupDataAndCloseRD(closeAction);
        List<Opportunity> oldOpps = rd.npe03__Donations__r;

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));

        System.assertEquals(oldOpps.size(), oppById.size(), 'The number of Opps should match');
        System.assertEquals(true, oppById.get(oldOpps[0].Id).isWon, 'The closed Opp should stay won');
        System.assertEquals(true, oppById.get(oldOpps[1].Id).isClosed, 'Open Opp should be closed now');
        System.assertEquals(false, oppById.get(oldOpps[1].Id).isWon, 'Open Opp should be lost won now');
    }

    /**
     * @description Verifies open Opportunities are deleted when RD is closed and
     * Recurring Donation settings Open Opportunity Behaviour is set to delete open Opps
     */
    @IsTest
    private static void shouldDeleteOpenOppsWhenRDIsClosed() {
        String closeAction = RD2_Constants.CloseActions.Delete_Open_Opportunities.name();

        npe03__Recurring_Donation__c rd = setupDataAndCloseRD(closeAction);
        List<Opportunity> oldOpps = rd.npe03__Donations__r;

        List<Opportunity> opps = oppGateway.getRecords(rd);

        System.assertEquals(1, opps.size(), 'The number of Opps should match');
        System.assertEquals(oldOpps[0].Name, opps[0].Name, 'The closed won Opp should not be deleted');
        System.assertEquals(true, opps[0].isWon, 'The closed won Opp should be unchanged');
    }

    /**
     * @description Verifies open Opportunities are unchanged when RD is closed and
     * Recurring Donation settings Open Opportunity Behaviour is set to not change open Opps
     */
    @IsTest
    private static void shouldNotChangeOpenOppsWhenRDIsClosed() {        
        String closeAction = RD2_Constants.CloseActions.No_Action.name();

        npe03__Recurring_Donation__c rd = setupDataAndCloseRD(closeAction);
        List<Opportunity> oldOpps = rd.npe03__Donations__r;

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));

        System.assertEquals(oldOpps.size(), oppById.size(), 'The number of Opps should match');
        System.assertEquals(true, oppById.get(oldOpps[0].Id).isWon, 'Closed Opp should be unchanged');
        System.assertEquals(false, oppById.get(oldOpps[1].Id).isClosed, 'Open Opp should stay open');
    }

    /**
    * @description When Installment Auto Creation Setting is set to Disable First Installment, 
    * the installment should be created on existing RD when the nightly batch job run
    */
    @IsTest
    private static void shouldCreateSecondInstallmentWhenBatchRunWhenAutoCreationIsDisableFirst() {
        setUpRD2AndInstallmentAutoCreation(RD2_Constants.InstallmentCreation.Disable_First_Installment.name());
        
        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();
        insert rd;
        
        Opportunity pastInstallment = new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c)
            .withCloseDate(Date.today().addDays(-10))
            .withClosedLostStage()
            .build();

        insert pastInstallment;

        rd.npe03__Next_Payment_Date__c = Date.today().addDays(10);
        update rd;

        Test.startTest();
        Database.executeBatch(new RD2_OpportunityEvaluation_BATCH());
        Test.stopTest();

        List<Opportunity> installments = oppGateway.getRecords(rd);

        System.assertEquals(2, installments.size(),
            'The next installment should be created when Installment Auto Creation setting is set to Disable First Installment');
    }

    /**
    * @description When Installment Auto Creation Setting is set to Disable All Installments, 
    * no installment should be created on inserted of RD and during nightly batch job
    */
    @IsTest
    private static void shouldNotCreateInstallmentWhenInstallmentAutoCreationIsDiableAll() {
        setUpRD2AndInstallmentAutoCreation(RD2_Constants.InstallmentCreation.Disable_All_Installments.name());

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();

        Test.startTest();
        insert rd;
        Test.stopTest();
        
        List<Opportunity> installments = oppGateway.getRecords(rd);

        System.assertEquals(0, installments.size(),
            'The installment opportunity should not be created when the Auto Creation Setting is set to disalbe all Installments');
    }

    /**
    * @description When Installment Auto Creation Setting is set to Always Create Next Installment, 
    * the installment should be created on inserted of RD and during nightly batch job
    */
    @IsTest
    private static void shouldCreateInstallmentWhenInstallmentAutoCreationIsAlwaysCreate() {
        setUpRD2AndInstallmentAutoCreation(RD2_Constants.InstallmentCreation.Always_Create_Next_Installment.name());

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();

        Test.startTest();
        insert rd;
        Test.stopTest();
        
        List<Opportunity> installments = oppGateway.getRecords(rd);

        System.assertEquals(1, installments.size(),
            'The installment opportunity should be created when the Auto Creation Setting is set to always create installments');
    }

    /**
    * @description When Installment Auto Creation Setting is set to Disabled First Installment, 
    * the installment should not be created if there is no existing opportunity in the system
    */
    @IsTest
    private static void shouldNotCreateInstallmentOnRDInsertWhenInstallmentAutoCreationIsDisableFirst() {
        setUpRD2AndInstallmentAutoCreation(RD2_Constants.InstallmentCreation.Disable_First_Installment.name());

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();

        Test.startTest();
        insert rd;
        Test.stopTest();
        List<Opportunity> installments = oppGateway.getRecords(rd);

        System.assertEquals(0, installments.size(),
            'The installment opportunity should be created when the Auto Creation Setting is set to disalbe first installment');
    }

    @IsTest
    private static void shouldNotCreateInstallmentWhenBatchRunWhenAutoCreationIsDisableAll() {
         setUpRD2AndInstallmentAutoCreation(RD2_Constants.InstallmentCreation.Disable_All_Installments.name());

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact()).build();
        insert rd;

        Test.startTest();
        Database.executeBatch(new RD2_OpportunityEvaluation_BATCH());
        Test.stopTest();
        
        List<Opportunity> installments = oppGateway.getRecords(rd);

        System.assertEquals(0, installments.size(),
            'The installment opportunity should not be created when the Auto Creation Setting is set to disalbe all Installments');
    }

    /**
     * @description Sets up data to test open Installment Opportunity behaviour on RD close
     * @param closeAction Recurring Donation settings Open Opportunity Behaviour close action
     * @return npe03__Recurring_Donation__c Created Recurring Donation with related Opps
     */
    private static npe03__Recurring_Donation__c setupDataAndCloseRD(String closeAction) {
        Map<String, Object> rdSettingFieldMap = new Map<String, Object> {
            'npe03__Open_Opportunity_Behavior__c' => closeAction
        };
        
        setUpConfiguration(rdSettingFieldMap);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();
        insert rd;
        
        TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c);

        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(rd.npe03__Next_Payment_Date__c.addMonths(-1))
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(rd.npe03__Next_Payment_Date__c)
                .withOpenStage()
                .build()
        };
        insert opps;

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 'The number of returned Opps should match');

        opps[0] = oppById.get(opps[0].Id);
        opps[1] = oppById.get(opps[1].Id);

        System.assertEquals(true, opps[0].isClosed, 'The first Opp should be closed');
        System.assertEquals(true, opps[0].isWon, 'The first Opp should be won');
        System.assertEquals(false, opps[1].isClosed, 'The second Opp should be open');

        Test.startTest();
        rd.Status__c = RD2_Constants.STATUS_CLOSED;
        update rd;
        Test.stopTest();

        rd = mockRecurringDonationFullQueryResult(rd, oppById.values(), null);
        return rd;
    }

    /**
     * @description Verifies no exception is thrown when RD is closed and
     * has no Opportunities
     */
    @IsTest
    private static void shouldNotThrowExceptionWhenRDWithoutOppsIsClosed() { 
        Exception actualException;

        Map<String, Object> rdSettingFieldMap = new Map<String, Object> {
            'npe03__Open_Opportunity_Behavior__c' => RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name()
        };
        
        setUpConfiguration(rdSettingFieldMap);

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();
        insert rd;

        Test.startTest();
        rd.Status__c = RD2_Constants.STATUS_CLOSED;
        try {
            update rd;

        } catch (Exception e) {
            actualException = e;
        }
        Test.stopTest();

        System.assertEquals(null, actualException, 'No exception should be thrown when closed RD has no Opps');
    }



    // Helpers
    ///////////////////

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

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder() {
        return getRecurringDonationBuilder(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType));
    }

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @param c Contact
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder(Contact c) {
        return getRecurringDonationBuilder(c.Id);
    }

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @param contactId Contact Id
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(contactId)
            .withAmount(100)            
            .withPaymentMethod('Check')
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withCalculateNextDonationDate();
    }

    /**
     * @description Builds a fully mocked RecurringDonation record with subqueries on Opportunities and Schedules. This is
     * used to support mocked tests against the RD2_EvaluationService without having to insert any records.
     * @param rd Mocked Recurring Donation using TEST_RecurringDonationBuilder
     * @param opps Mocked Related Opportunties (or an empty collection)
     * @param schedules Mockked RecurringDonationSchedule records (can be built using the RD2_ScheduleService)
     * @return RecurringDonation with the Subqueries fully populated.
     */
    private static npe03__Recurring_Donation__c mockRecurringDonationFullQueryResult(npe03__Recurring_Donation__c rd,
            List<Opportunity> opps, List<RecurringDonationSchedule__c> schedules) {

        if (opps == null) {
            opps = new List<Opportunity>();
        }

        if (schedules == null) {
            schedules = new List<RecurringDonationSchedule__c>();
        }

        Contact contact = new Contact(
            Id = rd.npe03__Contact__c,
            AccountId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType),
            LastName = UTIL_UnitTestData_TEST.getUniqueString()
        );

        rd = TEST_RecurringDonationBuilder.addForeignKey(rd, 'npe03__Contact__r', contact);
        rd = TEST_RecurringDonationBuilder.addRelatedList(rd, 'npe03__Donations__r', opps);
        rd = TEST_RecurringDonationBuilder.addRelatedList(rd, UTIL_Namespace.StrTokenNSPrefix('RecurringDonationSchedules__r'), schedules);

        return rd;
    }

    private static void setUpRD2AndInstallmentAutoCreation(String autoCreationSettingString) {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Map<String, Object> rdSettingMap = new Map<String, Object> {
            'InstallmentOppAutoCreateOption__c' => autoCreationSettingString
        };
        setUpConfiguration(rdSettingMap);
    }
    /***
    * @description Generic version of creating Recurring Donations Settings
    * Apply current date override for the Opp service.
    *
    * @param valueByField A map of field name to value
    * @return void
    */
    private static void setUpConfiguration(Map<String, Object> valueByField) {
        //create RD settings
        npe03__Recurring_Donations_Settings__c rdSetting = new npe03__Recurring_Donations_Settings__c(
            npe03__Add_Campaign_to_All_Opportunites__c = true,//default
            IsRecurringDonations2Enabled__c = true,
            npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name()
        );

        for (String field : valueByField.keySet()) {
            rdSetting.put(field, valueByField.get(field));
        }

        UTIL_CustomSettingsFacade.reloadCustomSettingsOnRecordTypeCleanup();
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(rdSetting);
    }

}