/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group Utilities
* @description To prevent a timeout error counting Opportunity records using specific filters, this batch job
* is built to be generic enough to be executed in different configurations to count whatever large object requires
* counting. Stateful is used to hold the count variables and an Enum is used to define the mode the batch job
* is executing in.
* *
* Significant query tests were done in Oct/Nov 2018 to determine what query can run against a very very large
* organization without timing out. The initial query tests used two different WHERE clauses against the
* npe03__Recurring_Donation__c field. Both of those consistently failed with a query timeout error. The only query
* that did run consistently is one without any filter at all. Technically we could use a filter with against an
* indexed field, however in this case the goal was to use " != null" which would not use the index. As a result
* this job will query and loop through all Opportunity records, but just count the recurring donation related ones.
*/
public class UTIL_OrgTelemetry_SObject_BATCH implements Database.Batchable<SObject>, Database.Stateful {

    /**
     * @description Batch size for OPPORTUNITY job mode
     */
    public static final Integer OPPORTUNITIES_BATCH_SIZE = 2000;

    /**
     * @description Batch size for RECURRING_DONATIONS job mode. Limited to 200 as job needs to query related
     * opportunities during the execute method as sub-queries in a query locator can cause timeouts in large orgs.
     * A batch size of 200 allows each Recurring Donation to have 250 opportunities (i.e. 50,000 records SOQL limit)
     */
    public static final Integer RECURRING_DONATIONS_BATCH_SIZE = 200;
    /**
     * @description BatchJobMode is to add support for other query types in this same batch job
     * that aren't yet needed, but may be in the future
     */
    public enum TelemetryBatchJobMode {
        RECURRING_DONATIONS,
        OPPORTUNITIES
    }

    /** @description Limit for query locator. Property is public to allow for testing */
    public Integer chunkSize = 10000000;

    /** @description Last Id processed by the batch so query locator can return records in ID
     *  order and batch can be chained
    */
    public Id lastProcessedId;

    @TestVisible
    private UTIL_FeatureManagement featureManager = new UTIL_FeatureManagement();

    /** @description The job mode this particular batch iteration is executing in */
    private UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode jobMode;

    /** @description Stateful counter vars used for the different counting jobs */
    @TestVisible
    private Integer rdAllOppsCount = 0;

    @TestVisible
    private Integer rdOpenStatusOppsCount = 0;

    @TestVisible
    private Integer rdAllCount = 0;

    @TestVisible
    private Integer rdDiffCount = 0;

    private final String recurringDonationOpenStatusValue = System.Label.npe03.RecurringDonationOpenStatus;

    /**
     * @description Constructor
     */
    public UTIL_OrgTelemetry_SObject_BATCH(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode jobMode) {
        this.jobMode = jobMode;
    }

    /**
     * @description Execute the appropriate query to use in this batch job. Clears out the last processed Id to prevent
     * infinite loops
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        String soqlQuery = buildQuery(lastProcessedId, chunkSize);

        lastProcessedId = null;

        return Database.getQueryLocator(soqlQuery);
    }

    /**
     * @description Builds a query based on batch job mode, using specified Id offset and limit
     */
    private String buildQuery(Id idToOffset, Integer queryLimit) {
        String soqlQuery = 'SELECT Id FROM Account LIMIT 0';
        switch on (jobMode) {
            when OPPORTUNITIES {
                soqlQuery = 'SELECT Id, npe03__Recurring_Donation__r.npe03__Open_Ended_Status__c FROM Opportunity WHERE Id > \'\'{0}\'\' ORDER BY Id LIMIT {1}';
            }

            when RECURRING_DONATIONS {
                soqlQuery = 'SELECT npe03__Amount__c FROM npe03__Recurring_Donation__c WHERE Id > \'\'{0}\'\' ORDER BY Id LIMIT {1}';
            }

            when else {
                // If no conditions are met, this returns an empty query to avoid an NPE
                soqlQuery = 'SELECT Id FROM Account LIMIT 0';
            }
        }

        return String.format(
            soqlQuery,
            new List<String>{ idToOffset == null ? '' : idToOffset, String.valueOf(queryLimit) }
        );

    }

    /**
     * @description For each batch iteration, loop through the records and count as needed into
     * stateful vars
     */
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        // Since execution contexts might not run in order (ex., chunk size 10k,
        // batch size 2k has 5 batches but they won't run in a guaranteed order)
        // we first need to check if the last Id is greater than the value in lastProcessedId
        Id lastIdInScope = scope[scope.size() - 1].Id;
        if (lastProcessedId == null || lastIdInScope > lastProcessedId) {
            lastProcessedId = lastIdInScope;
        }

        switch on (jobMode) {
            when OPPORTUNITIES {
                handleOpportunityJobMode((List<Opportunity>) scope);
            }

            when RECURRING_DONATIONS {
                handleRecurringDonationsJobMode((List<npe03__Recurring_Donation__c>) scope);
            }
        }
    }

    /**
     * @description Handles batch logic for OPPORTUNITIES job mode
     */
    private void handleOpportunityJobMode(List<Opportunity> opps) {
        for (Opportunity opp : opps) {
            getOppRecurringDonationsCounts(opp);
        }
    }

    /**
     * @description Process RecurringDonation counters for the specific Opportunity
     */
    private void getOppRecurringDonationsCounts(Opportunity opp) {
        if (opp.npe03__Recurring_Donation__c == null) {
            return;
        }

        rdAllOppsCount++;

        Object rdStatus = opp.npe03__Recurring_Donation__r.npe03__Open_Ended_Status__c;
        if (rdStatus != null && (String) rdStatus == recurringDonationOpenStatusValue) {
            rdOpenStatusOppsCount++;
        }
    }

    /**
     * @description Handles batch logic for RECURRING_DONATIONS job mode
     */
    private void handleRecurringDonationsJobMode(List<npe03__Recurring_Donation__c> recurringDonations) {
        Map<Id, List<Opportunity>> oppsByRecurringDonationId = getOppsByRecurringDonationId(recurringDonations);

        for (npe03__Recurring_Donation__c recurringDonation : recurringDonations) {
            getRecurringDonationsCounts(recurringDonation, oppsByRecurringDonationId.get(recurringDonation.Id));
        }
    }

    /**
     * @description Process RecurringDonation counters for the specific Opportunity
     */
    private void getRecurringDonationsCounts(npe03__Recurring_Donation__c recurringDonation, List<Opportunity> relatedOpps) {
        rdAllCount++;

        if (relatedOpps == null) {
            return;
        }

        for (Opportunity opp : relatedOpps) {
            if (opp.Amount != recurringDonation.npe03__Amount__c) {
                rdDiffCount++;
                break;
            }
        }
    }

    /**
     * @description Builds a map of opportunities grouped by npe03__Recurring_Donation__c
     */
    private Map<Id, List<Opportunity>> getOppsByRecurringDonationId(List<npe03__Recurring_Donation__c> recurringDonations) {
        List<Opportunity> opps = [
            SELECT Amount, npe03__Recurring_Donation__c
            FROM Opportunity
            WHERE npe03__Recurring_Donation__c IN :recurringDonations
        ];

        Map<Id, List<Opportunity>> oppsByRecurringDonationId = new Map<Id, List<Opportunity>>();

        for (Opportunity opp : opps) {
            if (opp.npe03__Recurring_Donation__c == null) {
                continue;
            }

            if (!oppsByRecurringDonationId.containsKey(opp.npe03__Recurring_Donation__c)) {
                oppsByRecurringDonationId.put(opp.npe03__Recurring_Donation__c, new List<Opportunity>());
            }

            oppsByRecurringDonationId.get(opp.npe03__Recurring_Donation__c).add(opp);
        }

        return oppsByRecurringDonationId;
    }

    /**
     * @description When the entire batch job is done, submit the final count variables to the LMO
     */
    public void finish(Database.BatchableContext context) {
        if (shouldChainNextBatch()) {

            switch on (jobMode) {
                when OPPORTUNITIES {
                    Database.executeBatch(this, 2000);
                }

                when RECURRING_DONATIONS {
                    Database.executeBatch(this, 200);
                }
            }

        } else {
            switch on (jobMode) {
                when OPPORTUNITIES {
                    featureManager.setPackageIntegerValue(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsOpenEnded.name(), rdOpenStatusOppsCount);
                    featureManager.setPackageIntegerValue(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll.name(), rdAllOppsCount);
                }

                when RECURRING_DONATIONS {
                    featureManager.setPackageIntegerValue(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRecurringDonationsAll.name(), rdAllCount);
                    featureManager.setPackageIntegerValue(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdsWithDiffAmount.name(), rdDiffCount);
                }
            }
        }
    }

    /** @description Returns whether or not another batch should be chained*/
    private Boolean shouldChainNextBatch() {
        if (lastProcessedId == null) {
            return false;
        }

        String hasMoreQuery = buildQuery(lastProcessedId, 1);
        return !Database.query(hasMoreQuery).isEmpty();
    }
}