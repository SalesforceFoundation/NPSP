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
*/
public class UTIL_OrgTelemetry_SObject_BATCH implements Database.Batchable<SObject>, Database.Stateful {

    /**
     * @description BatchJobMode is to add support for other query types in this same batch job
     * that aren't yet needed, but may be in the future
     */
    public enum TelemetryBatchJobMode {
        RECURRING_DONATIONS
    }

    /** @description The job mode this particular batch iteration is executing in */
    private UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode jobMode;

    /** @description Stateful counter vars used for the different counting jobs */
    private Integer rdAllOppsCount = 0;
    private Integer rdOpenStatusOppsCount = 0;

    private static final String recurringDonationOpenStatusValue = System.Label.npe03.RecurringDonationOpenStatus;


    /**
     * @description Constructor
     */
    public UTIL_OrgTelemetry_SObject_BATCH(UTIL_OrgTelemetry_SObject_BATCH.TelemetryBatchJobMode jobMode) {
        this.jobMode = jobMode;
    }

    /**
     * @description Execute the appropriate query to use in this batch job.
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        switch on (jobMode) {
            when RECURRING_DONATIONS {
                return Database.getQueryLocator(
                        [SELECT Id, npe03__Recurring_Donation__r.npe03__Open_Ended_Status__c
                        FROM Opportunity
                        WHERE npe03__Recurring_Donation__c != null]);
            }
        }
        // If no conditions are met, this returns an empty query to avoid an NPE
        return Database.getQueryLocator([SELECT Id FROM Account LIMIT 0]);
    }

    /**
     * @description For each batch iteration, loop through the records and count as needed into
     * stateful vars
     */
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        for (SObject record : scope) {
            switch on (jobMode) {
                when RECURRING_DONATIONS {
                    getRecurringDonationsCounts((Opportunity)record);
                }
            }
        }
    }

    /**
     * @description Process RecurringDonation counters for the specific Opportunity
     */
    private void getRecurringDonationsCounts(Opportunity opp) {
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
     * @description When the entire batch job is done, submit the final count variables to the LMO
     */
    public void finish(Database.BatchableContext context) {
        switch on (jobMode) {
            when RECURRING_DONATIONS {
                System.FeatureManagement.setPackageIntegerValue(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsOpenEnded.name(), rdOpenStatusOppsCount);
                System.FeatureManagement.setPackageIntegerValue(UTIL_OrgTelemetry_SVC.TelemetryParameterName.Data_CountRdOppsAll.name(), rdAllOppsCount);
            }
        }
    }
}