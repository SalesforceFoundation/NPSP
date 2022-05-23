public with sharing class UTIL_DuplicateMgmt {

    public static Integer MAX_RECORDS_LIMIT = 50;
    /**
    * @description returns duplicate matching details for the records passed by param
    * @param List<sObject> records, records to find duplicates
    * @param decimal threshold, minimum threashold 
    * @return Map<String, BDI_DuplicateService.DataStagingDuplicate>
    */
    public static Map<SObject, DataStagingDuplicate> findDuplicates(List<sObject> records, decimal threshold) {
        System.debug('In findDuplicates');
        // result init
        Map<SObject, DataStagingDuplicate> sObjToDupeResults = new Map<SObject, DataStagingDuplicate>();
        // validations 
        if (records == null || 
            records.size() == 0 || 
            records.size() > MAX_RECORDS_LIMIT)
        {
            System.debug('TOO MANY RECORDS ENCOUNTERED');
            // TODO?: for size>50 we probably want to rise an exception
            return sObjToDupeResults;
        }

        // aux vars
        String baseURL = Url.getSalesforceBaseUrl().toExternalForm();
        Datacloud.FindDuplicatesResult[] results;

        try {
            // execute duplicate matching
            results = Datacloud.FindDuplicates.findDuplicates(records);
        } catch(Exception e) {
            System.debug('Exception while executing Datacloud.FindDuplicates.findDuplicates for: ');
            System.debug(records);
            System.debug('Exception cause:\n' + e.getCause() + '\nException message:\n' + e.getMessage());            
            return sObjToDupeResults;
        }
        
        // analyze results

        for (Integer i = 0; i < records.size(); i++) {
            Datacloud.FindDuplicatesResult findDupeResult = results[i];
            SObject recordToMatch = records[i];

            // Placing key in map for record to match.  If no matches are found the value will stay null.
            sObjToDupeResults.put(recordToMatch, null);


            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {      
                //System.debug('DupeResult: ' + dupeResult);          
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    //System.debug('MatchResult: ' + matchResult);   
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        //System.debug('matchRecord: ' + matchRecord);
                        //System.debug('AnyexistingMatchwiththisSobj: ' + sObjToDupeResults.get(recordToMatch));
                        // Ignore results below threshold, and ignore additional matches if one already exists.
                        if (sObjToDupeResults.get(recordToMatch) == null) {
                            //System.debug('inside Match');
                            // init wrapper class
                            DataStagingDuplicate stagingDup = new DataStagingDuplicate();                            
                            stagingDup.duplicateId = matchRecord.getRecord().Id;
                            //stagingDup.duplicateUrl = baseURL + '/' + stagingDup.duplicateId;
                            stagingDup.confidenceScore = matchRecord.getMatchConfidence();
                            stagingDup.matchingRuleName = matchResult.getRule();
                            /*
                            // create Comparison results
                            List<ComparisonResult> auxComparisonList = new List<ComparisonResult>();
                            ComparisonResult auxComparison;
                            // analyze match details
                            for(Datacloud.FieldDiff diff : matchRecord.getFieldDiffs()){
                                // create Comparison record
                                auxComparison = new ComparisonResult();
                                auxComparison.difference = diff.getDifference();
                                auxComparison.fieldName = diff.getName();
                                // add to list of Comparisons
                                auxComparisonList.add(auxComparison);                                                        
                            }
                            System.debug('after comparison list');
                            // match details results
                            stagingDup.matchDetails = JSON.serialize(auxComparisonList);
                            stagingDup.ComparisonResults = auxComparisonList;
                            */
                            // add details to result map                         
                            sObjToDupeResults.put(recordToMatch, stagingDup);
                            //System.debug('Found result for: ' + recordToMatch);
                            //System.debug('stagingDupIs: ' + stagingDup);
                        }
                    }
                }
            }                        
        }
        //System.debug('Returning sObjToDupeResults: ' + sObjToDupeResults );
        return sObjToDupeResults;
    }

    public static Map<SObject, DataStagingDuplicate> findDuplicatesBulk(List<sObject> records, decimal threshold) {
        Map<SObject, DataStagingDuplicate> dupeResults = new Map<SObject, DataStagingDuplicate>();
        Integer nextObjToProcess = 0;
        Integer objsRemaining = records.size();

        // Continue looping while there are still records remaining to process.
        while (objsRemaining > 0) {
            //System.debug('Objs remaining at start: ' + objsRemaining);
            SObject[] sObjBatch = new SObject[]{};

            // Only process up to 50 records at a time
            Integer objsToProcess = Math.min(objsRemaining,50);
            //System.debug('objsToProcess is: ' + objsToProcess);
            for (Integer i = 0; i < objsToProcess; i++) {
    
                sObjBatch.add(records[nextObjToProcess]);
                nextObjToProcess++;
            }

            objsRemaining = objsRemaining - objsToProcess;
            //System.debug('sObjBatch size is: ' + sObjBatch.size());
            // Call duplicate management logic
            Map<SObject, DataStagingDuplicate> tempDupeResults = findDuplicates(sObjBatch,threshold);
            
            // Put results in main return map
            for (SObject sObj : tempDupeResults.keySet()) {
                //System.debug('Putting result for ' + sobj);
                //System.debug('result is: ' + tempDupeResults.get(sObj));
                dupeResults.put(sObj,tempDupeResults.get(sObj));
            }
            //System.debug('Objs remaining at end: ' + objsRemaining);
        }
        return dupeResults;
    }



    /*
    public static Map<String, DataStagingDuplicate> findDuplicates(List<sObject> records, decimal threshold) {

        // result init
        Map<String, DataStagingDuplicate> sObjToDupeResults = new Map<String, DataStagingDuplicate>();
        // validations 
        if (records == null || 
            records.size() == 0 || 
            records.size() > MAX_RECORDS_LIMIT)
        {
            // TODO?: for size>50 we probably want to rise an exception
            return sObjToDupeResults;
        }

        // aux vars
        String baseURL = Url.getSalesforceBaseUrl().toExternalForm();
        Map<String, List<ComparisonResult>> ComparisonMap = new Map<String, List<ComparisonResult>>();
        Datacloud.FindDuplicatesResult[] results;

        try {
            // execute duplicate matching
            results = Datacloud.FindDuplicates.findDuplicates(records);
        } catch(Exception e) {
            System.debug('Exception while executing Datacloud.FindDuplicates.findDuplicates for: ');
            System.debug(records);
            System.debug('Exception cause:\n' + e.getCause() + '\nException message:\n' + e.getMessage());            
            return sObjToDupeResults;
        }
        
        // analyze results
        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {                
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        // threshold control
                        if (matchRecord.getMatchConfidence() > threshold ) {
                            // init wrapper class
                            DataStagingDuplicate stagingDup = new DataStagingDuplicate();                            
                            stagingDup.duplicateId = matchRecord.getRecord().Id;
                            stagingDup.duplicateUrl = baseURL + '/' + stagingDup.duplicateId;
                            stagingDup.confidenceScore = matchRecord.getMatchConfidence();
                            stagingDup.matchingRuleName = matchResult.getRule();
                            
                            // create Comparison results
                            List<ComparisonResult> auxComparisonList = new List<ComparisonResult>();
                            ComparisonResult auxComparison;
                            // analyze match details
                            for(Datacloud.FieldDiff diff : matchRecord.getFieldDiffs()){
                                // create Comparison record
                                auxComparison = new ComparisonResult();
                                auxComparison.difference = diff.getDifference();
                                auxComparison.fieldName = diff.getName();
                                // add to list of Comparisons
                                auxComparisonList.add(auxComparison);                                                        
                            }

                            // match details results
                            stagingDup.matchDetails = JSON.serialize(auxComparisonList);
                            stagingDup.ComparisonResults = auxComparisonList;

                            // add details to result map                            
                            sObjToDupeResults.put(stagingDup.matchingRuleName, stagingDup);
                        }
                    }
                }
            }                        
        }

        return sObjToDupeResults;
    }

    */
}
