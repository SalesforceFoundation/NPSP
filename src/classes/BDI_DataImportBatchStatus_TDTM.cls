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
* @group Batch Data Import
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Trigger Handler for the DataImport SObject to set the batch status
*/
public class BDI_DataImportBatchStatus_TDTM extends TDTM_Runnable {
/*******************************************************************************************************************
     * @description Trigger Handler on DataImport
     * @param newSObjects the list of records from trigger new.
     * @param oldSObjects the list of records from trigger old.
     * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
     * @param objResult the describe for BatchDataImport
     * @return dmlWrapper.
     ********************************************************************************************************************/
    public override DmlWrapper run(List<SObject> newSObjects, List<SObject> oldSObjects,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        if (triggerAction == TDTM_Runnable.Action.AfterInsert
              || triggerAction == TDTM_Runnable.Action.AfterUndelete) {
            setBatchStatus(newSObjects);
        }

        if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
          setBatchStatus(oldSObjects, newSObjects);
        }

        if (triggerAction == TDTM_Runnable.Action.AfterDelete) {
          setBatchStatus(oldSObjects);
        }

        return null;
    }

    /**
     * @description updates the batch status on di records insert, delete or undelete
     * @param diList the old or new list
     */
    private void setBatchStatus(List<DataImport__c> diList) {
        Set<Id> batchIdSet = new Set<Id>();

        // build a set of batch ids
        for (DataImport__c di : diList) {
            if (di.NPSP_Data_Import_Batch__c != null) {
                batchIdSet.add(di.NPSP_Data_Import_Batch__c);
            }
        }
        setBatchStatus(batchIdSet);
    }

    /**
     * @description updates the batch status on di records update
     * @param diOldList
     * @param diNewList
     */
    private void setBatchStatus(List<DataImport__c> diOldList, 
                                List<DataImport__c> diNewList) {

        Set<Id> batchIdSet = new Set<Id>();
        Map<Id, DataImport__c> diNewMap = new Map<Id, DataImport__c>(diNewList);

        // build a set of batch ids
        for(DataImport__c diOld : diOldList) {
            DataImport__c diNew = diNewMap.get(diOld.Id);

            if (diOld.NPSP_Data_Import_Batch__c != diNew.NPSP_Data_Import_Batch__c) {
                // di records changed parents
                if (diOld.NPSP_Data_Import_Batch__c != null) {
                    batchIdSet.add(diOld.NPSP_Data_Import_Batch__c);
                }
                if (diNew.NPSP_Data_Import_Batch__c != null) {
                    batchIdSet.add(diNew.NPSP_Data_Import_Batch__c);
                }
            } else if (diOld.Status__c != diNew.Status__c) {
                // status was changed; same parent
                batchIdSet.add(diOld.NPSP_Data_Import_Batch__c);
                }
            }
            setBatchStatus(batchIdSet);
        }

    /**
     * @description Update the batch status based on the data import statuses
     * @param Set<Id> batchIdSet
     * when all DIs are Imported -> then the Batch Status is Completed
     * when any DI status is blank or Dry Run Validated or Dry Run error -> then the Batch Status is Open
     * when any DI is Failed -> then the Batch Status is Failed - needs review
     * 
     */
    private void setBatchStatus(Set<Id> batchIdSet) {

        // get the all the batch and di records in one query
        List<DataImportBatch__c> batches = [SELECT Id, Batch_Status__c, 
                                            (SELECT Id, NPSP_Data_Import_Batch__c, Status__c 
                                                    FROM NPSP_Data_Imports__r)
                                            FROM DataImportBatch__c
                                            WHERE Id IN :batchIdSet];

        // go through the di statuses and aggregate them by batch
        // store the results in a map
        Map<Id, BatchDataImportStatusAggregate> batchDataImportStatusAggregateMap = 
            new Map<Id, BatchDataImportStatusAggregate>();
        for (DataImportBatch__c b : batches) {
            // initialize the counts with 0s in the aggregate counts
            batchDataImportStatusAggregateMap.put(b.Id, 
                                    new BatchDataImportStatusAggregate());

            // loop through the child DIs
            for (DataImport__c di : b.NPSP_Data_Imports__r) {
                BatchDataImportStatusAggregate batchStatusAggregate = 
                    batchDataImportStatusAggregateMap.get(di.NPSP_Data_Import_Batch__c);

                batchStatusAggregate.updateCounts(di.Status__c); 
                batchDataImportStatusAggregateMap.put(di.NPSP_Data_Import_Batch__c, 
                                                    batchStatusAggregate);
            }
        }
    
        // update the statuses on the batch records
        updateBatchStatus(batches, batchDataImportStatusAggregateMap);
    }

    /**
    * @description update the batch record status  
    * @param List<DataImportBatch__c>
    * @param Map<Id, BatchDataImportStatusAggregate>
    */
    private void updateBatchStatus(List<DataImportBatch__c> batches, 
        Map<Id, BatchDataImportStatusAggregate> batchDataImportStatusAggregateMap) { 

        List<DataImportBatch__c> batchesToUpdate = new List<DataImportBatch__c>();
        for(DataImportBatch__c batch : batches) {
            String newBatchStatus = 
                getBatchStatus(batchDataImportStatusAggregateMap.get(batch.Id));
            if (batch.Batch_Status__c != newBatchStatus) {
                batch.Batch_Status__c = newBatchStatus;
                batchesToUpdate.add(batch);
            }
        }
        update batchesToUpdate;
    }

    /**
    * @description get the batch status based on the di statuses
    * @param BatchDataImportStatusAggregate
    * @return String
    */
    private static String getBatchStatus(BatchDataImportStatusAggregate batchStatusAggregate) {
        // at least one failure means the batch failed
        if (0 < batchStatusAggregate.failedStatusCount) {
            return BDI_DataImportBatch_TDTM.BATCH_STATUS_FAILED;
        }

        // all di records are imported
        if (0 < batchStatusAggregate.importedStatusCount &&
            0 == batchStatusAggregate.openStatusCount && 
            0 == batchStatusAggregate.failedStatusCount) {
            return BDI_DataImportBatch_TDTM.BATCH_STATUS_COMPLETED;
        }

        return BDI_DataImportBatch_TDTM.BATCH_STATUS_OPEN;
    }

    /**
    * @description inner class to store the status composition 
    * of the di records in a batch
    */
    private class BatchDataImportStatusAggregate {
        Integer openStatusCount { get; set; }
        Integer importedStatusCount { get; set; }
        Integer failedStatusCount { get; set; }
    
        // default constructor
        BatchDataImportStatusAggregate() {
            openStatusCount = 0;
            importedStatusCount = 0;
            failedStatusCount = 0;
        }

        /**
         * @description update the status count based on the incoming di status
        * @param String status
        */
        void updateCounts(String status) {
            if (String.isBlank(status) || status == BDI_DataImport_API.bdiDryRunValidated
                                    || status == BDI_DataImport_API.bdiDryRunError) {
                openStatusCount++;
            } else if (status == BDI_DataImport_API.bdiImported) {
                importedStatusCount++;
            } else if (status == BDI_DataImport_API.bdiFailed) {
                failedStatusCount++;
            }
        }

    } 

}
