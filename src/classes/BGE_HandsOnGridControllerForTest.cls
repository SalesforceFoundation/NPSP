global class BGE_HandsOnGridControllerForTest{


    public static String jsonString {get; set;}

    private static Id batchId;
    private static List<DataImport__c> data;
    private static Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.DataImport__c.fields.getMap();

    public List<DataImport__c> errorRecords {get;set;}
    public List<DataImport__c> successRecords {get;set;}

    public Boolean validated {get; set;}


    public BGE_HandsOnGridControllerForTest() {

        // Initialize variables.
        errorRecords = new List<DataImport__c>();
        successRecords = new List<DataImport__c>();

        // Get the BatchId from the URL.
        findBatchId();

        // Get all the Data Import sObjects from the Batch.
        loadData(batchId);

        // Convert loaded Data Import objects into a JSON String.
        // Variable json String will be used to load the data into the grid.
        jsonString = JSON.serialize(data);
    }

    private static void findBatchId() {

        batchId = ApexPages.currentPage().getParameters().get('batchid');
    }

    private static void loadData(Id pBatchId) {

        data = [SELECT Id,
                       Donation_Name__c,
                       Donation_Amount__c,
                       Donation_Date__c,
                       Donation_Stage__c,
                       Donation_Donor__c,
                       NPSP_Data_Import_Batch__c

                FROM DataImport__c
                WHERE NPSP_Data_Import_Batch__c =: pBatchId
                ORDER BY createdDate ASC
                LIMIT 5000];

    }

    /*
     * Adds a new Data Import from the json data
     * @Param jsonData - data to create the Data Import
     * @Returns ResponseWrapper
     */
    @RemoteAction
    global static ResponseWrapper save(Id rowId, String pBatchId, String jsonData) {

        ResponseWrapper response = new ResponseWrapper();

        JSONParser parser = JSON.createParser(jsonData);

        try {

            DataImport__c newDataImport = (DataImport__c) parser.readValueAs(Type.forName('DataImport__c'));

            newDataImport.NPSP_Data_Import_Batch__c = pBatchId;

            if (rowId != null && !String.isEmpty(rowId)) {

                newDataImport.Id = rowId;
            }

            upsert newDataImport;

            response.addDataImportId(newDataImport.Id);

        //    response.addMessage('Data Import successfully created or updated');
        }
        catch (Exception e) {

            String error = e.getStackTraceString();

            response.addError(error);
        }

        return response;
    }

    /*
     * Delete a Data Import from the org.
     * @Param Id - Id of the sObject to delete.
     * @Returns ResponseWrapper
     */
    @RemoteAction
    global static ResponseWrapper deleteRow(Id rowId) {

        ResponseWrapper response = new ResponseWrapper();

        try {

            if (rowId != null) {

                DataImport__c dataImportToDelete = [SELECT Id FROM DataImport__c WHERE Id =: rowId];

                delete dataImportToDelete;

            //    response.addMessage('Data Import successfully deleted');
            }
        }
        catch (Exception e) {

            String error = e.getMessage();

            response.addError(error);
        }

        return response;
    }

    /*
     * Adds many new Data Import records from the json data
     * @Param jsonData - data to create the Data Import
     * @Returns ResponseWrapper
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

                            //    response.addMessage('Data Import successfully created or updated');
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
                //    response.addMessage('rows inserted correctly');

                    reloadData(pBatchId);

                    // Add the Ids of the newly created objects to the table.
                    for (DataImport__c currentNewDataImport : sObjectsToInsert) {
                        response.addMessage(currentNewDataImport.Id);
                        if (currentNewDataImport != null) {

                            response.addDataImportId(currentNewDataImport.Id);
                        }
                    }
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
                //    response.addMessage('rows updated correctly');
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
     * Deletes many Data Import objects from the json data
     * @Param batchIds - Ids of the Data Imports to delete.
     * @Returns ResponseWrapper
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

                //    response.addMessage('Data Import records successfully deleted');
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


    private static void reloadData(String pBatchId) {

        jsonString = '';

        // Clear the collection to make sure we don't have anything bothering.
    //    data = new List<DataImport__c>();

        // Get all the Data Import sObjects from the Batch.
        loadData(pBatchId);

        system.debug('DATA SIZE:    ' + data.size());

        // Convert loaded Data Import objects into a JSON String.
        // Variable json String will be used to load the data into the grid.
        jsonString = JSON.serialize(data);
    }


    global class ResponseWrapper {

        public Boolean success { get; set; }
        public String[] messages { get; set; }
        public String[] dataImportIds { get; set; }

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

        public void addDataImportId(String dataImportId) {

            dataImportIds.add(dataImportId);
        }
    }


}