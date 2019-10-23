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
* @description Unit Test for the data migration batch job
*
*/
@IsTest
private class RD2_DataMigration_TEST {

    /**
     * @description Verifies that the job should run with zero records processed when
     * RD2 is not enabled
     */
    @IsTest
    private static void shouldLaunchBatchJobWithNothingProcessed() {
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;

        npe03__Recurring_Donation__c rd = getNewRecurringDonationRD1Format(contact.Id);
        rd.Id = null;
        insert rd;

        Exception jobException;
        try {
            Test.startTest();
            RD2_DataMigration_BATCH batchJob = new RD2_DataMigration_BATCH();
            Database.executeBatch(batchJob);
            Test.stopTest();
        } catch (Exception ex) {
            jobException = ex;
        }

        System.assert(jobException != null, 'The batch job did not throw an exception');
        System.assert(jobException.getMessage().containsIgnoreCase(System.Label.RD2_ErrorDataMigrationJobCannotBeRun),
            'The exception message did not contain the expected text');
    }

    /**
     * @description Verifies that the batch job ran with one record processed when
     * RD2 is enabled
     */
    @IsTest
    private static void shouldLaunchBatchJobWithOneRecordProcessed() {
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;

        npe03__Recurring_Donation__c rd = getNewRecurringDonationRD1Format(contact.Id);
        rd.Id = null;
        insert rd;

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_EnablementService_TEST.configureRecurringDonations2Enabled();

        Test.startTest();
        RD2_DataMigration_BATCH batchJob = new RD2_DataMigration_BATCH();
        Database.executeBatch(batchJob);
        Test.stopTest();

        AsyncApexJob job = [SELECT Id, JobItemsProcessed FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'RD2_DataMigration_BATCH'
            LIMIT 1];
        System.assertEquals(1, job.JobItemsProcessed,
            'One batches should have run with one child batches processed'
        );
    }

    /**
     * @description Verifies that an RD1 format RD is recognized correctly
     */
    @IsTest
    private static void shouldRecognizeAsRd1Format() {
        Id contactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        Id acctId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType);
        npe03__Recurring_Donation__c rd = getNewRecurringDonationRD1Format(contactId);
        Opportunity opp = getOpportunityForRd(acctId, rd.Id);
        List<Opportunity> mockedRelatedOpps = new List<Opportunity>{ opp };

        RD2_DataMigration migrationService = new RD2_DataMigration()
            .withRecurringDonation(rd)
            .withRelatedOpportunities(mockedRelatedOpps);

        System.assertEquals(false, migrationService.hasAlreadyBeenConverted(),
            'This RD should not be in RD2 format');
    }

    /**
     * @description Verifies that an RD2 format RD is recognized correctly
     */
    @IsTest
    private static void shouldRecognizeAsRd2Format() {
        Id contactId = UTIL_UnitTestData_TEST.mockId(Contact.SObjectType);
        Id acctId = UTIL_UnitTestData_TEST.mockId(Account.SObjectType);
        npe03__Recurring_Donation__c rd = getNewRecurringDonationRD2Format(contactId);
        Opportunity opp = getOpportunityForRd(acctId, rd.Id);
        List<Opportunity> mockedRelatedOpps = new List<Opportunity>{ opp };

        RD2_DataMigration migrationService = new RD2_DataMigration()
            .withRecurringDonation(rd)
            .withRelatedOpportunities(mockedRelatedOpps);

        System.assertEquals(true, migrationService.hasAlreadyBeenConverted(),
            'This RD should be in RD2 format');
    }

    // HELPER METHODS

    /**
     * @description Instantiate an RD1 format recurring donation for a specific ContactId
     * @param contactId
     * @return Instantiated RD
     */
    private static npe03__Recurring_Donation__c getNewRecurringDonationRD1Format(Id contactId) {
        TEST_RecurringDonationBuilder rdBuilder = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withMockId()
            .withDefaultValues()
            .withOpenEndedStatusOpen()
            .withContact(contactId)
            .withAmount(100)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1');

        return rdBuilder.build();
    }

    /**
     * @description Instantiate an RD2 format recurring donation for a specific ContactId
     * @param contactId
     * @return Instantiated RD
     */
    private static npe03__Recurring_Donation__c getNewRecurringDonationRD2Format(Id contactId) {
        TEST_RecurringDonationBuilder rdBuilder = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withMockId()
            .withDefaultValues()
            .withContact(contactId)
            .withAmount(100)
            .withInstallmentPeriodMonthly()
            .withDayOfMonth('1');

        return rdBuilder.build();
    }

    /**
     * @description Instantiate an Opportunity specific AccountId and Rd Id
     * @param acctId AccountId
     * @param rdId RecurringDonationId
     * @return Instantiated Opportunity
     */
    private static Opportunity getOpportunityForRd(Id acctId, Id rdId) {
        TEST_OpportunityBuilder oppBuilder = new TEST_OpportunityBuilder()
            .withMockId()
            .withRecurringDonation(rdId)
            .withAmount(100)
            .withAccount(acctId)
            .withClosedWonStage();

        return oppBuilder.build();
    }
}