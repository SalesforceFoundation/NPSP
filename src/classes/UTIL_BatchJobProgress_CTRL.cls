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
* @group Batch Job
* @description Batch job progress controller
*/
public with sharing class UTIL_BatchJobProgress_CTRL {

    /***
     * @description Loads the latest batch job for the specified class name.
     * @param className Batch job class name
     * @return String JSON representation of the batch job
     */
    @AuraEnabled
    public static String loadBatchJob(String className) {
        String jsonBatchJob;

        try {
            UTIL_BatchJobService service = new UTIL_BatchJobService();
            jsonBatchJob = JSON.serialize(service.getBatchJob(className));

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }

        return jsonBatchJob;
    }

    /***
     * @description Loads the batch job summary.
     * NOTE: the batch summary is available for the latest batch for the class name
     *
     * @param className Batch job class name
     * @return String JSON representation of the batch job summary
     */
    @AuraEnabled
    public static String loadBatchJobSummary(String className) {
        String jsonBatchSummary;

        try {
            switch on className {
                when 'RD2_DataMigration_BATCH' {
                    jsonBatchSummary = getMigrationState(className);
                }
                when 'RD2_DataMigrationDryRun_BATCH' {
                    jsonBatchSummary = getMigrationState(className);
                }
            }

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }

        return jsonBatchSummary;
    }


    /***
    * @description Returns batch summary for enhanced RD data migration batch jobs
    * @param className Batch class name
    * @return String Batch Job Summary JSON string
    */
    @TestVisible
    private static String getMigrationState(String className) {     
        String summaryType = className == 'RD2_DataMigrationDryRun_BATCH' ? 'dryRun' : 'run';   
        String migrationState = UTIL_CustomSettingsFacade.getRecurringDonationsSettings().RecurringDonations2MigrationState__c;

        Map<String, UTIL_BatchJobService.JobSummary> summaryByType = String.isBlank(migrationState)
            ? new Map<String, UTIL_BatchJobService.JobSummary>()
            : (Map<String, UTIL_BatchJobService.JobSummary>) JSON.deserialize(migrationState, Map<String, UTIL_BatchJobService.JobSummary>.class);

        return
            summaryByType.containsKey(summaryType)
            ? JSON.serialize(summaryByType.get(summaryType))
            : null;
    }


    /***
    * @description Throws AuraHandledException
    * @param errMessage
    * @return void
    */
    private static void throwAuraHandledException(String errMessage) {
        AuraHandledException e = new AuraHandledException(errMessage);
        e.setMessage(errMessage);
        throw e;
    }

}