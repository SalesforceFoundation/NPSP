/*
    Copyright (c) 2020 Salesforce.org
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
* @description Unit tests for the Recurring Donation matcher applied to existing Opportunities and future installments
*
*/
@IsTest(IsParallel=true)
private class RD2_OpportunityMatcher_TEST {

    private static final Date TODAY = Date.newInstance(2019, 9, 21);
    private static final ID RD_ID = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.SObjectType);
    private static final Decimal RD_AMOUNT = 200;

    /**
     * @description Verifies Open/Closed Lost/Closed Won Opps are returned
     * when their Close Date year matches specified year.
     * Opportunities Closed Lost in data migration are not returned.
     */
    @IsTest
    private static void shouldIncludeAllOppsWhenCloseDateYearMatchesCurrentYear() {
        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder();
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addYears(-1))
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(-2))//match
                .withClosedLostStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(-1))//match
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY)//match
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))
                .withClosedLostStage()
                .withInstallmentNumberMigrationFlag()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addYears(1))
                .withOpenStage()
                .withInstallmentNumber(1)
                .build()
        };
        TEST_OpportunityBuilder.setUneditableFields(opps);

        List<RD2_OpportunityMatcher.Record> records = new RD2_OpportunityMatcher(TODAY)
            .includeByYear(opps, Date.newInstance(2019, 1, 1), Date.newInstance(2019, 12, 31))
            .getRecords();

        System.assertEquals(3, records.size(), 'Number of included Opportunities should match: ' + records);
        for (RD2_OpportunityMatcher.Record record : records) {
            System.assertEquals(2019, record.getOpportunity().CloseDate.year(), 'Opportunity Close Date Year should match');
            System.assertNotEquals(opps[4].Name, record.getOpportunity().Name, 'Opportunity Closed Lost in data migration should be excluded');
        }
    }

    /**
     * @description Verifies Open/Closed Lost/Closed Won Opps are returned
     * when their Close Date is greater or equal to the current date (today).
     * Opportunities Closed Lost in data migration are not returned.
     */
    @IsTest
    private static void shouldIncludeAllOppsWhenCloseDateIsGreaterOrEqualToCurrentDate() {
        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder();
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(-1))
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY)//match
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))
                .withClosedLostStage()
                .withInstallmentNumberMigrationFlag()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))//match
                .withClosedLostStage()
                .withInstallmentNumber(1)
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(2))//match
                .withOpenStage()
                .withInstallmentNumber(1)
                .build()
        };
        TEST_OpportunityBuilder.setUneditableFields(opps);

        List<RD2_OpportunityMatcher.Record> records = new RD2_OpportunityMatcher(TODAY)
            .includeCurrent(opps)
            .getRecords();

        System.assertEquals(3, records.size(), 'Number of included Opportunities should match: ' + records);

        for (RD2_OpportunityMatcher.Record record : records) {
            System.assert(record.getOpportunity().CloseDate >= TODAY, 'Opportunity Close Date should be >= TODAY: ' + record);
            System.assertNotEquals(opps[2].Name, record.getOpportunity().Name, 'Opportunity Closed Lost in data migration should be excluded');
        }
    }

    /**
     * @description Verifies matching of Opportunities and projected installments
     * is applied by matching Close Date.
     */
    @IsTest
    private static void shouldMatchCurrentOppWithInstallmentWhenMatchingCloseDateExactly() {
        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder();
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(-1))
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY)//match
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))//match
                .withClosedLostStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(2))//match
                .withOpenStage()
                .build()
        };
        TEST_OpportunityBuilder.setUneditableFields(opps);

        Integer firstMatchedOppIndex = 1;
        Integer numInstallments = 6;
        List<RD2_ScheduleService.Installment> installments = new RD2_ScheduleService().getVisualizedInstallments(
            TODAY, numInstallments, new List<RecurringDonationSchedule__c>{ getSchedule() }
        );

        List<RD2_OpportunityMatcher.Record> records = new RD2_OpportunityMatcher(TODAY)
            .includeCurrent(opps)
            .match(installments)
            .getRecords();

        System.assertEquals(numInstallments, records.size(),
            'Only current and future records should be returned: ' + records);

        for (Integer i = 0; i < numInstallments; i++) {
            Opportunity opp = records[i].getOpportunity();
            RD2_ScheduleService.Installment installment = records[i].getInstallment();

            if (i < 3) {
                System.assertEquals(opps[firstMatchedOppIndex + i].Name, opp.Name, 'The Opp should be assigned to the record');
                System.assertEquals(opps[firstMatchedOppIndex + i].CloseDate, installment.nextDonationDate, 'The Opp should match installment with the same Close Date');
            } else {
                System.assertEquals(true, records[i].isNew(), 'The installment should not have matching Opp');
                System.assertEquals(installments[i].nextDonationDate, installment.nextDonationDate, 'The expected installment Close Date should match');
            }
        }
    }

    /**
     * @description Verifies matching of Opportunities and projected installments
     * is done by matching the existing Opp with Close Date within +/- match day range
     * of the installment Close Date.
     */
    @IsTest
    private static void shouldMatchCurrentOppWithMonthlyInstallmentWhenCloseDateIsWithinMatchRange() {
        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder();
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(-1))
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addDays(-1))//match
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1).addDays(1))//match
                .withClosedLostStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(2))//match
                .withOpenStage()
                .build()
        };
        TEST_OpportunityBuilder.setUneditableFields(opps);

        Integer firstMatchedOppIndex = 1;
        Integer numInstallments = 6;
        List<RD2_ScheduleService.Installment> installments = new RD2_ScheduleService().getVisualizedInstallments(
            TODAY, numInstallments, new List<RecurringDonationSchedule__c>{ getSchedule() }
        );

        List<RD2_OpportunityMatcher.Record> records = new RD2_OpportunityMatcher(TODAY)
            .includeCurrent(opps)
            .match(installments)
            .getRecords();

        System.assertEquals(numInstallments, records.size(),
            'The current matched Opps and future unmatched installments should be returned: ' + records);

        System.assertEquals(opps[firstMatchedOppIndex].CloseDate, records[0].getOpportunity().CloseDate, 'The first Opp should be the first record');
        System.assertEquals(TODAY, records[0].getInstallment().nextDonationDate, 'The first Opp should be matched with the first installment');

        System.assertEquals(opps[firstMatchedOppIndex + 1].CloseDate, records[1].getOpportunity().CloseDate, 'The second Opp should be the second record');
        System.assertEquals(TODAY.addMonths(1), records[1].getInstallment().nextDonationDate, 'The second Opp should be matched with the second installment');

        System.assertEquals(opps[firstMatchedOppIndex + 2].CloseDate, records[2].getOpportunity().CloseDate, 'The third Opp should be the third record');
        System.assertEquals(opps[firstMatchedOppIndex + 2].CloseDate, records[2].getInstallment().nextDonationDate, 'The third Opp should be matched with the third installment');

        for (Integer i = 3; i < numInstallments; i++) {
            System.assertEquals(true, records[i].isNew(), 'The installment should not have a matching Opp');
            System.assertEquals(installments[i].nextDonationDate, records[i].getInstallment().nextDonationDate,
                'The expected installment Next Donation Date should match');
        }
    }

    @IsTest
    private static void shouldMatchCurrentOppWithYearlyInstallmentWhenCloseDateIsWithinMatchRange() {
        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder();
        List<Opportunity> opps = new List<Opportunity>{
                oppBuilder
                        .withName()
                        .withCloseDate(TODAY.addYears(-1))
                        .withOpenStage()
                        .build(),
                oppBuilder
                        .withName()
                        .withCloseDate(TODAY.addDays(-1))//match
                        .withOpenStage()
                        .build(),
                oppBuilder
                        .withName()
                        .withCloseDate(TODAY.addYears(1).addDays(1))//match
                        .withClosedLostStage()
                        .build(),
                oppBuilder
                        .withName()
                        .withCloseDate(TODAY.addYears(2))//match
                        .withOpenStage()
                        .build()
        };
        TEST_OpportunityBuilder.setUneditableFields(opps);

        Integer firstMatchedOppIndex = 1;
        Integer numInstallments = 6;
        RecurringDonationSchedule__c recurringDonationSchedule = getSchedule();
        recurringDonationSchedule.InstallmentPeriod__c = RD2_Constants.INSTALLMENT_PERIOD_YEARLY;
        recurringDonationSchedule.StartDate__c = TODAY;

        List<RD2_ScheduleService.Installment> installments = new RD2_ScheduleService().getVisualizedInstallments(
                TODAY, numInstallments, new List<RecurringDonationSchedule__c>{ recurringDonationSchedule }
        );

        List<RD2_OpportunityMatcher.Record> records = new RD2_OpportunityMatcher(TODAY)
                .includeCurrent(opps)
                .match(installments)
                .getRecords();

        System.assertEquals(numInstallments, records.size(),
                'The current matched Opps and future unmatched installments should be returned: ' + records.size());

        System.assertEquals(opps[firstMatchedOppIndex].Id, records[0].getOpportunity().Id, 'The first opportunity ' +
                'record id should match the first matched installment opportunity record id');

        System.assertEquals(TODAY, records[0].getInstallment().nextDonationDate, 'The first Opp should be matched with the first installment');

        System.assertEquals(opps[firstMatchedOppIndex + 1].Id, records[1].getOpportunity().Id, 'The second Opp' +
                ' should be the second record');
        System.assertEquals(TODAY.addYears(1), records[1].getInstallment().nextDonationDate, 'The second Opp should be ' +
                'matched with the second installment');

        System.assertEquals(opps[firstMatchedOppIndex + 2].Id, records[2].getOpportunity().Id, 'The third Opp ' +
                'should be the third record');
        System.assertEquals(opps[firstMatchedOppIndex + 2].CloseDate, records[2].getInstallment().nextDonationDate, 'The third Opp should be matched with the third installment');

        for (Integer i = 3; i < numInstallments; i++) {
            System.assertEquals(true, records[i].isNew(), 'The installment should not have a matching Opp');
            System.assertEquals(installments[i].nextDonationDate, records[i].getInstallment().nextDonationDate,
                    'The expected installment Next Donation Date should match');
        }
    }

    /**
     * @description Verifies a projected installment is not matched with an extra Opp 
     * having Close Date outside Next Donation Date +/- match day range
     */
    @IsTest
    private static void shouldNotMatchExtraOppWithInstallmentWhenCloseDateIsOutsideMatchRange() {
        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder();
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(TODAY)//match
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1).addDays(1))//match
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1).addDays(4))//extra Opp: no match with any installment
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(2))//match
                .withOpenStage()
                .build()
        };
        TEST_OpportunityBuilder.setUneditableFields(opps);
        
        testAndAssertExtraOppIsNotMatched(opps);
    }

    /**
     * @description Verifies a projected installment is matching only one Opp
     * when more than one Opp is matching the Next Donation Date +/- match day range
     */
    @IsTest
    private static void shouldMatchOneOppOnlyWithInstallmentWhenMoreThanOneOppWithinMatchRange() {
        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder();
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(TODAY)//match
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1).addDays(1))//match
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1).addDays(2))//extra Opp: no match with any installment
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(2))//match
                .withOpenStage()
                .build()
        };
        TEST_OpportunityBuilder.setUneditableFields(opps);

        testAndAssertExtraOppIsNotMatched(opps);
    }

    /**
     * @description Verifies an extra Opp is not matched with an installment
     */
    private static void testAndAssertExtraOppIsNotMatched(List<Opportunity> opps) {
        Integer numInstallments = 6;
        List<RD2_ScheduleService.Installment> installments = new RD2_ScheduleService().getVisualizedInstallments(
            TODAY, numInstallments, new List<RecurringDonationSchedule__c>{ getSchedule() }
        );

        List<RD2_OpportunityMatcher.Record> records = new RD2_OpportunityMatcher(TODAY)
            .includeCurrent(opps)
            .match(installments)
            .getRecords();

        System.assertEquals(numInstallments + 1, records.size(),
            'The current matched Opps and future unmatched installments should be returned: ' + records);

        System.assertEquals(opps[0].CloseDate, records[0].getOpportunity().CloseDate, 'The first Opp should be the first record');
        System.assertEquals(opps[0].CloseDate, records[0].getInstallment().nextDonationDate, 'The first Opp should be matched with the first installment');

        System.assertEquals(opps[1].CloseDate, records[1].getOpportunity().CloseDate, 'The second Opp should be the second record');
        System.assertEquals(TODAY.addMonths(1), records[1].getInstallment().nextDonationDate, 'The second Opp should be matched with the second installment');

        System.assertEquals(opps[2].CloseDate, records[2].getOpportunity().CloseDate, 'The third Opp should be the third record');
        System.assertEquals(null, records[2].getInstallment(), 'The third Opp should not be matched with any installment');

        System.assertEquals(opps[3].CloseDate, records[3].getOpportunity().CloseDate, 'The fourth Opp should be the fourth record');
        System.assertEquals(opps[3].CloseDate, records[3].getInstallment().nextDonationDate, 'The fourth Opp should be matched with the third installment');

        for (Integer i = 4; i < numInstallments + 1; i++) {
            System.assertEquals(true, records[i].isNew(), 'The installment should not have a matching Opp');
            System.assertEquals(installments[i - 1].nextDonationDate, records[i].getInstallment().nextDonationDate, 
                'The installment Next Donation Date should match');
        }
    }

    /**
     * @description Verifies an Open Opportunity with a Close Date < current date
     * is not matched with a projected installment
     */
    @IsTest
    private static void shouldNotMatchPastOpenOppWithAnInstallment() {
        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder();
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(-1))//not a match
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY)//match w installment
                .withOpenStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(1))//match w installment
                .withClosedLostStage()
                .build(),
            oppBuilder
                .withName()
                .withCloseDate(TODAY.addMonths(2))//match w installment
                .withOpenStage()
                .build()
        };
        TEST_OpportunityBuilder.setUneditableFields(opps);

        Integer pastOpenOppIndex = 0;
        Integer firstMatchedOppIndex = 1;
        Integer numInstallments = 6;
        List<RD2_ScheduleService.Installment> installments = new RD2_ScheduleService().getVisualizedInstallments(
            TODAY, numInstallments, new List<RecurringDonationSchedule__c>{ getSchedule() }
        );

        List<RD2_OpportunityMatcher.Record> records = new RD2_OpportunityMatcher(TODAY)
            .includeCurrentOrOpen(opps)
            .match(installments)
            .getRecords();

        System.assertEquals(numInstallments + 1, records.size(),
            'The past open Opp, current matched Opps and future unmatched installments should be returned: ' + records);
        
        System.assertEquals(opps[pastOpenOppIndex].CloseDate, records[0].getOpportunity().CloseDate, 'The past open Opp should be the first record');
        System.assertEquals(null, records[0].getInstallment(), 'The past open Opp should not be matched with an installment');

        for (Integer i = firstMatchedOppIndex, installment = 1; i <= firstMatchedOppIndex + 2; i++) {
            System.assertEquals(opps[i].CloseDate, records[installment++].getInstallment().nextDonationDate, 'The Opp should be matched with the installment');
        }

        System.assertEquals(true, records[4].isNew(), 'The installment should not have a matching Opp');
        System.assertEquals(installments[3].nextDonationDate, records[4].getInstallment().nextDonationDate, 'The expected installment Close Date should match');
    }



    // Helpers
    ///////////////////

    /**
     * @description Instantiate an Opp builder for the specified Recurring Donation
     * @return TEST_OpportunityBuilder New Opp builder
     */
    private static TEST_OpportunityBuilder getOpportunityBuilder() {
        return new TEST_OpportunityBuilder()
            .withMockId()
            .withContact(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType))
            .withRecurringDonation(RD_ID)
            .withAmount(RD_AMOUNT)
            .withInstallmentNumber(1);
    }

    /**
     * @description Returns mock of Recurring Donation Schedule
     * @return RecurringDonationSchedule__c
     */
    private static RecurringDonationSchedule__c getSchedule() {
        return new RecurringDonationSchedule__c(
            RecurringDonation__c = RD_ID,
            InstallmentAmount__c = RD_AMOUNT,
            InstallmentFrequency__c = 1,
            InstallmentPeriod__c = RD2_Constants.INSTALLMENT_PERIOD_MONTHLY,
            StartDate__c = TODAY.addMonths(-2),
            DayOfMonth__c = String.valueOf(TODAY.day())
        );
    }
}