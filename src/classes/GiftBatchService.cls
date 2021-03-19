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
* @description Service class for Gift Batches in NPSP.
*/
public with sharing class GiftBatchService {
    public GiftBatchService() {}

    public Map<String, Integer> getGiftBatchTotalsMapFor(Id batchId) {
        AggregateResult[] results =
            new GiftBatchSelector().selectBatchGiftsGroupedByStatusBy(batchId);

        Integer totalGifts = 0;
        Integer processedGifts = 0;
        Integer failedPayments = 0;
        Integer failedGifts = 0;

        for (AggregateResult result : results) {
            totalGifts += (Integer) result.get('recordCount');

            String status = (String) result.get(Schema.SObjectType.DataImport__c.fields.Status__c.getName());
            if (status == 'Imported') {
                processedGifts = (Integer) result.get('recordCount');
                continue;
            }

            String paymentStatus = (String) result.get(Schema.SObjectType.DataImport__c.fields.Payment_Status__c.getName());
            if (paymentStatus == 'DECLINED') {
                failedPayments += (Integer) result.get('recordCount');
            }
            if (status == 'Failed') {
                failedGifts += (Integer) result.get('recordCount');
            }
        }

        return new Map<String, Integer> {
            'totalGifts' => totalGifts,
            'processedGifts' => processedGifts,
            'failedPayments' => failedPayments,
            'failedGifts'=> failedGifts
        };
    }
}
