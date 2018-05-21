public with sharing class BGE_HandsOnGridColumnWrapper {

    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_enum_Schema_DisplayType.htm

    private static final String DATA_IMPORT_NAME = 'DataImport__c';
    private static final String ACCOUNT_NAME = 'Account';
    private static final String CONTACT_NAME = 'Contact';
    private static final String OPPORTUNITY_NAME = 'Opportunity';

    private static final Set<String> LOOKUP_VALUES_CONTACT = new Set<String>(new String[] {'contact1', 'contact2'});
    private static final Set<String> LOOKUP_VALUES_ACCOUNT = new Set<String>(new String[] {'account1', 'account2'});

    private static final String RECORDTYPEID_NAME = 'RecordTypeId';

    public String label {get; set;}
    public String apiName {get; set;}
    public String type {get; set;}
    public Boolean required {get; set;}
    public Map<String, String> picklistValues {get; set;}

	public BGE_HandsOnGridColumnWrapper(Batch_Template_Field__c templateField) {

        picklistValues =  null;
        String objectName = DATA_IMPORT_NAME;

        Schema.SObjectField dataImportField = getObjectFields(DATA_IMPORT_NAME).get(templateField.Name);
        Schema.DescribeFieldResult dataImportFieldDescribe = dataImportField.getDescribe();

        Schema.SObjectField recordField = dataImportField;
        Schema.DescribeFieldResult recordFieldDescribe = dataImportFieldDescribe;

        // On the Help Text - We have the Object Relation of the field we are trying to match to.
        if (String.isNotEmpty(recordFieldDescribe.getInlineHelpText())) {

            System.debug(recordFieldDescribe.getName() + ' ' + recordFieldDescribe.getInlineHelpText());

            String[] fieldsRelationship = recordFieldDescribe.getInlineHelpText().toLowerCase().split('\\.');

            if (LOOKUP_VALUES_CONTACT.contains(fieldsRelationship[0]) && String.isNotEmpty(fieldsRelationship[1])) {

                recordField = getObjectFields(CONTACT_NAME).get(fieldsRelationship[1]);
                recordFieldDescribe = recordField.getDescribe();
                objectName = CONTACT_NAME;
            }
            else if (LOOKUP_VALUES_ACCOUNT.contains(fieldsRelationship[0]) && String.isNotEmpty(fieldsRelationship[1])) {

                recordField = getObjectFields(ACCOUNT_NAME).get(fieldsRelationship[1]);
                recordFieldDescribe = recordField.getDescribe();
                objectName = ACCOUNT_NAME;
            }
            else if (fieldsRelationship[0].contains(OPPORTUNITY_NAME.toLowerCase()) && String.isNotEmpty(fieldsRelationship[1])) {

                recordField = getObjectFields(OPPORTUNITY_NAME).get(fieldsRelationship[1]);
                recordFieldDescribe = recordField.getDescribe();
                objectName = OPPORTUNITY_NAME;
            }
        }

        label = dataImportFieldDescribe.getLabel();
        type = String.valueOf(recordFieldDescribe.getType()).toUpperCase();
        apiName = templateField.Name;
        required = templateField.Required__c;

        if (type.equalsIgnoreCase('PICKLIST')) {
            picklistValues = getObjectFieldPicklistValues(recordFieldDescribe);
        }

        if (recordFieldDescribe.getName().equalsIgnoreCase(RECORDTYPEID_NAME)) {
            type = 'PICKLIST';
            picklistValues = getObjectRecordTypes(objectName);
        }
    }

	private static Map<String, String> getObjectFieldPicklistValues(Schema.DescribeFieldResult fieldDescribe) {

        Map<String, String> result = new Map<String, String>();

		for (Schema.PicklistEntry value :fieldDescribe.getPicklistValues()) {

            result.put(value.getLabel(), value.getValue());
		}

        return result;
    }

	private static Map<String, String> getObjectRecordTypes(String objectName) {

        Map<String, String> result = new Map<String, String>();

        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByName();

        for (Schema.RecordTypeInfo recordType :recordTypes.values()) {

            result.put(recordType.getName(), recordType.getRecordTypeId());
        }

        return result;
    }

    private static Map<String, Schema.SObjectField> getObjectFields(String objectName) {

        return Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    }

}