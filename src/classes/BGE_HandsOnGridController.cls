global class BGE_HandsOnGridController {

    private static final String CELL_DML = 'cellsUpdate';
    private static final String ROW_DML = 'ROW_DML';
    private static final String DATA_IMPORT_NAME = 'DataImport__c';

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

        List<Object> templateFields = selector.getTemplateFieldsByTemplateId(batch.Batch_Template__c);

        BGE_HandsOnGridColumnWrapper[] columns = new BGE_HandsOnGridColumnWrapper[] {};
        String[] fieldNames = new String[] {};
            
        for(Object fld : templateFields){    
            Map<String,Object> data = (Map<String,Object>)fld;
			columns.add(new BGE_HandsOnGridColumnWrapper((Map<String,Object>)data));
           	fieldNames.add((String)data.get('name'));
        }

        if (!columns.isEmpty()) {

            SObject[] records = selector.getDataImportsByBatchId(batchId, fieldNames);

            System.debug(JSON.serializePretty(records));

            result.put('templateFields', String.join(fieldNames, ';'));
            result.put('data', selector.sanitizeDataImports(records));
            result.put('templateId', batch.Batch_Template__c);
            result.put('columns', columns);
            result.put('rowsCount', selector.getDataImportBatchCountByBatchId(batchId));
            result.put('rowsAmount', selector.getDataImportDonationAmountByBatchId(batchId));
        }

        return result;
    }

    @RemoteAction
    global static Object[] dmlCellsRowGrid(Map<String, Object> parameters) {

        Object[] result = new Object[] {};

        Id batchId = Id.valueOf((String) parameters.get('batchId'));

        Object[] cells = (Object[]) JSON.deserializeUntyped((String) parameters.get('cellRecords'));
        Map<String, Object[]> rowCells = new Map<String, Object[]>();

        for (Object cell :cells) {

            Map<String, Object> cellData = (Map<String, Object>) cell;

            String cellKey = (String) cellData.get('recordId');

            if (!rowCells.containsKey(cellKey)) {
                rowCells.put(cellKey, new Object[] {});
            }

            rowCells.get(cellKey).add(cell);
        }

        result = runDmlCellsRowGrid(batchId, rowCells);

        return result;
    }

    private static Object[] runDmlCellsRowGrid(Id batchId, Map<String, Object[]> rowCells) {

        Map<String, DataImport__c> dataImports = new Map<String, DataImport__c>();

        Set<Object> result = new Set<Object>();
    
        for (String rowKey :rowCells.keySet()) {

            SObject dataImport = (SObject) new DataImport__c(NPSP_Data_Import_Batch__c = batchId);

            if (dataImports.containsKey(rowKey)) {
                dataImport = (SObject) dataImports.get(rowKey);
            }

            dataImport.put('External_Id__c', (Object) rowKey);

            for (Object cell :rowCells.get(rowKey)) {

                Map<String, Object> cellData = (Map<String, Object>) cell;
                String cellType = (String) cellData.get('type');

                // System.debug((String) cellData.get('field') + (String) cellData.get('newValue'));

                // BASED ON THE CELL TYPE WE PROCESS THE INFO

                Schema.SObjectField dataImportField = Schema.getGlobalDescribe().get(DATA_IMPORT_NAME).getDescribe().fields.getMap().get((String) cellData.get('field'));
                Schema.DescribeFieldResult dataImportFieldDescribe = dataImportField.getDescribe();
                String type = String.valueOf(dataImportFieldDescribe.getType()).toUpperCase();

                if ((new String[] {'STRING', 'PICKLIST', 'PHONE'}).contains(type)) {

                    dataImport.put((String) cellData.get('field'), String.valueOf(cellData.get('newValue')) );
                    dataImports.put(rowKey, (DataImport__c) dataImport);
                }
                else if ((new String[] {'EMAIL'}).contains(type)) {

                    String email = (String) cellData.get('newValue');

                    if (isEmailValid(email)) {
                        dataImport.put((String) cellData.get('field'), cellData.get('newValue'));
                        dataImports.put(rowKey, (DataImport__c) dataImport);
                    }
                    else {
                        result.add(buildCellError(cell, cellData.get('field'), 'Invalid Email'));
                    }
                }
                else if ((new String[] {'DATE', 'DATETIME'}).contains(type)) {

                    String dtString = (String) cellData.get('newValue');

                    if (String.isEmpty(dtString)) {
                        dataImport.put((String) cellData.get('field'), null);
                        dataImports.put(rowKey, (DataImport__c) dataImport);
                    }
                    else {

                        String[] dts = dtString.split('/');

                        if (dts.size() == 3) {
                            Date dt = Date.newInstance(Integer.valueOf(dts[2]), Integer.valueOf(dts[0]), Integer.valueOf(dts[1]));
                            dataImport.put((String) cellData.get('field'), (Object) dt);
                            dataImports.put(rowKey, (DataImport__c) dataImport);
                        }
                        else {
                            result.add(buildCellError(cell, cellData.get('field'), 'Invalid Date'));
                        }
                    }
                }
                else if ((new String[] {'CURRENCY', 'DECIMAL'}).contains(type)) {

                    if (cellData.get('newValue') instanceOf Decimal || (cellData.get('newValue') == null)) {
                        dataImport.put((String) cellData.get('field'), cellData.get('newValue'));
                        dataImports.put(rowKey, (DataImport__c) dataImport);
                    }
                    else {
                        result.add((buildCellError(cell, cellData.get('field'), 'Invalid Currency')));
                    }
                }
                else if ((new String[] {'NUMBER'}).contains(type)) {

                    if (cellData.get('newValue') instanceOf Integer || (cellData.get('newValue') == null)) {
                        dataImport.put((String) cellData.get('field'), cellData.get('newValue'));
                        dataImports.put(rowKey, (DataImport__c) dataImport);
                    }
                    else {
                        result.add(result.add(buildCellError(cell, cellData.get('field'), 'Invalid number')));
                    }
                }
                else {
                    dataImport.put((String) cellData.get('field'), cellData.get('newValue'));
                    dataImports.put(rowKey, (DataImport__c) dataImport);
                }
            }
        }

        if (!dataImports.isEmpty()) {

            DataImport__c[] upsertRecords = dataImports.values();
            Database.UpsertResult[] upsertResults = new Database.UpsertResult[] {};

            for (String key :dataImports.keySet()) {
                if (key InstanceOf Id) {
                    dataImports.get(key).Id = Id.valueOf(key);
                }
            }

            upsertResults = Database.upsert(upsertRecords, false);

            for (Integer index = 0; index < upsertResults.size(); index ++) {

                Database.UpsertResult upsertResult = upsertResults[index];
                DataImport__c upsertRecord = upsertRecords[index];

                Object[] cells = (Object[]) rowCells.get(upsertRecord.External_Id__c);

                if (!upsertResult.isSuccess()) {

                    Database.Error upsertResultError = upsertResult.getErrors()[0];
                    Map<String, String> upsertErrorDetail = new Map<String, String>();

                    String errorField = upsertResultError.getFields()[0];
                    upsertErrorDetail.put('field', errorField);
                    upsertErrorDetail.put('messages', upsertResultError.getMessage());

                    for (Object cell :cells) {
                        Map<String, Object> cellData = (Map<String, Object>) cell;
                        if (cellData.get('field') == errorField) {
                            cellData.put('errors', (Object) new Object[] {upsertErrorDetail});
                            result.add(cell);
                        }
                    }
                }
                else {

                    for (Object cell :cells) {

                        Map<String, Object> cellData = (Map<String, Object>) cell;
                        cellData.put('sfdcid', (Object) upsertResult.getId());

                        if (!isCellIncluded(cell, result)) {
                            result.add(cell);
                        }
                    }
                }
            }
        }

        System.debug(JSON.serializePretty(result));
        result.remove(null);
        Object[] resultCells = new Object[] {};
        resultCells.addAll(result);
        return resultCells;
    }

    private static Object buildCellError(Object cell, Object fieldNameObject, String message) {

        String fieldName = (String) fieldNameObject;

        Map<String, Object> cellData = (Map<String, Object>) cell;
        Map<String, String> upsertErrorDetail = new Map<String, String>();

        upsertErrorDetail.put('field', fieldName);
        upsertErrorDetail.put('messages', message);

        cellData.put('errors', (Object) new Object[] {upsertErrorDetail});

        return cell;
    }

    private static Boolean isCellIncluded(Object instance, Set<Object> cells) {

        Boolean result = false;

        Map<String, Object> instanceData = (Map<String, Object>) instance;
        
        for (Object cell :cells) {

            Map<String, Object> cellData = (Map<String, Object>) cell;

            if ((cellData.get('field') == instanceData.get('field')) && 
                (cellData.get('recordId') == instanceData.get('recordId'))) {

                    result = true;
                    break;
            }
        }

        return result;
    }

    @RemoteAction
    global static Object[] dmlCellsGrid(Map<String, Object> parameters) {

        Map<String, Object> result = new Map<String, Object>();
        Object[] exceptionResult = new Object[] {};

        Id batchId = Id.valueOf((String) parameters.get('batchId'));

        Object[] cells = (Object[]) JSON.deserializeUntyped((String) parameters.get('cellRecords'));

        Map<String, DataImport__c> dataImports = new Map<String, DataImport__c>();

        for (Object cell :cells) {

            Map<String, Object> cellData = (Map<String, Object>) cell;

            String cellKey = (String) cellData.get('recordId');
            result.put(cellKey, cell);
            exceptionResult.add(cell);

            SObject dataImport = (SObject) new DataImport__c(NPSP_Data_Import_Batch__c = batchId);

            if (dataImports.containsKey(cellKey)) {
                dataImport = (SObject) dataImports.get(cellKey);
            }



            String cellType = (String) cellData.get('type');

            System.debug((String) cellData.get('field') + (String) cellData.get('newValue'));

            try {

                if (cellType != null && cellType.equalsIgnoreCase('DATE')) {

                    String oldValue = (String) cellData.get('oldValue');
                    string newValue = (String) cellData.get('newValue');

                    if (newValue == null && oldValue != null ) {

                        Date dt = null;
                        dataImport.put((String) cellData.get('field'), (Object) dt);

                        dataImports.put(cellKey, (DataImport__c) dataImport);
                    }
                    else if (newValue == null && oldValue == null ) {

                    }
                    else {

                        String dtString = (String) cellData.get('newValue');
                        String[] dts = dtString.split('/');
                        Date dt = Date.newInstance(Integer.valueOf(dts[2]), Integer.valueOf(dts[0]), Integer.valueOf(dts[1]));
                        dataImport.put((String) cellData.get('field'), (Object) dt);

                        dataImports.put(cellKey, (DataImport__c) dataImport);
                    }


                }
                else {

                    // If the type we get from the front end is TEXT
                    if (cellType != null && cellType.equalsIgnoreCase('TEXT')) {

                        Schema.SObjectField dataImportField = BGE_HandsOnGridColumnWrapper.getObjectFields(BGE_HandsOnGridColumnWrapper.DATA_IMPORT_NAME).get((String) cellData.get('field'));

                        Schema.DescribeFieldResult dataImportFieldDescribe = dataImportField.getDescribe();

                        String type = String.valueOf(dataImportFieldDescribe.getType()).toUpperCase();

                        // If the actual type is EMAIL
                        if (type == 'EMAIL' && !isEmailValid( (String) cellData.get('newValue') )){

                            String emailErrorMessage = 'invalid email format';

                            Map<String, String> emailError = new Map<String, String>();
                            emailError.put('field', (String) cellData.get('field'));
                            emailError.put('messages', emailErrorMessage);

                            Object[] emailErrorMessagesList = new Object[] {};
                            emailErrorMessagesList.add((Object) emailError);

                            cellData.put('errors', emailErrorMessagesList);
                        }
                        else if ((String) cellData.get('newValue') != (String) cellData.get('oldValue')) {
                            // If we are receiving just text or the email is valid.
                            dataImport.put((String) cellData.get('field'), cellData.get('newValue'));

                            System.debug(JSON.serializePretty(dataImport));

                            dataImports.put(cellKey, (DataImport__c) dataImport);
                        }
                    }
                    else if (cellData.get('newValue') != cellData.get('oldValue')) {
                        // If type from the frontend is number or boolean.
                        dataImport.put((String) cellData.get('field'), cellData.get('newValue'));

                        System.debug(JSON.serializePretty(dataImport));

                        dataImports.put(cellKey, (DataImport__c) dataImport);
                    }

                }
            }
            catch (Exception ex) {

                Map<String, String> exceptionError = new Map<String, String>();
                exceptionError.put('field', (String) cellData.get('field'));
                exceptionError.put('messages', (String) ex.getMessage());

                Object[] exceptionErrors = new Object[] {};
                exceptionErrors.add((Object) exceptionError);

                if (cellData.containsKey('errors')) {

                    Object[] existingExceptionErrors = (Object[]) cellData.get('errors');

                    if (existingExceptionErrors != null && existingExceptionErrors.size() > 0) {
                        existingExceptionErrors.addAll(exceptionErrors);
                        cellData.put('errors', (Object) existingExceptionErrors);
                    }
                    else {
                        cellData.put('errors', (Object) existingExceptionErrors);
                    }
                }
                else {
                    cellData.put('errors', (Object) exceptionErrors);
                }
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

            return result.values();
        }
        else {
            return exceptionResult;
        }

        return null;
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

                        // BDI_DataImport_API.processDataImportRecords(diSetting, new DataImport__c[] {dataImport}, true);
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

        String[] fieldNames = new String[] {};
        String templateFields = (String) parameters.get('templateFields');

        fieldNames = templateFields.split(';');

        if (!fieldNames.isEmpty()) {
            SObject[] records = selector.getDataImportsByBatchId(batchId, fieldNames, offset.intValue() * 50);
            result.put('data', selector.sanitizeDataImports(records));
        }

        return result;
    }

    private static Boolean isEmailValid(String email) {

        Boolean isValid = true;

        if (!String.isEmpty(email) ) {

            String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$';
            Pattern MyPattern = Pattern.compile(emailRegex);
            Matcher MyMatcher = MyPattern.matcher(email.toUpperCase());

            if (!MyMatcher.matches()) {

                isValid = false;
            }
        }

        return isValid;
    }

}