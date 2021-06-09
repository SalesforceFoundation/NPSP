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

    public static final List<String> PAYMENT_INTEGRATION_FIELDS = new List<String>{
        String.valueOf(DataImport__c.Donation_Amount__c), 
        String.valueOf(DataImport__c.Donation_Date__c), 
        String.valueOf(DataImport__c.Contact1Imported__c),
        String.valueOf(DataImport__c.Contact1_Firstname__c), 
        String.valueOf(DataImport__c.Contact1_Lastname__c), 
        String.valueOf(DataImport__c.Account1Imported__c),
        String.valueOf(DataImport__c.Account1_Name__c)
    };

    public Map<String, Integer> getGiftBatchTotalsMapFor(Id batchId) {
        GiftBatches batches = new GiftBatches(new Set<Id> {batchId}, new GiftBatchSelector());
        GiftBatchGroupedTotals groupedTotals = batches.getGroupedTotals();
        return groupedTotals.totalsFor(batchId);
    }

    public void processGiftsFor(Id batchId) {
        GiftBatch giftBatch = new GiftBatch(batchId);
        giftBatch.processGifts();
    }

    public void giftsFailedCaptureFor(Id batchId, Map<String, String> failReasonByElevateBatchId) {
        GiftBatch giftBatch = new GiftBatch(batchId);
        giftBatch.failGiftsWithReason(failReasonByElevateBatchId);
        giftBatch.updateRecords();
    }

    /*******************************************************************************************************
    * @description runs BDI Dry Run against all Data Import records based on the processing settings of a
    *  given batch
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @return DataImportModel with updated data import record row and updated totals for the batch
    */
    public String runBatchDryRun(Id batchId, Integer numberOfRowsToReturn) {
        Data_Import_Settings__c dataImportSettings = BDI_DataImportService.loadSettings(batchId);

        List<DataImport__c> allRawDataImports = getAllDataImportRecordsForDryRunByBatchId(batchId);
        List<DataImport__c> rawDataImportsToPrepareForDryRun = new List<DataImport__c>();
        for (DataImport__c di : allRawDataImports) {
            if (di.Status__c != BDI_DataImport_API.bdiImported) {
                rawDataImportsToPrepareForDryRun.add(di);
            }
        }

        if (rawDataImportsToPrepareForDryRun.size() > 0) {
            List<DataImport__c> dataImportListToRun =
                    prepareDataImportsForDryRun(rawDataImportsToPrepareForDryRun);
            BDI_DataImport_API.processDataImportRecords(dataImportSettings, dataImportListToRun, true);
        }

        DataImportModel dataImportModel = getUpdatedTotals(batchId);

        List<DataImportRow> rows = new List<DataImportRow>();
        List<DataImport__c> dataImportsToReturn =
                getNumOfDataImportRecordsByBatchId(batchId, numberOfRowsToReturn);
        for (DataImport__c di : dataImportsToReturn) {
            DataImportRow processedDataImportRow = new DataImportRow(di);
            rows.add(processedDataImportRow);
        }
        dataImportModel.dataImportRows = rows;

        return JSON.serialize(dataImportModel);
    }

    /*******************************************************************************************************
    * @description initializes the data model for the BGE_DataImportBatchEntry component
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @return serialized string of dataImportModel
    */
    public String getDataImportModel(Id batchId) {
        if (batchId == null) {
            throw new AuraHandledException('Data Import Model must receive a Batch ID.');
        }
        DataImportModel dataImportModel = new DataImportModel();
        dataImportModel.id = batchId;
        dataImportModel.dataImportRows = getDataImportRows(batchId, 0);
        dataImportModel.setColumns();
        dataImportModel.labels = getBatchDataImportLabels();
        dataImportModel.isNamespaced = String.isNotBlank(UTIL_Namespace.getNamespace());
        dataImportModel.totalCountOfRows = getDataImportBatchTotalCount(batchId);
        AggregateResult[] aggResult = getDataImportBatchTotalAmount(batchId);
        dataImportModel.totalRowAmount = (Decimal)aggResult[0].get('amount');
        dataImportModel.batchTotalRowAmount = getBatchTotalRowAmount(dataImportModel.dataImportRows);
        checkBatchGiftEntryFieldPermissions (batchId);
        return JSON.serialize(dataImportModel);
    }

    private void checkBatchGiftEntryFieldPermissions(Id batchId) {
        Decimal batchGiftEntryVersion;
        Boolean isQueryException = false;
        try {
            batchGiftEntryVersion = getBatchGiftEntryVersion(batchId);
        } catch (QueryException qe) {
            // If User doesn't have access to Version field, treat as 1.0.
            isQueryException = true;
        }

        GiftBatch giftBatch = new GiftBatch(batchId);
        List<String> fields = giftBatch.getDataImportFields(true);

        if (isQueryException || batchGiftEntryVersion < 2) {
            checkFieldPermissions(
                    String.valueOf(DataImport__c.SObjectType),
                    fields
            );
        } else {
            List<String> nonNameFields = getNonNameFields(fields);
            checkFieldPermissions(
                    String.valueOf(DataImport__c.SObjectType),
                    nonNameFields
            );
        }
    }

    /*******************************************************************************************************
    * @description Checks to see whether the running user has permission to edit a given list of fields
    * @param fieldsToCheck list of DescribeFieldResult records to check
    * @return void Throws an exception if user lacks edit permissions on any field
    */
    public void checkFieldPermissions(List<DescribeFieldResult> fieldsToCheck) {
        Boolean hasPermission = true;
        List<String> fieldsWithoutPermission = new List<String>();

        for (DescribeFieldResult dfr : fieldsToCheck) {
            Boolean canReadCustomFormulaField =
                    dfr.isCalculated() && UTIL_Permissions.canRead(dfr, false);
            if (canReadCustomFormulaField) {
                continue;
            }
            if (!UTIL_Permissions.canUpdate(dfr, false)) {
                hasPermission = false;
                fieldsWithoutPermission.add(dfr.getLabel());
            }
        }

        if (!hasPermission) {
            handleMissingPermissions(fieldsWithoutPermission);
        }

    }

    public void checkFieldPermissions(String objectName, List<String> fieldNamesToCheck) {
        List<DescribeFieldResult> fieldResults = new List<DescribeFieldResult>();
        for (String fieldName : fieldNamesToCheck) {
            if (fieldName.contains('__r')) {
                fieldName = fieldName.substringBefore('__r') + '__c';
            }

            DescribeFieldResult fieldResult =
                    UTIL_Describe.getFieldDescribe(UTIL_Namespace.StrAllNSPrefix(objectName), fieldName);

            if (fieldName != 'Id' && !fieldResults.contains(fieldResult)) {
                fieldResults.add(fieldResult);
            }
        }
        checkFieldPermissions(fieldResults);
    }

    /*******************************************************************************************************
    * @description Handles missing field permissions
    * @param missingPermissions list of Strings identifying the fields with missing permissions
    * @return void Throws an exception if user lacks permissions on any field
    */
    private void handleMissingPermissions(List<String> missingPermissions) {

        if (!missingPermissions.isEmpty()) {
            String errorMsg = Label.bgeFLSError + ' [' + truncateList(missingPermissions, 3) + ']';
            AuraHandledException ex = new AuraHandledException(errorMsg);
            ex.setMessage(errorMsg);
            throw ex;
        }
    }

    /*******************************************************************************************************
    * @description Handles missing field permissions
    * @param missingPermissions list of DescribeFieldResult records for which permissions are lacking
    * @return void Throws an exception if user lacks permissions on any field
    */
    public void handleMissingPermissions(List<DescribeFieldResult> missingPermissions) {
        List<String> fieldNames = new List<String>();
        for (DescribeFieldResult fieldResult : missingPermissions) {
            fieldNames.add(fieldResult.getLabel());
        }
        handleMissingPermissions(fieldNames);
    }

    /*******************************************************************************************************
    * @description Takes a list of strings and converts it to a string of a subset of the original list
    * @param items list of Strings
    * @param maxItems the maximum number of Strings from the list to retain
    * @return String the truncated list of strings, separated by a comma
    * @example truncateList(new List<String>{ 'apple', 'orange', 'banana', 'pear' }, 2); // returns 'apple,
    *  orange ...'
    */
    @TestVisible
    private static String truncateList(List<String> items, Integer maxItems) {
        Integer totalItems = items.size();
        List<String> limitedItems = new List<String>();

        for (Integer i = 0; i < maxItems && i < items.size(); i++) {
            limitedItems.add(items[i]);
        }

        return String.join(limitedItems, ', ') + (totalItems > maxItems ? ' ...' : '');
    }

    private Decimal getBatchGiftEntryVersion(Id batchId) {
        return [
                SELECT Batch_Gift_Entry_Version__c
                FROM DataImportBatch__c
                WHERE Id = :batchId
                WITH SECURITY_ENFORCED
        ][0].Batch_Gift_Entry_Version__c;
    }

    private static List<String> getNonNameFields(List<String> fields) {
        List<String> nonNameFields = new List<String>();
        for (String str : fields) {
            Boolean isNameField = str.contains('.');
            if (isNameField) {
                continue;
            } else if (!nonNameFields.contains(str)) {
                nonNameFields.add(str);
            }
        }
        return nonNameFields;
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
    * @description queries the DataImport__c records associated with the given batchId
    * @param batchId: ID of the NPSP_Data_Import_Batch__c
    * @param offset: next offset to query
    * @return list of custom DataImportRow objects for use in the lightning:datatable
    */
    private List<DataImportRow> getDataImportRows(Id batchId, Integer offset){
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
    * @description the number of additional data import records to load on each infinite scroll query
    */
    private static integer loadsize = 100;

    /*******************************************************************************************************
    * @description returns an offset list of DataImport__c records from a batch Id
    * @param batchId a Data Import Batch Id
    * @param offset Offset on the query
    * @return List<DataImport__c>
    */
    private List<DataImport__c> getDataImportRecordsByBatchId(Id batchId, Integer offset) {
        String query = getDataImportQuery(batchId, null, loadSize, offset);
        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description returns a list of all DataImport__c records from a batch Id
    * @param batchId a Data Import Batch Id
    @ param numberOfRowsToReturn Limit on the query
    * @return List<DataImport__c>
    */
    private List<DataImport__c> getNumOfDataImportRecordsByBatchId(Id batchId, Integer numberOfRowsToReturn) {
        String query = getDataImportQuery(batchId, null, numberOfRowsToReturn, null);
        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description Builds DataImport__c query based on provided parameters
    * @param batchId a Data Import Batch Id
    * @param dataImportIds List of Data Import Ids
    * @param numRows Limit on the query
    * @param offset Offset on the query
    * @return Query string
    */
    public String getDataImportQuery(Id batchId, List<Id> dataImportIds, Integer numRows, Integer offset) {
        List<String> dataImportFields = getDataImportFields(batchId);

        String query =  'SELECT ' + String.join(dataImportFields,', ') +
                ' FROM DataImport__c' +
                ' WHERE NPSP_Data_Import_Batch__c = :batchId';

        if (dataImportIds != null && dataImportIds.size() > 0) {
            query += ' AND Id IN :dataImportIds';
        }

        query += ' ORDER BY CreatedDate DESC';

        if (numRows != null) {
            query += ' LIMIT ' + numRows;
        }

        if (offset != null) {
            query += ' OFFSET ' + offset;
        }

        return query;
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
        dataImportModel.batchTotalRowAmount = getBatchTotalRowAmount(batchId);

        return dataImportModel;
    }

    private static Decimal getBatchTotalRowAmount(List<DataImportRow> dataImportRows) {
        Decimal totalAmount = 0;

        for (DataImportRow dataImportRow: dataImportRows) {
            totalAmount+= dataImportRow.record.Donation_Amount__c == null
                    ? 0
                    : dataImportRow.record.Donation_Amount__c;
        }
        return totalAmount;
    }

    private static Decimal getBatchTotalRowAmount(Id batchId) {
        Decimal totalAmount = 0;

        for (DataImport__c dataImport: [
                SELECT Donation_Amount__c
                FROM DataImport__c
                WHERE NPSP_Data_Import_Batch__c =: batchId
        ]) {
            totalAmount+= dataImport.Donation_Amount__c == null
                    ? 0
                    : dataImport.Donation_Amount__c;
        }
        return totalAmount;
    }

    /*******************************************************************************************************
    * @description Gets the sum of the amount totals of all rows for that batch
    * @param recordId the ID of the NPSP_Data_Import_Batch__c
    * @return Decimal amount
    */
    private static AggregateResult[] getDataImportBatchTotalAmount(Id recordId) {
        return [
                SELECT Sum(Donation_Amount__c)amount
                FROM DataImport__c
                WHERE NPSP_Data_Import_Batch__c =: recordId
        ];
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
    * @description returns a list of all DataImport__c records for a batch Id, with fields needed for dry run
    * @param batchId a Data Import Batch Id
    * @return List<DataImport__c>
    */
    public static List<DataImport__c> getAllDataImportRecordsForDryRunByBatchId(Id batchId) {
        String query = BDI_DataImportService.strSoqlForBatchProcess(batchId);
        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description prepare the data import record for dry run by clearing certain fields or retaining them
    * based on if user has already selected a match, or if they want to let matching run. Either way, we want to use Dry Run
    * to check for potential errors.
    * @return List<DataImport__c> because BDI expects a list
    */
    private static List<DataImport__c> prepareDataImportsForDryRun(List<DataImport__c> dataImportRecords) {
        // Skip records where user has explicitly selected a matching record in BGE UI
        for(DataImport__c dataImportRecord : dataImportRecords) {
            if (dataImportRecord.DonationImportStatus__c == Label.bdiMatchedByUser
                    || dataImportRecord.DonationImportStatus__c == Label.bdiMatchedByUserNewOpp
                    || dataImportRecord.DonationImportStatus__c == Label.bdiMatchedApplyNewPayment) {
                // User defined match, so we do nothing and retain the values
            } else {
                // Clear Dry Run fields before running Dry Run so new field values are accounted for
                if (dataImportRecord.Status__c != null) {
                    dataImportRecord.Status__c = null;
                }
                if (dataImportRecord.FailureInformation__c != null) {
                    dataImportRecord.FailureInformation__c = null;
                }
                if (dataImportRecord.DonationImported__c != null) {
                    dataImportRecord.DonationImported__c = null;
                }
                if (dataImportRecord.DonationImportStatus__c != null) {
                    dataImportRecord.DonationImportStatus__c = null;
                }
                if (dataImportRecord.PaymentImported__c != null) {
                    dataImportRecord.PaymentImported__c = null;
                }
                if (dataImportRecord.PaymentImportStatus__c != null) {
                    dataImportRecord.PaymentImportStatus__c = null;
                }

            }
        }

        update dataImportRecords;

        return dataImportRecords;
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
        @AuraEnabled public Decimal batchTotalRowAmount;
        @AuraEnabled public List<UTIL_LightningComponentSupport.Notice> notices =
                new List<UTIL_LightningComponentSupport.Notice>();

        /*******************************************************************************************************
        * @description Retrieves the related list of columns for the BGE interface
        * @return list of Columns to use in BGE_DataImportBatchEntry table
        */
        public void setColumns() {
            List<Column> columns = new List<Column>();

            columns.addAll(getUserDefinedColumns());

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

            this.columns = columns;
        }

        /*******************************************************************************************************
        * @description Retrieves the related list of columns defined by users in the Batch record Active_Fields__c
        * @return list of Columns to use in BGE_DataImportBatchEntry table
        */
        private List<Column> getUserDefinedColumns() {
            List<Column> columns = new List<Column>();

            DataImportBatch__c batch = [SELECT Active_Fields__c FROM DataImportBatch__c
            WHERE Id = :id];
            String activeFieldsJSON = batch.Active_Fields__c;
            if (activeFieldsJSON != null) {
                List<BGE_ConfigurationWizard_CTRL.BGEField> activeFields =
                        (List<BGE_ConfigurationWizard_CTRL.BGEField>)JSON.deserialize(
                                activeFieldsJSON,
                                List<BGE_ConfigurationWizard_CTRL.BGEField>.class
                        );

                Map<String, Schema.DescribeFieldResult> fieldMap = UTIL_Describe.getAllFieldsDescribe(
                        UTIL_Namespace.StrTokenNSPrefix('DataImport__c')
                );

                List<DescribeFieldResult> unpermittedFields = new List<DescribeFieldResult>();
                Set<String> unmappedFields = new Set<String>();

                for (BGE_ConfigurationWizard_CTRL.BGEField field : activeFields) {
                    Schema.DescribeFieldResult dataImportDFR = fieldMap.get(field.name.toLowerCase());
                    if (dataImportDFR != null) {

                        if (UTIL_Permissions.canUpdate(dataImportDFR, false)) {

                            String targetObject = '';
                            String targetField = '';
                            BDI_TargetFields targetFields =
                                    BGE_BatchGiftEntry_UTIL.targetFieldsBySourceField.get(
                                            dataImportDFR.getSObjectField());

                            if (targetFields == null) {
                                if (unmappedFields == null) {
                                    unmappedFields = new Set<String>();
                                }
                                unmappedFields.add(field.name);
                                continue;
                            }

                            Map<SObjectType, Set<SObjectField>> targetFieldsByTargetObject =
                                    targetFields.getTargetFieldsByTargetObject();

                            // One DI field can be mapped to multiple target fields although it will be rare
                            // and presents some issues with picklists; here we will return info for the first
                            // match
                            for (Schema.SObjectType targetSObjType: targetFieldsByTargetObject.keySet()) {
                                String aTargetObjectName = targetSObjType.getDescribe().getName();
                                if (BGE_BatchGiftEntry_UTIL.objectGroupNameByAllowedObjects.containsKey(
                                        aTargetObjectName)) {

                                    targetObject = aTargetObjectName;
                                    List<SObjectField> mappedTargetFields =
                                            new List<SObjectField> (targetFieldsByTargetObject.get(targetSObjType));
                                    if(mappedTargetFields.size() > 0) {
                                        targetField = mappedTargetFields[0].getDescribe().getName();
                                    }
                                }
                            }
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

                if (!unmappedFields.isEmpty()) {
                    notices.add(new UnmappedFieldsNotice(unmappedFields));
                }
            }

            return columns;
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

    /**
    * @description The Notice displayed to the User when fields that are selected for
    * display on the Batch do not have field mappings configured in the Advanced Mapping
    * settings.
    */
    @TestVisible
    private class UnmappedFieldsNotice extends UTIL_LightningComponentSupport.Notice {
        private Set<String> unmappedFieldNames = new Set<String>();

        public UnmappedFieldsNotice(Set<String> unmappedFieldNames) {
            this.unmappedFieldNames = unmappedFieldNames;
            this.header = Label.bgeUnmappedFieldsNoticeHeader;
            this.title = Label.bgeUnmappedFieldsNoticeTitle;
            this.message = getMessage();
            setVariant(UTIL_LightningComponentSupport.Variant.WARNING);
        }

        private String getMessage() {
            String fieldNames = String.join(new List<String>(unmappedFieldNames), ', ');
            String unmappedFieldsTemplate = '';
            String fieldMappingMethod =
                    UTIL_CustomSettingsFacade.getDataImportSettings().Field_Mapping_Method__c;

            if (fieldMappingMethod == BDI_DataImportService.FM_DATA_IMPORT_FIELD_MAPPING) {
                unmappedFieldsTemplate =
                        Label.bgeUnmappedFieldsNoticeMessageAdvancedMapping;
            } else if (fieldMappingMethod == BDI_DataImportService.FM_HELP_TEXT) {
                unmappedFieldsTemplate =
                        Label.bgeUnmappedFieldsNoticeMessageHelpTextMapping;
            }

            return String.format(
                    unmappedFieldsTemplate, new List<String>{
                            fieldNames
                    });
        }
    }

    /*******************************************************************************************************
    * @description returns a list of DataImport__c fields the Batch Gift Entry UI needs in SOQL
    * @param batchId the batch for which to get all fields for soql
    * @return List<String> list of DataImport__c field api names
    */
    public List<String> getDataImportFields(Id batchId) {
        return getDataImportFields(batchId, true);
    }

    /*******************************************************************************************************
    * @description returns a list of DataImport__c fields the Batch Gift Entry UI needs in SOQL
    * @param batchId the batch for which to get all fields for soql
    * @param includeRelationshipFields whether to include relationship fields in the returned list
    * @return List<String> list of DataImport__c field api names
    */
    public List<String> getDataImportFields(Id batchId, Boolean includeRelationshipFields) {
        GiftBatch giftBatch = new GiftBatch(batchId);
        return giftBatch.getDataImportFields(includeRelationshipFields);
    }

}
