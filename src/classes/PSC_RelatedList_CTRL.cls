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
 * @author Tadeas Brzak
 * @author Tomas "Bobby" Hnizdil
 * @date 8/20/2013
 * @description Controller for SoftCreditList VF page displaying list of OpportunityContactRole and Partial_Soft_Credit__c records on Opportunity page layout
 *
 * This code has been contributed by KELL Partners, and enhanced by Salesforce.org
 */
public with sharing class PSC_RelatedList_CTRL {

    public Opportunity opp {get; set;}
    public List<SoftCredit> softCredits {get; set;}
    public String manageSoftCreditsUrl {get {return Page.PSC_ManageSoftCredits.getUrl();}}

    /*******************************************************************************************************
    * @description constructor for the page
    * @param controller the Opportunity StandardController for the page
    * @return nothing
    */ 
    public PSC_RelatedList_CTRL(ApexPages.StandardController controller) {
        opp = [SELECT Id, Name, Amount FROM Opportunity WHERE Id = :controller.getRecord().Id];
        refreshSoftCredits();
    }
    
    /*******************************************************************************************************
    * @description creates the softCredits list which hold both OCRs and PSCs the page runs off of.
    * @return nothing
    */ 
    private void refreshSoftCredits() {
        Map<Id, SoftCredit> ocrs = new Map<Id, SoftCredit>();
        softCredits = new List<SoftCredit>();
        for (OpportunityContactRole ocr : [SELECT Id, ContactId, Contact.Name, Contact.Email, Contact.AccountId, Contact.Account.Name, Role, Opportunity.Amount, IsPrimary 
                                           FROM OpportunityContactRole WHERE OpportunityId = :opp.Id ORDER BY IsPrimary DESC]) {
            SoftCredit sc = new SoftCredit(ocr);
            softCredits.add(sc);
            ocrs.put(ocr.Id, sc);
        }
        for (Partial_Soft_Credit__c psc : [SELECT Id, Amount__c, Contact_Role_ID__c FROM Partial_Soft_Credit__c WHERE Opportunity__c = :opp.Id AND Contact_Role_ID__c IN :ocrs.keySet()]) {
            ocrs.get(psc.Contact_Role_ID__c).partial = psc;
        }
    }
    
    /*******************************************************************************************************
    * @description ActionMethod that deletes any PSCs and the OCR for the specified OCR Id.
    * @return null
    */ 
    public PageReference deleteSoftCredit() {
        String recordId = ApexPages.currentPage().getParameters().get('recordId');
        List<Partial_Soft_Credit__c> correspondingPartial = [SELECT Id FROM Partial_Soft_Credit__c WHERE Contact_Role_ID__c = :recordId];
        delete correspondingPartial;
        OpportunityContactRole ocr = new OpportunityContactRole(Id = recordId);
        delete ocr;
        refreshSoftCredits();
        return null;
    }
    
    /*******************************************************************************************************
    * @description class used to hold an OCR and its potential PSC.
    */ 
    public class SoftCredit {
        public OpportunityContactRole contactRole {get; set;}
        public Partial_Soft_Credit__c partial {get; set;}

        public SoftCredit(OpportunityContactRole ocr) {
            this.contactRole = ocr;
        }
    }
}