public with sharing class BGE_TemplateController {

    private static final Integer SQL_MAJOR_LIMIT = 10000;
    private static final Integer SQL_MINOR_LIMIT = 1;

    public static Batch_Template__c templateRecord = new Batch_Template__c();
    public static DataImportBatch__c batchRecord = new DataImportBatch__c();
    public static Id templateId;
    public static String[] templateFieldNames = new String[]{};
    public static Batch_Template_Field__c[] templateFields;
    public static Batch_Template_Field__c[] templateFieldsToDelete;

    private static final Set<String> TEMPLATE_FIELDS_TO_REMOVE = new Set<String>{'Account1Imported__c', 
                                                                                'Account1ImportStatus__c',
                                                                                'Account2Imported__c',
                                                                                'Account2ImportStatus__c',
                                                                                'ApexJobId__c',
                                                                                'Contact1Imported__c',
                                                                                'Contact1ImportStatus__c',
                                                                                'Contact2Imported__c',
                                                                                'Contact2ImportStatus__c',
                                                                                'DonationImported__c',
                                                                                'DonationImportStatus__c',
                                                                                'Donation_Possible_Matches__c',
                                                                                'FailureInformation__c',
                                                                                'HomeAddressImported__c',
                                                                                'HomeAddressImportStatus__c',
                                                                                'HouseholdAccountImported__c',
                                                                                'ImportedDate__c',
                                                                                'NPSP_Data_Import_Batch__c',
                                                                                'PaymentImported__c',
                                                                                'PaymentImportStatus__c',
                                                                                'Payment_Possible_Matches__c',
                                                                                'Status__c',
                                                                                'Account2ImportStatus__c'
                                                                                };

    public BGE_TemplateController() {}

    public static Id saveBatch (DataImportBatch__c batch, Id templateId) {

        Id batchId = null;
        batchRecord = batch;
        batchRecord.Batch_Template__c = templateId;

        // Insert batch
        if (batchRecord != null) {

           insert batchRecord;

           batchId = batchRecord.Id;
        }
        return batchId;
    }

    public static Id updateBatch (DataImportBatch__c batch, Id templateId) {

        Id batchId = null;
        batchRecord = batch;
        batchRecord.Batch_Template__c = templateId;

        // Insert batch
        if (batchRecord != null) {

           update batchRecord;
           batchId = batchRecord.Id;
        }
        return batchId;
    }

    public static String saveTemplate (Batch_Template__c newTemplate, Batch_Template_Field__c[] batchTemplateFields) {

        String result = '';
        templateRecord = newTemplate;
        templateFields = batchTemplateFields;

        // Insert template
        if (templateRecord != null) {

            try {

                insert templateRecord;
                Batch_Template_Field__c templateFieldId = new Batch_Template_Field__c(Read_Only__c = false, Batch_Template__c=templateRecord.Id, Order__c=2, Required__c=false, Sticky_Field_Visibility__c=false, Name='Id');
                batchTemplateFields.add(templateFieldId);
                saveTemplateFields(templateFields, templateRecord.Id);
            }
            catch (DMLException ex) {
                result = ex.getMessage();

                if (!result.contains('STORAGE_LIMIT_EXCEEDED')) {
                    result = 'There is already a record with this Name, please change the Name.';
                }
                else {
                    result = 'STORAGE_LIMIT_EXCEEDED: You need to review count of existing records for template object.';
                }
            }
            catch (Exception ex) {
                result = ex.getMessage();
            }
        }
        return result;
    }



    public static Boolean deleteTemplate (Id templateIdToDelete) {

        Boolean result = false;
        Batch_Template__c templateToDelete;
        Batch_Template__c[] templates = [SELECT Id FROM Batch_Template__c WHERE Id = :templateIdToDelete LIMIT :SQL_MINOR_LIMIT];
        DataImportBatch__c[] batches = [SELECT Id, Batch_Template__c FROM DataImportBatch__c WHERE Batch_Template__c = :templateIdToDelete LIMIT :SQL_MAJOR_LIMIT];

        if (!templates.isEmpty() && batches.isEmpty()) {

            templateToDelete = templates[0];

            try {
                delete templateToDelete;
                result = true;
            }
            catch(Exception ex) {
                result = false;
            }
        }
        else {
            result = false;
        }
        return result;
    }

    public static String cloneTemplate (Batch_Template__c newTemplate, Batch_Template_Field__c[] batchTemplateFields) {

        String result = '';
        templateRecord = newTemplate;
        templateFields = batchTemplateFields;

        Batch_Template__c templateToClone = new Batch_Template__c(Name = templateRecord.Name, Description__c = templateRecord.Description__c);

        // Insert template
        if (templateToClone != null) {

            try {

                insert templateToClone;
                cloneTemplateFields(templateFields, templateToClone.Id);
            }
            catch (DMLException ex) {
                result = ex.getMessage();

                if (!result.contains('STORAGE_LIMIT_EXCEEDED')) {
                    result = 'There is already a record with this Name, please change the Name.';
                }
                else {
                    result = 'STORAGE_LIMIT_EXCEEDED: You need to review count of existing records for template object.';
                }
            }
            catch (Exception ex) {
                result = ex.getMessage();
            }
        }
        return result;
    }

    public static String editTemplate (Batch_Template__c newTemplate, Batch_Template_Field__c[] batchTemplateFields, Batch_Template_Field__c[] batchTemplateFieldsToDelete) {

        String result = '';
        templateRecord = newTemplate;
        templateFields = batchTemplateFields;

        // Update template
        if (templateRecord != null) {

            try {

                update templateRecord;
                Map<String, Batch_Template_Field__c> existingTemplateFields = loadTemplateFieldsMap(templateRecord.Id);

                updateTemplateFields(templateFields, existingTemplateFields, templateRecord.Id);
                deleteTemplateFields(templateFields, existingTemplateFields);
            }
            catch (DMLException ex) {
                result = ex.getMessage();

                if (!result.contains('STORAGE_LIMIT_EXCEEDED')) {
                    result = 'There is already a record with this Name, please change the Name.';
                }
                else {
                    result = 'STORAGE_LIMIT_EXCEEDED: You need to review count of existing records for template object.';
                }
            }
            catch (Exception ex) {
                result = ex.getMessage();
            }
        }
        return result;
    }

    private static void saveTemplateFields (Batch_Template_Field__c[] templateFields, Id templateId) {

        Batch_Template_Field__c[] templateFieldsToSave = new Batch_Template_Field__c[]{};

        for (Batch_Template_Field__c templateField : templateFields) {

            templateField.Batch_Template__c = templateId;
            templateFieldsToSave.add(templateField);
        }

        if (!templateFieldsToSave.isEmpty()) {

            upsert templateFieldsToSave;
        }
    }
    private static void updateTemplateFields (Batch_Template_Field__c[] templateFields, Map<String, Batch_Template_Field__c> existingTemplateFieldsMap, Id templateId) {

        Batch_Template_Field__c[] templateFieldsToSave = new Batch_Template_Field__c[]{};

        for (Batch_Template_Field__c templateField : templateFields) {

            if (!existingTemplateFieldsMap.isEmpty()) {

                if (existingTemplateFieldsMap.containsKey(templateField.Name)) {

                    Batch_Template_Field__c existingTemplateField = existingTemplateFieldsMap.get(templateField.Name);
                    templateField.Id = existingTemplateField.Id;
                }
            }

            if (templateField.Id == null) {

                templateField.Batch_Template__c = templateId;
            }

            templateFieldsToSave.add(templateField);
        }

        if (!templateFieldsToSave.isEmpty()) {

            upsert templateFieldsToSave;
        }


    }

    private static void cloneTemplateFields (Batch_Template_Field__c[] templateFields, Id templateId) {

        Batch_Template_Field__c[] templateFieldsToSave = new Batch_Template_Field__c[]{};
        Batch_Template_Field__c templateToClone = null;

        for (Batch_Template_Field__c templateField : templateFields) {

            templateToClone =  new Batch_Template_Field__c(Batch_Template__c = templateId,
                                                            Name = templateField.Name,
                                                            Order__c = templateField.Order__c,
                                                            Read_Only__c = templateField.Read_Only__c,
                                                            Required__c = templateField.Required__c
                                                            );

            if (templateToClone != null) {
                templateFieldsToSave.add(templateToClone);
            }
        }

        if (!templateFieldsToSave.isEmpty()) {
            insert templateFieldsToSave;
        }
    }

    public static Boolean deleteTemplateFields (Batch_Template_Field__c[] templateFields, Map<String, Batch_Template_Field__c> existingTemplateFieldsMap) {

        Boolean result = false;
        Boolean exists = false;
        Integer i = 0;
        Batch_Template_Field__c[] templateFieldsToDelete = new Batch_Template_Field__c[]{};


        for (Batch_Template_Field__c templateField : existingTemplateFieldsMap.values()) {

            exists = false;
            i = 0;
            while(!exists && i < templateFields.size()) {

                Batch_Template_Field__c templateFieldNew = templateFields[i];
                if (templateFieldNew.Name.equals(templateField.Name)) {

                    exists = true;
                }
                i++;
            }

            if (!exists && !templateField.Name.equals('Id')) {
                templateFieldsToDelete.add(templateField);
            }
        }

        if (!templateFieldsToDelete.isEmpty()) {
            delete templateFieldsToDelete;
        }

        return true;
    }

    public static Batch_Template_Field__c[] loadTemplateFields (Id templateId) {

        Batch_Template_Field__c[] templateFields = new Batch_Template_Field__c[]{};

        templateFields = [SELECT Id,
                                Name,
                                Order__c,
                                Read_Only__c,
                                Required__c,
                                Batch_Template__c
                            FROM Batch_Template_Field__c
                            WHERE Batch_Template__c = :templateId
                            ORDER BY Order__c
                            LIMIT :SQL_MAJOR_LIMIT];

        if (templateFields.isEmpty()) {
            templateFields = null;
        }

        return templateFields;
    }

    private static Map<String, Batch_Template_Field__c> loadTemplateFieldsMap (Id templateId) {


        Map<String, Batch_Template_Field__c> templateFieldsMap = new Map<String, Batch_Template_Field__c>(); 
        for(Batch_Template_Field__c templateField : [SELECT Id,
                                                            Name,
                                                            Order__c,
                                                            Read_Only__c,
                                                            Required__c,
                                                            Batch_Template__c
                                                        FROM Batch_Template_Field__c
                                                        WHERE Batch_Template__c = :templateId
                                                        ORDER BY Order__c
                                                        LIMIT :SQL_MAJOR_LIMIT])
                templateFieldsMap.put(templateField.Name, templateField);


        return templateFieldsMap;
    }

    public static Batch_Template__c[] loadTemplates () {

        Batch_Template__c[] templates = new Batch_Template__c[]{};

        templates = [SELECT Id, Name, Description__c FROM Batch_Template__c];

        return templates;
    }

    public static Batch_Template_Field__c[] loadDataImportApiNames () {

        Schema.FieldSetMember[] templateFieldSet = SObjectType.DataImport__c.FieldSets.Data_Import_Field_Set.getFields();
        Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.DataImport__c.fields.getMap();

        List< Map<String, Object>> apiNameOptions = new List<Map<String, Object>>{};
        Batch_Template_Field__c[] templateFields = new Batch_Template_Field__c[]{};

        for(Schema.FieldSetMember fm : templateFieldSet) {

			String fieldType = String.valueOf(fm.getType());

			if (fieldsMap.containsKey(fm.getFieldPath()) && (fieldsMap.get(fm.getFieldPath())).getDescribe().isUpdateable()) {

                if (!TEMPLATE_FIELDS_TO_REMOVE.contains(fm.getFieldPath())) {

                    Map<String, Object> labelApiNameMap = new Map<String, Object>();
                    Batch_Template_Field__c templateField = new Batch_Template_Field__c(Name = fm.getFieldPath(), Label__c = fm.getLabel());

                    templateFields.add(templateField);
                }
			}
		}

        return templateFields;
    }



    public static Batch_Template__c loadtemplateName(Id templateId) {

        Batch_Template__c templateName = [SELECT Name, Description__c FROM Batch_Template__c WHERE Id =: templateId LIMIT 1][0];

        return templateName;
    }
}