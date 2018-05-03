public with sharing class BGE_DynamicalColumnWrapper {

	private static final Map<String, String> GRID_COLUMN_TYPES = new Map<String, String>
                                                                {  'STRING' => 'text',
																   'PICKLIST' => 'dropdown',
                                                                   'DATE' => 'date',
                                                                   'DATETIME' => 'date',
                                                                   'ID' => 'text',
                                                                   'CURRENCY' => 'numeric',
                                                                   'BOOLEAN' => 'boolean',
                                                                   'NUMBER' => 'numeric',
                                                                   'DECIMAL' => 'numeric',
																   'EMAIL' => 'email'
                                                                };

	public String apiName { get; set; }
	public String name { get; set; }
	public String type { get; set; }
	public String isDecimal { get; set; }
	public Boolean required { get; set; }
	public Boolean allowInvalid { get; set; }
	public List<String> pickListValuesList {get; set;}

	//Constructor
	public BGE_DynamicalColumnWrapper(Batch_Template_Field__c templateField) {

		pickListValuesList = new List<String>();

		Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();

		// Schema of Data Import fields
		Map <String, Schema.SObjectField> dataImportFieldMap = schemaMap.get('DataImport__c').getDescribe().fields.getMap();

		// Schema of Contact and Account
		Map <String, Schema.SObjectField> contactFieldMap = schemaMap.get('Contact').getDescribe().fields.getMap();
		Map <String, Schema.SObjectField> accountFieldMap = schemaMap.get('Account').getDescribe().fields.getMap();

		Schema.SObjectField dataImportField = dataImportFieldMap.get(templateField.Name);

		if (dataImportField != null) {

			Schema.DescribeFieldResult field = dataImportField.getDescribe();

			String nameAux = '';

			if (field.getInlineHelpText() != null) {

				String aux = field.getInlineHelpText();

				if (aux.substringBefore('.').toLowerCase() == 'contact1' || aux.substringBefore('.').toLowerCase() == 'contact2') {

					nameAux = contactFieldMap.get(aux.substringAfter('.')).getDescribe().getLabel();

				}
				else if (aux.substringBefore('.').toLowerCase() == 'account1' || aux.substringBefore('.').toLowerCase() == 'account2') {

					nameAux = accountFieldMap.get(aux.substringAfter('.')).getDescribe().getLabel();
				}
				else {
					// Default value for avoid null pointer exceptions
					nameAux = field.getLabel();
				}
			}
			else {
				// Default value for avoid null pointer exceptions
				nameAux = field.getLabel();
			}

			apiName = templateField.Name;

			name = nameAux;

			isDecimal = 'false';
			type = String.valueOf(field.getType());

			required = templateField.Required__c;
			allowInvalid = false;

			mapFieldTypes();

			if (type === 'dropdown') {

				getPickListValuesIntoList(dataImportFieldMap);
			}

			if (apiName === 'Donation_Record_Type_Name__c') {

				type = 'dropdown';
				pickListValuesList.addAll(getDonationRecordtypes());
			}

		}
		else {

			name = 'ERROR';
			type = 'text';
		}
	}

	private void mapFieldTypes() {

		if(type.equals('CURRENCY') || type.equals('DECIMAL')) {

			isDecimal = 'true';
		}

		if(GRID_COLUMN_TYPES.containsKey(type)) {

			type = GRID_COLUMN_TYPES.get(type);
		}
		else {

			type = 'text';
		}

	}

	public List<String> getPickListValuesIntoList(Map <String, Schema.SObjectField> fieldMap){

		Schema.DescribeFieldResult fieldResult = fieldMap.get(apiName).getDescribe();

		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

		for( Schema.PicklistEntry pickListVal : ple){

			pickListValuesList.add(pickListVal.getLabel());
		}

		return pickListValuesList;
    }


	private Set<String> getDonationRecordtypes() {

        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();

        return rtMapByName.keySet();
    }

}