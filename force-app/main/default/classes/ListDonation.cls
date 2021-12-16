/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2021
* @group Donation
* @description Class for list donation history by credit type.
*/
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
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean isPrimary;
        @AuraEnabled public Date closeDate;
        @AuraEnabled public String role;
        @AuraEnabled public String creditType;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String paymentMethod;
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return Donation History list.
    */
    @AuraEnabled(cacheable=true)
    public static List<DonationHistory> getDonationHistory(Id contactId){
        List<OpportunityContactRole> donations = [SELECT Id, Opportunity.Name, Opportunity.CloseDate, Opportunity.Amount, Contact.Email, Contact.Name, Role, isPrimary 
                                                    FROM OpportunityContactRole 
                                                    WHERE Opportunity.IsWon = true 
                                                    AND ContactId =:contactId 
                                                    ORDER BY Opportunity.CloseDate 
                                                    DESC LIMI 2000];
        List<DonationHistory> result = verifyCreditCondition(donations);
        return result;
    }

    @AuraEnabled(cacheable=true)
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
    public static List<DonationHistory> verifyCreditCondition(List<OpportunityContactRole> donations){
        List<DonationHistory> donationHistory = new List<DonationHistory>();
        List<DonationHistory> hardCredit = verifyHardCreditCondition(donations);
        List<DonationHistory> softCredit = verifySoftCreditCondition(donations);
        List<Id> donationsId = filterVerifiedIds(softCredit);
        List<DonationHistory> partialSoftCredit = verifyPartialSoftCreditCondition(donationsId, donations);
        List<DonationHistory> partialAndSoftCredit = verifyPartialAndSoftCreditCondition(softCredit, partialSoftCredit);
        
        donationHistory.addAll(hardCredit);
        donationHistory.addAll(partialAndSoftCredit);

        return donationHistory;
    }
    
    /** 
    * @author Salesforce.org
    * @date 2021
    * @description Verify hard credit condition.
    */
    public static List<DonationHistory> verifyHardCreditCondition(List<OpportunityContactRole> donations){
        List<DonationHistory> hardCreditList = new List<DonationHistory>();
        for(OpportunityContactRole ocr: donations){
            if (opp.isPrimary) {
                DonationHistory hardCredit = new DonationHistory();
                hardCredit.id = opp.Id;
                hardCredit.name = opp.Opportunity.Name;
                hardCredit.isPrimary = opp.isPrimary;
                hardCredit.closeDate = opp.Opportunity.CloseDate;
                hardCredit.role = opp.Role;
                hardCredit.amount = opp.Opportunity.Amount;
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
    public static List<DonationHistory> verifySoftCreditCondition(List<OpportunityContactRole> donations){
        //with the list of donations verify if the Role match the filter rule value on the NPSP_ClosedWon_Opps_SC filter group
        Filter_Rule__mdt roles = [SELECT Constant__c FROM Filter_Rule__mdt WHERE QualifiedApiName = 'NPSP_OppsSoftCreditRoles'];
        List<String> softCreditRoles = roles.Constant__c.split(';');
        List<DonationHistory> softCreditList = new List<DonationHistory>();
        for(OpportunityContactRole ocr: donations){
            if (softCreditRoles.contains(opp.Role) && opp.isPrimary==false) {
                DonationHistory softCredit = new DonationHistory();
                softCredit.id = opp.Id;
                softCredit.name = opp.Opportunity.Name;
                softCredit.isPrimary = opp.isPrimary;
                softCredit.closeDate = opp.Opportunity.CloseDate;
                softCredit.role = opp.Role;
                softCredit.amount = opp.Opportunity.Amount;
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
    public static List<Id> filterVerifiedIds(List<DonationHistory> softCredit){
        List<Id> donationsId = new List<Id>();
        for(DonationHistory dh: softCredit){
            donationsId.add(dh.id);
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
        List<Id> partialSoftCreditIds = new List<Id>();
        List<Partial_Soft_Credit__c> partialSoftCredit = [SELECT id, Amount__c, Contact_Role_ID__c FROM Partial_Soft_Credit__c WHERE Contact_Role_ID__c IN :donationsId];
        for(Partial_Soft_Credit__c ps: partialSoftCredit){
            partialSoftCreditIds.add(ps.Contact_Role_ID__c);
        }
        List<DonationHistory> partialSoftCreditList = new List<DonationHistory>();
        for(OpportunityContactRole ocr: donations){
            if (partialSoftCreditIds.contains(opp.id)) {
                DonationHistory newPartialSoftCredit = new DonationHistory();
                newPartialSoftCredit.id = opp.Id;
                newPartialSoftCredit.name = opp.Opportunity.Name;
                newPartialSoftCredit.isPrimary = opp.isPrimary;
                newPartialSoftCredit.closeDate = opp.Opportunity.CloseDate;
                newPartialSoftCredit.role = opp.Role;
                newPartialSoftCredit.creditType = PARTIAL_SOFT_CREDIT;
                newPartialSoftCredit.paymentMethod = 'Cash';
                //TODO: change for Amount__c get on partialSoftCredit query
                newPartialSoftCredit.amount = opp.Opportunity.Amount;
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
    public static List<DonationHistory> verifyPartialAndSoftCreditCondition(List<DonationHistory> soft, List<DonationHistory> partialSoft){
        List<Id> partialSoftCreditIds = filterVerifiedIds(partialSoft);
        List<DonationHistory> partialAndSoftCredit = new List<DonationHistory>();
        for(DonationHistory opp: soft){
            if (!partialSoftCreditIds.contains(opp.id)) {
                partialAndSoftCredit.add(opp);
            }
        }
        partialAndSoftCredit.addAll(partialSoft);
        return partialAndSoftCredit;
    }
}