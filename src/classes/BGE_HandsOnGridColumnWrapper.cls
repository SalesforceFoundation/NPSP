public with sharing class BGE_HandsOnGridColumnWrapper {

    // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_enum_Schema_DisplayType.htm

    public static final String DATA_IMPORT_NAME = 'DataImport__c';
    private static final String ACCOUNT_NAME = 'Account';
    private static final String CONTACT_NAME = 'Contact';
    private static final String PAYMENT_NAME = 'npe01__OppPayment__c';
    private static final String HOUSEHOLD_NAME = 'Account';
    private static final String ADDRESS_NAME = 'Address__c';
    private static final String OPPORTUNITY_NAME = 'Opportunity';

    private static final Set<String> LOOKUP_VALUES_PAYMENT = new Set<String>(new String[] {'payment', 'npe01__opppayment__c'});
    private static final Set<String> LOOKUP_VALUES_HOUSEHOLD = new Set<String>(new String[] {'household', 'npo02__household__c'});
    private static final Set<String> LOOKUP_VALUES_ADDRESS = new Set<String>(new String[] {'address', 'address__c', 'npsp__address__c'});
    private static final Set<String> LOOKUP_VALUES_CONTACT = new Set<String>(new String[] {'contact1', 'contact2'});
    private static final Set<String> LOOKUP_VALUES_ACCOUNT = new Set<String>(new String[] {'account1', 'account2'});

    private static final String RECORDTYPEID_NAME = 'RecordTypeId';

    public String label {get; set;}
    public String apiName {get; set;}
    public String type {get; set;}
    public Boolean required {get; set;}
    public Map<String, String> picklistValues {get; set;}
    public Boolean isRecordType {get; set;}

    public BGE_HandsOnGridColumnWrapper(Map<String,Object> templateField) {
        
        picklistValues =  null;
        isRecordType = false;
        String objectName = DATA_IMPORT_NAME;

        Schema.SObjectField dataImportField = getObjectFields(DATA_IMPORT_NAME).get((String)templateField.get('name'));
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
            else if (LOOKUP_VALUES_PAYMENT.contains(fieldsRelationship[0]) && String.isNotEmpty(fieldsRelationship[1])) {

                recordField = getObjectFields(PAYMENT_NAME).get(fieldsRelationship[1]);
                recordFieldDescribe = recordField.getDescribe();
                objectName = PAYMENT_NAME;
            }
            else if (LOOKUP_VALUES_HOUSEHOLD.contains(fieldsRelationship[0]) && String.isNotEmpty(fieldsRelationship[1])) {

                recordField = getObjectFields(HOUSEHOLD_NAME).get(fieldsRelationship[1]);
                recordFieldDescribe = recordField.getDescribe();
                objectName = HOUSEHOLD_NAME;
            }
            else if (LOOKUP_VALUES_ADDRESS.contains(fieldsRelationship[0]) && String.isNotEmpty(fieldsRelationship[1])) {

                recordField = getObjectFields(ADDRESS_NAME).get(fieldsRelationship[1].remove('npsp__'));

                recordFieldDescribe = recordField.getDescribe();
                objectName = ADDRESS_NAME;
            }
            else if (fieldsRelationship[0].contains(OPPORTUNITY_NAME.toLowerCase()) && String.isNotEmpty(fieldsRelationship[1])) {

                recordField = getObjectFields(OPPORTUNITY_NAME).get(fieldsRelationship[1]);
                recordFieldDescribe = recordField.getDescribe();
                objectName = OPPORTUNITY_NAME;
            }
        }

        label = recordFieldDescribe.getLabel();
        type = String.valueOf(recordFieldDescribe.getType()).toUpperCase();
        apiName = (String)templateField.get('name');
        required = (Boolean)templateField.get('required');

        if (type.equalsIgnoreCase('PICKLIST')) {
            picklistValues = getObjectFieldPicklistValues(recordFieldDescribe);
        }

        if (recordFieldDescribe.getName().equalsIgnoreCase(RECORDTYPEID_NAME)) {
            type = 'PICKLIST';
            picklistValues = getObjectRecordTypes(objectName);
            picklistValues.remove('Master');
            isRecordType = true;
        }
    }

	private static Map<String, String> getObjectFieldPicklistValues(Schema.DescribeFieldResult fieldDescribe) {

        Map<String, String> result = new Map<String, String>();

        result.put('', '');

		for (Schema.PicklistEntry value :fieldDescribe.getPicklistValues()) {

            result.put(value.getLabel(), value.getValue());
		}
        return result;
    }

	private static Map<String, String> getObjectRecordTypes(String objectName) {

        Map<String, String> result = new Map<String, String>();

        Map<String, Schema.RecordTypeInfo> recordTypes = Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfosByName();

        result.put('', '');

        for (Schema.RecordTypeInfo recordType :recordTypes.values()) {

            result.put(recordType.getName(), recordType.getRecordTypeId());
        }

        return result;
    }

    public static Map<String, Schema.SObjectField> getObjectFields(String objectName) {
        return Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    }

}