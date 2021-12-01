public with sharing class ListDonation {

    static final String HARD_CREDIT = 'Hard Credit';
    static final String SOFT_CREDIT = 'Soft Credit';
    static final String PARTIAL_SOFT_CREDIT = 'Partial Soft Credit';

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Donation History inner class.
    */
    public class DonationHistory{
        public Id id { get; set; }
        public String name { get; set; }
        public Date closeDate { get; set; }
        public String role { get; set; }
        public String creditType { get; set; }
        public Decimal amount { get; set; }
        //public String paymentMethod { get; set; }
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return Donation History list.
    */
    @AuraEnabled
    public static List<DonationHistory> getDonationHistory(){
        List<OpportunityContactRole> donations = [SELECT Id, Opportunity.Name, Opportunity.CloseDate, Opportunity.Amount, Contact.Email, Contact.Name, Role, isPrimary FROM OpportunityContactRole WHERE Opportunity.StageName = 'Closed Won'];
        List<DonationHistory> result = verifyCreditCondition(donations);
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Verify each condition to list Donation.
    */
    public static List<DonationHistory> verifyCreditCondition(List<OpportunityContactRole> donations){
        List<DonationHistory> donationHistory = new List<DonationHistory>();
        List<DonationHistory> hardCredit = verifyHardCreditCondition(donations);
        donationHistory.addAll(hardCredit);

        List<DonationHistory> softCredit = verifySoftCreditCondition(donations);
        donationHistory.addAll(softCredit);

        List<Id> donationsId = filterVerifiedIds(donationHistory, donations);
        List<DonationHistory> partialSoftCredit = verifyPartialSoftCreditCondition(donationsId, donations);
        donationHistory.addAll(partialSoftCredit);

        return donationHistory;
    }
    
    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Verify hard credit condition.
    */
    public static List<DonationHistory> verifyHardCreditCondition(List<OpportunityContactRole> donations){
        List<DonationHistory> hardCreditList = new List<DonationHistory>();
        for(OpportunityContactRole opp: donations){
            if (opp.isPrimary) {
                DonationHistory hardCredit = new DonationHistory();
                hardCredit.id = opp.Id;
                hardCredit.name = opp.Opportunity.Name;
                hardCredit.closeDate = opp.Opportunity.CloseDate;
                hardCredit.role = opp.Role;
                hardCredit.amount = opp.Opportunity.Amount;
                hardCredit.creditType = HARD_CREDIT;
                hardCreditList.add(hardCredit);
            }
        }
        return hardCreditList;
    }
    
    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Verify soft credit condition.
    */
    public static List<DonationHistory> verifySoftCreditCondition(List<OpportunityContactRole> donations){
        //with the list of donations verify if the Role match the filter rule value on the NPSP_ClosedWon_Opps_SC filter group
        Filter_Rule__mdt roles = [SELECT Constant__c FROM Filter_Rule__mdt WHERE QualifiedApiName = 'NPSP_OppsSoftCreditRoles'];
        List<String> softCreditRoles = roles.Constant__c.split(';');
        List<DonationHistory> softCreditList = new List<DonationHistory>();
        for(OpportunityContactRole opp: donations){
            if (softCreditRoles.contains(opp.Role)) {
                DonationHistory softCredit = new DonationHistory();
                softCredit.id = opp.Id;
                softCredit.name = opp.Opportunity.Name;
                softCredit.closeDate = opp.Opportunity.CloseDate;
                softCredit.role = opp.Role;
                softCredit.amount = opp.Opportunity.Amount;
                softCredit.creditType = SOFT_CREDIT;
                softCreditList.add(softCredit);
            }
        }
        return softCreditList;
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Filter for ids already classified.
    */
    public static List<Id> filterVerifiedIds(List<DonationHistory> donationHistory, List<OpportunityContactRole> donations){
        List<Id> donationsId = new List<Id>();
        List<Id> donationHistoryList = new List<Id>();
        for(DonationHistory dh: donationHistory){
            donationHistoryList.add(dh.id);
        }
        for(OpportunityContactRole opp: donations){
            if (!donationHistoryList.contains(opp.id)) {
                donationsId.add(opp.Id);
            }
        }
        return donationsId;
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Verify partial soft credit condition.
    */
    public static List<DonationHistory> verifyPartialSoftCreditCondition(List<Id> donationsId, List<OpportunityContactRole> donations){
        //search on PartialSoftCredit object for ids filtered before usin IN()
        //only ids with not type of credit defined before
        List<Partial_Soft_Credit__c> partialSoftCredit = [SELECT id, Amount__c FROM Partial_Soft_Credit__c WHERE Contact_Role_ID__c IN :donationsId];
        Set<Id> resultIds = (new Map<Id,Partial_Soft_Credit__c>(partialSoftCredit)).keySet();
        List<DonationHistory> partialSoftCreditList = new List<DonationHistory>();
        for(OpportunityContactRole opp: donations){
            if (resultIds.contains(opp.id)) {
                DonationHistory newPartialSoftCredit = new DonationHistory();
                newPartialSoftCredit.id = opp.Id;
                newPartialSoftCredit.name = opp.Opportunity.Name;
                newPartialSoftCredit.closeDate = opp.Opportunity.CloseDate;
                newPartialSoftCredit.role = opp.Role;
                newPartialSoftCredit.creditType = PARTIAL_SOFT_CREDIT;
                //TODO: change for Amount__c get on partialSoftCredit query
                newPartialSoftCredit.amount = opp.Opportunity.Amount;
                partialSoftCreditList.add(newPartialSoftCredit);
            }
        }
        return partialSoftCreditList;
    }
}