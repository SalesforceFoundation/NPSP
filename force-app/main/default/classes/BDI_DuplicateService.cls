/**
 * Duplicate Matching POC
 * @author CCS Team
 */
public with sharing class BDI_DuplicateService {
    
    public static Integer MAX_RECORDS_LIMIT = 50;

    /**
     * @description returns duplicate matching details for the records passed by param
     * @param List<sObject> records, records to find duplicates
     * @param decimal threshold, minimum threashold 
     * @return Map<String, BDI_DuplicateService.DataStagingDuplicate>
     */
    public static Map<String, DataStagingDuplicate> findDuplicates(List<sObject> records, decimal threshold) {

        // result init
        Map<String, DataStagingDuplicate> stagingDuplicates = new Map<String, DataStagingDuplicate>();
        // validations 
        // TODO: add threshold validations > 0 && <= 100 
        if (records == null || 
            records.size() == 0 || 
            records.size() > MAX_RECORDS_LIMIT)
        {
            // TODO?: we probably want to thow an exception when size > 50
            return stagingDuplicates;
        }

        // aux vars
        String baseURL = Url.getSalesforceBaseUrl().toExternalForm();
        Map<String, List<ComparsionResult>> comparsionMap = new Map<String, List<ComparsionResult>>();
        Datacloud.FindDuplicatesResult[] results;

        try {
            // execute duplicate matching
            results = Datacloud.FindDuplicates.findDuplicates(records);
        } catch(Exception e) {
            System.debug('Exception while executing Datacloud.FindDuplicates.findDuplicates for: ');
            System.debug(records);
            System.debug('Exception cause:\n' + e.getCause() + '\nException message:\n' + e.getMessage());            
            return stagingDuplicates;
        }
        
        // analyze results
        System.debug('records size: ' + records.size());
        System.debug('results size: ' +results.size());
        for (Datacloud.FindDuplicatesResult findDupeResult : results) { 
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) { 
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) { 
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) { 
                        // threshold control
                        if (matchRecord.getMatchConfidence() >= threshold ) {
                            // init wrapper class
                            DataStagingDuplicate stagingDup = new DataStagingDuplicate();                            
                            stagingDup.duplicateId = matchRecord.getRecord().Id;
                            stagingDup.duplicateUrl = baseURL + '/' + stagingDup.duplicateId;
                            stagingDup.confidenceScore = matchRecord.getMatchConfidence();
                            stagingDup.matchingRuleName = matchResult.getRule();
                            
                            // create comparsion results
                            List<ComparsionResult> auxComparsionList = new List<ComparsionResult>();
                            ComparsionResult auxComparsion;
                            // analyze match details
                            for(Datacloud.FieldDiff diff : matchRecord.getFieldDiffs()){
                                // create comparsion record
                                auxComparsion = new ComparsionResult();
                                auxComparsion.difference = diff.getDifference();
                                auxComparsion.fieldName = diff.getName();
                                // add to list of comparsions
                                auxComparsionList.add(auxComparsion);                                                        
                            }

                            // match details results
                            stagingDup.matchDetails = JSON.serialize(auxComparsionList);
                            stagingDup.comparsionResults = auxComparsionList;

                            // add details to result map                            
                            stagingDuplicates.put(stagingDup.matchingRuleName, stagingDup);
                        }
                    }
                }
            }                        
        }

        return stagingDuplicates;
    }

    

    public class DataStagingDuplicate {        
        // the found duplicate record id returned by the Datacloud.MatchRecord.getRecord method:
        public Id duplicateId;
        // the link to the found duplicate record:
        public String duplicateUrl;
        // the decimal number returned by the Datacloud.MatchRecord.getMatchConfidence method:
        public Decimal confidenceScore;
        // the matching rule name returned by the Datacloud.MatchResult.getRule method:
        public String matchingRuleName;
        // the JSON string structure containing the result of Datacloud.FieldDiff.getName and Datacloud.FieldDiff.getDifference
        // we can use List<ComparsionResult> to deserlialize this json string into something easier to handle
        public String matchDetails;
        // match details as list 
        public List<ComparsionResult> comparsionResults;
    }

    public class ComparsionResult {
        public String fieldName;
        public String difference;
    }

    public static void testExactMatch() {        

        Contact c = [
            SELECT Id, FirstName, LastName, npe01__HomeEmail__c 
            FROM Contact 
            LIMIT 1
        ];

        Contact newDupContact = new Contact();
        newDupContact.FirstName = c.FirstName;
        newDupContact.LastName = c.LastName;
        newDupContact.npe01__HomeEmail__c = c.npe01__HomeEmail__c;

        //For this script we pass 80.0 as the confidence level, but that can be changed here.
        Map<String, BDI_DuplicateService.DataStagingDuplicate> duplicates = BDI_DuplicateService.findDuplicates(
            new List<sObject>{newDupContact}, 
            80.0
        );
        System.debug('duplicates size: ' + duplicates.size());
        System.debug('analyzed rules: ' + duplicates.keySet());
        for (BDI_DuplicateService.DataStagingDuplicate d: duplicates.values()){
            System.debug('Duplicate Rule Name: ' + d.matchingRuleName);
            System.debug('Confidence Score: ' + d.confidenceScore);
            System.debug('Duplicate Id: ' + d.duplicateId);
            System.debug('Duplicate URL: ' + d.duplicateUrl);
            System.debug('Match details: ');
            for(BDI_DuplicateService.ComparsionResult cr: d.comparsionResults) {
                System.debug(' -' + cr.fieldName + ': ' + cr.difference);
            }
        }

    }

    public static void testFirstNameFuzzyMatch() {   
        
        String sName = 'Robert';
        String sLastName = 'Test';
        String sEmail = 'robert.test@mailinator.net';
        Contact c;

        List<Contact> lContacts = [
            SELECT Id, FirstName, LastName, npe01__HomeEmail__c 
            FROM Contact 
            WHERE FirstName = :sName AND LastName =:sLastName AND npe01__HomeEmail__c =:sEmail 
            LIMIT 1
        ];
        if (lContacts.size()==0) {
            c = new Contact(
                FirstName = sName,
                LastName = sLastName,
                npe01__HomeEmail__c = sEmail
            );
            insert c;
        } else {
            c = lContacts.get(0);
        }       

        Contact newDupContact = new Contact();
        newDupContact.FirstName = 'Bob';
        newDupContact.LastName = c.LastName;
        newDupContact.npe01__HomeEmail__c = c.npe01__HomeEmail__c;

        //For this script we pass 80.0 as the confidence level, but that can be changed here.
        Map<String, BDI_DuplicateService.DataStagingDuplicate> duplicates = BDI_DuplicateService.findDuplicates(
            new List<sObject>{newDupContact}, 
            80.0
        );
        System.debug('duplicates size: ' + duplicates.size());
        System.debug('analyzed rules: ' + duplicates.keySet());
        for (BDI_DuplicateService.DataStagingDuplicate d: duplicates.values()){
            System.debug('Duplicate Rule Name: ' + d.matchingRuleName);
            System.debug('Confidence Score: ' + d.confidenceScore);
            System.debug('Duplicate Id: ' + d.duplicateId);
            System.debug('Duplicate URL: ' + d.duplicateUrl);
            System.debug('Match details: ');
            for(BDI_DuplicateService.ComparsionResult cr: d.comparsionResults) {
                System.debug(' -' + cr.fieldName + ': ' + cr.difference);
            }
        }

    }

}