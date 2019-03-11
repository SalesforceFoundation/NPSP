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
* @group-content ../../ApexDocContent/BatchDataImport.htm
* @description Lightning Component Server Controller for the Data Import Batch Entry component.
*/

public with sharing class BGE_DataImportBatchEntry_CTRL {

    /*******************************************************************************************************
    * @description The number of additional Data Import Records to load on each infinite scroll query
    */
    private static Integer loadSize = 100;

    /*******************************************************************************************************
    * @description Checks for field permissions to create a new Batch
    * @return void; throws an AuraHandledException if any fields fail FLS check
    */
    @AuraEnabled
    public static void checkFieldPermissions() {
        BGE_BatchGiftEntry_UTIL.checkFieldPermissionsNeededForBatch();
    }

    /*******************************************************************************************************
    * @description deletes DataImport__c record and returns updated totals in the model
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @param dataImportId: ID of the DataImport__c
    * @return String serialized DataImportModel to update totals
    */
    @AuraEnabled
    public static String deleteDataImportRow(Id batchId, Id dataImportId) {
        try {
            delete new DataImport__c(Id = dataImportId);

            DataImportModel dataImportModel = getUpdatedTotals(batchId);
            return JSON.serialize(dataImportModel);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
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
        Integer rowOffset = 0;

        dataImportModel.id = batchId;
        dataImportModel.dataImportRows = getDataImportRows(batchId, rowOffset);
        dataImportModel.columns = getColumns(batchId);
        dataImportModel.labels = getBatchDataImportLabels();
        dataImportModel.isNamespaced = String.isNotBlank(UTIL_Namespace.getNamespace());
        dataImportModel.totalCountOfRows = getDataImportBatchTotalCount(batchId);

        AggregateResult[] aggResult = getDataImportBatchTotalAmount(batchId);
        dataImportModel.totalRowAmount = (Decimal)aggResult[0].get('amount');

        // check permissions on hard coded fields
        BGE_BatchGiftEntry_UTIL.checkFieldPermissions(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), getDataImportFields());

        return JSON.serialize(dataImportModel);
    }

    /*******************************************************************************************************
    * @description queries the DataImport__c records associated with the given batchId
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @param offset: next offset to query
    * @return list of custom DataImportRow objects for use in the lightning:datatable
    */
    @AuraEnabled
    public static List<DataImportRow> getDataImportRows(Id batchId, Integer offset){

        try {
            List<DataImportRow> rows = new List<DataImportRow>();
            List<DataImport__c> dataImports = getDataImportRecordsByBatchId(batchId, offset);
            for (DataImport__c dataImportRecord : dataImports) {
                rows.add(new DataImportRow(dataImportRecord));
            }

            return rows;
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
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
    * @description runs BDI Dry Run against a given Id based on the processing settings of a given batch
    * @param dataImportId: the NPSP_Data_Import__c record to update
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @return DataImportModel with updated data import record row and updated totals for the batch
    */
    @AuraEnabled
    public static String runDryRun(Id dataImportId, Id batchId) {
        try {
            Data_Import_Settings__c dataImportSettings = BDI_DataImportService.loadSettings(batchId);
            List<DataImport__c> dataImportListToRun = prepareDataImportForDryRun(getDataImportRecordById(batchId, dataImportId));
            BDI_DataImport_API.processDataImportRecords(dataImportSettings, dataImportListToRun, true);

            DataImportModel dataImportModel = getUpdatedTotals(batchId);
            DataImportRow processedDataImportRow = new DataImportRow(getDataImportRecordById(batchId, dataImportId));
            dataImportModel.dataImportRows = new List<DataImportRow>{
                    processedDataImportRow
            };

            return JSON.serialize(dataImportModel);
        } catch (Exception ex){
            throw new AuraHandledException('ERROR: ' + ex.getMessage());
        }
    }


    /*******************************************************************************************************
    * @description updates data import record, dry runs the record, and returns updated totals with the new row.
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @param dataImport: the NPSP_Data_Import__c record to update
    * @return String serialized DataImportModel to update totals
    */
    @AuraEnabled
    public static String updateAndDryRunRow(Id batchId, DataImport__c dataImport) {
        try {
            Database.update(dataImport);
            return runDryRun(dataImport.Id, batchId);
        } catch (Exception ex) {
            String saveErrorMessage = String.format(Label.CRLP_SaveError, new List<String>{Schema.SObjectType.DataImport__c.getName()});
            throw new AuraHandledException(saveErrorMessage + '. ' + ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description gets updated amount total and row count for the batch
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @return DataImportModel updated model with total amount and number of rows
    */
    public static DataImportModel getUpdatedTotals(Id batchId) {
        DataImportModel dataImportModel = new DataImportModel();

        dataImportModel.id = batchId;
        dataImportModel.totalCountOfRows = getDataImportBatchTotalCount(batchId);
        AggregateResult[] aggResult = getDataImportBatchTotalAmount(batchId);
        dataImportModel.totalRowAmount = (Decimal) aggResult[0].get('amount');

        return dataImportModel;
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
        statusCol.fieldName = Schema.SObjectType.DataImport__c.fields.Status__c.getName();
        statusCol.readOnly = true;
        statusCol.type = 'text';
        columns.add(statusCol);

        return columns;
    }

    /*******************************************************************************************************
    * @description Gets the sum of the amount totals of all rows for that batch
    * @param recordId the ID of the NPSP_Data_Import_Batch__c
    * @return Decimal amount
    */
    private static AggregateResult[] getDataImportBatchTotalAmount(Id recordId) {
        return [SELECT Sum(Donation_Amount__c)amount FROM DataImport__c WHERE NPSP_Data_Import_Batch__c =: recordId];
    }

    /*******************************************************************************************************
    * @description Gets the count of Data Import Batch records in a particular batch
    * @param recordId the ID of the NPSP_Data_Import_Batch__c
    * @return Integer count of batch records
    */
    private static Integer getDataImportBatchTotalCount(Id recordId) {
        return [SELECT Count() FROM DataImport__c WHERE NPSP_Data_Import_Batch__c =: recordId];
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
            List<BGE_ConfigurationWizard_CTRL.BGEField> activeFields =
                (List<BGE_ConfigurationWizard_CTRL.BGEField>)JSON.deserialize(activeFieldsJSON,
                        List<BGE_ConfigurationWizard_CTRL.BGEField>.class);

            Map<String, Schema.DescribeFieldResult> fieldMap = UTIL_Describe.getAllFieldsDescribe(
                    UTIL_Namespace.StrTokenNSPrefix('DataImport__c')
            );

            List<DescribeFieldResult> unpermittedFields = new List<DescribeFieldResult>();

            for (BGE_ConfigurationWizard_CTRL.BGEField field : activeFields) {
                Schema.DescribeFieldResult dataImportDFR = fieldMap.get(field.name.toLowerCase());
                if (dataImportDFR != null) {

                    if (UTIL_Permissions.canUpdate(dataImportDFR, false)) {
                        String targetObject = BDI_DataImportService.getTargetObject(dataImportDFR.name);
                        String targetField = BDI_DataImportService.getTargetField(dataImportDFR.name);
                        DescribeFieldResult targetDFR = UTIL_Describe.getFieldDescribe(targetObject, targetField);

                        Column col = new Column();

                        col.label = dataImportDFR.label;
                        col.fieldName = dataImportDFR.name;
                        col.defaultValue = field.defaultValue;
                        col.required = field.requiredInEntryForm;
                        col.hide = field.hide;
                        col.type = UTIL_LightningComponentSupport.getLightningDataTableDataType(dataImportDFR.type);
                        // lookups aren't editable in the grid since we don't have lookup support there
                        col.readOnly = col.type == 'reference' ? true : false;
                        col.typeAttributes = '{}';
                        col.options = BGE_BatchGiftEntry_UTIL.getPicklistOptions(col.fieldName);
                        
                        if (dataImportDFR.type == Schema.DisplayType.Reference) {
                            if (targetDFR.getReferenceTo() == dataImportDFR.getReferenceTo()) {
                                // manually construct EXTRA column for lookup link
                                Column linkCol = new Column();
                                linkCol.label = dataImportDFR.getLabel();
                                String fieldLabel = dataImportDFR.name + '_label';
                                String fieldName = dataImportDFR.name + '_link';
                                linkCol.fieldName = fieldName;
                                linkCol.readOnly = true;
                                linkCol.required = field.requiredInEntryForm;
                                linkCol.type = 'url';
                                linkCol.typeAttributes = '{"label":{"fieldName":"' + fieldLabel + '"},"target":"_blank"}';

                                columns.add(linkCol);
                                columns.add(col);
                            }
                        } else {
                            columns.add(col);
                        }

                        if (!UTIL_Permissions.canUpdate(targetDFR, false)) {
                            unpermittedFields.add(targetDFR);
                        }
                    } else {
                        unpermittedFields.add(dataImportDFR);
                    }

                }
            }

            BGE_BatchGiftEntry_UTIL.handleMissingPermissions(unpermittedFields);

        }

        return columns;
    }

    /*******************************************************************************************************
    * @description prepare the data import record for dry run by clearing certain fields or retaining them
    * based on if user has already selected a match, or if they want to let matching run. Either way, we want to use Dry Run
    * to check for potential errors.
    * @return List<DataImport__c> because BDI expects a list
    */
    private static List<DataImport__c> prepareDataImportForDryRun(DataImport__c dataImportRecord) {
        // Skip records where user has explicitly selected a matching record in BGE UI
        if (dataImportRecord.DonationImportStatus__c == Label.bdiMatchedByUser
                || dataImportRecord.DonationImportStatus__c == Label.bdiMatchedByUserNewOpp
                || dataImportRecord.DonationImportStatus__c == Label.bdiMatchedApplyNewPayment) {
            // User defined match, so we do nothing and retain the values
        } else {
            // Clear Dry Run fields before running Dry Run so new field values are accounted for
            dataImportRecord.Status__c = null;
            dataImportRecord.FailureInformation__c = null;
            dataImportRecord.DonationImported__c = null;
            dataImportRecord.DonationImportStatus__c = null;
            dataImportRecord.PaymentImported__c = null;
            dataImportRecord.PaymentImportStatus__c = null;
        }
        update dataImportRecord;

        return new List<DataImport__c>{dataImportRecord};
    }

    /*******************************************************************************************************
    * @description returns an offset list of DataImport__c records from a batch Id
    * @param batchId a Data Import Batch Id
    * @return List<DataImport__c>
    */
    private static List<DataImport__c> getDataImportRecordsByBatchId(Id batchId, Integer offset) {

        List<String> dataImportFields = getDataImportFields(batchId);

        String query = 'SELECT ' + String.join(dataImportFields,', ') +
            ' FROM DataImport__c' +
            ' WHERE NPSP_Data_Import_Batch__c = :batchId' +
            ' ORDER BY CreatedDate DESC' +
            ' LIMIT ' + loadSize +
            ' OFFSET ' + offset;
        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description returns one Data Import record by Id
    * @param dataImportId the Id to query
    * @return DataImport__c
    */
    private static DataImport__c getDataImportRecordById(Id batchId, Id dataImportId) {

        List<String> dataImportFields = getDataImportFields(batchId);

        String query = 'SELECT ' + String.join(dataImportFields,', ') +
            ' FROM DataImport__c' +
            ' WHERE Id =:dataImportId ' +
            ' LIMIT 1';

        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description returns the subset of DataImport__c fields that are part of every batch
    * @return List<String> list of DataImport__c field api names
    */
    private static List<String> getDataImportFields() {
        return new List<String> {
            'Id',
            'Account1Imported__c',
            'Account1Imported__r.Name',
            'Contact1Imported__c',
            'Contact1Imported__r.Name',
            'Donation_Donor__c',
            'DonationImported__c',
            'DonationImported__r.Name',
            'DonationImportStatus__c',
            'FailureInformation__c',
            'NPSP_Data_Import_Batch__c',
            'PaymentImported__c',
            'PaymentImported__r.Name',
            'PaymentImportStatus__c',
            'Status__c'
        };
    }

    /*******************************************************************************************************
    * @description reads the Active_Fields__c field to get active configured fields for the batch
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @return list of field API names
    */
    private static List<String> getActiveFieldNamesFromBatch(Id batchId) {

        DataImportBatch__c batch = [SELECT Active_Fields__c FROM DataImportBatch__c WHERE Id = :batchId];
        String activeFieldsJSON = batch.Active_Fields__c;
        List<String> activeFieldNames = new List<String>();

        if (activeFieldsJSON != null) {
            List<BGE_ConfigurationWizard_CTRL.BGEField> activeFields =
                    (List<BGE_ConfigurationWizard_CTRL.BGEField>)
                            JSON.deserialize(activeFieldsJSON, List<BGE_ConfigurationWizard_CTRL.BGEField>.class);
            for (BGE_ConfigurationWizard_CTRL.BGEField field : activeFields) {
                activeFieldNames.add(field.name);
                if (field.type == 'reference') {
                    DescribeFieldResult lookupDFR = UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrTokenNSPrefix('DataImport__c'), field.name.toLowerCase());
                    String referencedObjectName = lookupDFR.getReferenceTo()[0].getDescribe().name;
                    activeFieldNames.add(field.name.substringBefore('__c') + '__r.' + UTIL_Describe.getNameField(referencedObjectName));
                }
            }
        }

        return activeFieldNames;
    }

    /*******************************************************************************************************
    * @description returns a list of DataImport__c fields the Batch Gift Entry UI needs in SOQL
    * @return List<String> list of DataImport__c field api names
    */
    private static List<String> getDataImportFields(Id batchId) {

        List<String> fields = getDataImportFields();
        fields.addAll(getActiveFieldNamesFromBatch(batchId));
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
        @AuraEnabled public Integer totalCountOfRows;
        @AuraEnabled public Decimal totalRowAmount;
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
            catch (Exception ex) {
                throw new AuraHandledException(ex.getMessage());
            }
        }
    }
}