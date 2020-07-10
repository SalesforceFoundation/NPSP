/*
    Copyright (c) 20120 Salesforce.org
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
* @description Trigger Handler for the DataImport SObject
*/
public class BDI_DataImport_TDTM extends TDTM_Runnable {
  
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
              || triggerAction == TDTM_Runnable.Action.AfterUpdate
              || triggerAction == TDTM_Runnable.Action.AfterUndelete) {
            updateBatchStatus(newSObjects);
        }

        if (triggerAction == TDTM_Runnable.Action.AfterDelete) {
          updateBatchStatus(oldSObjects);
        }

        return null;
    }

    /**
     * @description Update the batch status based on the data import statuses
     * when all DIs are Imported -> then the Batch Status is Completed
     * when any DI status is blank or Dry Run Validated or Dry Run error -> then the Batch Status is Open
     * when any DI is Failed -> then the Batch Status is Failed - needs review
     * 
     */
    private void updateBatchStatus(List<DataImport__c> diRecords) {
      Set<Id> batchIdSet = new Set<Id>();

      // build a set of parent ids(batch ids)
      for (DataImport__c di : diRecords) {
        if (di.npsp__NPSP_Data_Import_Batch__c != null) {
          batchIdSet.add(di.npsp__NPSP_Data_Import_Batch__c);
        }
        batchIdSet.add(di.npsp__NPSP_Data_Import_Batch__c);
      }

      Map<Id, DataImportStatus> batchDiStatusCompositionMap = new Map<Id, DataImportStatus>();

      for(DataImport__c di : diRecords) {
        
      }

    }

    /**
    * @description inner class to store the status composition 
    * of the di records in a batch
    */
    private class DataImportStatus {
      Boolean hasBlank { get; set; }
      Boolean hasDryRunValidated { get; set; }
      Boolean hasDryRunError { get; set; }
      Boolean hasImported { get; set; }
      Boolean hasFailed { get; set; }
    
      // default constructor
      DataImportStatus() {
        hasBlank = false;
        hasDryRunValidated = false;
        hasDryRunError = false;
        hasImported = false;
        hasFailed = false;
      }

    }


}
