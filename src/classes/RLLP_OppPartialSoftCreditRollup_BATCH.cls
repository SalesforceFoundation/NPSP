/*
 * @author Tomas "Bobby" Hnizdil
 * @date 8/22/2013
 * @description Schedulable batch class to update soft credit rollup fields on Contact with values from OpportunityContactRole and Partial_Soft_Credit__c records
 *
 * This code has been contributed by KELL Partners
 */
public class RLLP_OppPartialSoftCreditRollup_BATCH implements Database.Batchable<sObject>, Schedulable {

    public void execute(SchedulableContext sc) {
        Integer batchSize = RLLP_OppRollup_UTIL.BATCH_SIZE; 
        Database.executeBatch(new RLLP_OppPartialSoftCreditRollup_BATCH(), batchSize);
    }

    public Database.querylocator start(Database.BatchableContext BC){    
        String query = 'SELECT Id,' +
                              'First_Soft_Credit_Amount__c,' +
                              'First_Soft_Credit_Date__c,' +
                              'Largest_Soft_Credit_Amount__c,' +
                              'Largest_Soft_Credit_Date__c,' +
                              'Last_Soft_Credit_Amount__c,' +
                              'Last_Soft_Credit_Date__c,' +
                              'npo02__Soft_Credit_Last_Year__c,' +
                              'Number_of_Soft_Credits_Last_Year__c,' +
                              'npo02__Soft_Credit_Total__c,' +
                              'Number_of_Soft_Credits__c,' +
                              'npo02__Soft_Credit_This_Year__c,' +
                              'Number_of_Soft_Credits_This_Year__c ' +
                       'FROM Contact';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) {
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
        Date currentYearStart;
        if (RLLP_OppRollup_UTIL.useFiscalYear) {
            currentYearStart = Date.newInstance(Date.Today().Year(), [SELECT FiscalYearStartMonth FROM Organization LIMIT 1].FiscalYearStartMonth, 1);
            if (currentYearStart > Date.Today()) currentYearStart = currentYearStart.addYears(-1);
        } else {
            currentYearStart = Date.newInstance(Date.Today().Year(), 1, 1);
        }
    
        Map<Id, List<OpportunityContactRole>> opportunityContactRoles = new Map<Id, List<OpportunityContactRole>>();
        for (OpportunityContactRole ocr : [SELECT Id, ContactId, Opportunity.CloseDate, Opportunity.Amount 
                                           FROM OpportunityContactRole WHERE ContactId IN :scope AND Opportunity.isWon=true AND Role IN :RLLP_OppRollup_UTIL.softCreditRoles]) {
            if (!opportunityContactRoles.containsKey(ocr.ContactId)) opportunityContactRoles.put(ocr.ContactId, new List<OpportunityContactRole>());
            opportunityContactRoles.get(ocr.ContactId).add(ocr);
        }
        
        Map<Id, List<Partial_Soft_Credit__c>> partialSoftCredits = new Map<Id, List<Partial_Soft_Credit__c>>();
        for (Partial_Soft_Credit__c psr : [SELECT Id, Contact__c, Opportunity__r.CloseDate, Amount__c, Contact_Role_ID__c 
                                           FROM Partial_Soft_Credit__c WHERE Contact__c IN :scope AND Opportunity__r.isWon=true AND Role_Name__c IN :RLLP_OppRollup_UTIL.softCreditRoles]) {
            if (!partialSoftCredits.containsKey(psr.Contact__c)) partialSoftCredits.put(psr.Contact__c, new List<Partial_Soft_Credit__c>());
            partialSoftCredits.get(psr.Contact__c).add(psr);
        }
    
        List<Contact> toUpdate = new List<Contact>();
        for (SObject o : scope) {
            Contact c = (Contact) o;
            Contact newC = new Contact(Id = c.Id,
                                       First_Soft_Credit_Amount__c = 0,
                                       First_Soft_Credit_Date__c = null,
                                       Largest_Soft_Credit_Amount__c = 0,
                                       Largest_Soft_Credit_Date__c = null,
                                       Last_Soft_Credit_Amount__c = 0,
                                       Last_Soft_Credit_Date__c = null,                                       
                                       npo02__Soft_Credit_Last_Year__c = 0,
                                       Number_of_Soft_Credits_Last_Year__c = 0,
                                       npo02__Soft_Credit_Total__c = 0,
                                       Number_of_Soft_Credits__c = 0,
                                       npo02__Soft_Credit_This_Year__c = 0,
                                       Number_of_Soft_Credits_This_Year__c = 0);
            
            Set<String> ocrIds = new Set<String>();
            if (partialSoftCredits.containsKey(c.Id)) {
                for (Partial_Soft_Credit__c psc : partialSoftCredits.get(c.Id)) {
                    newC = countPartialSoftCredits(newC, psc, currentYearStart);
                    ocrIds.add(psc.Contact_Role_ID__c);
                }
            }
            
            if (opportunityContactRoles.containsKey(c.Id)) {
                for (OpportunityContactRole ocr : opportunityContactRoles.get(c.Id)) {
                    if (ocrIds.contains(ocr.Id)) continue; // partial soft credit
                    newC = countOpportunityContactRoles(newC, ocr, currentYearStart);
                }
            }
            
            if (newC.First_Soft_Credit_Amount__c != c.First_Soft_Credit_Amount__c
             || newC.First_Soft_Credit_Date__c != c.First_Soft_Credit_Date__c
             || newC.Largest_Soft_Credit_Amount__c != c.Largest_Soft_Credit_Amount__c
             || newC.Largest_Soft_Credit_Date__c != c.Largest_Soft_Credit_Date__c
             || newC.Last_Soft_Credit_Amount__c != c.Last_Soft_Credit_Amount__c
             || newC.Last_Soft_Credit_Date__c != c.Last_Soft_Credit_Date__c
             || newC.npo02__Soft_Credit_Last_Year__c != c.npo02__Soft_Credit_Last_Year__c
             || newC.Number_of_Soft_Credits_Last_Year__c != c.Number_of_Soft_Credits_Last_Year__c
             || newC.npo02__Soft_Credit_Total__c != c.npo02__Soft_Credit_Total__c
             || newC.Number_of_Soft_Credits__c != c.Number_of_Soft_Credits__c
             || newC.npo02__Soft_Credit_This_Year__c != c.npo02__Soft_Credit_This_Year__c
             || newC.Number_of_Soft_Credits_This_Year__c != c.Number_of_Soft_Credits_This_Year__c) {
                toUpdate.add(newC);
            }
        }
        update toUpdate;
    }
    
    private Contact countPartialSoftCredits(Contact c, Partial_Soft_Credit__c psc, Date currentYearStart) {
        if (psc.Amount__c == null) psc.Amount__c = 0;
                
        if (psc.Opportunity__r.CloseDate != null) {
            if (c.First_Soft_Credit_Date__c == null || c.First_Soft_Credit_Date__c > psc.Opportunity__r.CloseDate) {
                c.First_Soft_Credit_Date__c = psc.Opportunity__r.CloseDate;
                c.First_Soft_Credit_Amount__c = psc.Amount__c;
            }
            
            if (c.Last_Soft_Credit_Date__c == null || c.Last_Soft_Credit_Date__c < psc.Opportunity__r.CloseDate) {
                c.Last_Soft_Credit_Date__c = psc.Opportunity__r.CloseDate;
                c.Last_Soft_Credit_Amount__c = psc.Amount__c;
            }
            
            if (psc.Opportunity__r.CloseDate >= currentYearStart.addYears(-1) && psc.Opportunity__r.CloseDate < currentYearStart) { // lastYearSoftCredit
                c.Number_of_Soft_Credits_Last_Year__c++;
                c.npo02__Soft_Credit_Last_Year__c += psc.Amount__c;
                
            }
            
            if (psc.Opportunity__r.CloseDate >= currentYearStart && psc.Opportunity__r.CloseDate <= Date.Today()) { // YTDSoftCredit
                c.Number_of_Soft_Credits_This_Year__c++;
                c.npo02__Soft_Credit_This_Year__c += psc.Amount__c;
            }
        }
        
        if (c.Largest_Soft_Credit_Amount__c < psc.Amount__c) {
            c.Largest_Soft_Credit_Amount__c = psc.Amount__c;
            c.Largest_Soft_Credit_Date__c = psc.Opportunity__r.CloseDate;
        }
        
        c.Number_of_Soft_Credits__c++;
        c.npo02__Soft_Credit_Total__c += psc.Amount__c;
        return c;
    }
    
    private Contact countOpportunityContactRoles(Contact c, OpportunityContactRole ocr, Date currentYearStart) {
        Double amount = ocr.Opportunity.Amount != null ? ocr.Opportunity.Amount : 0;
    
        if (ocr.Opportunity.CloseDate != null) {
            if (c.First_Soft_Credit_Date__c == null || c.First_Soft_Credit_Date__c > ocr.Opportunity.CloseDate) {
                c.First_Soft_Credit_Date__c = ocr.Opportunity.CloseDate;
                c.First_Soft_Credit_Amount__c = amount;
            }
            
            if (c.Last_Soft_Credit_Date__c == null || c.Last_Soft_Credit_Date__c < ocr.Opportunity.CloseDate) {
                c.Last_Soft_Credit_Date__c = ocr.Opportunity.CloseDate;
                c.Last_Soft_Credit_Amount__c = amount;
            }
            
            if (ocr.Opportunity.CloseDate >= currentYearStart.addYears(-1) && ocr.Opportunity.CloseDate < currentYearStart) { // lastYearSoftCredit
                c.Number_of_Soft_Credits_Last_Year__c++;
                c.npo02__Soft_Credit_Last_Year__c += amount;
                
            }
            
            if (ocr.Opportunity.CloseDate >= currentYearStart && ocr.Opportunity.CloseDate <= Date.Today()) { // YTDSoftCredit
                c.Number_of_Soft_Credits_This_Year__c++;
                c.npo02__Soft_Credit_This_Year__c += amount;
            }
        }
        
        if (c.Largest_Soft_Credit_Amount__c < amount) {
            c.Largest_Soft_Credit_Amount__c = amount;
            c.Largest_Soft_Credit_Date__c = ocr.Opportunity.CloseDate;
        }
        
        c.Number_of_Soft_Credits__c++;
        c.npo02__Soft_Credit_Total__c += amount;
        return c;
    }
    
    public void finish(Database.BatchableContext BC) {}
}