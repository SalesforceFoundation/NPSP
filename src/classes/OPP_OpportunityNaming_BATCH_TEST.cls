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
* @date 2019
* @group Opportunity
* @group-content
* @description Unit Tests for the Opportunity Naming batch job
*/

@isTest
private with sharing class OPP_OpportunityNaming_BATCH_TEST {
    private static final Integer NUM_OPPS = 10;

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
        OPP_OpportunityNaming_BATCH.defaultQueryLimit = NUM_OPPS - 1;
        OPP_OpportunityNaming_BATCH batch = new OPP_OpportunityNaming_BATCH();

        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();

        List<AsyncApexJob> jobsApexBatch = queryOppNamingBatchJobs();
        System.assertEquals(2, jobsApexBatch.size(), 'Batch should run for each chunk of opportunities');

        for (Opportunity opp : [SELECT Name FROM Opportunity]) {
            System.assertEquals(false, opp.Name.startsWith('Test Opp'),
                'The opportunity should have been renamed: ' + opp.Name);
        }
    }

    /**
     * @description Confirms that batch query locator retrieves Opportunitie in order of Id
     */
    @isTest
    private static void shouldQueryAllOpportunitiesInIdOrder() {
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity ORDER BY Id];

        OPP_OpportunityNaming_BATCH batch = new OPP_OpportunityNaming_BATCH(testOpps[0].Id);

        String query = batch.start(null).getQuery();
        List<Opportunity> queriedOpps = Database.query(query);
        System.assertEquals(NUM_OPPS - 1, queriedOpps.size(), 'Only the offset opportunities should have been returned');

        testOpps.remove(0);
        for (Integer i = 0; i < NUM_OPPS - 1; i++) {
            System.assertEquals(testOpps[i].Id, queriedOpps[i].Id,
                'The opportunities should have been queried in order of Id');
        }
    }

    /**
     * @description Confirms that batch query locator uses an Id offset when constructed with an Id parameter
     */
    @isTest
    private static void shouldQueryOffsetOpportunitiesWhenGivenId() {
        OPP_OpportunityNaming_BATCH batch = new OPP_OpportunityNaming_BATCH();
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity ORDER BY Id];

        String query = batch.start(null).getQuery();
        List<Opportunity> queriedOpps = Database.query(query);
        System.assertEquals(NUM_OPPS, queriedOpps.size(), 'All of the opportunities should have been returned');

        for (Integer i = 0; i < NUM_OPPS; i++) {
            System.assertEquals(testOpps[i].Id, queriedOpps[i].Id,
                'The opportunities should have been queried in order of Id');
        }
    }

    /**
     * @description Confirms that batch query locator is limited
     */
    @isTest
    private static void shouldLimitQuery() {
        OPP_OpportunityNaming_BATCH batch = new OPP_OpportunityNaming_BATCH();
        String query = batch.start(null).getQuery();
        System.assert(query.endsWith('LIMIT 10000000'), 'The query should have the correct limit');
    }

    /**
     * @description Confirms that the execute method tracks the Id of the last Opportunity processed
     */
    @isTest
    private static void shouldTrackLastOpportunityIdProcessed() {
        List<Opportunity> testOpps = [SELECT Id, Name FROM Opportunity ORDER BY Id];

        OPP_OpportunityNaming_BATCH batch = new OPP_OpportunityNaming_BATCH();

        Test.startTest();
        batch.execute(null,testOpps);
        Test.stopTest();

        Id expectedId = testOpps[NUM_OPPS - 1].Id;
        System.assertEquals(expectedId, batch.lastOppIdProcessed,
            'The execute method should track the Id of the last opportunity processed');
    }

    /**
     * @description Confirms that the finish method chains the next batch with an offset
     * of the last Opportunity Id processed
     */
    @isTest
    private static void shouldChainNextBatchOffsetByLastRecordProcessed() {
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity ORDER BY Id];

        OPP_OpportunityNaming_BATCH batch = new OPP_OpportunityNaming_BATCH();
        batch.lastOppIdProcessed = testOpps[0].Id;

        Test.startTest();
        batch.finish(null);
        Test.stopTest();

        List<AsyncApexJob> jobsApexBatch = queryOppNamingBatchJobs();
        System.assertEquals(1, jobsApexBatch.size(), 'The naming batch should be started again');

        Opportunity offsetOpportunity = [SELECT Name FROM Opportunity WHERE Id = :testOpps[0].Id];
        System.assert(offsetOpportunity.Name.startsWith('Test Opp'),
            'The offset opportunity should not have been processed in the chained batch');

        for (Opportunity opp : [SELECT Name FROM Opportunity WHERE Id != :testOpps[0].Id]) {
            System.assertEquals(false, opp.Name.startsWith('Test Opp'),
                'The remaining opportunities should have been renamed: ' + opp.Name);
        }
    }

    /**
     * @description Confirms that the finish method does not chain the next batch
     * if it fails to capture the last Opportunity Id processed
     */
    @isTest
    private static void shouldNotChainNextBatchIfLastOppIdProcessedIsNull() {
        OPP_OpportunityNaming_BATCH batch = new OPP_OpportunityNaming_BATCH();

        Test.startTest();
        batch.finish(null);
        Test.stopTest();

        List<AsyncApexJob> jobsApexBatch = [
            SELECT Id FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'OPP_OpportunityNaming_BATCH'
        ];

        System.assert(jobsApexBatch.isEmpty(), 'The naming batch should not be started again');
    }

    /**
     * @description Confirms that the finish method does not chain the next batch
     * if there are no more records to process
     */
    @isTest
    private static void shouldNotChainNextBatchIfThereAreNoMoreRecordsToProcess() {
        List<Opportunity> testOpps = [SELECT Id FROM Opportunity ORDER BY Id];

        OPP_OpportunityNaming_BATCH batch = new OPP_OpportunityNaming_BATCH();
        batch.lastOppIdProcessed = testOpps[testOpps.size()-1].Id;

        Test.startTest();
        batch.finish(null);
        Test.stopTest();

        List<AsyncApexJob> jobsApexBatch = queryOppNamingBatchJobs();
        System.assert(jobsApexBatch.isEmpty(), 'The naming batch should not be started again');
    }

    /**
     * @description Creates a given number of test opportunities
     */
    private static List<Opportunity> createOpportunities(Integer numOpps) {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < numOpps; i++) {
            opps.add(
                new Opportunity(
                    AccountId = testAccount.Id,
                    Name = 'Test Opp ' + i,
                    StageName = 'Closed Won',
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
            Opportunity_Name_Format__c = '{!Account.Name} {!CloseDate}',
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
