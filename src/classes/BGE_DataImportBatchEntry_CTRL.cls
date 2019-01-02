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
    * @description Checks for field permissions to create a new Batch
    * @return void; throws an AuraHandledException if any fields fail FLS check
    */
    @AuraEnabled
    public static void checkFieldPermissions() {
        BGE_BatchGiftEntry_UTIL.checkFieldPermissionsNeededForBatch();
    }

    /*******************************************************************************************************
    * @description deletes DataImport__c record
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @param dataImportId: ID of the DataImport__c
    * @return serialized string of DataImportRow for use in the lightning:datatable
    */
    @AuraEnabled
    public static String deleteDataImportRow(Id batchId, Id dataImportId) {
        delete new DataImport__c(Id = dataImportId);
        return JSON.serialize(getDataImportRows(batchId));
    }

    /*******************************************************************************************************
    * @description initializes the data model for the BGE_DataImportBatchEntry component
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @return serialized string of dataImportModel
    */
    @AuraEnabled
    public static String getDataImportModel(Id batchId) {

        if (batchId == null) {
            throw new AuraHandledException('Data Import Model must receive a Batch ID.');
        }

        DataImportModel dataImportModel = new DataImportModel();

        dataImportModel.id = batchId;
        dataImportModel.dataImportRows = getDataImportRows(batchId);
        dataImportModel.columns = getColumns(batchId);
        dataImportModel.labels = getBatchDataImportLabels();
        dataImportModel.isNamespaced = String.isNotBlank(UTIL_Namespace.getNamespace());

        return JSON.serialize(dataImportModel);
    }

    @AuraEnabled
    public static List<DataImportRow> updateDataImports(List<DataImport__c> dataImports, Id batchId) {
        Database.update(dataImports);

        return getDataImportRows(batchId);
    }

    /*******************************************************************************************************
    * @description queries the DataImport__c records associated with the given batchId
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @return list of custom DataImportRow objects for use in the lightning:datatable
    */
    @AuraEnabled
    public static List<DataImportRow> getDataImportRows(Id batchId){

        try {
            List<DataImportRow> rows = new List<DataImportRow>();
            List<DataImport__c> dataImports = getDataImportRecordsByBatchId(batchId);
            for (DataImport__c dataImportRecord : dataImports) {
                rows.add(new DataImportRow(dataImportRecord));
            }

            return rows;
        }
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description Retrieves all open Opportunities and unpaid Payments for the selected Donor (Account or Contact)
    * @return JSON stringified Map<String, List<SObject>> of all openOpportunities and unpaidPayments for the given donor
    */
    @AuraEnabled
    public static String getOpenDonations(Id donorId, String donorType) {
        String relationshipField;
        if (donorType == 'Account1') {
            relationshipField = 'AccountId';
        } else if (donorType == 'Contact1') {
            relationshipField = 'Primary_Contact__c';
        }

        String opportunitySOQL = 'SELECT Id, ' +
                                'Name, ' +
                                'StageName, ' +
                                'Amount ' +
                                'FROM Opportunity ' +
                                'WHERE ' + relationshipField + ' = :donorId ' +
                                'AND IsClosed = false';

        String paymentSOQL = 'SELECT Id, ' +
                                'Name, ' +
                                'npe01__Scheduled_Date__c, ' +
                                'npe01__Opportunity__r.Name, ' +
                                'npe01__Opportunity__c, ' +
                                'npe01__Payment_Amount__c ' +
                                'FROM npe01__OppPayment__c ' +
                                'WHERE npe01__Opportunity__r.' + relationshipField + ' = :donorId ' +
                                'AND npe01__Paid__c = false';

        try {
            List<Opportunity> openOpportunities = Database.query(opportunitySOQL);
            List<npe01__OppPayment__c> unpaidPayments = Database.query(paymentSOQL);

            Map<Id, Opportunity> openOpportunitiesById = new Map<Id, Opportunity>(openOpportunities);

            // openOpportunities should only include opps with NO UNPAID PAYMENTS for BDI to process donations correctly
            for (npe01__OppPayment__c payment : unpaidPayments) {
                Id idOfCurrentOpportunity = payment.npe01__Opportunity__c;
                if (openOpportunitiesById.containsKey(idOfCurrentOpportunity)) {
                    openOpportunitiesById.remove(idOfCurrentOpportunity);
                }
            }

            Map<String, List<SObject>> response = new Map<String, List<SObject>>{
                'openOpportunities' => openOpportunitiesById.values(),
                'unpaidPayments' => unpaidPayments
            };
            return JSON.serialize(response);
        } catch (Exception ex){
            throw new AuraHandledException('ERROR: ' + ex.getMessage());
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
            'bdiBatchClass' => UTIL_Namespace.StrTokenNSPrefix('BDI_DataImport'),
            'contactLookup' => Schema.SObjectType.DataImport__c.fields.Contact1Imported__c.getName(),
            'contactObject' => Schema.SObjectType.Contact.getLabel(),
            'dataImportObject' => Schema.SObjectType.DataImport__c.getName(),
            'donationDonor' => Schema.SObjectType.DataImport__c.fields.Donation_Donor__c.getName(),
            'donationAmountField' => Schema.SObjectType.DataImport__c.fields.Donation_Amount__c.getName(),
            'expectedCountField' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Count_of_Gifts__c.getName(),
            'expectedTotalField' => Schema.SObjectType.DataImportBatch__c.fields.Expected_Total_Batch_Amount__c.getName(),
            'noDataImportsFound' => String.format(Label.stgNoObjectsFound, new List<String>{Schema.SObjectType.DataImport__c.getName()}),
            'opportunityImportedLookupField' => Schema.SObjectType.DataImport__c.fields.DonationImported__c.getName(),
            'opportunityImportedStatusField' => Schema.SObjectType.DataImport__c.fields.DonationImportStatus__c.getName(),
            'opportunityAmount' => Schema.SObjectType.Opportunity.fields.Amount.getLabel(),
            'opportunityObject' => Schema.SObjectType.Opportunity.getLabel(),
            'opportunityName' => Schema.SObjectType.Opportunity.getLabel(),
            'opportunityStage' => Schema.SObjectType.Opportunity.fields.StageName.getLabel(),
            'paymentAmount' => Schema.SObjectType.npe01__OppPayment__c.fields.npe01__Payment_Amount__c.getLabel(),
            'paymentObject' => Schema.SObjectType.npe01__OppPayment__c.getLabel(),
            'paymentScheduledDate' => Schema.SObjectType.npe01__OppPayment__c.fields.npe01__Scheduled_Date__c.getLabel(),
            'paymentImportedLookupField' => Schema.SObjectType.DataImport__c.fields.PaymentImported__c.getName(),
            'paymentImportedStatusField' => Schema.SObjectType.DataImport__c.fields.PaymentImportStatus__c.getName(),
            'requireTotalMatch' => Schema.SObjectType.DataImportBatch__c.fields.RequireTotalMatch__c.getName()
        };

        return labels;
    }

    /*******************************************************************************************************
    * @description Retrieves the related list of columns for the BGE interface
    * @return list of Columns to use in BGE_DataImportBatchEntry table
    */
    private static List<Column> getColumns(Id batchId) {
        List<Column> columns = new List<Column>();

        columns.addAll(getUserDefinedColumns(batchId));

        //add derived matched record column
        Column linkCol = new Column();
        linkCol.label = Label.bdiDonation;
        linkCol.fieldName = 'matchedRecordUrl';
        linkCol.readOnly = true;
        linkCol.type = 'url';
        linkCol.typeAttributes = '{"label":{"fieldName":"matchedRecordLabel"},"target":"_blank"}';
        columns.add(linkCol);

        //status of the DI record
        Column statusCol = new Column();
        statusCol.label = Schema.SObjectType.DataImport__c.fields.Status__c.getLabel();
        statusCol.fieldName = 'Status__c';
        statusCol.readOnly = true;
        statusCol.type = 'text';
        columns.add(statusCol);

        return columns;
    }

    /*******************************************************************************************************
    * @description Retrieves the related list of columns defined by users in the Batch record Active_Fields__c
    * @return list of Columns to use in BGE_DataImportBatchEntry table
    */
    private static List<Column> getUserDefinedColumns(Id batchId) {
        List<Column> columns = new List<Column>();

        DataImportBatch__c batch = [SELECT Active_Fields__c FROM DataImportBatch__c WHERE Id = :batchId];
        String activeFieldsJSON = batch.Active_Fields__c;
        if (activeFieldsJSON != null) {
            List<BGE_ConfigurationWizard_CTRL.BGEField> activeFields = (List<BGE_ConfigurationWizard_CTRL.BGEField>)JSON.deserialize(activeFieldsJSON, List<BGE_ConfigurationWizard_CTRL.BGEField>.class);

            Map<String, Schema.DescribeFieldResult> fieldMap = UTIL_Describe.getAllFieldsDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'));
            for (BGE_ConfigurationWizard_CTRL.BGEField field : activeFields) {
                Schema.DescribeFieldResult dataImportDFR = fieldMap.get(field.name.toLowerCase());
                if (dataImportDFR != null) {

                    checkFLS(dataImportDFR);

                    Column col = new Column();
                    col.label = dataImportDFR.getLabel();
                    col.fieldName = dataImportDFR.getName();
                    col.readOnly = false;
                    col.defaultValue = field.defaultValue;
                    col.required = field.required;
                    col.hide = field.hide;
                    col.type = dataImportDFR.getType().name().toLowerCase();
                    if (col.type == 'date') {
                        col.type = 'date-local';
                    }
                    if (col.type == 'double') {
                        col.type = 'number';
                    }
                    col.typeAttributes = '{}';

                    col.options = BGE_ConfigurationWizard_CTRL.getPicklistOptions(col.fieldName);

                    columns.add(col);

                    String targetObject = BDI_DataImportService.getTargetObject(col.fieldName);
                    if (targetObject == 'Payment') {
                        targetObject = 'npe01__OppPayment__c';
                    }
                    String targetField = BDI_DataImportService.getTargetField(col.fieldName);
                    DescribeFieldResult targetDFR = UTIL_Describe.getFieldDescribe(targetObject,targetField);

                    checkFLS(targetDFR);

                }
            }
        }

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
        List<DataImport__c> dataImportRecords = getDataImportRecordsByIds(batchId, recordIds);

        // Skip records where user has explicitly selected a matching record in BGE UI
        for (DataImport__c dataImport : dataImportRecords) {
            if (dataImport.DonationImportStatus__c == Label.bdiMatchedByUser
                || dataImport.DonationImportStatus__c == Label.bdiMatchedByUserNewOpp
                || dataImport.DonationImportStatus__c == Label.bdiMatchedApplyNewPayment) {
                // User defined match, so we do nothing and retain the values
            } else {
                // Clear Dry Run fields before running Dry Run so new field values are accounted for
                dataImport.Status__c = null;
                dataImport.FailureInformation__c = null;
                dataImport.DonationImported__c = null;
                dataImport.DonationImportStatus__c = null;
                dataImport.PaymentImported__c = null;
                dataImport.PaymentImportStatus__c = null;
            }
        }

        update dataImportRecords;

        if (dataImportRecords.size() > 0){
            BDI_DataImport_API.processDataImportRecords(dataImportSettings, dataImportRecords, true);
        }

        return getDataImportRows(batchId);
    }

    /*******************************************************************************************************
    * @description returns a list of DataImport__c records from a batch Id
    * @param batchId a Data Import Batch Id
    * @return List<DataImport__c>
    */
    public static List<DataImport__c> getDataImportRecordsByBatchId(Id batchId) {

        List<String> dataImportFields = BGE_BatchGiftEntry_UTIL.getDataImportFields(batchId);

        String query = 'SELECT ' + String.join(dataImportFields,', ') +
            ' FROM DataImport__c' +
            ' WHERE NPSP_Data_Import_Batch__c = :batchId' +
            ' ORDER BY CreatedDate ASC';

        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description returns a list of DataImport__c records from a set of Ids
    * @param dataImportIds set of DataImport__c Ids
    * @return List<DataImport__c>
    */
    public static List<DataImport__c> getDataImportRecordsByIds(Id batchId, Set<Id> dataImportIds) {

        List<String> dataImportFields = BGE_BatchGiftEntry_UTIL.getDataImportFields(batchId);

        String query = 'SELECT ' + String.join(dataImportFields,', ') +
            ' FROM DataImport__c' +
            ' WHERE Id IN :dataImportIds' +
            ' ORDER BY CreatedDate ASC';

        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description checks for read, create, and edit FLS for a given field
    * @param dfr DescribeFieldResult of the field to check
    * @return void, throws AuraHandledException to display UI error
    */
    private static void checkFLS(DescribeFieldResult dfr) {
        if (!dfr.isCreateable() || !dfr.isUpdateable()) {
            throw new AuraHandledException(label.bgeFLSError);
        }
    }

    /*******************************************************************************************************
    * @description a class to retrieve information related to Active and Available fields.
    */
    public class Column {
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public Boolean readOnly;
        @AuraEnabled public String type;
        @AuraEnabled public String defaultValue;
        @AuraEnabled public Boolean required;
        @AuraEnabled public Boolean hide;
        @AuraEnabled public String typeAttributes;
        @AuraEnabled public List<Map<String, String>> options;
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
        @AuraEnabled public String donorName;
        @AuraEnabled public String donorLink;
        @AuraEnabled public String matchedRecordUrl;
        @AuraEnabled public String matchedRecordLabel;
        @AuraEnabled public DataImport__c record;
        @AuraEnabled public List<String> errors;

        public DataImportRow(DataImport__c record) {
            getDonorInfo(record);
            setDryRunRecordInfo(record);
            this.record = record;
        }

        private void getDonorInfo(DataImport__c record) {
            String donorName = '';
            if (record.Donation_Donor__c == 'Account1' && record.Account1Imported__c != null) {
                this.donorName = record.Account1Imported__r.Name;
                this.donorLink = '/'+record.Account1Imported__c;
            }
            if (record.Donation_Donor__c == 'Contact1' && record.Contact1Imported__c != null) {
                this.donorName = record.Contact1Imported__r.Name;
                this.donorLink = '/'+record.Contact1Imported__c;
            }
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

                Boolean donationMatched = (record.DonationImported__c != null);
                Boolean paymentMatched = (record.PaymentImported__c != null);
                Boolean importFailure = (record.FailureInformation__c != null);

                if (paymentMatched) {
                    //if there is a match, set url, preferably for the payment
                    String importedId = record.PaymentImported__c;
                    matchedUrlLabel = record.PaymentImported__r.Name;
                    matchedUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + importedId;
                } else if (donationMatched) {
                    String importedId = record.DonationImported__c;
                    matchedUrlLabel = record.DonationImported__r.Name;
                    matchedUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/' + importedId;
                }

                if (importFailure) {

                    //if Donation and Payment didn't have matched or matched none status, then an error was set
                    if (record.DonationImportStatus__c != null
                            && !donationMatched) {
                        errors.add(record.DonationImportStatus__c);
                    }
                    if (record.PaymentImportStatus__c != null
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