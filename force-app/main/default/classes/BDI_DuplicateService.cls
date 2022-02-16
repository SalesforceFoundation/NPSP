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
     * @return 
     */
    public static List<DataStagingDuplicate> findDuplicates(List<sObject> records, decimal threshold) {

        // result init
        List<DataStagingDuplicate> stagingDuplicates = new List<DataStagingDuplicate>();
        // validations 
        if (records == null || 
            records.size() == 0 || 
            records.size() > MAX_RECORDS_LIMIT)
        {
            // TODO?: for size>50 we probably want to rise an exception
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
        for (Datacloud.FindDuplicatesResult findDupeResult : results) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                // TODO?: Duplicate Result Name Filtering
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        // TODO?: Threshold Management
                        //if (matchRecord.getMatchConfidence() > threshold ) {

                            DataStagingDuplicate stagingDup = new DataStagingDuplicate();
                            // stagingDup.dataStagingId = stagingRecordId;
                            stagingDup.duplicateId = matchRecord.getRecord().Id;
                            stagingDup.duplicateUrl = baseURL + '/' + stagingDup.duplicateId;
                            stagingDup.confidenceScore = matchRecord.getMatchConfidence();
                            stagingDup.matchingRuleName = matchResult.getRule();
                            
                            // create comparsion results
                            List<ComparsionResult> auxComparsionList = new List<ComparsionResult>();
                            ComparsionResult auxComparsion;

                            for(Datacloud.FieldDiff diff : matchRecord.getFieldDiffs()){
                                // create comparsion record
                                auxComparsion = new ComparsionResult();
                                auxComparsion.Difference = diff.getDifference();
                                auxComparsion.Name = diff.getName();
                                // add to list of comparsions
                                auxComparsionList.add(auxComparsion);                                                        
                            }

                            // TODO? do we really want to make this a string instead of leaving it as list?
                            stagingDup.matchDetails = JSON.serialize(auxComparsionList);

                            // add details to result
                            // TODO? maybe we can return Map<String, DataStagingDuplicate> instead of List<DataStagingDuplicate> by using rule-name as key                            
                            stagingDuplicates.add(stagingDup);
                        //}
                    }
                }
            }                        
        }

        return stagingDuplicates;
    }

    public class DataStagingDuplicate {
        Id id;
        // the id of the data staging record, this must be provided as a parameter:
        Id dataStagingId;
        // the found duplicate record id returned by the Datacloud.MatchRecord.getRecord method:
        Id duplicateId;
        // the link to the found duplicate record:
        String duplicateUrl;
        // the decimal number returned by the Datacloud.MatchRecord.getMatchConfidence method:
        Decimal confidenceScore;
        // the matching rule name returned by the Datacloud.MatchResult.getRule method:
        String matchingRuleName;
        // the JSON string structure containing the result of Datacloud.FieldDiff.getName and Datacloud.FieldDiff.getDifference
        // we can use List<ComparsionResult> to deserlialize this json string into something easier to handle
        String matchDetails;
    }

    public class ComparsionResult {
        String Name;
        String Difference;
    }

    public static void testExactMatch() {        

        Contact c = [SELECT FirstName, LastName, npe01__HomeEmail__c FROM Contact LIMIT 1];

        Contact newDupContact = new Contact();
        newDupContact.FirstName = c.FirstName;
        newDupContact.LastName = c.LastName;
        newDupContact.npe01__HomeEmail__c = c.npe01__HomeEmail__c;

        //For this script we pass 80.0 as the confidence level, but that can be changed here.
        List<BDI_DuplicateService.DataStagingDuplicate> duplicates = BDI_DuplicateService.findDuplicates(
            new List<sObject>{newDupContact}, 
            80.0
        );
        System.debug('duplicates size: ' + duplicates.size());
        for (BDI_DuplicateService.DataStagingDuplicate d: duplicates){
            System.debug(d);
        }

    }

    public static void testFirstNameFuzzyMatch() {   
        
        String sName = 'Robert';
        String sLastName = 'Test';
        String sEmail = 'robert.test@mailinator.net';
        Contact c;

        List<Contact> lContacts = [SELECT Id FROM Contact WHERE FirstName = 'Robert' AND LastName = 'Test' AND npe01__HomeEmail__c = 'robert.test@mailinator.net' LIMIT 1];
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
        List<BDI_DuplicateService.DataStagingDuplicate> duplicates = BDI_DuplicateService.findDuplicates(
            new List<sObject>{newDupContact}, 
            80.0
        );
        System.debug('duplicates size: ' + duplicates.size());
        for (BDI_DuplicateService.DataStagingDuplicate d: duplicates){
            System.debug(d);
        }

    }

}