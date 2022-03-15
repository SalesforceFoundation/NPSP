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
    
    static final String NPSP_CREDIT_ROLES = 'NPSP_OppsSoftCreditRoles';
    private List<OpportunityContactRole> hardCredits;
    private List<OpportunityContactRole> softCredits;
    private List<OpportunityContactRole> partialSoftCredits;
    private Id contactId;

    public DonationHistoryService(Id contactId) {
        this.contactId = contactId;
        this.hardCredits = new List<OpportunityContactRole>();
        this.softCredits = new List<OpportunityContactRole>();
        this.partialSoftCredits = new List<OpportunityContactRole>();
    }

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

    private DonationHistorySelector selector {
        get {
            if(selector == null) {
                selector = new DonationHistorySelector();
            }
            return selector;
        }
        set;
    }

    private Boolean hasAccessToDonationHistory() {
        return permissions.canRead(Opportunity.SObjectType, new Set<SObjectField>{
            Opportunity.Amount,
            Opportunity.CloseDate
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
    * @param contactId contact id which is going to be requested.
    */
    public void buildDonationHistory() {
        if (hasAccessToDonationHistory()) {
            List<OpportunityContactRole> credits = 
                selector.getWonOpportunityContactRolesByContactId(this.contactId);
            buildDonationHistoryFromOCRs(credits);
        } else {
            throw new UTIL_Permissions.InsufficientPermissionException(Label.commonInsufficientPermissions);
        }
    }


    public List<OpportunityContactRole> getPartialSoftCredits() {
        return this.partialSoftCredits;
    }


    public List<OpportunityContactRole> getHardCredits() {
        return this.hardCredits;
    }


    public List<OpportunityContactRole> getSoftCredits() {
        List<OpportunityContactRole> filteredSoftCredits = new List<OpportunityContactRole>();
        Set<Id> partialSoftCreditIds = getPartialSoftCreditIds();
        for(OpportunityContactRole softCredit : this.softCredits) {
            if(!partialSoftCreditIds.contains(softCredit.Id)) {
                filteredSoftCredits.add(softCredit);
            }
        }
        return filteredSoftCredits;
    }


    public String getSoftCreditLabel() {
        return UTIL_Describe.getObjectLabel(String.valueOf(Partial_Soft_Credit__c.SObjectType));
    }


    private void buildDonationHistoryFromOCRs(List<OpportunityContactRole> credits) {
        this.hardCredits = buildHardCreditHistoryFromOCRs(credits);
        this.softCredits = buildSoftCreditHistoryFromOCRs(credits);
        this.partialSoftCredits = buildPartialSoftCredits(credits);
    }


    private Set<Id> getPartialSoftCreditIds() {
        return UTIL_SObject.extractIds(this.partialSoftCredits);
    }


    private Set<Id> getSoftCreditIds() {
        return UTIL_SObject.extractIds(this.softCredits);
    }


    private List<OpportunityContactRole> buildHardCreditHistoryFromOCRs(List<OpportunityContactRole> credits) {
        List<OpportunityContactRole> hardCreditOCRs = new List<OpportunityContactRole>();

        for(OpportunityContactRole ocr: credits){
            if (ocr.IsPrimary) {
                hardCreditOCRs.add(ocr);
            }
        }
        return hardCreditOCRs;
    }


    private List<OpportunityContactRole> buildSoftCreditHistoryFromOCRs(List<OpportunityContactRole> credits) {
        //with the list of donations verify if the Role match the filter rule value on the NPSP_ClosedWon_Opps_SC filter group 
        Filter_Rule__mdt filterRule = CMT_FilterRule_SEL.getFilterRuleByDeveloperName(NPSP_CREDIT_ROLES);
        List<String> softCreditRoles = filterRule.Constant__c.split(';');
        List<OpportunityContactRole> softCreditOCRs = new List<OpportunityContactRole>();
        for(OpportunityContactRole ocr : credits) {
            if (softCreditRoles.contains(ocr.Role) && !ocr.IsPrimary) {
                softCreditOCRs.add(ocr);
            }
        }
        return softCreditOCRs;
    }


    private List<OpportunityContactRole> buildPartialSoftCredits(List<OpportunityContactRole> credits) {
        List<Partial_Soft_Credit__c> partialSoftCreditRecords =
                selector.getPartialSoftCredits(this.getSoftCreditIds());
        Set<Id> partialSoftCreditOCRIds = new Set<Id>();
        for(Partial_Soft_Credit__c partialSoftCreditRecord : partialSoftCreditRecords) {
            partialSoftCreditOCRIds.add(partialSoftCreditRecord.Contact_Role_ID__c);
        }
        List<OpportunityContactRole> partialSoftCreditOCRs = new List<OpportunityContactRole>();
        for(OpportunityContactRole ocr : credits) {
            if (partialSoftCreditOCRIds.contains(ocr.Id)) {
                partialSoftCreditOCRs.add(ocr);
            }
        }
        return partialSoftCreditOCRs;
    }
}