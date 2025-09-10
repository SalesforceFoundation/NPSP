public with sharing class PotentialDuplicates {

    private static final String SET_OF_MATCHES_KEY = 'setOfMatches';

    @AuraEnabled
    public static Map<String, Object> getDuplicates(Id recordId) {
        Map<String, Object> returnParams = new Map<String, Object>{ SET_OF_MATCHES_KEY => null };

        try {
            returnParams.put(SET_OF_MATCHES_KEY, getDuplicateList(recordId));
        }
        catch (Exception e) {
        }

        return returnParams;
    }

    private static String getDuplicateList(Id recordId) {
        String strSetOfMatches = '';

        Set<String> setOfMatchIds = new Set<String>();
        List<Datacloud.FindDuplicatesResult> results =
                Datacloud.FindDuplicatesByIds.findDuplicatesByIds(new List<Id>{recordId});
        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        setOfMatchIds.add(matchRecord.getRecord().Id);
                    }
                }
            }
        }
        for (String matchId : setOfMatchIds) {
            strSetOfMatches += (strSetOfMatches == '' ? '' : ',') + matchId;
        }

        return strSetOfMatches;
    }
}