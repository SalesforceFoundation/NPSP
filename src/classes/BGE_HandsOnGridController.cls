global class BGE_HandsOnGridController {

    private static final String CELL_DML = 'cellsUpdate';
    private static final String ROW_DML = 'ROW_DML';

    public Boolean hasError {get; set;}

    public BGE_HandsOnGridController() {

        hasError = false;
    }

    @RemoteAction
    global static Map<String, Object> initGrid(Map<String, Object> parameters) {

        Map<String, Object> result = new Map<String, Object>();

        BGE_HandsOnGridSelector selector = new BGE_HandsOnGridSelector();

        Id batchId = Id.valueOf((String) parameters.get('batchId'));

        DataImportBatch__c batch = selector.getBatchById(batchId);

        Map<Id, Batch_Template_Field__c> templateFields = selector.getTemplateFieldsByTemplateId(batch.Batch_Template__c);

        BGE_HandsOnGridColumnWrapper[] columns = new BGE_HandsOnGridColumnWrapper[] {};
        String[] fieldNames = new String[] {};

        for (Batch_Template_Field__c templateField :templateFields.values()) {
            columns.add(new BGE_HandsOnGridColumnWrapper(templateField));
            fieldNames.add(templateField.Name);
        }

        if (!columns.isEmpty()) {

            SObject[] records = selector.getDataImportsByBatchId(batchId, fieldNames);

            System.debug(JSON.serializePretty(records));

            result.put('data', selector.sanitizeDataImports(records));
            result.put('templateId', batch.Batch_Template__c);
            result.put('columns', columns);
            result.put('rowsCount', selector.getDataImportBatchCountByBatchId(batchId));
            result.put('rowsAmount', selector.getDataImportDonationAmountByBatchId(batchId));
        }

        return result;
    }

    @RemoteAction
    global static Object[] dmlCellsGrid(Map<String, Object> parameters) {

        Map<String, Object> result = new Map<String, Object>();

        Id batchId = Id.valueOf((String) parameters.get('batchId'));

        Object[] cells = (Object[]) JSON.deserializeUntyped((String) parameters.get('cellRecords'));

        Map<String, DataImport__c> dataImports = new Map<String, DataImport__c>();

        for (Object cell :cells) {

            Map<String, Object> cellData = (Map<String, Object>) cell;
            cellData.put('errors', null);

            String cellKey = (String) cellData.get('recordId');
            result.put(cellKey, cell);

            SObject dataImport = (SObject) new DataImport__c(NPSP_Data_Import_Batch__c = batchId);

            if (dataImports.containsKey(cellKey)) {
                dataImport = (SObject) dataImports.get(cellKey);
            }

            dataImport.put('External_Id__c', (Object) cellKey);

            String cellType = (String) cellData.get('type');

            try {

                if (cellType != null && cellType.equalsIgnoreCase('DATE')) {

                    String dtString = (String) cellData.get('newValue');
                    String[] dts = dtString.split('/');
                    Date dt = Date.newInstance(Integer.valueOf(dts[2]), Integer.valueOf(dts[0]), Integer.valueOf(dts[1]));
                    dataImport.put((String) cellData.get('field'), (Object) dt);
                }
                else {
                    dataImport.put((String) cellData.get('field'), cellData.get('newValue'));
                }

                System.debug(JSON.serializePretty(dataImport));

                dataImports.put(cellKey, (DataImport__c) dataImport);
            }
            catch (Exception ex) {

                Map<String, String> exceptionError = new Map<String, String>();
                exceptionError.put('field', (String) cellData.get('field'));
                exceptionError.put('messages', (String) ex.getMessage());

                Object[] exceptionErrors = new Object[] {};
                exceptionErrors.add((Object) exceptionError);
                cellData.put('errors', exceptionErrors);
            }
        }

        if (!dataImports.isEmpty()) {

            for (String key :dataImports.keySet()) {
                if (key InstanceOf Id) {
                    dataImports.get(key).Id = Id.valueOf(key);
                }
            }

            DataImport__c[] upsertRecords = dataImports.values();
            Database.UpsertResult[] upsertResults = new Database.UpsertResult[] {};

            try {

                upsertResults = Database.upsert(upsertRecords, true);
            }
            catch (DmlException ex) {

                Object cell = result.values()[0];

                Map<String, Object> cellData = (Map<String, Object>) cell;

                Map<String, String> exceptionError = new Map<String, String>();
                exceptionError.put('field', (String) cellData.get('field'));
                exceptionError.put('messages', (String) ex.getMessage());

                Object[] exceptionErrors = new Object[] {};
                exceptionErrors.add((Object) exceptionError);
                cellData.put('errors', exceptionErrors);
            }

            for (Integer i = 0; i < upsertResults.size(); i ++) {

                Database.UpsertResult upsertResult = upsertResults[i];
                DataImport__c upsertRecord = upsertRecords[i];

                Map<String, Object> cellData = (Map<String, Object>) result.get(upsertRecord.External_Id__c);

                if (!upsertResult.isSuccess()) {

                    Map<Integer, Map<String, String>> upsertErrors = new Map<Integer, Map<String, String>>();
                    Database.Error[] upsertResultErrors = upsertResult.getErrors();

                    for (Integer j = 0; j < upsertResultErrors.size(); j ++) {

                        Database.Error upsertResultError = upsertResultErrors[j];
                        Map<String, String> upsertErrorDetail = new Map<String, String>();

                        upsertErrorDetail.put('field', (String) upsertResultError.getFields()[0]);
                        upsertErrorDetail.put('messages', (String) upsertResultError.getMessage());
                        upsertErrors.put(j, upsertErrorDetail);
                    }

                    cellData.put('errors', (Object) upsertErrors.values());
                }
                else {
                    cellData.put('sfdcid', (Object) upsertResult.getId());
                }
            }
        }


        // System.debug(JSON.serializePretty(result));

        return result.values();
    }

    @RemoteAction
    global static Map<String, Object> dryRunRowGrid(Map<String, Object> parameters) {

        Map<String, Object> result = new Map<String, Object>();

        result = parameters.clone();

        BGE_HandsOnGridSelector selector = new BGE_HandsOnGridSelector();

        Id batchId = Id.valueOf((String) parameters.get('batchId'));

        String recordId = (String) parameters.get('recordId');

        DataImportBatch__c batch = selector.getBatchById(batchId);

        if (batch != null) {

            try {

                Data_Import_Settings__c diSetting = BDI_DataImportService.diSettingsFromDiBatch(batch);

                result.put('status', 'NONE');

                if (recordId InstanceOf Id) {

                    DataImport__c dataImport = selector.getDataImportForDryRunByBatchId(recordId);

                    if (diSetting != null && dataImport != null) {

                        BDI_DataImport_API.processDataImportRecords(diSetting, new DataImport__c[] {dataImport}, true);
                        result.put('status', 'OK');
                        result.put('data', JSON.serialize(dataImport));
                    }
                }
            }
            catch (Exception ex) {
                result.put('status', 'ERROR');
                result.put('message', ex.getMessage());
            }
        }

        return result;
    }

    @RemoteAction
    global static Map<String, Object> getSummaryData(Map<String, Object> parameters) {

        Map<String, Object> result = new Map<String, Object>();

        BGE_HandsOnGridSelector selector = new BGE_HandsOnGridSelector();

        Id batchId = Id.valueOf((String) parameters.get('batchId'));

        result.put('rowsCount', selector.getDataImportBatchCountByBatchId(batchId));
        result.put('rowsAmount', selector.getDataImportDonationAmountByBatchId(batchId));

        return result;
    }

    @RemoteAction
    global static Map<String, Object> deleteRowsGrid(Map<String, Object> parameters) {

        Map<String, Object> result = new Map<String, Object>();

        BGE_HandsOnGridSelector selector = new BGE_HandsOnGridSelector();

        Id batchId = Id.valueOf((String) parameters.get('batchId'));

        Object[] dataImportIds = (Object[]) JSON.deserializeUntyped((String) parameters.get('rowRecordIds'));

        Set<Id> recordsIds = new Set<Id>();

        for (Object dataImportId :dataImportIds) {

            String recordsId = (String) dataImportId;

            if (recordsId instanceOf Id) {
                recordsIds.add(Id.valueOf(recordsId));
            }

        }

        selector.deleteRowsById(recordsIds);

        return result;
    }

    @RemoteAction
    global static Map<String, Object> changePageGrid(Map<String, Object> parameters) {

        Map<String, Object> result = new Map<String, Object>();

        BGE_HandsOnGridSelector selector = new BGE_HandsOnGridSelector();

        Id batchId = Id.valueOf((String) parameters.get('batchId'));
        Decimal offset = (Decimal) parameters.get('offset');

        DataImportBatch__c batch = selector.getBatchById(batchId);

        Map<Id, Batch_Template_Field__c> templateFields = selector.getTemplateFieldsByTemplateId(batch.Batch_Template__c);

        String[] fieldNames = new String[] {};
        for (Batch_Template_Field__c templateField :templateFields.values()) {
            fieldNames.add(templateField.Name);
        }

        if (!fieldNames.isEmpty()) {
            SObject[] records = selector.getDataImportsByBatchId(batchId, fieldNames, offset.intValue() * 50);
            result.put('data', selector.sanitizeDataImports(records));
        }

        return result;
    }

}