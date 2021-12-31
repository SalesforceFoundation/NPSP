public inherited sharing class DonationHistorySelector {
    public List<OpportunityContactRole> getOpportunityContactRoleList(Id contactId) {
        return [
            SELECT Id, 
                Opportunity.Name, 
                Opportunity.CloseDate, 
                Opportunity.Amount, 
                Contact.Email, 
                Contact.Name, 
                Role, 
                isPrimary 
            FROM OpportunityContactRole 
            WHERE Opportunity.IsWon = true 
            AND ContactId =:contactId 
            WITH SECURITY_ENFORCED
            ORDER BY Opportunity.CloseDate 
            DESC LIMIT 2000
        ];
    }
    public List<Partial_Soft_Credit__c> getPartialSoftCredit(List<Id> donationIds){
        return [
            SELECT 
                id, 
                Amount__c, 
                Contact_Role_ID__c 
            FROM Partial_Soft_Credit__c 
            WHERE Contact_Role_ID__c IN :donationIds
        ];
    }   
}
