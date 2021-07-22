/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2015
* @group Opportunity
* @group-content
* @description Unit Tests for the Opportunity Naming batch job
*/

@isTest
private with sharing class OPP_OpportunityNaming_BATCH_TEST {
    private static final Integer NUM_OPPS = 10;
    private static final String CLOSED_WON_STAGE = UTIL_UnitTestData_TEST.getClosedWonStage();

    @TestSetup
    static void setup() {
        List<Opportunity> testOpps = createOpportunities(NUM_OPPS);
        createOpportunityNamingSetting();
    }

    /**
     * @description Confirms that Opportunities are renamed in chained batch chunks
     */
    @isTest
    private static void shouldRenameOpportunitiesInChunks() {
        OPP_OpportunityNaming_BATCH batch = new OPP_OpportunityNaming_BATCH();

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        // Record count for test is small enough for only one execution
        // LDV Chunking etc. tested for base class
        List<AsyncApexJob> jobsApexBatch = queryOppNamingBatchJobs();
        System.assertEquals(1, jobsApexBatch.size(), 'Batch should run for each chunk of opportunities');

        for (Opportunity opp : [SELECT Name FROM Opportunity]) {
            System.assertEquals(false, opp.Name.startsWith('Test Opp'),
                'The opportunity should have been renamed: ' + opp.Name);
        }
    }

    /**
     * @description Coverage of Schedulable Method
     */
    @isTest
    private static void testSchedulable() {
        OPP_OpportunityNaming_BATCH batch = new OPP_OpportunityNaming_BATCH();

        Test.startTest();

        String CRON_EXP = '0 0 23 * * ?';
        String jobId = System.schedule('Test Sched', CRON_EXP, batch);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP, ct.CronExpression);
        System.assertEquals(0, ct.TimesTriggered);

        Test.stopTest();
    }

    /**
     * @description Creates a given number of test opportunities
     */
    private static List<Opportunity> createOpportunities(Integer numOpps) {
        List<Account> testAccounts = UTIL_UnitTestData_TEST.createMultipleTestAccounts (1, null);
        insert testAccounts;
        List<Opportunity> opps = new List<Opportunity>();


        for (Integer i = 0; i < numOpps; i++) {
            opps.add(
                new Opportunity(
                    AccountId = testAccounts[0].Id,
                    Name = 'Test Opp ' + i,
                    StageName = CLOSED_WON_STAGE,
                    CloseDate = Date.today()
                )
            );
        }
        insert opps;
        return opps;
    }

    /**
     * @description Creates a Opportunity_Naming_Settings__c record
     */
    private static void createOpportunityNamingSetting() {
        Opportunity_Naming_Settings__c oppNamingSettings = new Opportunity_Naming_Settings__c(
            Name = 'foo',
            Opportunity_Name_Format__c = '{!Account.Id} {!CloseDate}',
            Attribution__c = Label.oppNamingBoth
        );
        insert oppNamingSettings;
    }

    /**
     * @description Retrieves OPP_OpportunityNaming_BATCH batch jobs
     */
    private static List<AsyncApexJob> queryOppNamingBatchJobs() {
        return [
            SELECT Id FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'OPP_OpportunityNaming_BATCH'
        ];
    }
}