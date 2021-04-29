/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Batch entity class in NPSP.
*/

public inherited sharing class NPSP_Batch {

    private Id batchId;
    private List<DataImport__c> dataImports;
    private List<String> groupIds = new List<String>();


    private ElevateCaptureGroupService captureGroupService {
        get {
            if (captureGroupService == null) {
                captureGroupService = new ElevateCaptureGroupService();
            }
            return captureGroupService;
        }
        set;
    }

    private void updatePaymentStatusesFor(List<DataImport__c> dataImports,
            List<ElevateCaptureGroupResponse> captureGroupResponses) {
        for (DataImport__c dataImport : dataImports) {
            for (ElevateCaptureGroupResponse response : captureGroupResponses) {
                if(isValidCaptureResponse(response, dataImport)) {
                    dataImport.Payment_Status__c = response.status;
                }
            }
        }
        update dataImports;
    }

    private Boolean isValidCaptureResponse (ElevateCaptureGroupResponse response, DataImport__c dataImport) {
        return response.id.equals(dataImport.Payment_Elevate_Batch_ID__c) && response.errors == null;
    }

    private void setElevateBatchIds() {
        // Build list of elevate batch Ids here
        dataImports = [
                SELECT Payment_Elevate_Batch_ID__c, Id
                FROM DataImport__c
                WHERE NPSP_Data_Import_Batch__c =: batchId
                AND Payment_Status__c=: ElevateTransactionStatus.AUTHORIZED.name()
        ];

        for (DataImport__c dataImport : dataImports) {
            groupIds.add(dataImport?.Payment_Elevate_Batch_ID__c);
        }
    }

    public NPSP_Batch(Id batchId) {
        this.batchId = batchId;
    }

    public void processPayments() {
        setElevateBatchIds();
        List<ElevateCaptureGroupResponse> captureGroupResponses = captureGroupService.sendChargeRequest(groupIds);
        updatePaymentStatusesFor(dataImports, captureGroupResponses);
    }


}