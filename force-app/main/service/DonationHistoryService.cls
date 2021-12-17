public with sharing class DonationHistoryService {

    static final String HARD_CREDIT = 'Hard Credit';
    static final String SOFT_CREDIT = 'Soft Credit';
    static final String PARTIAL_SOFT_CREDIT = 'Partial Soft Credit';
    
    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return Donation History list.
    */
    public List<DonationHistoryController.DonationHistory> getDonationHistory(Id contactId){
        List<OpportunityContactRole> donations = [SELECT Id, Opportunity.Name, Opportunity.CloseDate, Opportunity.Amount, Contact.Email, Contact.Name, Role, isPrimary 
                                                    FROM OpportunityContactRole 
                                                    WHERE Opportunity.IsWon = true 
                                                    AND ContactId =:contactId 
                                                    ORDER BY Opportunity.CloseDate 
                                                    DESC LIMIT 2000];
        List<DonationHistoryController.DonationHistory> result = verifyCreditCondition(donations);
        return result;
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return total number of record
    */
    public static List<AggregateResult> getTotalRecords(Id contactId){
        List<AggregateResult> totalRecords = [SELECT COUNT(Id)
                                FROM OpportunityContactRole 
                                WHERE Opportunity.IsWon = true 
                                AND ContactId =:contactId];
        return totalRecords;
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Verify each condition to list Donation.
    */
    private static List<DonationHistoryController.DonationHistory> verifyCreditCondition(List<OpportunityContactRole> donations){
        List<DonationHistoryController.DonationHistory> donationHistory = new List<DonationHistoryController.DonationHistory>();
        List<DonationHistoryController.DonationHistory> hardCredit = verifyHardCreditCondition(donations);
        List<DonationHistoryController.DonationHistory> softCredit = verifySoftCreditCondition(donations);
        List<Id> donationsId = filterVerifiedIds(softCredit);
        List<DonationHistoryController.DonationHistory> partialSoftCredit = verifyPartialSoftCreditCondition(donationsId, donations);
        List<DonationHistoryController.DonationHistory> partialAndSoftCredit = verifyPartialAndSoftCreditCondition(softCredit, partialSoftCredit);
        
        donationHistory.addAll(hardCredit);
        donationHistory.addAll(partialAndSoftCredit);

        return donationHistory;
    }
    
    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Verify hard credit condition.
    */
    private static List<DonationHistoryController.DonationHistory> verifyHardCreditCondition(List<OpportunityContactRole> donations){
        List<DonationHistoryController.DonationHistory> hardCreditList = new List<DonationHistoryController.DonationHistory>();
        for(OpportunityContactRole ocr: donations){
            if (ocr.isPrimary) {
                DonationHistoryController.DonationHistory hardCredit = new DonationHistoryController.DonationHistory();
                hardCredit.id = ocr.Id;
                hardCredit.name = ocr.Opportunity.Name;
                hardCredit.isPrimary = ocr.isPrimary;
                hardCredit.closeDate = ocr.Opportunity.CloseDate;
                hardCredit.role = ocr.Role;
                hardCredit.amount = ocr.Opportunity.Amount;
                hardCredit.creditType = HARD_CREDIT;
                hardCredit.paymentMethod = 'Cash';
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
    private static List<DonationHistoryController.DonationHistory> verifySoftCreditCondition(List<OpportunityContactRole> donations){
        //with the list of donations verify if the Role match the filter rule value on the NPSP_ClosedWon_Opps_SC filter group
        Filter_Rule__mdt roles = [SELECT Constant__c FROM Filter_Rule__mdt WHERE QualifiedApiName = 'NPSP_OppsSoftCreditRoles'];
        List<String> softCreditRoles = roles.Constant__c.split(';');
        List<DonationHistoryController.DonationHistory> softCreditList = new List<DonationHistoryController.DonationHistory>();
        for(OpportunityContactRole ocr: donations){
            if (softCreditRoles.contains(ocr.Role) && ocr.isPrimary==false) {
                DonationHistoryController.DonationHistory softCredit = new DonationHistoryController.DonationHistory();
                softCredit.id = ocr.Id;
                softCredit.name = ocr.Opportunity.Name;
                softCredit.isPrimary = ocr.isPrimary;
                softCredit.closeDate = ocr.Opportunity.CloseDate;
                softCredit.role = ocr.Role;
                softCredit.amount = ocr.Opportunity.Amount;
                softCredit.creditType = SOFT_CREDIT;
                softCredit.paymentMethod = 'Cash';
                softCreditList.add(softCredit);
            }
        }
        return softCreditList;
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Filter for ids already classified as Soft Credit.
    */
    private static List<Id> filterVerifiedIds(List<DonationHistoryController.DonationHistory> softCredit){
        List<Id> donationsId = new List<Id>();
        for(DonationHistoryController.DonationHistory dh: softCredit){
            donationsId.add(dh.id);
        }
        return donationsId;
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Verify partial soft credit condition.
    */
    private static List<DonationHistoryController.DonationHistory> verifyPartialSoftCreditCondition(List<Id> donationsId, List<OpportunityContactRole> donations){
        //search on PartialSoftCredit object for ids filtered before usin IN()
        //only ids with not type of credit defined before
        List<Id> partialSoftCreditIds = new List<Id>();
        List<Partial_Soft_Credit__c> partialSoftCredit = [SELECT id, Amount__c, Contact_Role_ID__c FROM Partial_Soft_Credit__c WHERE Contact_Role_ID__c IN :donationsId];
        for(Partial_Soft_Credit__c ps: partialSoftCredit){
            partialSoftCreditIds.add(ps.Contact_Role_ID__c);
        }
        List<DonationHistoryController.DonationHistory> partialSoftCreditList = new List<DonationHistoryController.DonationHistory>();
        for(OpportunityContactRole ocr: donations){
            if (partialSoftCreditIds.contains(ocr.id)) {
                DonationHistoryController.DonationHistory newPartialSoftCredit = new DonationHistoryController.DonationHistory();
                newPartialSoftCredit.id = ocr.Id;
                newPartialSoftCredit.name = ocr.Opportunity.Name;
                newPartialSoftCredit.isPrimary = ocr.isPrimary;
                newPartialSoftCredit.closeDate = ocr.Opportunity.CloseDate;
                newPartialSoftCredit.role = ocr.Role;
                newPartialSoftCredit.creditType = PARTIAL_SOFT_CREDIT;
                newPartialSoftCredit.paymentMethod = 'Cash';
                //TODO: change for Amount__c get on partialSoftCredit query
                newPartialSoftCredit.amount = ocr.Opportunity.Amount;
                partialSoftCreditList.add(newPartialSoftCredit);
            }
        }
        return partialSoftCreditList;
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Method to avoid duplicated records for Soft and Partial Soft credits.
    */
    private static List<DonationHistoryController.DonationHistory> verifyPartialAndSoftCreditCondition(List<DonationHistoryController.DonationHistory> soft, List<DonationHistoryController.DonationHistory> partialSoft){
        List<Id> partialSoftCreditIds = filterVerifiedIds(partialSoft);
        List<DonationHistoryController.DonationHistory> partialAndSoftCredit = new List<DonationHistoryController.DonationHistory>();
        for(DonationHistoryController.DonationHistory ocr: soft){
            if (!partialSoftCreditIds.contains(ocr.id)) {
                partialAndSoftCredit.add(ocr);
            }
        }
        partialAndSoftCredit.addAll(partialSoft);
        return partialAndSoftCredit;
    }
}
