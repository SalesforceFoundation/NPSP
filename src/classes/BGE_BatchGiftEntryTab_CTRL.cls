/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group BGE
* @group-content
* @description BGE Tab Component Controller.
*/
public with sharing class BGE_BatchGiftEntryTab_CTRL {

    /*******************************************************************************************************
    * @description Gets Data Import Batch data to populate datatable on BGE Batch Gift Entry Tab
    * @return List<DataImportBatch__c> list of Data Import Batches
    */
    @AuraEnabled
    public static String getTabModel() {
        if (UTIL_Permissions.canRead(UTIL_Namespace.StrTokenNSPrefix('DataImportBatch__c'), false)) {
            TabModel model = new TabModel();
            model.columns = getTabColumns();
            model.batches = getInitialBatches();
            model.totalNumberOfRows = [SELECT Count() FROM DataImportBatch__c WHERE GiftBatch__c = TRUE];
            return JSON.serialize(model);
        } else {
            throw new AuraHandledException(Label.bgeFLSError);
        }
    }

    /*******************************************************************************************************
    * @description Gets columns to create datatable on BGE Batch Gift Entry Tab
    * @return List<Column> list of columns for datatable
    */
    public static List<Column> getTabColumns() {

        Set<String> disallowedFields = new Set<String>{
                'Name',
                UTIL_Namespace.StrTokenNSPrefix('Active_Fields__c')
        };

        List<String> fieldNames = getDataTableColumnFieldNames();
        List<Column> columns = new List<Column>();

        Column batchLinkCol = new Column();
        batchLinkCol.label = UTIL_Describe.getFieldLabel(UTIL_Namespace.StrTokenNSPrefix('DataImportBatch__c'), 'Name');
        batchLinkCol.fieldName = 'batchLink';
        batchLinkCol.sortable = true;
        batchLinkCol.type = 'url';
        columns.add(batchLinkCol);

        for (String fieldName : fieldNames) {
            if (!disallowedFields.contains(fieldName)) {
                DescribeFieldResult dfr = UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImportBatch__c'), fieldName);
                String dataType = dfr.getType().name().toLowerCase();
                Column col = new Column();
                col.fieldName = fieldName;
                col.label = dfr.label;
                col.type = UTIL_LightningComponentSupport.getLightningDataType(dfr.getType().name());
                col.sortable = col.type == 'textarea' ? false : true;

                // special case for known User lookups
                if (dataType == 'reference') {
                    col.type = UTIL_LightningComponentSupport.getLightningDataType('string');
                    col.label = UTIL_Describe.getUserReferenceFieldLabel(dfr);
                }

                columns.add(col);
            }
        }
        return columns;
    }

    /*******************************************************************************************************
    * @description Gets initial set of Data Import Batch data to populate datatable on BGE Batch Gift Entry Tab
    * @return List<DataImportBatch__c> list of Data Import Batches
    */
    public static List<DataImportBatch__c> getInitialBatches() {
        return getBatches(50, 0);
    }

    /*******************************************************************************************************
    * @description Gets Data Import Batch data to populate datatable on BGE Batch Gift Entry Tab
    * @param queryAmount the number of new records to query
    * @param offset the number of records to offset by
    * @return List<DataImportBatch__c> list of Data Import Batches
    */
    @AuraEnabled
    public static List<DataImportBatch__c> getBatches(Integer queryAmount, Integer offset) {

        List<String> fields = getDataTableColumnFieldNames();
        List<DataImportBatch__c> batches = new List<DataImportBatch__c>();

        // ensure Name and Id are included but not duplicated from user input in field set
        fields.add('Name');
        fields.add('Id');
        fields.add('CreatedBy.Name');
        fields.add('LastModifiedBy.Name');
        fields.add('Owner.Name');
        Set<String> deduplicatedFields = new Set<String>(fields);
        List<String> finalFields = new List<String>(deduplicatedFields);

        String query = 'SELECT ' +
                String.join(finalFields, ', ') +
                ' FROM ' + UTIL_Namespace.StrTokenNSPrefix('DataImportBatch__c') +
                ' WHERE GiftBatch__c = TRUE' +
                ' LIMIT ' + queryAmount +
                ' OFFSET ' + offset;
        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description Gets Data Import Batch fields for datatable columns on BGE Batch Gift Entry Tab
    * @return List<String> list of Data Import Batch field api names
    */
    public static List<String> getDataTableColumnFieldNames() {
        List<String> fieldNames = UTIL_Describe.listStrFromFieldSet(UTIL_Namespace.StrTokenNSPrefix('DataImportBatch__c'), UTIL_Namespace.StrTokenNSPrefix('BatchGiftEntryTabDataTableColumns'));
        for (Integer i=0; i<fieldNames.size(); i++) {
            if (!UTIL_Permissions.canRead(UTIL_Namespace.StrTokenNSPrefix('DataImportBatch__c'), fieldNames[i], false)) {
                fieldNames.remove(i);
            }
        }
        return fieldNames;
    }

    /*******************************************************************************************************
    * @description Checks for field permissions to create a new Batch/Template
    * @return void; throws an AuraHandledException if any fields fail FLS check
    */
    @AuraEnabled
    public static void checkFieldPermissions() {
        BGE_BatchGiftEntry_UTIL.checkFieldPermissionsNeededForBatch();
    }

    /*******************************************************************************************************
    * @description a class to retrieve info for BGE_BatchGiftEntryTab component
    */
    public class TabModel {
        @AuraEnabled public List<DataImportBatch__c> batches;
        @AuraEnabled public List<Column> columns;
        @AuraEnabled public Integer totalNumberOfRows;
    }

    /*******************************************************************************************************
    * @description a class to retrieve column info for datatable
    */
    public class Column {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean readOnly;
        @AuraEnabled public Boolean sortable;
        @AuraEnabled public String type;
    }

}