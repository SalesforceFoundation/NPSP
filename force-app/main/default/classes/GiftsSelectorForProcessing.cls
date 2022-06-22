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
* @date 2022
* @description Selector for gifts used when retrieving gifts to be processed
*              through BDI
*/
public with sharing class GiftsSelectorForProcessing {

    private final String CREATED_DATE = String.valueOf(DataImport__c.CreatedDate);

    private List<String> giftFields {
        get {
            if (giftFields == null) {
                Map<String, Schema.SObjectField> mapS = Schema.SObjectType.DataImport__c.fields.getMap();
                giftFields = new List<String>();
                giftFields.addAll(mapS.keySet());
                giftFields.add('NPSP_Data_Import_Batch__r.Batch_Number__c');
            }
            return giftFields;
        }
        set;
    }

    public List<DataImport__c> getGiftsReadyToMoveToProcessing(List<Id> giftIds, Integer chunkSize) {
        String dataImportBatchLookup = String.valueOf(DataImport__c.NPSP_Data_Import_Batch__c);
        String status = String.valueOf(DataImport__c.Status__c);

        List<String> whereClauses = new List<String>{
            status + ' != \'' + BDI_DataImport_API.bdiImported + '\'',
            status + ' != \'' + BDI_DataImport_API.bdiProcessing + '\'',
            'Id IN :giftIds'
        };

        String queryString =
            new UTIL_Query()
            .withSelectFields(giftFields)
            .withFrom(DataImport__c.SObjectType)
            .withWhere(whereClauses)
            .withOrderBy(CREATED_DATE)
            .withLimit(chunkSize)
            .build();

        return Database.query(queryString);            
    }

    public List<DataImport__c> getGiftsReadyToMoveToProcessing(GiftBatchId giftBatchId) {
        String dataImportBatchLookup = String.valueOf(DataImport__c.NPSP_Data_Import_Batch__c);
        String status = String.valueOf(DataImport__c.Status__c);
        Id giftBatchIdValue = giftBatchId.value();

        List<String> whereClauses = new List<String>{
            status + ' != \'' + BDI_DataImport_API.bdiImported + '\'',
            status + ' != \'' + BDI_DataImport_API.bdiProcessing + '\'',
            dataImportBatchLookup + ' =: giftBatchIdValue'
        };

        String queryString =
            new UTIL_Query()
            .withSelectFields(new List<String> { 'Id' })
            .withFrom(DataImport__c.SObjectType)
            .withWhere(whereClauses)
            .withOrderBy(CREATED_DATE)
            .withLimit(50000)
            .build();

        return Database.query(queryString);            
    }
}
