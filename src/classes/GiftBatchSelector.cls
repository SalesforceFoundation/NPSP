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
* @description Selector class for Gift Batches in NPSP.
*/
public inherited sharing class GiftBatchSelector {

    public DataImportBatch__c selectGiftBatchById(Id id) {
        return [
            SELECT Id,
                Form_Template__r.Template_JSON__c
            FROM DataImportBatch__c
            WHERE Id = :id
            WITH SECURITY_ENFORCED
        ];
    }

    public List<DataImportBatch__c> selectGiftBatchesById(Set<Id> ids) {
        return [
            SELECT Id
            FROM DataImportBatch__c
            WHERE Id IN :ids
            WITH SECURITY_ENFORCED
        ];
    }

    public List<AggregateResultProxy> selectBatchGiftsGroupedByStatusBy(Set<Id> ids) {
        List<AggregateResultProxy> results = new List<AggregateResultProxy>();
        for (AggregateResult result : [SELECT COUNT(Id)recordCount,
                                            Status__c,
                                            Payment_Status__c,
                                            NPSP_Data_Import_Batch__c
                                        FROM DataImport__c
                                        WHERE NPSP_Data_Import_Batch__c IN :ids
                                        GROUP BY
                                            Status__c,
                                            Payment_Status__c,                                            
                                            NPSP_Data_Import_Batch__c]) {
            results.add(new AggregateResultProxy().withAggregateResult(result));
        }
        return results;
    }
}
