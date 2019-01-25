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
    * @description The number of additional Data Import Batches to load on each infinite scroll query
    */
    private static Integer loadSize = 50;

    /*******************************************************************************************************
    * @description Gets Data Import Batch data to populate datatable on BGE Batch Gift Entry Tab
    * @return String JSON serialized TabModel
    */
    @AuraEnabled
    public static String getTableModel() {
        if (UTIL_Permissions.canRead(UTIL_Namespace.StrTokenNSPrefix('DataImportBatch__c'), false)) {
            TableModel model = new TableModel();
            model.columns = getTableColumns();
            model.batches = getBatches(0, 'CreatedDate', 'DESC');
            model.totalNumberOfRows = getTotalNumberOfRows();
            return JSON.serialize(model);
        } else {
            throw new AuraHandledException(Label.bgeFLSError);
        }
    }

    /*******************************************************************************************************
    * @description Starts over with initial load based on re-sorted data table
    * @return String JSON serialized TabModel
    */
    @AuraEnabled
    public static String getSortedData(Integer offset, String sortBy, String sortDirection) {
        TableModel model = new TableModel();
        model.batches = getBatches(offset, sortBy, sortDirection);
        model.totalNumberOfRows = getTotalNumberOfRows();
        return JSON.serialize(model);
    }

    /*******************************************************************************************************
    * @description Gets columns to create datatable on BGE Batch Gift Entry Tab
    * @return List<Column> list of columns for datatable
    */
    public static List<Column> getTableColumns() {

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
    * @description Gets Data Import Batch data to populate datatable on BGE Batch Gift Entry Tab
    * @param offset the number of records to offset by
    * @return List<DataImportBatch__c> list of Data Import Batches
    */
    public static List<DataImportBatch__c> getBatches(Integer offset, String sortBy, String sortDirection) {
        List<String> fields = getDataTableColumnFieldNames();
        List<DataImportBatch__c> batches = new List<DataImportBatch__c>();

        // ensure Name, CreatedDate, Id, and user lookups are included but not duplicated from user input in field set
        fields.add('Name');
        fields.add('CreatedDate');
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
                ' ORDER BY ' + sortBy + ' ' + sortDirection +
                ' LIMIT ' + loadSize +
                ' OFFSET ' + offset;
        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description Gets the count of Data Import Batch records where GiftBatch=true and accessible to user
    * @return Integer count of batch records
    */
    private static Integer getTotalNumberOfRows() {
        return [SELECT Count() FROM DataImportBatch__c WHERE GiftBatch__c = TRUE];
    }

    /*******************************************************************************************************
    * @description Gets Data Import Batch fields for datatable columns on BGE Batch Gift Entry Tab
    * @return List<String> list of Data Import Batch field api names
    */
    public static List<String> getDataTableColumnFieldNames() {
        List<String> fieldNames =
                UTIL_Describe.listStrFromFieldSet(
                        UTIL_Namespace.StrTokenNSPrefix('DataImportBatch__c'),
                        UTIL_Namespace.StrTokenNSPrefix('BatchGiftEntryTabDataTableColumns')
                );
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
    public class TableModel {
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