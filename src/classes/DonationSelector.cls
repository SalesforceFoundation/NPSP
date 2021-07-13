public with sharing class DonationSelector {
    
    public DonationSelector() {}

    public List<Opportunity> getOpenDonations(String relationshipField, Id donorId) {
        String opportunitySOQL = 'SELECT Id, ' +
                    'Name, ' +
                    'StageName, ' +
                    'CloseDate, ' +
                    'IsClosed, ' +
                    'Amount, ' +
                    'npe01__Number_of_Payments__c, ' +
                    '(SELECT Id, ' +
                    'Name, ' +
                    'npe01__Scheduled_Date__c, ' +
                    'npe01__Opportunity__r.Name, ' +
                    'npe01__Opportunity__c, ' +
                    'npe01__Payment_Amount__c,' +
                    'npe01__Payment_Date__c,' +
                    'npe01__Paid__c, ' +
                    'npe01__Written_Off__c, ' +
                    'Elevate_Payment_API_Status__c ' +
                    'FROM npe01__OppPayment__r ' +
                    'WHERE npe01__Written_Off__c = false ' +
                    'AND npe01__Paid__c = false),' +
                    '(SELECT Id, Role, ContactId FROM OpportunityContactRoles)' +
                    'FROM Opportunity ' +
                    'WHERE ' + relationshipField + ' = :donorId ' +
                    'AND IsClosed = false ' +
                    'WITH SECURITY_ENFORCED ' +
                    'ORDER BY CloseDate ASC';
        return Database.query(opportunitySOQL);      
    }
}
