public with sharing class PotentialDuplicates {

    private static final String DUPLICATE_COUNT_KEY = 'duplicateCount';

    @AuraEnabled
    public static Map<String, Object> getDuplicates(Id recordId) {
        Map<String, Object> duplicateCount = new Map<String, Object>{ DUPLICATE_COUNT_KEY => 0 };

        try {
            duplicateCount.put(DUPLICATE_COUNT_KEY, getDuplicateCount(recordId));
        }
        catch (Exception e) {
        }

        return duplicateCount;
    }

    private static Integer getDuplicateCount(Id recordId) {
        Integer duplicateCount = 0;

        List<Datacloud.FindDuplicatesResult> duplicateResults =
                Datacloud.FindDuplicatesByIds.findDuplicatesByIds(new List<Id>{recordId});
        if (duplicateResults?.size() > 0) {
            duplicateCount = duplicateResults[0].getDuplicateResults()[0].getMatchResults()[0].size;
        }

        return duplicateCount;
    }
}