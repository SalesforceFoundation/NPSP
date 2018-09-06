/*
    Copyright (c) 2018, Salesforce.org
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
* @date 2018
* @group BGE
* @group-content //todo
* @description Lightning Component Server Controller for the Data Import Batch Entry component.
*/

public with sharing class BGE_DataImportBatchEntry_CTRL {

    /*******************************************************************************************************
    * @description deletes data DataImport__c record
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @param dataImportId: ID of the DataImport__c
    * @return serialized string of DataImportRow for use in the lightning:datatable
    */
    @AuraEnabled
    public static String deleteDataImportRow(Id batchId, Id dataImportId) {
        delete new DataImport__c(Id = dataImportId);
        return JSON.serialize(getDataImports(batchId));
    }

    /*******************************************************************************************************
    * @description initializes the data model for the BGE_DataImportBatchEntry component
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @return serialized string of dataImportModel
    */
    @AuraEnabled
    public static String getDataImportModel(Id batchId){

        DataImportModel dataImportModel = new DataImportModel();

        dataImportModel.id = batchId;
        dataImportModel.dataImportRows = getDataImports(batchId);
        dataImportModel.columns = getColumns();
        dataImportModel.labels = getBatchDataImportLabels();

        return JSON.serialize(dataImportModel);
    }

    @AuraEnabled
    public static void updateDataImports(List<DataImport__c> diList) {
        database.update(diList);
    }

    /*******************************************************************************************************
    * @description queries the DataImport__c records associated with the given batchId
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @return list of custom DataImportRow objects for use in the lightning:datatable
    */
    @AuraEnabled
    public static List<DataImportRow> getDataImports(Id batchId){

        try {
            List<DataImportRow> result = new List<DataImportRow>();
            for (DataImport__c dataImportRecord :[SELECT Id
                    , Name
                    , Contact1_Firstname__c
                    , Contact1_Lastname__c
                    , Contact1Imported__c
                    , Contact1Imported__r.FirstName
                    , Contact1Imported__r.LastName
                    , Account1Imported__c
                    , Account1Imported__r.Name
                    , Donation_Date__c
                    , Donation_Amount__c
                    , Donation_Donor__c
                    , Payment_Method__c
                    , Payment_Check_Reference_Number__c
            FROM DataImport__c
            WHERE NPSP_Data_Import_Batch__c = :batchId
            ORDER BY Id ASC]) {
                result.add(new DataImportRow(dataImportRecord));
            }

            return result;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description Retrieves required schema information for the component.
    * @return Map of DataImport__c object and field name keys to their labels.
    */
    private static Map<String, String> getBatchDataImportLabels() {

        //todo: can Schema.SObjectType.DataImport__c.fields just be in a variable?

        Map<String, String> labels = new Map<String, String> {
                'accountLookup' => Schema.SObjectType.DataImport__c.fields.Account1Imported__c.getName(),
                'batchIdField' => Schema.SObjectType.DataImport__c.fields.NPSP_Data_Import_Batch__c.getName(),
                'contactLookup' => Schema.SObjectType.DataImport__c.fields.Contact1Imported__c.getName(),
                'dataImportObject' => Schema.SObjectType.DataImport__c.getName(),
                'donationDonor' => Schema.SObjectType.DataImport__c.fields.Donation_Donor__c.getName(),
                'donationAmountField' => Schema.SObjectType.DataImport__c.fields.Donation_Amount__c.getName(),
                'expectedCountField' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Count_of_Gifts__c.getName(),
                'expectedTotalField' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Total_Batch_Amount__c.getName()
        };

        labels.put('forceRecordDataFields', labels.get('expectedCountField') + ',' + labels.get('expectedTotalField'));

        return labels;
    }

    /*******************************************************************************************************
    * @description Retrieves the related list of columns for DataImport__c from a specified list (currently hardcoded)
    * @return list of Columns to use in BGE_DataImportBatchEntry table
    */
    private static List<Column> getColumns() {
        List<Column> columns = new List<Column>();
        List<String> fields = new List<String>{
            'Donation_Amount__c',
            'Donation_Date__c',
            'Payment_Method__c',
            'Payment_Check_Reference_Number__c'
        };

        Map<String, Schema.DescribeFieldResult> fieldMap = UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'));
        for (String field : fields) {
            String namespacedField = UTIL_Namespace.StrTokenNSPrefix(field);
            Schema.DescribeFieldResult dfr = fieldMap.get(namespacedField.toLowerCase());
            if (dfr != null) {
                Column col = new Column();
                col.label = dfr.label;
                col.fieldName = dfr.name;
                col.editable = true;
                col.type = dfr.type.name().toLowerCase();
                if (col.type == 'date') {
                    col.type = 'date-local';
                }

                columns.add(col);
            }
        }
            

        return columns;
    }

    /*******************************************************************************************************
    * @description a class to retrieve information related to Active and Available fields.
    */
    public class Column {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean editable;
        @AuraEnabled public String type;
    }

    /*******************************************************************************************************
    * @description a class to retrieve and save the required information for the Batch Data Import component.
    */
    public class DataImportModel {
        @AuraEnabled public Id id;
        @AuraEnabled public List<DataImportRow> dataImportRows;
        @AuraEnabled public List<Column> columns;
        @AuraEnabled public Map<String, String> labels;
    }

    /*******************************************************************************************************
    * @description a class to retrieve DataImport__c records with derived donor information.
    */
    public class DataImportRow {
        @AuraEnabled public String donor;
        @AuraEnabled public DataImport__c record;

        public DataImportRow(DataImport__c record) {
            donor = getDonorName(record);
            this.record = record;
        }

        private String getDonorName(DataImport__c record) {
            String donorName = '';
            if (record.Donation_Donor__c == 'Account1' && record.Account1Imported__c != null) {
                donorName = record.Account1Imported__r.Name;

            } 
            if (record.Donation_Donor__c == 'Contact1' && record.Contact1Imported__c != null) {
                donorName = record.Contact1Imported__r.FirstName + ' ' + record.Contact1Imported__r.LastName;
            }
            return donorName;
        }
    }
}