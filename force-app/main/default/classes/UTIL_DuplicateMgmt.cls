/*
    Copyright (c) 2022, Salesforce.org
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.org
* @date 2022
* @group Utilities
* @description Utility methods to faciliate using the built-in findDuplicates function.
*/
public with sharing class UTIL_DuplicateMgmt {

    /**
    * @description Returns map of duplicate matching details for the records passed in.  Note:
    * Will throw error if more than 50 SObjects are passed in.
    * @param List<sObject> list of Sobjects that duplicates will be located for
    * @return Map<SObject, BDI_DuplicateService.MatchDetail[]>
    */
    private static Map<SObject, MatchDetail[]> findDuplicates(List<SObject> records) {
        // Initiate return map
        Map<SObject, MatchDetail[]> sObjToDupeResults = new Map<SObject, MatchDetail[]>();

        Datacloud.FindDuplicatesResult[] results;

        // execute duplicate matching
        results = Datacloud.FindDuplicates.findDuplicates(records);

        // Loop through results and create MatchDetail records to store the information.
        for (Integer i = 0; i < records.size(); i++) {
            Datacloud.FindDuplicatesResult findDupeResult = results[i];
            SObject recordToMatch = records[i];

            // Placing key in map for record to match.  If no matches are found the value will stay null.
            sObjToDupeResults.put(recordToMatch, null);

            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {   
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        storeMatchDetail(sObjToDupeResults, recordToMatch, dupeResult, matchResult, matchRecord);
                    }
                }
            }
        }

        return sObjToDupeResults;
    }

    /**
    * @description Returns map of duplicate matching details for the records passed in.  Breaks down any list
    * of SObjects over 50 into chunks of 50 that can be processed without error.
    * @param List<sObject> list of Sobjects that duplicates will be located for
    * @return Map<String, BDI_DuplicateService.MatchDetail[]>
    */
    public Map<SObject, MatchDetail[]> findDuplicatesBulk(List<SObject> records) {
        Map<SObject, MatchDetail[]> dupeResults = new Map<SObject, MatchDetail[]>();
        Integer nextObjToProcess = 0;
        Integer objsRemaining = records.size();

        // Continue looping while there are still records remaining to process.
        while (objsRemaining > 0) {
            SObject[] sObjBatch = new SObject[]{};

            // Only process up to 50 records at a time
            Integer objsToProcess = Math.min(objsRemaining,50);

            for (Integer i = 0; i < objsToProcess; i++) {
    
                sObjBatch.add(records[nextObjToProcess]);
                nextObjToProcess++;
            }

            objsRemaining = objsRemaining - objsToProcess;
            // Call duplicate management logic
            Map<SObject, MatchDetail[]> tempDupeResults = findDuplicates(sObjBatch);
            
            // Put results in main return map
            dupeResults.putAll(tempDupeResults);
        }
        return dupeResults;
    }

    /**
    * @description Populates a MatchDetail record from the provided match/duplicate objects.
    * This is separated out to facilitate easier unit testing.
    * @param sObjToDupeResults Map<SObject, MatchDetail[]> return map to be updated
    * @param sObject the SObject record that was provided for duplicate detection.
    * @param dupeResult Datacloud.DuplicateResult from duplicate data
    * @param matchResult Datacloud.MatchResult from duplicate data
    * @param matchRecord Datacloud.MatchRecord from duplicate data
    * @return Map<String, BDI_DuplicateService.MatchDetail[]>
    */
    @TestVisible
    private static void storeMatchDetail (Map<SObject, MatchDetail[]> sObjToDupeResults,
                                        SObject recordToMatch, 
                                        Datacloud.DuplicateResult dupeResult, 
                                        Datacloud.MatchResult matchResult,
                                        Datacloud.MatchRecord matchRecord) {
        // Create wrapper class to hold match details
        MatchDetail match = new MatchDetail();

        // Populate key match details
        match.recordId = (matchRecord != null ? matchRecord.getRecord().Id : null);
        match.confidenceScore = (matchRecord != null ? matchRecord.getMatchConfidence() : null);
        match.duplicateRuleName = (dupeResult != null ? dupeResult.getDuplicateRule() : null);
        match.matchingRuleName = (matchResult != null ? matchResult.getRule() : null);

        // Store match details in the map of results.
        MatchDetail[] matchDetails = new MatchDetail[]{};
        if (sObjToDupeResults.get(recordToMatch) != null) {
            matchDetails = sObjToDupeResults.get(recordToMatch);
        } 
        matchDetails.add(match);
        sObjToDupeResults.put(recordToMatch, matchDetails);
    }


    /**
    * @description Wrapper class that contains a simplified and flattened record of match results.
    */
    public class MatchDetail {
        // the found matching record id
        public String recordId;
        // the confidence score out of 100 for the match.
        public Decimal confidenceScore;
        // Duplicate rule name for the match
        public String duplicateRuleName;
        // Matching Rule name for the match
        public String matchingRuleName;
    }
}
