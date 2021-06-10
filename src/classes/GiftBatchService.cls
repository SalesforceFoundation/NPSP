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

        GiftBatchUIModel dataImportModel = getUpdatedTotals(batchId);

        List<GiftUIModel> rows = new List<GiftUIModel>();
        List<DataImport__c> dataImportsToReturn =
                getNumOfDataImportRecordsByBatchId(batchId, numberOfRowsToReturn);
        for (DataImport__c di : dataImportsToReturn) {
            GiftUIModel processedDataImportRow = new GiftUIModel(di);
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
    public String getGiftBatchUIModel(Id batchId) {
        if (batchId == null) {
            throw new AuraHandledException('Data Import Model must receive a Batch ID.');
        }
        GiftBatchUIModel giftBatchUIModel = new GiftBatchUIModel();
        giftBatchUIModel.id = batchId;
        giftBatchUIModel.dataImportRows = getGifts(batchId, 0);
        giftBatchUIModel.setColumns();
        giftBatchUIModel.labels = getBatchDataImportLabels();
        giftBatchUIModel.isNamespaced = String.isNotBlank(UTIL_Namespace.getNamespace());
        giftBatchUIModel.totalCountOfRows = getDataImportBatchTotalCount(batchId);
        AggregateResult[] aggResult = getDataImportBatchTotalAmount(batchId);
        giftBatchUIModel.totalRowAmount = (Decimal)aggResult[0].get('amount');
        giftBatchUIModel.batchTotalRowAmount = getBatchTotalRowAmount(giftBatchUIModel.dataImportRows);
        checkBatchGiftEntryFieldPermissions (batchId);
        return JSON.serialize(giftBatchUIModel);
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
    private List<GiftUIModel> getGifts(Id batchId, Integer offset){
        try {
            List<GiftUIModel> rows = new List<GiftUIModel>();
            List<DataImport__c> dataImports = getDataImportRecordsByBatchId(batchId, offset);
            for (DataImport__c dataImportRecord : dataImports) {
                rows.add(new GiftUIModel(dataImportRecord));
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
    public static GiftBatchUIModel getUpdatedTotals(Id batchId) {
        GiftBatchUIModel dataImportModel = new GiftBatchUIModel();

        dataImportModel.id = batchId;
        dataImportModel.totalCountOfRows = getDataImportBatchTotalCount(batchId);
        AggregateResult[] aggResult = getDataImportBatchTotalAmount(batchId);
        dataImportModel.totalRowAmount = (Decimal) aggResult[0].get('amount');
        dataImportModel.batchTotalRowAmount = getBatchTotalRowAmount(batchId);

        return dataImportModel;
    }

    private static Decimal getBatchTotalRowAmount(List<GiftUIModel> dataImportRows) {
        Decimal totalAmount = 0;

        for (GiftUIModel dataImportRow: dataImportRows) {
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
