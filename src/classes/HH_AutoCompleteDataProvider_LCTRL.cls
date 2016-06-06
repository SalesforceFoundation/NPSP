public with sharing class HH_AutoCompleteDataProvider_LCTRL {

    @AuraEnabled
    public static List<ProviderResult> queryObjects(String queryValue, list<Contact> listCon) {
        try {
            // '%', '_', and '\' all are special characters in LIKE syntax.
            // We escape them here by prepending those characters with a backslash
            String preparedQueryValue = '%' + queryValue.replaceAll('([%_\\\\])', '\\\\$0') + '%';
            
			// use helper to get all contact fields to support custom household naming and greetings.
            String strSoql = HH_Container_LCTRL.conSelect;
            strSoql += ' WHERE Name LIKE :preparedQueryValue AND Id not in :listCon LIMIT 100';
    
            List<SObject> results = Database.query(strSoql);
    
            List<ProviderResult> providerResults = new List<ProviderResult>();
    
            for (SObject so : results) {
                ProviderResult result = new ProviderResult();
                result.value = so;
                result.displayValue = (String) so.get('Name');
                providerResults.add(result);
            }
    
            return providerResults;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class ProviderResult {
        @AuraEnabled
        public String displayValue;

        @AuraEnabled
        public SObject value;
    }
}