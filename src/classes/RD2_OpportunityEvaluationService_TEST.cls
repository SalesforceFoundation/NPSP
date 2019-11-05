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
            .withPaymentMethod('Check')
            .withInstallmentPeriodMonthly()
            .withInstallmentFrequency(1)
            .withDayOfMonth('20')
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withStartDate(Date.newInstance(2019, 9, 15))
            .withCalculateNextDonationDate()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        Opportunity opp = [SELECT Id, Amount, AccountId, Primary_Contact__c, StageName, CloseDate
            FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id];

        System.assertEquals(rd.npe03__Amount__c, opp.Amount, 'The Opportunity Amount does not match the RD Amount');
        System.assertEquals(rd.npe03__Contact__c, opp.Primary_Contact__c, 'The Opportunity Contact does not match the RD Contact');
        System.assertEquals(rd.npe03__Next_Payment_Date__c, opp.CloseDate, 'The Opportunity CloseDate does not match the RD NextDonationDate');
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
            .withPaymentMethod('Check')
            .withInstallmentPeriodMonthly()
            .withInstallmentFrequency(1)
            .withDayOfMonth('20')
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withStartDate(Date.newInstance(2019, 9, 15))
            .withCalculateNextDonationDate()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);

        List<Opportunity> opps = [SELECT Id, Amount, AccountId, Primary_Contact__c, StageName, CloseDate
            FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id];
        System.assertEquals(0, opps.size(), 'There should not have been any Installment Opps created for this RD');
    }

    /**
     * @description Verify that the Recurring Donations are eligible to have an installment opportunity created
     */
    @IsTest
    private static void shouldBeEligibleForNewInstallmentOpp() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();

        npe03__Recurring_Donation__c rd1 = getRecurringDonationBuilder()
            .withPaymentMethod('Check')
            .withInstallmentPeriodMonthly()
            .withInstallmentFrequency(1)
            .withDayOfMonth('20')
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withStartDate(Date.newInstance(2019, 9, 15))
            .withCalculateNextDonationDate()
            .build();
        rd1 = mockRecurringDonationFullQueryResult(rd1, new List<Opportunity>(), scheduleService.getNewSchedules(rd1));

        npe03__Recurring_Donation__c rd2 = getRecurringDonationBuilder()
            .withPaymentMethod('Check')
            .withInstallmentPeriodWeekly()
            .withInstallmentFrequency(3)
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withStartDate(Date.newInstance(2019, 9, 15))
            .withCalculateNextDonationDate()
            .build();
        rd2 = mockRecurringDonationFullQueryResult(rd2, new List<Opportunity>(), scheduleService.getNewSchedules(rd2));

        npe03__Recurring_Donation__c rd3 = getRecurringDonationBuilder()
            .withPaymentMethod('Check')
            .withInstallmentPeriodYearly()
            .withInstallmentFrequency(1)
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withStartDate(Date.newInstance(2019, 6, 1))
            .withCalculateNextDonationDate()
            .build();
        rd3 = mockRecurringDonationFullQueryResult(rd3, new List<Opportunity>(), scheduleService.getNewSchedules(rd3));

        RD2_OpportunityEvaluationService oppEvalSvc = new RD2_OpportunityEvaluationService();
        oppEvalSvc.rds = new List<npe03__Recurring_Donation__c>{ rd1, rd2, rd3 };

        System.assertEquals(true, oppEvalSvc.isCandidate(rd1), 'RD1 should be eligible for an Installment Opp');
        System.assertEquals(true, oppEvalSvc.isCandidate(rd2), 'RD2 should be eligible for an Installment Opp');
        System.assertEquals(true, oppEvalSvc.isCandidate(rd3), 'RD3 should be eligible for an Installment Opp');
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
            .withPaymentMethod('Check')
            .withInstallmentPeriodMonthly()
            .withInstallmentFrequency(1)
            .withDayOfMonth('20')
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withStartDate(Date.newInstance(2019, 9, 15))
            .withCalculateNextDonationDate()
            .build();
        rd1 = mockRecurringDonationFullQueryResult(rd1, new List<Opportunity>(), scheduleService.getNewSchedules(rd1));

        // Recurring Donation with no Schedule records
        npe03__Recurring_Donation__c rd2 = getRecurringDonationBuilder()
            .withPaymentMethod('Check')
            .withInstallmentPeriodWeekly()
            .withInstallmentFrequency(3)
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withStartDate(Date.newInstance(2019, 9, 15))
            .withCalculateNextDonationDate()
            .build();
        rd2 = mockRecurringDonationFullQueryResult(rd2, new List<Opportunity>(), new List<RecurringDonationSchedule__c>());

        // Recurring Donation with an empty NextDonationDate
        npe03__Recurring_Donation__c rd3 = getRecurringDonationBuilder()
            .withPaymentMethod('Check')
            .withInstallmentPeriodYearly()
            .withInstallmentFrequency(1)
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withStartDate(Date.newInstance(2019, 6, 1))
            .withCalculateNextDonationDate()
            .build();
        rd3.npe03__Next_Payment_Date__c = null;
        rd3 = mockRecurringDonationFullQueryResult(rd3, new List<Opportunity>(), scheduleService.getNewSchedules(rd3));

        RD2_OpportunityEvaluationService oppEvalSvc = new RD2_OpportunityEvaluationService();
        oppEvalSvc.rds = new List<npe03__Recurring_Donation__c>{ rd1, rd2, rd3 };

        System.assertEquals(false, oppEvalSvc.isCandidate(rd1), 'Closed RD1 should not be eligible for an Installment Opp');
        System.assertEquals(false, oppEvalSvc.isCandidate(rd2), 'RD2 with no Schedules should not be eligible for an Installment Opp');
        System.assertEquals(false, oppEvalSvc.isCandidate(rd3), 'RD3 without a NextDonationDate should not be eligible for an Installment Opp');
    }

    /**
     * @description Verify that the Recurring Donations are recognized as "New" if there are no related Opps
     * or "Not New" if there are related Opps.
     */
    @IsTest
    private static void shouldDetermineIfNewOrPreExistingRecurringDonation() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();

        // New Opportunity - Is New RD
        npe03__Recurring_Donation__c rdNew = getRecurringDonationBuilder()
            .withPaymentMethod('Check')
            .withInstallmentPeriodMonthly()
            .withInstallmentFrequency(1)
            .withDayOfMonth('20')
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withStartDate(Date.newInstance(2019, 9, 15))
            .withCalculateNextDonationDate()
            .build();
        rdNew = mockRecurringDonationFullQueryResult(rdNew, new List<Opportunity>(), scheduleService.getNewSchedules(rdNew));

        // Old Opportunity (has related Opps) - Not New RD
        npe03__Recurring_Donation__c rdOld = getRecurringDonationBuilder()
            .withPaymentMethod('Check')
            .withInstallmentPeriodWeekly()
            .withInstallmentFrequency(3)
            .withDateEstablished(Date.newInstance(2019, 9, 15))
            .withStartDate(Date.newInstance(2019, 9, 15))
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

        RD2_OpportunityEvaluationService oppEvalSvc = new RD2_OpportunityEvaluationService();
        oppEvalSvc.rds = new List<npe03__Recurring_Donation__c>{ rdNew, rdOld };

        System.assertEquals(true, oppEvalSvc.isNewRecurringDonation(rdNew), 'RD1 should be a New Recurring Donation');
        System.assertEquals(false, oppEvalSvc.isNewRecurringDonation(rdOld), 'RD2 should not be a new Recurring Donation');
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
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
            .withCalculateNextDonationDate()
            .withAmount(100);
    }

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder(Contact c) {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(c.Id)
            .withCalculateNextDonationDate()
            .withAmount(100);
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

}