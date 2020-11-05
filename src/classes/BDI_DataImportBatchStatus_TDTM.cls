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
    public override TDTM_Runnable.DmlWrapper run(List<SObject> newSObjects, List<SObject> oldSObjects,
            TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        switch on triggerAction {
            when AfterInsert, AfterUndelete {
                setBatchStatus(newSObjects);
            }

            when AfterUpdate {
                setBatchStatusOnUpdate(oldSObjects, newSObjects);
            }

            when AfterDelete {
                setBatchStatus(oldSObjects);
            }
        }

        return null;
    }

    private void setBatchStatusOnUpdate(List<DataImport__c> diOldList,
            List<DataImport__c> diNewList) {

        Set<Id> batchIdSet = getBatchIdsToUpdate(diOldList, diNewList);
        updateBatchStatus(batchIdSet);
    }

    private void setBatchStatus(List<DataImport__c> diList) {
        Set<Id> batchIdSet = getBatchIdsToUpdate(diList);
        updateBatchStatus(batchIdSet);
    }

    private Set<Id> getBatchIdsToUpdate(List<DataImport__c> diList) {
        Set<Id> batchIdSet = new Set<Id>();

        for (DataImport__c di : diList) {
            if (di.NPSP_Data_Import_Batch__c != null) {
                batchIdSet.add(di.NPSP_Data_Import_Batch__c);
            }
        }

        return batchIdSet;
    }

    private Set<Id> getBatchIdsToUpdate(List<DataImport__c> diOldList, List<DataImport__c> diNewList) {
        Map<Id, DataImport__c> diNewMap = new Map<Id, DataImport__c>(diNewList);
        Set<Id> batchIdSet = new Set<Id>();

        for (DataImport__c diOld : diOldList) {
            DataImport__c diNew = diNewMap.get(diOld.Id);
            if (needsStatusUpdate(diOld, diNew)) {
                batchIdSet.add(diNew.NPSP_Data_Import_Batch__c);
            }
        }

        return batchIdSet;
    }

    private Boolean needsStatusUpdate(DataImport__c diOld, DataImport__c diNew) {
        if (diOld.NPSP_Data_Import_Batch__c != diNew.NPSP_Data_Import_Batch__c) {
            // di records changed parents
            if (diOld.NPSP_Data_Import_Batch__c != null) {
                return true;
            }
            if (diNew.NPSP_Data_Import_Batch__c != null) {
                return true;
            }
        } else if (diOld.Status__c != diNew.Status__c) {
            // status was changed; same parent
            if (diNew.NPSP_Data_Import_Batch__c != null) {
                return true;
            }
        }

        return false;
    }

    /**
     * @description Update the batch status based on statuses of the data import records associated with that batch
     * @param batchIdSet
     * When one DI is imported, and none are failed or open -> then the Batch Status is Completed
     * When one DI status is blank or Dry Run Validated or Dry Run error, and none are failed -> then the Batch Status is Open
     * When any DI is Failed -> then the Batch Status is Failed - Needs Review
     *
     */
    private void updateBatchStatus(Set<Id> batchIdSet) {

        BatchDataImportStatusAggregator aggregator = getBatchAggregates(batchIdSet);
        List<DataImportBatch__c> batches = new List<DataImportBatch__c>();
        for (Id batchId : batchIdSet) {
            String status = aggregator.getBatchStatus(batchId);
            batches.add(new DataImportBatch__c(
                    Id = batchId,
                    Batch_Status__c = status
            ));

        }

        update batches;
    }

    private List<DataImportBatch__c> getBatchesWithFailedRows(Set<Id> batchIds) {
        return [
                SELECT Id, (
                        SELECT Id, Status__c
                        FROM NPSP_Data_Imports__r
                        WHERE Status__c = :BDI_DataImport_API.bdiFailed
                        LIMIT 1
                )
                FROM DataImportBatch__c
                WHERE Id = :batchIds
        ];
    }

    private List<DataImportBatch__c> getBatchesWithOpenRows(Set<Id> batchIds) {
        return [
                SELECT
                        Id, (
                        SELECT Id, Status__c
                        FROM NPSP_Data_Imports__r
                        WHERE Status__c = :BDI_DataImport_API.bdiDryRunValidated
                        OR Status__c = :BDI_DataImport_API.bdiDryRunError
                        OR Status__c = NULL
                        LIMIT 1
                )
                FROM DataImportBatch__c
                WHERE Id = :batchIds
        ];
    }

    private List<DataImportBatch__c> getBatchesWithImportedRows(Set<Id> batchIds) {
        return [
                SELECT Id, (
                        SELECT Id, Status__c
                        FROM NPSP_Data_Imports__r
                        WHERE Status__c = :BDI_DataImport_API.bdiImported
                        LIMIT 1
                )
                FROM DataImportBatch__c
                WHERE Id = :batchIds
        ];
    }

    private BatchDataImportStatusAggregator getBatchAggregates(Set<Id> batchIds) {
        List<DataImportBatch__c> failedRowBatches = getBatchesWithFailedRows(batchIds);
        List<DataImportBatch__c> openRowBatches = getBatchesWithOpenRows(batchIds);
        List<DataImportBatch__c> importedRowBatches = getBatchesWithImportedRows(batchIds);

        BatchDataImportStatusAggregator aggregator = new BatchDataImportStatusAggregator();
        aggregator.readBatches(failedRowBatches);
        aggregator.readBatches(openRowBatches);
        aggregator.readBatches(importedRowBatches);

        return aggregator;
    }

    /**
     * Aggregator class for determining the status of many Data Import batches at the same time.
     */
    private class BatchDataImportStatusAggregator {
        Map<Id, BatchDataImportStatus> statusesById;

        BatchDataImportStatusAggregator() {
            this.statusesById = new Map<Id, BatchDataImportStatus>();
        }

        String getBatchStatus(Id batchId) {
            return statusesById.get(batchId).getBatchStatus();
        }

        /**
         * Reads in a list of Data Import batches, and creates or updates a BatchDataImportStatus instance for each batch
         * @param batches A list of Data Import batches to determine the status of.
         */
        void readBatches(List<DataImportBatch__c> batches) {
            for (DataImportBatch__c batch : batches) {
                if (statusesById.containsKey(batch.Id)) {
                    statusesById.get(batch.Id).readQueryResult(batch);
                } else {
                    BatchDataImportStatus importStatus = new BatchDataImportStatus();
                    importStatus.readQueryResult(batch);
                    statusesById.put(batch.Id, importStatus);
                }
            }
        }
    }

    /**
     * A class for determining the status of a single Data Import Batch
     */
    private class BatchDataImportStatus {
        Boolean hasOpenRow = false;
        Boolean hasImportedRow = false;
        Boolean hasFailedRow = false;

        /**
         * @param batch A data import batch with a single row sub-query on the NPSP_Data_Imports__r relationship
         */
        void readQueryResult(DataImportBatch__c batch) {
            if (batch.NPSP_Data_Imports__r != null) {
                for (DataImport__c dataImport : batch.NPSP_Data_Imports__r) {
                    readRowStatus(dataImport);
                }
            }
        }

        /**
         * Read the status of a single data import row from the inner query on the batch,
         * and set one of the batch status flags to indicate that the specified type of row was found.
         * @param dataImport The data import row to get the status of.
         */
        void readRowStatus(DataImport__c dataImport) {
            String status = dataImport.Status__c;

            if (isOpen(status)) {
                this.hasOpenRow = true;
                return;
            }

            if (isImported(status)) {
                this.hasImportedRow = true;
                return;
            }

            if (isFailed(status)) {
                this.hasFailedRow = true;
                return;
            }
        }

        /**
         * After ingesting all of the Data Import Batch rows, determine the final batch status.
         * @return {String} One of 'Failed - Needs Review', 'Open', or 'Completed'
         */
        String getBatchStatus() {
            // The order of these conditionals is IMPORTANT. Failed rows have precedence over Open rows when
            // determining batch status, and Open rows have precedence over Imported rows. This means all rows
            // must be marked as Imported for a batch to be marked as Completed, no Failed or Open rows allowed.
            if (this.hasFailedRow) {
                return BDI_DataImport_API.BATCH_STATUS_FAILED;
            }

            if (!this.hasOpenRow) {
                return BDI_DataImport_API.BATCH_STATUS_COMPLETED;
            }

            return BDI_DataImport_API.BATCH_STATUS_OPEN;
        }

        Boolean isOpen(String status) {
            return String.isBlank(status) || status == BDI_DataImport_API.bdiDryRunValidated
                    || status == BDI_DataImport_API.bdiDryRunError;
        }

        Boolean isImported(String status) {
            return status == BDI_DataImport_API.bdiImported;
        }

        Boolean isFailed(String status) {
            return status == BDI_DataImport_API.bdiFailed;
        }
    }

}
