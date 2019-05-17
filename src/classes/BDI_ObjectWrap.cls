public with sharing class BDI_ObjectWrap {
	public String wrapId;

	public Data_Import_Object_Mapping__mdt objMapping;
	public Data_Import_Field_Mapping__mdt[] fieldMappings;
	public DataImport__c di;
	public Sobject sobj;

	public Id existingSobjectId;

	public BDI_ObjectWrap(DataImport__c di, Data_Import_Object_Mapping__mdt objMapping, Data_Import_Field_Mapping__mdt[] fieldMappings) {
		this.objMapping = objMapping;
		this.fieldMappings = fieldMappings;
		this.di = di;
		this.wrapId = di.Id + '' + objMapping.DeveloperName;
	}
}