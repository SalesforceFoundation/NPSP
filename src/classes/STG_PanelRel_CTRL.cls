public with sharing class STG_PanelRel_CTRL extends STG_Panel { 

    public override string idPanel() { return 'idPanelRel'; }
    
    public list<SelectOption> listSOGenderFieldOptions {
    	get {
	        if (listSOGenderFieldOptions == null) {
	            listSOGenderFieldOptions = new list<SelectOption>();
	            //add a default option
	            listSOGenderFieldOptions.add(new SelectOption('', '- none -'));
	                        
	            map<String, Schema.SObjectField> conFieldTokenList = Schema.SObjectType.Contact.fields.getMap(); 
	           
	            //only get the describe information for custom fields (not from NPSP)
	            for (string fieldName : conFieldTokenList.keyset()) {
	                if (fieldname.endsWith('__c') && !fieldname.startsWith('np')) {
	                    listSOGenderFieldOptions.add(new SelectOption(fieldName, UTIL_Describe.getFieldLabel('Contact', fieldName))); 
	                }               
	            }
	        }               
	        return listSOGenderFieldOptions;
        }
        private set;
    }  
    
    
}