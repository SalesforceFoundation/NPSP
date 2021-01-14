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
* @description Trigger Handler for the DataImportBatch SObject
*/
public class BDI_DataImportBatch_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************************
     * @description Trigger Handler on BatchDataImport
     * @param newSObjects the list of records from trigger new.
     * @param oldSObjects the list of records from trigger old.
     * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.).
     * @param objResult the describe for BatchDataImport
     * @return dmlWrapper.
     ********************************************************************************************************************/
    public override DmlWrapper run(List<SObject> newSObjects, List<SObject> oldSObjects,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            handleBefore(newSObjects);
        } 

        return null;
    }

    /**
     * @description In the before trigger context, sets the status for the batch
     * @param List<DataImportBatch__c> 
     */
    private void handleBefore(List<DataImportBatch__c> batches) {
        for (DataImportBatch__c b : batches) {
            b.Batch_Status__c = BDI_DataImport_API.BATCH_STATUS_OPEN;
        }
    }
}
