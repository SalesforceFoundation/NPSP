public with sharing class DataProviderSobject_CTRL {
    @AuraEnabled
    public static List<ProviderResult> queryObjects(String sobjectName, List<String> fields, String searchField, String queryValue) {
        try {
        List<String> uniqueFields = new List<String>(new Set<String>(fields));
        
        // '%', '_', and '\' all are special characters in LIKE syntax.
        // We escape them here by prepending those characters with a backslash
        String preparedQueryValue = '%' + queryValue.replaceAll('([%_\\\\])', '\\\\$0') + '%';
        
        String query = String.format(
            'SELECT {0} FROM {1} WHERE {2} LIKE :preparedQueryValue',
            new List<String>{
                String.join(uniqueFields, ', '),
                sobjectName,
                searchField
            }
        );
        
        List<SObject> results = Database.query(query);
        
        List<ProviderResult> providerResults = new List<ProviderResult>();
        
        for (SObject so : results) {
            ProviderResult result = new ProviderResult();
            result.value = so;
            result.displayValue = (String) so.get(searchField);
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