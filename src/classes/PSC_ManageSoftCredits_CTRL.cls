/*
    Copyright (c) 2015 Salesforce.org
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
 * @author Tomas "Bobby" Hnizdil
 * @date 8/21/2013
 * @description Controller for ManageSoftCredits VF page allowing users to add, remove and edit full and soft credits on Opportunity
 * This code has been contributed by KELL Partners, and enhanced by Salesforce.org
 */
public with sharing class PSC_ManageSoftCredits_CTRL {

    public Opportunity opp {get; set;}
    public boolean amount_percentage {get; set;} // true = amount, false = percentage
    public boolean checkTotalAllocatedAmount {get; set;}
    public List<SoftCredit> softCredits {get; set;}
    public List<SelectOption> contactRoles {get; private set;}

    /*******************************************************************************************************
    * @description constructor for the page
    * @param controller the StandardController for the page
    * @return nothing
    */ 
    public PSC_ManageSoftCredits_CTRL(ApexPages.StandardController controller) {
        opp = [SELECT Id, Name, Amount, AccountId, Account.Name FROM Opportunity WHERE Id = :controller.getRecord().Id];
        amount_percentage = true;
        checkTotalAllocatedAmount = false;
        
        Map<Id, SoftCredit> ocrs = new Map<Id, SoftCredit>();
        softCredits = new List<SoftCredit>();
        for (OpportunityContactRole ocr : [SELECT Id, ContactId, Role, Opportunity.Amount 
                                           FROM OpportunityContactRole WHERE OpportunityId = :opp.Id AND IsPrimary != true]) {
            SoftCredit sc = new SoftCredit(ocr);
            softCredits.add(sc);
            ocrs.put(ocr.Id, sc);
        }
        for (Partial_Soft_Credit__c psc : [SELECT Id, Opportunity__c, Contact__c, Amount__c, Role_Name__c, Contact_Role_ID__c
                                           FROM Partial_Soft_Credit__c WHERE Opportunity__c = :opp.Id AND Contact_Role_ID__c IN :ocrs.keySet()]) {
            ocrs.get(psc.Contact_Role_ID__c).partial = psc;
            ocrs.get(psc.Contact_Role_ID__c).fullCredit = false;
        }
        
        contactRoles = new List<SelectOption>();
        for (Schema.PicklistEntry pe : OpportunityContactRole.Role.getDescribe().getPicklistValues()) {
            if (pe.getValue() != UTIL_CustomSettingsFacade.getContactsSettings().npe01__Opportunity_Contact_Role_Default_role__c) {
                contactRoles.add(new SelectOption(pe.getLabel(), pe.getValue()));
            }
        }
    }
    
    /*******************************************************************************************************
    * @description actionMethod to save the soft credits on the page
    * @return the Opportunity's detail page if success, or null if any error encountered.
    */ 
    public PageReference save() {
        String ocrKeyPrefix = OpportunityContactRole.SObjectType.getDescribe().getKeyPrefix();
        String pscKeyPrefix = Partial_Soft_Credit__c.SObjectType.getDescribe().getKeyPrefix();
        Map<Id, String> donors = new Map<Id, String>(); // Contact Id, Contact Name
        for (OpportunityContactRole ocr : [SELECT Id, ContactId, Contact.Name FROM OpportunityContactRole WHERE OpportunityId = :opp.Id AND IsPrimary = true]) {
            donors.put(ocr.ContactId, ocr.Contact.Name);
        }
        List<SObject> toDelete = new List<SObject>();
        List<OpportunityContactRole> toUpsertContactRoles = new List<OpportunityContactRole>();
        List<Partial_Soft_Credit__c> toUpsertPartialCredits = new List<Partial_Soft_Credit__c>();
        List<SoftCredit> upsertedSoftCredits = new List<SoftCredit>();
        for (SoftCredit sc : softCredits) {
            if (sc.contactRole.ContactId != null) {
                if (donors.containsKey(sc.contactRole.ContactId)) {
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
                        string.Format(Label.pscManageSoftCreditsInvalidContact, new String[]{donors.get(sc.contactRole.ContactId)})));
                    return null;
                } else if (sc.partial.Amount__c == null) {
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.pscManageSoftCreditsAmountMissing));
                    return null;
                }
                
                if (sc.fullCredit || sc.partial.Amount__c == opp.Amount) {
                    if (sc.partial.Id != null) toDelete.add(sc.partial);
                    toUpsertContactRoles.add(sc.contactRole);
                } else {
                    if (sc.partial.Contact__c == null) sc.partial.Contact__c = sc.contactRole.ContactId;
                    else if (sc.partial.Contact__c != sc.contactRole.ContactId) {
                        toDelete.add(sc.partial);
                        sc.partial = new Partial_Soft_Credit__c(Contact__c = sc.contactRole.ContactId, Amount__c = sc.partial.Amount__c);
                    }
                    if (sc.partial.Opportunity__c == null) sc.partial.Opportunity__c = sc.contactRole.OpportunityId;
                    sc.partial.Role_Name__c = sc.contactRole.Role;
                    toUpsertContactRoles.add(sc.contactRole);
                    upsertedSoftCredits.add(sc);
                }
            } else {
                if (sc.partial.Id != null) toDelete.add(sc.partial);
                if (sc.contactRole.Id != null) toDelete.add(sc.contactRole);
            }
        }
        if (checkTotalAllocatedAmount && getTotalSoftCreditAmount() > opp.Amount) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.pscManageSoftCreditsReconcileFail));
            return null;
        }
        
        try {
            delete toDelete;
            upsert toUpsertContactRoles;
            for (SoftCredit sc : upsertedSoftCredits) {
                sc.partial.Contact_Role_ID__c = sc.contactRole.Id;
                if (!amount_percentage) sc.partial.Amount__c = convertPercentageToAmount(sc.partial.Amount__c);
                toUpsertPartialCredits.add(sc.partial);
            }
            upsert toUpsertPartialCredits;
            
            if (!amount_percentage) {
                for (SoftCredit sc : upsertedSoftCredits) {
                    sc.partial.Amount__c = convertPercentageToAmount(sc.partial.Amount__c);
                }
            }
        
            //no reason to do this, since we are redirecting back to the Opp.
            //Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'All soft credit records have been saved.'));
            
            return new PageReference('/' + opp.Id);
        } catch (Exception ex) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }
    
    /*******************************************************************************************************
    * @description actionMethod for the Cancel button
    * @return the Opportunity's detail page
    */ 
    public PageReference cancel() {
        return new PageReference('/' + opp.Id);
    }
    
    /*******************************************************************************************************
    * @description actionMethod that doesn't do anything, but causes a page refresh
    * @return void
    */ 
    public void refresh() {}
    
    /*******************************************************************************************************
    * @description sets the appropriate amount for each soft credit
    * @return void
    */ 
    public void checkFullCredit() {
        for (SoftCredit sc : softCredits) {
            if (sc.fullCredit) {
                sc.partial.Amount__c = amount_percentage ? opp.Amount : 100;
            }
        }
    }
    
    /*******************************************************************************************************
    * @description sets the appropriate amount for each soft credit
    * @return void
    */ 
    public void checkFullAndPartialCredit() {
        for (SoftCredit sc : softCredits) {
            if (sc.fullCredit) {
                sc.partial.Amount__c = amount_percentage ? opp.Amount : 100;
            } else {
                sc.partial.Amount__c = amount_percentage ? convertPercentageToAmount(sc.partial.Amount__c) : convertAmountToPercentage(sc.partial.Amount__c);
            }
        }
    }
    
    /*******************************************************************************************************
    * @description converts the decimal amount to a percentage of the Opp's full amount
    * @param amount a decimal amount of a soft credit
    * @return Double a percentage
    */ 
    private Double convertAmountToPercentage(Decimal amount) {
        if (amount == null) amount = 0;
        return (amount / opp.Amount * 100).setScale(2, RoundingMode.HALF_UP);
    }
    
    /*******************************************************************************************************
    * @description converts the a percentage of the Opp's full amount, to a percentage
    * @param percentage a decimal representing a percentage of the opp's full amount
    * @return Double the amount that percentage represents
    */ 
    private Double convertPercentageToAmount(Decimal percentage) {
        if (percentage == null) percentage = 0;
        return (opp.Amount * percentage / 100).setScale(2, RoundingMode.HALF_UP);
    }
    
    /*******************************************************************************************************
    * @description actionMethod to add an additional soft credit record
    * @return void
    */ 
    public void addAnotherSoftCredit() {
        softCredits.add(new SoftCredit(new OpportunityContactRole(OpportunityId = opp.Id)));
    }
    
    /*******************************************************************************************************
    * @description gets the total amount of all soft credits
    * @return void
    */ 
    public Double getTotalSoftCreditAmount() {
        Double total = 0;
        for (SoftCredit sc : softCredits) {
            if (sc.contactRole.ContactId != null) {
                total += sc.partial.Amount__c != null ? sc.partial.Amount__c : 0;
            }
        }
        return amount_percentage ? total : (total/100) * opp.Amount;
    }
    
    /*******************************************************************************************************
    * @description helper class to represent a soft credit, which contains both an OCR and a PSC.
    */ 
    public class SoftCredit {
        public OpportunityContactRole contactRole {get; set;}
        public Partial_Soft_Credit__c partial {get; set;}
        public Boolean fullCredit {get; set;}
        
        public SoftCredit(OpportunityContactRole ocr) {
            this.contactRole = ocr;
            this.partial = new Partial_Soft_Credit__c(Amount__c = ocr.Opportunity.Amount);
            this.fullCredit = ocr.Id != null;
        }
    }
}