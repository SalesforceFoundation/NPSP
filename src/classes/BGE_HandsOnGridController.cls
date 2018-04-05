global class BGE_HandsOnGridController {

    private static final Integer SQL_MINOR_LIMIT = 1;
    private static final Integer SQL_MAJOR_LIMIT = 10000;
    private static final integer PAGE_SIZE  = 50; // to set the page size to show the rows/records

    private static Id batchId;
    private static Id templateId;
    private static List<DataImport__c> data;
    private static List<BGE_DynamicalColumnWrapper> columns;
    private static Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.DataImport__c.fields.getMap();
    private static Batch_Template_Field__c[] templateFields;

    public static String jsonString {get; set;}
    public static String jsonUpdatedString {get; set;}
    public static String jsonColumnsString {get; set;}
    public static integer totalOfRecords {get; set;} // used to show user the total size of the list
    public static integer totalDonationAmount {get; set;}
    public static integer totalOfPages {get; set;}
    public List<DataImport__c> errorRecords {get;set;}
    public List<DataImport__c> successRecords {get;set;}
    public Boolean validated {get; set;}


    public BGE_HandsOnGridController() {

        // Initialize variables.
        errorRecords = new List<DataImport__c>();
        successRecords = new List<DataImport__c>();

        // Get the BatchId from the URL.
        findBatchId();
        findTemplateId();

        // Get all Template fields and load columns.
        loadDynamicColumns();

        // Convert loaded Template Fields objects into a JSON String to display dynamic columns.
        jsonColumnsString = JSON.serialize(columns);

        // Get all the Data Import sObjects from the Batch.
        loadData(batchId);

        // Convert loaded Data Import objects into a JSON String.
        // Variable json String will be used to load the data into the grid.
        jsonString = JSON.serialize(data);

        // Escape json string.
        jsonString = String.escapeSingleQuotes(jsonString);

        totalOfRecords = calculateTotalOfRecords(batchId);

        totalDonationAmount = calculateTotalAmount(batchId);

        totalOfPages = calculateTotalPages(batchId, totalOfRecords);
    }

    private static void findBatchId() {

        batchId = ApexPages.currentPage().getParameters().get('batchid');
    }

    private static void findTemplateId() {

        DataImportBatch__c[] batches = new DataImportBatch__c[]{};

        batches = [SELECT Id,
                        Batch_Template__c
                    FROM DataImportBatch__c
                    WHERE Id =: batchId
                    LIMIT :SQL_MINOR_LIMIT];

        if (!batches.isEmpty()) {
            templateId = batches[0].Batch_Template__c;
        }
    }

    private static void loadDynamicColumns() {

        templateFields = new Batch_Template_Field__c[]{};

        BGE_DynamicalColumnWrapper column;
        columns = new BGE_DynamicalColumnWrapper[]{};

        templateFields = [SELECT Id,
                                Name,
                                Order__c,
                                Read_Only__c,
                                Required__c,
                                Sticky_Field__c,
                                Sticky_Field_Value__c,
                                Sticky_Field_Visibility__c
                            FROM Batch_Template_Field__c
                            WHERE Batch_Template__c =: templateId
                            ORDER BY Order__c ASC
                            LIMIT :SQL_MAJOR_LIMIT];

        for (Batch_Template_Field__c field : templateFields) {

            column = new BGE_DynamicalColumnWrapper(field);
            columns.add(column);
        }
    }

    /*
     * Load data for the grid based on Batch Id
     * @Param batchId - Id reference to the current Batch used in the grid
     */
    private static void loadData(Id pBatchId) {

        String query = 'SELECT ';

        for (Batch_Template_Field__c field : templateFields) {

            // This is the first record avoid adding the ',' character
            if (field.Id == templateFields[0].Id) {

                query = query + field.Name;
            }
            else {

                query = query + ', ' + field.Name;
            }

        }

        query = query + ' FROM DataImport__c WHERE NPSP_Data_Import_Batch__c = \'' +  pBatchId +'\'' + ' ORDER BY createdDate ASC LIMIT ' + PAGE_SIZE;

        data = Database.query(query);
    }

    /*
     * @description Updates a Data Import from the json data
     * @param jsonData - data to update the Data Import
     * @return ResponseWrapper
     */
    @RemoteAction
    global static ResponseWrapper updateCell (Id rowId, String pBatchId, String jsonData) {

        ResponseWrapper response = new ResponseWrapper();

        try {

            JSONParser parser = JSON.createParser(jsonData);

            DataImport__c dataImportToUpdate = (DataImport__c) parser.readValueAs(Type.forName('DataImport__c'));
            dataImportToUpdate.NPSP_Data_Import_Batch__c = pBatchId;

            if (rowId != null && !String.isEmpty(rowId)) {

                dataImportToUpdate.Id = rowId;
            }

            upsert dataImportToUpdate;
            response.addDataImportId(dataImportToUpdate.Id);
        }
        catch (DmlException dmlEx) {

            String error = 'Error in this field:     ' + dmlEx.getDmlFieldNames(0);

            response.addError(error);
        }
        catch (JSONException jsonEx){

            String error = 'EXCEPTION OF TYPE ' + jsonEx.getTypeName() + ' WAS CAUSED BY ' + jsonEx.getCause() + ' ' + jsonEx.getMessage() + ' AT LINE ' + jsonEx.getLineNumber();

            response.addError(error);
        }
        catch(System.LimitException limitEx) {

            String error = 'EXCEPTION OF TYPE ' + limitEx.getTypeName() + ' WAS CAUSED BY ' + limitEx.getCause() + ' ' + limitEx.getMessage() + ' AT LINE ' + limitEx.getLineNumber();

            response.addError(error);
        }
        catch (Exception ex) {

            String error = 'EXCEPTION OF TYPE ' + ex.getTypeName() + ' WAS CAUSED BY ' + ex.getCause() + ' ' + ex.getMessage() + ' AT LINE ' + ex.getLineNumber();

            response.addError(error);
        }

        return response;
    }

    /*
     * @description Adds a new Data Import from the json data
     * @param jsonData - data to create the Data Import
     * @return ResponseWrapper
     */
    @RemoteAction
    global static ResponseWrapper save (Id rowId, String pBatchId, String jsonData) {

        ResponseWrapper response = new ResponseWrapper();

        try {

            JSONParser parser = JSON.createParser(jsonData);

            DataImport__c newDataImport = (DataImport__c) parser.readValueAs(Type.forName('DataImport__c'));

            newDataImport.NPSP_Data_Import_Batch__c = pBatchId;

            if (rowId != null && !String.isEmpty(rowId)) {

                newDataImport.Id = rowId;
            }

            upsert newDataImport;

            response.addDataImportId(newDataImport.Id);

            dryRunProcessByRow(newDataImport, pBatchId);

            update newDataImport;

            response.addName(newDataImport.Name);

            response.addFailureInformation(newDataImport.FailureInformation__c);

            response.addAccount1ImportStatus(newDataImport.Account1ImportStatus__c);

            response.addAccount2ImportStatus(newDataImport.Account2ImportStatus__c);

            response.addCampaignMemberStatus(newDataImport.Campaign_Member_Status__c);

            response.addContact1ImportStatus(newDataImport.Contact1ImportStatus__c);

            response.addContact2ImportStatus(newDataImport.Contact2ImportStatus__c);

            response.addDonationImportStatus(newDataImport.DonationImportStatus__c);

            response.addHomeAddressImportStatus(newDataImport.HomeAddressImportStatus__c);

            response.addPaymentImportStatus(newDataImport.PaymentImportStatus__c);

            response.addAccount1Imported(newDataImport.Account1Imported__c);

            response.addAccount2Imported(newDataImport.Account2Imported__c);

            response.addContact1Imported(newDataImport.Contact1Imported__c);

            response.addContact2Imported(newDataImport.Contact2Imported__c);

            response.addDonationImported(newDataImport.DonationImported__c);

            response.addHomeAddressImported(newDataImport.HomeAddressImported__c);

            response.addHouseholdAccountImported(newDataImport.HouseholdAccountImported__c);

            response.addPaymentImported(newDataImport.PaymentImported__c);

            response.addImportedDate(newDataImport.ImportedDate__c);

            response.addStatus(newDataImport.Status__c);

            if (newDataImport.Status__c.equals('Dry Run - Error')) {

                response.addMessage('Please validate information ' + newDataImport.FailureInformation__c);
            }

        }
        catch (DmlException dmlEx) {

            String error = dmlEx.getMessage();

            if (error.contains('STORAGE_LIMIT_EXCEEDED')) {

                error = 'Error: STORAGE_LIMIT_EXCEEDED, Please validate records in the org.';
            }
            else {
                error = 'Error in this field: ' + dmlEx.getDmlFieldNames(0);
            }

            response.addError(error);
        }
        catch (JSONException jsonEx){

            String error = 'Incorrect value on cell, please recheck.';

            system.debug('EXCEPTION OF TYPE ' + jsonEx.getTypeName() + ' WAS CAUSED BY ' + jsonEx.getCause() + ' ' + jsonEx.getMessage() + ' AT LINE ' + jsonEx.getLineNumber());

            response.addError(error);
        }
        catch(System.LimitException limitEx) {

            String error = 'EXCEPTION OF TYPE ' + limitEx.getTypeName() + ' WAS CAUSED BY ' + limitEx.getCause() + ' ' + limitEx.getMessage() + ' AT LINE ' + limitEx.getLineNumber();

            response.addError(error);
        }
        catch (Exception ex) {

            String error = 'EXCEPTION OF TYPE ' + ex.getTypeName() + ' WAS CAUSED BY ' + ex.getCause() + ' ' + ex.getMessage() + ' AT LINE ' + ex.getLineNumber();

            response.addError(error);
        }

        return response;
    }

    /*
     * @description Adds many new Data Import records from the json data
     * @param jsonData - data to create the Data Import
     * @return ResponseWrapper
     */
    @RemoteAction
    global static ResponseWrapper saveAll(String pBatchId,String jsonData) {

        ResponseWrapper response = new ResponseWrapper();

        // Parse entire JSON response.
        JSONParser parser = JSON.createParser(jsonData.replace('""', 'null'));

        List<DataImport__c> sObjectsToInsert = new List<DataImport__c>();
        List<DataImport__c> sObjectsToUpdate = new List<DataImport__c>();

        // To avoid having duplicates at the list.
        Set<Id> existingIds = new Set<Id>();

        try {

            while (parser.nextToken() != null) {

                // Start at the array of data imports.
                if (parser.getCurrentToken() == JSONToken.START_ARRAY) {

                    while (parser.nextToken() != null) {

                        // Advance to the start object marker to
                        //  find next Data Import object.
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {

                            // Read entire Data Import object.
                            Map<String, String> wrap = (Map<String, String>)parser.readValueAs(Map<String, String>.class);

                            Set<String> keySet = wrap.keySet();

                            DataImport__c newDataImport = new DataImport__c();

                            checkType(wrap, newDataImport, keySet);

                            // Insert and upsert are done separately so we can include the ids of the new rows and avoid bugs.
                            if (newDataImport.id == null) {

                                newDataImport.NPSP_Data_Import_Batch__c = pBatchId;

                                sObjectsToInsert.add(newDataImport);
                            }
                            else {

                                sObjectsToUpdate.add(newDataImport);
                            }

                            // Skip the child start array and start object markers.
                            parser.skipChildren();
                        }
                    }
                }
            }

            // If there are new rows.
            if (!sObjectsToInsert.isEmpty()) {

                // The last row is always blank, remove it.
                sObjectsToInsert.remove(sObjectsToInsert.size()-1);

                try{

                    // Insert them
                    insert sObjectsToInsert;

                    // Send a message to the user.
                    response.addMessage('rows inserted correctly');
                }
                catch(DmlException dmlE){

                    String error = dmlE.getStackTraceString();

                    // Send a message to the user.
                    response.addError(error);
                }

            }
            // For updated rows
            if (!sObjectsToUpdate.isEmpty()) {

                try{

                    // Do the update.
                    update sObjectsToUpdate;

                    // Send a message to the user.
                    response.addMessage('rows updated correctly');
                }
                catch(DmlException dmlE){

                    String error = dmlE.getStackTraceString();

                    // Send a message to the user.
                    response.addError(error);
                }
            }
        }
        catch (Exception e) {

            String error = e.getStackTraceString();

            response.addError(error);
        }

        return response;
    }

    private static void checkType(Map<String, String> wrap, DataImport__c newDataImport, set<String> keySet) {

        if (!keySet.isEmpty()) {

            // as we are sending changes on the JSON, the fields we are using may vary
            // therefore loop over the values sent on the JSON.
            for (String key : keySet) {

                if (wrap.containsKey(key)) {

                    if (wrap.get(key) != null){

                        Schema.SObjectField field = fieldsMap.get(key);

                        Schema.DisplayType fldType = field.getDescribe().getType();

                        // Assign value from the JSON to the corresponding field in the data import.
                        if (fldType != Schema.DisplayType.String) {

                            if (fldType == Schema.DisplayType.Id){

                                Id idField = wrap.get(key);
                                newDataImport.put(key,idField);
                            }
                            else if (fldType == Schema.DisplayType.Date) {

                                Date dateField = system.today();

                                try{

                                    dateField = Date.valueOf(wrap.get(key));
                                }
                                catch(TypeException e){

                                    // If date format was incorrect.
                                    dateField = Date.parse(wrap.get(key));
                                }

                                newDataImport.put(key,dateField);
                            }
                            else if (fldType == Schema.DisplayType.DateTime) {

                                DateTime dateTimeFIeld = system.now();

                                try{

                                    dateTimeFIeld = DateTime.parse(wrap.get(key));
                                }
                                catch(TypeException e){

                                    dateTimeFIeld = DateTime.valueOf(wrap.get(key));
                                }

                                newDataImport.put(key,dateTimeFIeld);
                            }
                            else if (fldType == Schema.DisplayType.Double){

                                Double doubleField = Double.valueOf(wrap.get(key));
                                newDataImport.put(key,doubleField);
                            }
                            else if (fldType == Schema.DisplayType.Boolean){

                                Boolean booleanField = Boolean.valueOf(wrap.get(key));
                                newDataImport.put(key,booleanField);
                            }
                            else if (fldType == Schema.DisplayType.Currency) {

                                Decimal currencyField = Decimal.valueOf(wrap.get(key));
                                newDataImport.put(key,currencyField);
                            }
                            else if(fldType == Schema.DisplayType.Integer){

                                Integer integerField = Integer.valueOf(wrap.get(key));
                                newDataImport.put(key,integerField);
                            }
                        }
                        else {

                            newDataImport.put(key,wrap.get(key));
                        }
                    }
                }
            }
        }
    }


    /*
     * @description Deletes many Data Import objects from the json data
     * @param batchIds - Ids of the Data Imports to delete.
     * @return ResponseWrapper
     */
    @RemoteAction
    global static ResponseWrapper deleteAll(List<String> batchIds) {

        ResponseWrapper response = new ResponseWrapper();

        try {

            // Check that we have received the Ids from the Javascript controller.
            if (batchIds != null && !batchIds.isEmpty()) {

                // Assign the objects to a list to ease debugging and defensive programming.
                List<DataImport__c> dataImportsToDelete = [SELECT Id, Donation_Name__c from DataImport__c WHERE Id IN: batchIds];

                // Check that we have received the objects from the Salesforce database.
                if (dataImportsToDelete != null && !dataImportsToDelete.isEmpty()) {

                    delete dataImportsToDelete;

                    response.addMessage('Data Import records successfully deleted');
                }
                else{

                    response.addMessage('No record was found on the database.');
                }
            }
            else {

                response.addMessage('No record was sent for deletion');
            }
        }
        catch (Exception e) {

            String error = e.getStackTraceString();

            response.addError(error);
        }

        return response;
    }


    // Save all rows to the database.
    public void continueToValidation(){

        if (data != null && !data.isEmpty()) {

            Database.UpsertResult[] lsr = Database.upsert(data, false);
            Integer index = 0;

            if (!lsr.isEmpty()) {

                for (Database.UpsertResult sr : lsr) {

                    try {

                        if (sr.isSuccess()) {

                            successRecords.add(data[index]);
                        }
                        else if (!sr.isSuccess()) {

                            errorRecords.add(data[index]);
                        }
                    }
                    catch(Exception ex) {

                        system.debug('EXCEPTION MESSAGE:    ' + ex.getMessage());
                    }

                    index++;
                }
            }
        }

        data = errorRecords;

        jsonString = JSON.serialize(data);

        validated = true;
    }

    /*
    * @description Run Dry Run process - and display errors if something goes wrong.
    * @return ResponseWrapper
    */
    @RemoteAction
    global static ResponseWrapper dryRunProcess(String pBatchId) {

        list<ID> listBatchId = new list<ID>();

        listBatchId.add(pBatchId);

        ResponseWrapper response = new ResponseWrapper();

        try {

            List<BDI_DataImport_API.ProcessDataImportBatchesResult> importedBatches = BDI_DataImport_API.processDataImportBatches(listBatchId,true);

            for (BDI_DataImport_API.ProcessDataImportBatchesResult result : importedBatches) {

                response.addMessage('BATCH JOB IS RUNNING WITH ID:    ' + result.apexJobId);
            }

        } catch (exception ex) {

            response.addError(ex.getMessage());
        }

        return response;
    }

     /*******************************************************************************************************
    * @description Integrate BDI Dry Run logic, process each DataImport saved in the grid. Get Data Import Setting corresponding to the batch
    * @param Data Import record (edited or created). Batch Id corresponding to current batch used in the grid
    * @return ResponseWrapper Result of data to set at grid level
    */ 
    @RemoteAction
    global static ResponseWrapper dryRunProcessByRow (DataImport__c dataImport, String pBatchId) {

        DataImportBatch__c[] batches = new DataImportBatch__c[]{};
        DataImportBatch__c currentBatch;

        batches = [SELECT Id,
                        Batch_Template__c,
                        Account_Custom_Unique_ID__c,
                        Batch_Process_Size__c,
                        Contact_Custom_Unique_ID__c,
                        Contact_Matching_Rule__c,
                        Donation_Matching_Behavior__c,
                        Donation_Matching_Implementing_Class__c,
                        Donation_Matching_Rule__c,
                        Donation_Date_Range__c,
                        Run_Opportunity_Rollups_while_Processing__c,
                        Post_Process_Implementing_Class__c
                    FROM DataImportBatch__c
                    WHERE Id =: pBatchId
                    LIMIT :SQL_MINOR_LIMIT];

        try {

             if (!batches.isEmpty()) {
                currentBatch = batches[0];
            }

            Data_Import_Settings__c diSetting = BDI_DataImportService.diSettingsFromDiBatch(currentBatch);

            DataImport__c[] dataImports = new DataImport__c[]{};
            dataImports.add(dataImport);

            if (diSetting != null) {

                BDI_DataImport_API.processDataImportRecords(diSetting, dataImports, true);
            }
        }
        catch (Exception ex) {
            System.debug('Error at time to obtain DataImportSetting from BDI Class diSettingsFromDiBatch ' + ex.getMessage());
        }

        ResponseWrapper response = new ResponseWrapper();

        return response;
    }


    @RemoteAction
    global static List<DataImport__c> changePage(String pBatchId, Integer pOffset) {    //user clicked the Next button

        List<DataImport__c> result = new List<DataImport__c>();

        batchId = pBatchId;

        findTemplateId();

        // Get all Template fields and load columns.
        loadDynamicColumns();

        // Convert loaded Template Fields objects into a JSON String to display dynamic columns.
        jsonColumnsString = JSON.serialize(columns);

        String query = 'SELECT ';

        for (Batch_Template_Field__c field : templateFields) {

            // This is the first record avoid adding the ',' character
            if (field.Id == templateFields[0].Id) {

                query = query + field.Name;
            }
            else {

                query = query + ', ' + field.Name;
            }

        }

        query = query + ' FROM DataImport__c WHERE NPSP_Data_Import_Batch__c = \'' +  pBatchId +'\'' + ' ORDER BY createdDate ASC LIMIT ' + PAGE_SIZE + ' OFFSET ' + pOffset;

        result = Database.query(query);

        return result;
    }


    @RemoteAction
    global static Integer calculateTotalOfRecords(String pBatchId) {

        Integer result;

        // set the total size in the constructor
        result = [SELECT count() FROM DataImport__c WHERE NPSP_Data_Import_Batch__c =: pBatchId];

        return result;
    }

    @RemoteAction
    global static Integer calculateTotalAmount(String pBatchId) {

        Integer result;

        List<AggregateResult> query = [SELECT SUM(Donation_Amount__c) FROM DataImport__c WHERE NPSP_Data_Import_Batch__c =: pBatchId AND Donation_Amount__c != null];    //set the total size in the constructor

        result = Integer.valueOf(query[0].get('expr0'));

        return result;
    }

    @RemoteAction
    global static Integer calculateTotalPages(String pBatchId, Integer pTotalOfRecords) {

        Integer result = 0;
        system.debug('MODULE    ' + math.mod(pTotalOfRecords, PAGE_SIZE));
        if (math.mod(pTotalOfRecords, PAGE_SIZE) >= 0) {
            system.debug('pTotalOfRecords    ' + pTotalOfRecords);
            result = pTotalOfRecords/PAGE_SIZE + 1;
            system.debug('RESULT    ' + result);
            totalOfPages = result;
        }
        else {

            result = pTotalOfRecords/PAGE_SIZE;

            totalOfPages  = result;
        }

        return result;
    }



    global class ResponseWrapper {

        public Boolean success { get; set; }
        public String[] messages { get; set; }
        public String[] dataImportIds { get; set; }

        public String name { get; set; }
        public String failureInformation { get; set; }
        public String account1ImportStatus { get; set; }
        public String account2ImportStatus { get; set; }
        public String campaignMemberStatus { get; set; }
        public String contact1ImportStatus { get; set; }
        public String contact2ImportStatus { get; set; }
        public String donationImportStatus { get; set; }
        public String homeAddressImportStatus { get; set; }
        public String paymentImportStatus { get; set; }
        public String account1Imported { get; set; }
        public String account2Imported { get; set; }
        public String contact1Imported { get; set; }
        public String contact2Imported { get; set; }
        public String donationImported { get; set; }
        public String homeAddressImported { get; set; }
        public String householdAccountImported { get; set; }
        public String paymentImported { get; set; }
        public DateTime importedDate { get; set; }
        public String status { get; set; }


        //Constructor
        public ResponseWrapper() {

            success = true;
            messages = new String[]{};
            dataImportIds = new String[]{};
        }


        /*
         * add a message with the Id to the list.
         * @Param message - message to add
         */
        public void addMessage(String message) {

            messages.add(message);
        }


        /*
         * add am error message to the list.
         * @Param message - message to add
         */
        public void addError(String errorMessage) {

            success = false;
            addMessage(errorMessage);
        }

        public void addName(String pName){

            name = pName;
        }

        public void addDataImportId(String dataImportId) {

            dataImportIds.add(dataImportId);
        }

        public void addFailureInformation(String pFailureInformation) {

            failureInformation = pFailureInformation;
        }

        public void addAccount1ImportStatus(String pAccount1ImportStatus) {

            account1ImportStatus = pAccount1ImportStatus;
        }

        public void addAccount2ImportStatus(String pAccount2ImportStatus) {

            account2ImportStatus = pAccount2ImportStatus;
        }

        public void addCampaignMemberStatus(String pCampaignMemberStatus) {

            campaignMemberStatus = pCampaignMemberStatus;
        }

        public void addContact1ImportStatus(String pContact1ImportStatus) {

            contact1ImportStatus = pContact1ImportStatus;
        }

        public void addContact2ImportStatus(String pContact2ImportStatus) {

            contact2ImportStatus = pContact2ImportStatus;
        }

        public void addDonationImportStatus(String pDonationImportStatus) {

            donationImportStatus = pDonationImportStatus;
        }

        public void addHomeAddressImportStatus(String pHomeAddressImportStatus) {

            homeAddressImportStatus = pHomeAddressImportStatus;
        }

        public void addPaymentImportStatus(String pPaymentImportStatus) {

            paymentImportStatus = pPaymentImportStatus;
        }

        public void addAccount1Imported(String pAccount1Imported) {

            account1Imported = pAccount1Imported;
        }

        public void addAccount2Imported(String pAccount2Imported) {

            account2Imported = pAccount2Imported;
        }

        public void addContact1Imported(String pContact1Imported) {

            contact1Imported = pContact1Imported;
        }

        public void addContact2Imported(String pContact2Imported) {

            contact2Imported = pContact2Imported;
        }

        public void addDonationImported(String pDonationImported) {

            donationImported = pDonationImported;
        }

        public void addHomeAddressImported(String pHomeAddressImported) {

            homeAddressImported = pHomeAddressImported;
        }

        public void addHouseholdAccountImported(String pHouseholdAccountImported) {

            householdAccountImported = pHouseholdAccountImported;
        }

        public void addPaymentImported(String pPaymentImported) {

            paymentImported = pPaymentImported;
        }

        public void addImportedDate(DateTime pImportedDate) {

            importedDate = pImportedDate;
        }

        public void addStatus(String pStatus) {

            status = pStatus;
        }
    }
}