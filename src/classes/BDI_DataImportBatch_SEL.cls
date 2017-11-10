/*
    Copyright (c) 2017 Salesforce.org
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
* @date 2017
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Selector class for the DataImportBatch SObject
*/
public with sharing class BDI_DataImportBatch_SEL {

    /*******************************************************************************************************
    * @description queries the database for all Data Import Batch records with the specified Id's
    * @param setBatchId The batches to query for.
    * @return list<DataImportBatch__c>
    */
    public static list<DataImportBatch__c> selectByIds(Set<Id> setBatchId) {
        return [SELECT Id,
                    Name,
                    Account_Custom_Unique_ID__c,
                    Batch_Description__c,
                    Batch_Process_Size__c,
                    Contact_Custom_Unique_ID__c,
                    Contact_Matching_Rule__c,
                    Donation_Matching_Behavior__c,
                    Donation_Matching_Implementing_Class__c,
                    Donation_Matching_Rule__c,
                    Donation_Date_Range__c,
                    Process_Using_Scheduled_Job__c,
                    Last_Processed_On__c,
                    Records_Failed__c,
                    Records_Successfully_Processed__c,
                    Post_Process_Implementing_Class__c,
                    Run_Opportunity_Rollups_while_Processing__c
            FROM DataImportBatch__c
            WHERE Id in :setBatchId];
    }

    /*******************************************************************************************************
    * @description queries the database for the Data Import Batch record with the specified Id
    * @param batchId The batch to query for.
    * @return DataImportBatch__c
    */
    public static DataImportBatch__c selectById(Id batchId) {
        list<DataImportBatch__c> listBatches = selectByIds(new set<Id>{batchId});
        return listBatches[0];
    }

    /*******************************************************************************************************
    * @description queries the database for all Data Import Batch records that are marked with Scheduled
    * processing, and have DI records to import.
    * @return list<Id>
    */
    public static list<Id> selectUsingScheduledProcessing() {
        Map<Id, DataImportBatch__c> mapIdToBatch = new Map<Id, DataImportBatch__c>([
            SELECT Id
            FROM DataImportBatch__c
            WHERE Process_Using_Scheduled_Job__c = TRUE]);
        return new List<Id>(mapIdToBatch.keySet());
    }
}