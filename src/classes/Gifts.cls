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
* @description Gifts entity class in NPSP.
*/

public with sharing class Gifts {

    private Set<String> elevateBatchIds;
    @TestVisible private List<DataImport__c> dataImports;
    @TestVisible private List<DataImport__c> giftsToUpdate = new List<DataImport__c>();

    public Gifts(List<DataImport__c> dataImports) {
        this.dataImports = dataImports;
        setElevateBatchIds(dataImports);
    }

    public List<DataImport__c> authorizedGifts() {
        List<DataImport__c> giftsToReturn = new List<DataImport__c>();
        for (DataImport__c gift : dataImports) {
            if (gift.Payment_Status__c == ElevateTransactionStatus.AUTHORIZED.name()) {
                giftsToReturn.add(gift);
            }
        }
        return giftsToReturn;
    }

    public void updateRecords() {
        update giftsToUpdate;
    }

    public Set<String> elevateBatchIds() {
        return elevateBatchIds;
    }

    public void authorizedToPaymentProcessingStatus() {
        for (DataImport__c gift : authorizedGifts()) {
            gift.Payment_Status__c = ElevateTransactionStatus.PAYMENTPROCESSING.name();
            giftsToUpdate.add(gift);
        }
    }

    public void failGiftsByElevateBatchIdWithReason(Map<String, String> failReasonByElevateBatchId) {
        for (String elevateBatchId : failReasonByElevateBatchId.keySet()) {
            List<DataImport__c> giftsInElevateBatch = findGiftsByElevateBatchId(elevateBatchId);
            String failReason = failReasonByElevateBatchId.get(elevateBatchId);
            applyFailReasonToGiftsIn(giftsInElevateBatch, failReason);
        }
    }

    private void applyFailReasonToGiftsIn(List<DataImport__c> giftsInElevateBatch, String failReason) {
        for (DataImport__c gift : giftsInElevateBatch) {
            gift.Payment_Status__c = ElevateTransactionStatus.RETRYABLEERROR.name();
            gift.FailureInformation__c = failReason;
            giftsToUpdate.add(gift);
        }
    }

    private List<DataImport__c> findGiftsByElevateBatchId(String elevateBatchId) {
        List<DataImport__c> giftsInElevateBatch = new List<DataImport__c>();
        for (DataImport__c gift : dataImports) {
            if (gift.Payment_Elevate_Batch_ID__c == elevateBatchId) {
                giftsInElevateBatch.add(gift);
            }
        }
        return giftsInElevateBatch;
    }

    private void setElevateBatchIds(List<DataImport__c> dataImports) {
        elevateBatchIds = new Set<String>();
        for (DataImport__c dataImport : dataImports) {
            if (dataImport.Payment_Status__c == ElevateTransactionStatus.AUTHORIZED.name()) {
                elevateBatchIds.add(dataImport.Payment_Elevate_Batch_ID__c);
            }
        }
    }
}