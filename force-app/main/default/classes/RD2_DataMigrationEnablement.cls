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
* @group Recurring Donations
* @description Contains enhanced Recurring Donation data migration enablement helper classes
*/
public with sharing class RD2_DataMigrationEnablement {

    /**
    * @description Saves data migration batch summaries
    */
    public class BatchJob {
        public final String DRY_RUN_MODE = 'dryRun';
        public final String RUN_MODE = 'run';
        public final String DRY_RUN_MIGRATION_BATCH_CLASS = 'RD2_DataMigrationDryRun_BATCH';
        public final String MIGRATION_BATCH_CLASS = 'RD2_DataMigration_BATCH';

        /***
        * @description Returns batch summary type for the specified batch class name
        * @param className Batch class name
        * @return String 
        */
        public String getSummaryType(String className) {
            return className == DRY_RUN_MIGRATION_BATCH_CLASS ? DRY_RUN_MODE : RUN_MODE;   
        }

        /***
        * @description Returns batch summary type
        * @param isDryRunMode Indicates if dry run mode is turned on
        * @return String 
        */
        public String getSummaryType(Boolean isDryRunMode) {
            return isDryRunMode ? DRY_RUN_MODE : RUN_MODE;   
        }

        /**
        * @description Saves batch job results
        * @param summary Batch job summary/result
        * @param isDryRunMode Indicates if dry run mode is turned on
        * @return void
        */
        public void saveSummary(UTIL_BatchJobService.JobSummary summary, Boolean isDryRunMode) {
            npe03__Recurring_Donations_Settings__c rdSettings = UTIL_CustomSettingsFacade.getRecurringDonationsSettings();            
            Map<String, UTIL_BatchJobService.JobSummary> summaryByType = getSummaryByType(rdSettings);

            summaryByType.put(getSummaryType(isDryRunMode), summary);
            rdSettings.RecurringDonations2MigrationState__c = JSON.serialize(summaryByType);

            if (!Test.isRunningTest()) {
                upsert rdSettings;
            }
        }

        /***
        * @description Returns batch summary for the specified batch class name
        * @param batchId Batch job Id
        * @param className Batch class name
        * @return UTIL_BatchJobService.JobSummary
        */
        public UTIL_BatchJobService.JobSummary getSummary(Id batchId, String className) {     
            String summaryType = getSummaryType(className);   

            Map<String, UTIL_BatchJobService.JobSummary> summaryByType = 
                getSummaryByType(UTIL_CustomSettingsFacade.getRecurringDonationsSettings());

            UTIL_BatchJobService.JobSummary summary = summaryByType.get(summaryType);

            if (summary != null && summary.batchId != batchId) {
                summary = null;
            }
            
            return summary;
        }

        /***
        * @description Returns batch summary by the summary type
        * @param rdSettings Recurring Donation custom settings
        * @return Map<String, UTIL_BatchJobService.JobSummary>
        */
        public Map<String, UTIL_BatchJobService.JobSummary> getSummaryByType(npe03__Recurring_Donations_Settings__c rdSettings) {
            String migrationState = rdSettings.RecurringDonations2MigrationState__c;

            return String.isBlank(migrationState)
                ? new Map<String, UTIL_BatchJobService.JobSummary>()
                : (Map<String, UTIL_BatchJobService.JobSummary>) JSON.deserialize(migrationState, Map<String, UTIL_BatchJobService.JobSummary>.class);
        }
    }
}
