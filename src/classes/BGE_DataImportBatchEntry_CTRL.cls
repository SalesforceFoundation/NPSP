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
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Lightning Component Server Controller for the Data Import Batch Entry component.
*/

public with sharing class BGE_DataImportBatchEntry_CTRL {

    /*******************************************************************************************************
    * @description deletes DataImport__c record
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
        dataImportModel.isNamespaced = String.isNotBlank(UTIL_Namespace.getNamespace());

        return JSON.serialize(dataImportModel);
    }

    @AuraEnabled
    public static List<DataImportRow> updateDataImports(List<DataImport__c> dataImports, Id batchId) {
        Database.update(dataImports);

        return getDataImports(batchId);
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
            List<DataImport__c> dataImports = getDataImportsByBatchId(batchId);
            for (DataImport__c dataImportRecord : dataImports) {
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

        Map<String, String> labels = new Map<String, String> {
                'accountObject' => Schema.SObjectType.Account.getLabel(),
                'accountLookup' => Schema.SObjectType.DataImport__c.fields.Account1Imported__c.getName(),
                'batchIdField' => Schema.SObjectType.DataImport__c.fields.NPSP_Data_Import_Batch__c.getName(),
                'contactLookup' => Schema.SObjectType.DataImport__c.fields.Contact1Imported__c.getName(),
                'contactObject' => Schema.SObjectType.Contact.getLabel(),
                'dataImportObject' => Schema.SObjectType.DataImport__c.getName(),
                'donationDonor' => Schema.SObjectType.DataImport__c.fields.Donation_Donor__c.getName(),
                'donationAmountField' => Schema.SObjectType.DataImport__c.fields.Donation_Amount__c.getName(),
                'expectedCountField' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Count_of_Gifts__c.getName(),
                'expectedTotalField' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Total_Batch_Amount__c.getName(),
                'noDataImportsFound' => String.format(Label.stgNoObjectsFound, new List<String>{Schema.SObjectType.DataImport__c.getName()})
        };

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
                col.readOnly = false;
                col.type = dfr.type.name().toLowerCase();
                if (col.type == 'date') {
                    col.type = 'date-local';
                }
                col.typeAttributes = new Map<String, Map<String, String>>();

                columns.add(col);
            }
        }

        //add derived matched record column
        Column col = new Column();
        Map<String, Map<String, String>> typeAttributes = new Map<String, Map<String, String>>();
        typeAttributes.put('label', new Map<String, String>{'fieldName' => 'matchedRecordLabel'});

        col.label = 'Matched Record';
        col.fieldName = 'matchedRecordUrl';
        col.readOnly = true;
        col.type = 'url';
        col.typeAttributes = typeAttributes;
        columns.add(col);

        return columns;
    }

    /*******************************************************************************************************
    * @description runs BDI Dry Run against a list of DataImport__c Ids
    * based on the processing settings of a given batch
    * @return the full data set for the batch
    */
    @AuraEnabled
    public static List<DataImportRow> runDryRun(List<Id> dataImportIds, Id batchId) {
        Data_Import_Settings__c dataImportSettings = BDI_DataImportService.loadSettings(batchId);
        Set<Id> recordIds = new Set<Id>(dataImportIds);
        List<DataImport__c> dataImportRecords = getDataImportsByIds(recordIds);

        // Clear Dry Run fields before running Dry Run so new field values are accounted for
        for (DataImport__c dataImport : dataImportRecords) {
            dataImport.Status__c = null;
            dataImport.FailureInformation__c = null;
            dataImport.DonationImported__c = null;
            dataImport.DonationImportStatus__c = null;
        }
        update dataImportRecords;

        BDI_DataImport_API.processDataImportRecords(dataImportSettings, dataImportRecords, true);
        
        return getDataImports(batchId);
    }

    /*******************************************************************************************************
    * @description returns a list of DataImport__c records from a batch Id
    * @param batchId a Data Import Batch Id
    * @return List<DataImport__c>
    */
    public static List<DataImport__c> getDataImportsByBatchId(Id batchId) {
        List<String> dataImportFields = getDataImportFields();

        String query = 'SELECT ' + String.join(dataImportFields,', ') +
                ' FROM DataImport__c' +
                ' WHERE NPSP_Data_Import_Batch__c = :batchId' +
                ' ORDER BY Id ASC';

        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description returns a list of DataImport__c records from a set of Ids
    * @param dataImportIds set of DataImport__c Ids
    * @return List<DataImport__c>
    */
    public static List<DataImport__c> getDataImportsByIds(Set<Id> dataImportIds) {
        List<String> dataImportFields = getDataImportFields();

        String query = 'SELECT ' + String.join(dataImportFields,', ') +
                ' FROM DataImport__c' +
                ' WHERE Id IN :dataImportIds' +
                ' ORDER BY Id ASC';

        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description returns a list of DataImport__c fields the Batch Gift Entry  UI needs in SOQL
    * @return List<String> list of DataImport__c field api names
    */
    public static List<String> getDataImportFields() {
        List<String> fields = new List<String> {
                'Id',
                'Contact1_Firstname__c',
                'Contact1_Lastname__c',
                'Contact1Imported__c',
                'Contact1Imported__r.FirstName',
                'Contact1Imported__r.LastName',
                'Contact1Imported__r.Name',
                'Account1Imported__c',
                'Account1Imported__r.Name',
                'NPSP_Data_Import_Batch__c',
                'Donation_Donor__c',
                'Donation_Amount__c',
                'Donation_Date__c',
                'Payment_Method__c',
                'Payment_Check_Reference_Number__c',
                'DonationImported__c',
                'Status__c',
                'FailureInformation__c',
                'DonationImportStatus__c',
                'PaymentImportStatus__c',
                'PaymentImported__c',
                'PaymentImported__r.Name',
                'DonationImported__r.Name'
        };
        return fields;
    }

    /*******************************************************************************************************
    * @description a class to retrieve information related to Active and Available fields.
    */
    public class Column {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean readOnly;
        @AuraEnabled public String type;
        @AuraEnabled public Map<String, Map<String, String>> typeAttributes;
    }

    /*******************************************************************************************************
    * @description a class to retrieve and save the required information for the Batch Data Import component.
    */
    public class DataImportModel {
        @AuraEnabled public Id id;
        @AuraEnabled public List<DataImportRow> dataImportRows;
        @AuraEnabled public List<Column> columns;
        @AuraEnabled public Boolean isNamespaced;
        @AuraEnabled public Map<String, String> labels;
    }

    /*******************************************************************************************************
    * @description a class to retrieve DataImport__c records with derived donor information.
    */
    public class DataImportRow {
        @AuraEnabled public String donor;
        @AuraEnabled public String matchedRecordUrl;
        @AuraEnabled public String matchedRecordLabel;
        @AuraEnabled public DataImport__c record;
        @AuraEnabled public List<String> errors;

        public DataImportRow(DataImport__c record) {
            donor = setDonorName(record);
            setDryRunRecordInfo(record);
            this.record = record;
        }

        private String setDonorName(DataImport__c record) {
            String donorName = '';
            if (record.Donation_Donor__c == 'Account1' && record.Account1Imported__c != null) {
                donorName = record.Account1Imported__r.Name;
            } 
            if (record.Donation_Donor__c == 'Contact1' && record.Contact1Imported__c != null) {
                donorName = record.Contact1Imported__r.Name;
            }
            return donorName;
        }

        /***************************************************************************************************
        * @description sets DataImport__c record with matching url or failure information matching based on
        * the BDI_Donations setDryRunDonationStatuses
        * @param record: the DataImport__c record to check for matches
        */
        private void setDryRunRecordInfo(DataImport__c record) {
            try {
                String matchedUrl = '';
                String matchedUrlLabel = '';
                List<String> errors = new List<String>();

                Boolean donationMatched = (record.DonationImportStatus__c == Label.bdiDryRunMatched ||
                        record.DonationImportStatus__c == Label.bdiDryRunMatchedBest ||
                        record.DonationImportStatus__c == Label.bdiDryRunMatchedId);
                Boolean paymentMatched = (record.PaymentImportStatus__c == Label.bdiDryRunMatched ||
                        record.PaymentImportStatus__c == Label.bdiDryRunMatchedBest ||
                        record.PaymentImportStatus__c == Label.bdiDryRunMatchedId);
                Boolean importFailure = record.FailureInformation__c != null;

                if (paymentMatched) {
                    //if there is a match, set url, preferably for the payment
                    String importedId = record.PaymentImported__c != null ? record.PaymentImported__c : '';
                    matchedUrlLabel = record.PaymentImported__c != null && record.PaymentImported__r != null ? record.PaymentImported__r.Name : '';
                    matchedUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + importedId;
                } else if (donationMatched) {
                    String importedId = record.DonationImported__c != null ? record.DonationImported__c : '';
                    matchedUrlLabel = record.DonationImported__c != null && record.DonationImported__r != null ? record.DonationImported__r.Name : '';
                    matchedUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + importedId;
                }

                if (importFailure) {

                    //if Donation and Payment didn't have matched or matched none status, then an error was set
                    if (record.DonationImportStatus__c != Label.bdiMatchedNone
                            && record.DonationImportStatus__c != null
                            && !donationMatched) {
                        errors.add(record.DonationImportStatus__c);
                    }
                    if (record.PaymentImportStatus__c != Label.bdiMatchedNone
                            && record.PaymentImportStatus__c != null
                            && !paymentMatched
                            && record.PaymentImportStatus__c != record.DonationImportStatus__c) {
                        errors.add(record.PaymentImportStatus__c);
                    }

                    //get any additional errors
                    if (record.FailureInformation__c != record.PaymentImportStatus__c
                            && record.FailureInformation__c != record.DonationImportStatus__c) {
                        errors.add(record.FailureInformation__c);
                    }
                }

                this.matchedRecordUrl = matchedUrl;
                this.matchedRecordLabel = matchedUrlLabel;
                this.errors = errors;

            }
            catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }



        }
    }
}