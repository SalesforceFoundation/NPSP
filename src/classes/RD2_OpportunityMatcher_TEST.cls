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
	private static final Integer CURRENT_YEAR = TODAY.year();
	private static final ID RD_ID = UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.SObjectType);
    private static final Decimal RD_AMOUNT = 200;

    /**
     * @description 
     */
    @IsTest
    private static void shouldFilterAllOppsWhenCloseDateYearMatchesCurrentDateYear() {
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
			.filterByYear(opps, CURRENT_YEAR)
			.getRecords();

		System.assertEquals(3, records.size(), 'Number of filtered Opportunities should match: ' + records);
        for (RD2_OpportunityMatcher.Record record : records) {
			System.assertEquals(CURRENT_YEAR, record.getOpportunity().CloseDate.year(), 'Opportunity Close Date Year should match');
			System.assertNotEquals(opps[4].Name, record.getOpportunity().Name, 'Opportunity Closed Lost in data migration should be excluded');
		}
    }

    /**
     * @description 
     */
    @IsTest
    private static void shouldFilterOpenOppsWhenCloseDateIsGreaterOrEqualToCurrentDate() {
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
				.withCloseDate(TODAY.addMonths(1))
				.withClosedLostStage()
				.withInstallmentNumberMigrationFlag()
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
			.filterCurrentOpen(opps)
			.getRecords();

		System.assertEquals(2, records.size(), 'Number of filtered Opportunities should match: ' + records);
        for (RD2_OpportunityMatcher.Record record : records) {
			System.assert(record.getOpportunity().CloseDate >= TODAY, 'Opportunity Close Date should be >= TODAY: ' + record);
			System.assertNotEquals(opps[2].Name, record.getOpportunity().Name, 'Opportunity Closed Lost in data migration should be excluded');
		}
    }

    /**
     * @description 
     */
    @IsTest
    private static void shouldFilterAllOppsWhenCloseDateIsGreaterOrEqualToCurrentDate() {
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
			.filterCurrent(opps)
			.getRecords();

		System.assertEquals(3, records.size(), 'Number of filtered Opportunities should match: ' + records);
        for (RD2_OpportunityMatcher.Record record : records) {
			System.assert(record.getOpportunity().CloseDate >= TODAY, 'Opportunity Close Date should be >= TODAY: ' + record);
			System.assertNotEquals(opps[2].Name, record.getOpportunity().Name, 'Opportunity Closed Lost in data migration should be excluded');
		}
    }

    /**
     * @description 
     */
    @IsTest
    private static void shouldMatchCurrentOppWithInstallmentByTheCloseDate() {
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

		Integer numInstallments = 6;
		List<RD2_ScheduleService.Installment> installments = new RD2_ScheduleService().getVisualizedInstallments(
			TODAY, numInstallments, new List<RecurringDonationSchedule__c>{ getSchedule() }
		);

		List<RD2_OpportunityMatcher.Record> records = new RD2_OpportunityMatcher(TODAY)
			.filterCurrent(opps)
			.match(installments)
			.getRecords();

		System.assertEquals(numInstallments, records.size(), 
			'Only current and future matched records should be returned: ' + records);
		for (Integer i = 0; i < numInstallments; i++) {
			Opportunity opp = records[i].getOpportunity();
			RD2_ScheduleService.Installment installment = records[i].getInstallment();

			if (i < 3) {
				System.assertEquals(opps[i + 1].Name, opp.Name, 'The Opp should be assigned to the matched record');
				System.assertEquals(opps[i + 1].CloseDate, installment.nextDonationDate, 'The Opp should match installment with the same Close Date');
			} else {
				System.assertEquals(true, records[i].isNew(), 'The installment should not have matching Opp');
				System.assertEquals(installments[i].nextDonationDate, installment.nextDonationDate, 'The expected installment Close Date should match');
			}
		}
    }

    /**
     * @description 
     */
    @IsTest
    private static void shouldMatchCurrentOppWithInstallmentOrderIfCannotMatchByTheCloseDate() {
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

		Integer numInstallments = 6;
		List<RD2_ScheduleService.Installment> installments = new RD2_ScheduleService().getVisualizedInstallments(
			TODAY, numInstallments, new List<RecurringDonationSchedule__c>{ getSchedule() }
		);

		List<RD2_OpportunityMatcher.Record> records = new RD2_OpportunityMatcher(TODAY)
			.filterCurrent(opps)
			.match(installments)
			.getRecords();

		System.assertEquals(numInstallments, records.size(), 
			'Only current and future matched records should be returned: ' + records);
		for (Integer i = 0; i < numInstallments; i++) {
			Opportunity opp = records[i].getOpportunity();
			RD2_ScheduleService.Installment installment = records[i].getInstallment();

			if (i == 1) {
				System.assertEquals(opps[2].Name, opp.Name, 'The Opp should be assigned to the matched record');
				System.assertEquals(TODAY.addMonths(1).addDays(1), opp.CloseDate, 'The Opp Close Date should be unchanged');
				System.assertEquals(TODAY.addMonths(1), installment.nextDonationDate, 'The installment Close Date should be unchanged');
			} else if (i < 3) {
				System.assertEquals(opps[i + 1].Name, opp.Name, 'The Opp should be assigned to the matched record');
				System.assertEquals(opps[i + 1].CloseDate, installment.nextDonationDate, 'The Opp should match installment with the same Close Date');
			} else {
				System.assertEquals(true, records[i].isNew(), 'The installment should not have matching Opp');
				System.assertEquals(installments[i].nextDonationDate, installment.nextDonationDate, 'The expected installment Close Date should match');
			}
		}
    }



	// Helpers
    ///////////////////
	
    /**
     * @description Instantiate an Opp builder for the specified Recurring Donation
     * @return TEST_OpportunityBuilder New Opp builder
     */
    private static TEST_OpportunityBuilder getOpportunityBuilder() {
        return new TEST_OpportunityBuilder()
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
