/*
    Copyright (c) 2021 Salesforce.org
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
* @description Donation History Service class in NPSP.
*/
public with sharing class DonationHistoryService {

    static final String HARD_CREDIT = 'Hard Credit';
    static final String SOFT_CREDIT = 'Soft Credit';
    static final String PARTIAL_SOFT_CREDIT = 'Partial Soft Credit';
    static final String NPSP_CREDIT_ROLES= 'NPSP_OppsSoftCreditRoles';
    
    @TestVisible
    private UTIL_Permissions permissions {
        get {
            if(permissions == null) {
                permissions = new UTIL_Permissions();
            }
            return permissions;
        }
        set;
    }

    private Boolean hasAccessToDonationHistory(){
        return permissions.canRead(Opportunity.SObjectType, new Set<SObjectField>{
            Opportunity.Amount,
            Opportunity.CloseDate,
            Opportunity.Name
        }) && permissions.canRead(Contact.SObjectType, new Set<SObjectField>{
            Contact.Email,
            Contact.Name
        }) && permissions.canRead(Partial_Soft_Credit__c.SObjectType, new Set<SObjectField>{
            Partial_Soft_Credit__c.Amount__c,
            Partial_Soft_Credit__c.Contact_Role_ID__c
        });
    }

    /** 
    * @author Salesforce.org
    * @date 2021
    * @description method to return Donation History list.
    */
    public List<DonationHistoryController.DonationHistory> getDonationHistory(Id contactId){
        if (hasAccessToDonationHistory()) {
            List<OpportunityContactRole> credits = new DonationHistorySelector().getWonOpportunityContactRolesByContactId(contactId);
            List<DonationHistoryController.DonationHistory> result = buildDonationHistoryFromOCRs(credits);
            System.debug(result.size());
            return result;
        } else {
            throw new UTIL_Permissions.InsufficientPermissionException(Label.commonInsufficientPermissions);
        }
    }

    private static List<DonationHistoryController.DonationHistory> buildDonationHistoryFromOCRs(List<OpportunityContactRole> credits){
        List<DonationHistoryController.DonationHistory> donationHistory = new List<DonationHistoryController.DonationHistory>();
        List<DonationHistoryController.DonationHistory> hardCredits = buildHardCreditHistoryFromOCRs(credits);
        List<DonationHistoryController.DonationHistory> softCredits = buildSoftCreditHistoryFromOCRs(credits);
        List<Id> softCreditIds = filterVerifiedIds(softCredits);
        List<DonationHistoryController.DonationHistory> partialSoftCredits = verifyPartialSoftCreditCondition(softCreditIds, credits);
        List<DonationHistoryController.DonationHistory> partialAndSoftCredits = buildPartialAndSoftCreditFromOCRs(softCredits, partialSoftCredits);
        
        donationHistory.addAll(hardCredits);
        donationHistory.addAll(partialAndSoftCredits);

        return donationHistory;
    }
    
    private static List<DonationHistoryController.DonationHistory> buildHardCreditHistoryFromOCRs(List<OpportunityContactRole> credits){
        List<DonationHistoryController.DonationHistory> hardCreditList = new List<DonationHistoryController.DonationHistory>();
        for(OpportunityContactRole ocr: credits){
            if (ocr.isPrimary) {
                DonationHistoryController.DonationHistory hardCredit = new DonationHistoryController.DonationHistory(ocr, HARD_CREDIT);
                hardCreditList.add(hardCredit);
            }
        }
        return hardCreditList;
    }
    
    private static List<DonationHistoryController.DonationHistory> buildSoftCreditHistoryFromOCRs(List<OpportunityContactRole> credits){
        //with the list of donations verify if the Role match the filter rule value on the NPSP_ClosedWon_Opps_SC filter group 
        Filter_Rule__mdt filterRule = CMT_FilterRule_SEL.getFilterRuleByDeveloperName(NPSP_CREDIT_ROLES);
        List<String> softCreditRoles = filterRule.Constant__c.split(';');
        List<DonationHistoryController.DonationHistory> softCreditList = new List<DonationHistoryController.DonationHistory>();
        for(OpportunityContactRole ocr: credits){
            if (softCreditRoles.contains(ocr.Role) && !ocr.isPrimary) {
                DonationHistoryController.DonationHistory softCredit = new DonationHistoryController.DonationHistory(ocr, SOFT_CREDIT);
                softCreditList.add(softCredit);
            }
        }
        return softCreditList;
    }

    private static List<Id> filterVerifiedIds(List<DonationHistoryController.DonationHistory> softCredits){
        List<Id> softCreditIds = new List<Id>();
        for(DonationHistoryController.DonationHistory dh: softCredits){
            softCreditIds.add(dh.id);
        }
        return softCreditIds;
    }

    private static List<DonationHistoryController.DonationHistory> verifyPartialSoftCreditCondition(List<Id> softCreditIds, List<OpportunityContactRole> credits){
        List<Id> partialSoftCreditIds = new List<Id>();
        List<Partial_Soft_Credit__c> partialSoftCredit = new DonationHistorySelector().getPartialSoftCredit(softCreditIds);
        Filter_Rule__mdt ruleCmt = CMT_FilterRule_SEL.getFilterRuleByDeveloperName(NPSP_CREDIT_ROLES);
        CMT_FilterRule rule = new CMT_FilterRule(ruleCmt);
        for(Partial_Soft_Credit__c ps: partialSoftCredit) {
            if(rule.isIncluded(ps)) {
                partialSoftCreditIds.add(ps.Contact_Role_ID__c);
            }
        }
        List<DonationHistoryController.DonationHistory> partialSoftCreditList = new List<DonationHistoryController.DonationHistory>();
        for(OpportunityContactRole ocr: credits){
            if (partialSoftCreditIds.contains(ocr.id)) {
                DonationHistoryController.DonationHistory newPartialSoftCredit = new DonationHistoryController.DonationHistory(ocr, PARTIAL_SOFT_CREDIT);
                partialSoftCreditList.add(newPartialSoftCredit);
            }
        }
        return partialSoftCreditList;
    }

    private static List<DonationHistoryController.DonationHistory> buildPartialAndSoftCreditFromOCRs(List<DonationHistoryController.DonationHistory> softCredits, List<DonationHistoryController.DonationHistory> partialSoftCredits){
        List<Id> partialSoftCreditIds = filterVerifiedIds(partialSoftCredits);
        List<DonationHistoryController.DonationHistory> partialAndSoftCredit = new List<DonationHistoryController.DonationHistory>();
        for(DonationHistoryController.DonationHistory ocr: softCredits){
            if (!partialSoftCreditIds.contains(ocr.id)) {
                partialAndSoftCredit.add(ocr);
            }
        }
        partialAndSoftCredit.addAll(partialSoftCredits);
        return partialAndSoftCredit;
    }
}
