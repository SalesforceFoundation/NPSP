/**
* Batch class for address verification
*
* Batch process looks for all populated addresses and then updates them if the setting is turned on to do that
*
* If skipPreviouslyVerified is true, the batch skips over objects that already have any verification records
*/
public with sharing class ADDR_Validator_Batch implements Database.Batchable<sObject>, Database.AllowsCallouts {

    private final String query;
    
    public ADDR_Validator_Batch(String q) {
        query = q;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<Address__c> scope) {

        list<Address__c> addressesToVerify = new list<Address__c>();

        // batch needs to accept accounts, contacts, or leads
        Schema.sObjectType objType = scope[0].getSObjectType();
        for (Address__c a : scope) {
            if (isUS(a)) addressesToVerify.add(a); 
        }
        
        // verify and update this batch of addresses
        if (!addressesToVerify.isEmpty()) {
            ADDR_Validator.verifyRecords( addressesToVerify );
        }       
    }
    
    public void finish(Database.BatchableContext BC) {}
    
    // Method to run this batch process on all three objects
    public static list<Id> verifyAllAddresses() { return verifyAllAddresses( true ); }
    
    public static list<Id> verifyAllAddresses( Boolean skipPreviouslyVerified ) {
        list<Id> apexJobIds = new list<Id>();
        
        apexJobIds.add( verifyAddresses( skipPreviouslyVerified ) );

        return apexJobIds;
    }

    // Methods to run the batch on each object
    public static Id verifyAddresses( Boolean skipPreviouslyVerified ) {

        // query for all US addresses
        String queryString = 'select id, name, MailingStreet__c, MailingCity__c, MailingState__c, MailingPostalCode__c, MailingCountry__c ' +
            ' from Address__c where ' +
            '(MailingCountry__c = null or MailingCountry__c in (\'US\', \'USA\', \'United States\', \'United States of America\')) ' +
            'and (MailingStreet__c != null or MailingPostalCode__c != null or (MailingCity__c != null and MailingState__c != null))';
         
        if (skipPreviouslyVerified == true)
            queryString += 'and Verified__c != true';

        if (Test.isRunningTest())
            queryString += 'LIMIT 200';

        ADDR_VAlidator_Batch b = new ADDR_VAlidator_Batch( queryString );
        return Database.executeBatch(b); 
    }
    
    static Boolean isUS( Address__c c ) {
        return ((c.MailingStreet__c != null || c.MailingPostalCode__c != null || (c.MailingCity__c != null && c.MailingState__c != null))
            && (c.MailingCountry__c == null || c.MailingCountry__c == 'US' || c.MailingCountry__c == 'USA' || 
                        c.MailingCountry__c == 'United States' || c.MailingCountry__c == 'United States of America'));
    }
}