public with sharing class GE_LookupController {

    @AuraEnabled(cacheable=true)
    public static List<LookupResult> doSearch(String searchValue, String sObjectType) {
        String likeLike = '%' + searchValue + '%';
        String queryString = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(sObjectType) + ' WHERE Name LIKE :likeLike';

        List<LookupResult> results = new List<LookupResult>();
        for(SObject result : Database.query(queryString)) {
            results.add(new LookupResult(result));
        }

        return results;
    }

    public class LookupResult {
        @AuraEnabled public Id value;
        @AuraEnabled public String displayValue;

        public LookupResult(SObject result) {
            this.value = (Id)result.get('Id');
            this.displayValue = (String)result.get('Name');
        }
    }
}