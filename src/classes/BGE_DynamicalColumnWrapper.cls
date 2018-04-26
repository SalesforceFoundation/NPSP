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
	public Boolean stickyField { get; set; }
	public String  stickyFieldValue { get; set; }
	public Boolean stickyFieldVisibility { get; set; }
	public Boolean required { get; set; }
	public Boolean allowInvalid { get; set; }
	public List<String> pickListValuesList {get; set;}

	//Constructor
	public BGE_DynamicalColumnWrapper(Batch_Template_Field__c templateField) {

		pickListValuesList = new List<String>();

		Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
		Map <String, Schema.SObjectField> fieldMap = schemaMap.get('DataImport__c').getDescribe().fields.getMap();
		Schema.SObjectField sObjectField = fieldMap.get(templateField.Name);

		if (sObjectField != null) {

			Schema.DescribeFieldResult field = sObjectField.getDescribe();

			apiName = templateField.Name;
			name = field.getLabel();
			isDecimal = 'false';
			type = String.valueOf(field.getType());

			required = templateField.Required__c;
			allowInvalid = false;

			mapFieldTypes();

			if (type == 'dropdown') {

				getPickListValuesIntoList(fieldMap);
			}

			if (apiName == 'Donation_Record_Type_Name__c') {

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