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
 * @group Opportunity
 * @description Controller for ManageSoftCredits VF page allowing users to add, remove and edit full and soft credits on Opportunity
 * This code has been contributed by KELL Partners, and enhanced by Salesforce.org
 */
public with sharing class PSC_ManageSoftCredits_CTRL {

    public Opportunity opp {get; set;}
    public Boolean isAmount {get; set;} // true = amount, false = percentage
    public Boolean allowTooManySoftCredits {get; set;}
    public List<SoftCredit> softCredits {get; set;}
    /** @description List of soft credits to delete when the user clicks Save.*/
    public List<SObject> listSoftCreditsForDelete = new List<sObject>();
    public List<SelectOption> contactRoles {get; private set;}
    /** @description Row number sent back by page for delete row method.*/
    public Integer rowNumber {get;set;}
    /** @description The currency symbol or ISO code of the related record or org default */
    @TestVisible private String currencySymbol;

    /** @description Set to true if the user has the appropriate permissions to access the page */
    public Boolean hasAccess {
        get {
            if (hasAccess == null) {
                hasAccess = getCurrentUserHasAccess();
            }
            return hasAccess;
        }
        private set;
    }

    /*******************************************************************************************************
    * @description Permissions class used to determine if the running user has permissions
    */
    @TestVisible
    private UTIL_Permissions perms {
        get {
            if (perms == null) {
                perms = new UTIL_Permissions();
            }

            return perms;
        }
        set;
    }

    /*******************************************************************************************************
    * @description temporary Opp to hold the current Total Soft Credit Amount and currency
    */
    public Opportunity oppTotalSoftCredit {
        get {
            if (oppTotalSoftCredit == null) {
                oppTotalSoftCredit = new Opportunity();
                if (userInfo.isMultiCurrencyOrganization()) 
                    oppTotalSoftCredit.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
            }
            oppTotalSoftCredit.Amount = getTotalSoftCreditAmount();
            return oppTotalSoftCredit;
        }
        private set;
    }
    
    /*******************************************************************************************************
    * @description temporary Opp to hold the current Unaccounted Amount and currency
    */
    public Opportunity oppTotalUnaccounted {
        get {
            if (oppTotalUnaccounted == null) {
                oppTotalUnaccounted = new Opportunity();
                if (userInfo.isMultiCurrencyOrganization()) 
                    oppTotalUnaccounted.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
            }
            oppTotalUnaccounted.Amount = opp.Amount - oppTotalSoftCredit.Amount;
            return oppTotalUnaccounted;
        }
        private set;
    }
    
    /*******************************************************************************************************
    * @description returns the number of soft credits
    * @return number of soft credits
    */
    public integer numberOfSoftCredits {
        get {
            return softCredits == null ? 0 : softCredits.size();
        } private set;
    }

    /*******************************************************************************************************
    * @description constructor for the page
    * @param controller the StandardController for the page
    * @return nothing
    */ 
    public PSC_ManageSoftCredits_CTRL(ApexPages.StandardController controller) {
        Id recordId = controller.getRecord().Id;

        if (!hasAccess) {
            opp = new Opportunity(Id = recordId);

            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, System.Label.pscManageSoftCreditsPermissionDenied));
            return;
        }

        String oppQuery = 'SELECT Id, Name, Amount, AccountId, Account.Name, npe01__Is_Opp_From_Individual__c, Primary_Contact__c, Primary_Contact__r.Name';

        if (userInfo.isMultiCurrencyOrganization()) {
            oppQuery += ', CurrencyIsoCode';
        }

        oppQuery +=  ' FROM Opportunity WHERE Id = :recordId';
        opp = Database.query(oppQuery);
        isAmount = true;
        allowTooManySoftCredits = false;

        //if the opp Amount is null,set it to $0 and allow the page to run.
        if (opp.Amount == null) 
            opp.Amount = 0;

        // this page wants to display just the Soft Credit OCRs and PSCs.
        // since the PSC lookup to an OCR is really just a text field,
        // we can't assume the lookup is valid, and we must also deal with
        // the lookup pointing at an OCR that we wouldn't normally include
        // (such as the primary ocr or a non-soft credit ocr).  Here are the cases
        // we must handle for a PSC's Contact_Role_ID__c lookup:
        //  - valid soft credit ocr
        //  - valid ocr, but it doesn't use a soft credit role
        //  - the primary ocr
        //  - an invalid ocr Id (ie, the ocr was deleted out from under the psc)
        //  - null for the ocr Id
        
        Map<Id, SoftCredit> ocrs = new Map<Id, SoftCredit>();
        softCredits = new List<SoftCredit>();
        Set<String> softCreditRoles = new Set<String>();

        if (UTIL_CustomSettingsFacade.getCustomizableRollupSettings().Customizable_Rollups_Enabled__c) {
            for(Schema.PicklistEntry pe : Schema.sObjectType.OpportunityContactRole.fields.Role.getPicklistValues()) {
                softCreditRoles.add(pe.getLabel());
            }
        } else if (UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Soft_Credit_Roles__c != null) {
            softCreditRoles = new Set<String>(UTIL_CustomSettingsFacade.getHouseholdsSettings().npo02__Soft_Credit_Roles__c.split(';'));
        }

        // get all OCR's for the Opp
        map<Id, OpportunityContactRole> mapIdToOCR = new map<Id, OpportunityContactRole>([SELECT Id, ContactId, Role, 
            IsPrimary, Opportunity.Amount FROM OpportunityContactRole WHERE OpportunityId = :opp.Id]);
            
        // get all PSC's for the Opp
        for (Partial_Soft_Credit__c psc : [SELECT Id, Opportunity__c, Contact__c, Amount__c, Role_Name__c, Contact_Role_ID__c
                FROM Partial_Soft_Credit__c WHERE Opportunity__c = :opp.Id]) {
                    
            // find its related OCR
            OpportunityContactRole ocr = mapIdToOCR.get(psc.Contact_Role_ID__c);
            
            // handle invalid ocr's
            if (ocr == null) {
                psc.Contact_Role_ID__c = null;
                ocr = new OpportunityContactRole(
                    OpportunityId = opp.Id, 
                    ContactId = psc.Contact__c,
                    Role = psc.Role_Name__c);
            } 
            
            // create our soft credit
            SoftCredit sc = new SoftCredit(ocr);
            sc.partial = psc;
            sc.fullCredit = false;
            softCredits.add(sc);
            
            // track which ocr's have been used by removing them from the map
            if (ocr.Id != null)
                mapIdToOCR.remove(ocr.Id);
        }
        
        // now deal with any remaining OCR's that didn't have a PSC, but are soft credits
        for (OpportunityContactRole ocr : mapIdToOCR.values()) {
            if (ocr.Role != null && softCreditRoles.contains(ocr.Role) && !ocr.IsPrimary)
                softCredits.add(new SoftCredit(ocr));
        }
        
        // get the list of Soft Credit Roles to put in our picklist
        contactRoles = new List<SelectOption>();
        for (Schema.PicklistEntry pe : OpportunityContactRole.Role.getDescribe().getPicklistValues()) {
            if (pe.getValue() != UTIL_CustomSettingsFacade.getContactsSettings().npe01__Opportunity_Contact_Role_Default_role__c &&
                (softCreditRoles.contains(pe.getValue()) || softCreditRoles.contains(pe.getLabel()))) {
                contactRoles.add(new SelectOption(pe.getLabel(), pe.getValue()));
            }
        }
        
        // warn user if no soft credit roles identified
        if (softCreditRoles.isEmpty())
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.pscManageSoftCreditsNoRoles));
        
    }

    /*******************************************************************************************************
    * @description Verifies the user has Create/Edit/Delete permissions for Partial Soft Credits object
    * and both view and edit permission on all relevant fields.
    * @return true when the user has the appropriate access
    */
    private Boolean getCurrentUserHasAccess() {
        Boolean accessResult = false;

        SObjectType psc = Partial_Soft_Credit__c.getSObjectType();
        SObjectType ocr = OpportunityContactRole.getSObjectType();
        if (perms.canCreate(psc) && perms.canCreate(ocr) &&
            UTIL_Permissions.canDelete(Schema.SObjectType.Partial_Soft_Credit__c.getName(), false) &&
            UTIL_Permissions.canDelete(Schema.SObjectType.OpportunityContactRole.getName(), false)
        ) {
            Set<SObjectField> sObjectPSCFieldsRead = new Set<SObjectField>{
                Partial_Soft_Credit__c.fields.Amount__c,
                Partial_Soft_Credit__c.fields.Contact_Name__c,
                Partial_Soft_Credit__c.fields.Contact_Role_ID__c,
                Partial_Soft_Credit__c.fields.Role_Name__c
            };
            Set<SObjectField> sObjectPSCFieldsModify = sObjectPSCFieldsRead.clone();
            sObjectPSCFieldsModify.remove(Partial_Soft_Credit__c.fields.Contact_Name__c);

            Set<SObjectField> sObjectOCRFieldsRead = new Set<SobjectField>{
                OpportunityContactRole.fields.ContactId,
                OpportunityContactRole.fields.OpportunityId,
                OpportunityContactRole.fields.IsPrimary,
                OpportunityContactRole.fields.Role
            };
            Set<SObjectField> sObjectOCRFieldsModify = sObjectOCRFieldsRead.clone();
            sObjectOCRFieldsModify.remove(OpportunityContactRole.fields.OpportunityId);

            if (!(perms.canRead(psc, sObjectPSCFieldsRead) && perms.canUpdate(psc, sObjectPSCFieldsModify) &&
                  perms.canRead(ocr, sObjectOCRFieldsRead) && perms.canUpdate(ocr, sObjectOCRFieldsModify))
            ) {
                return accessResult;
            }
            accessResult = true;
        }

        return accessResult;
    }

    /** @description Removes a row from the page, and adds to the list for deletion once the user saves.*/
    public pageReference delRow() {
        //add to deletion list if the soft credit has an id
        if (softCredits[rowNumber].partial.id!=null)
            listSoftCreditsForDelete.add(softCredits[rowNumber].partial);
        if (softCredits[rowNumber].contactRole.Id != null && !softCredits[rowNumber].contactRole.IsPrimary)
            listSoftCreditsForDelete.add(softCredits[rowNumber].contactRole);
        softCredits.remove(rowNumber);

        return null;
    }

    /*******************************************************************************************************
    * @description actionMethod to save the soft credits on the page
    * @return the Opportunity's detail page if success, or null if any error encountered.
    */ 
    public PageReference save() {
        if (!hasAccess) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.commonAccessErrorMessage));
            return null;
        }

        Map<Id, String> donors = new Map<Id, String>(); // Contact Id, Contact Name
        for (OpportunityContactRole ocr : [SELECT Id, ContactId, Contact.Name FROM OpportunityContactRole WHERE OpportunityId = :opp.Id AND IsPrimary = true]) {
            donors.put(ocr.ContactId, ocr.Contact.Name);
        }

        List<SObject> toDelete = listSoftCreditsForDelete;
        List<OpportunityContactRole> toUpsertContactRoles = new List<OpportunityContactRole>();
        List<Partial_Soft_Credit__c> toUpsertPartialCredits = new List<Partial_Soft_Credit__c>();
        List<SoftCredit> upsertedSoftCredits = new List<SoftCredit>();
        Map<Integer, OpportunityContactRole> rollbackContactRole = new Map<Integer, OpportunityContactRole>();
        Map<Integer, Partial_Soft_Credit__c> rollbackPartialSoftCredit = new Map<Integer, Partial_Soft_Credit__c>();        

        for (Integer i = 0, size = softCredits.size(); i < size; i++) {
            SoftCredit sc = softCredits[i];

            rollbackContactRole.put(i, sc.contactRole == null ? null : sc.contactRole.clone(true, true, true, true));
            rollbackPartialSoftCredit.put(i, sc.partial == null ? null : sc.partial.clone(true, true, true, true));

            if (sc.contactRole.ContactId != null) {
                if (donors.containsKey(sc.contactRole.ContactId)) {
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 
                        string.Format(Label.pscManageSoftCreditsInvalidContact, new String[]{donors.get(sc.contactRole.ContactId)})));
                    return null;

                } else if (sc.partial.Amount__c == null) {
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.pscManageSoftCreditsAmountMissing));
                    return null;

                } else if (sc.contactRole.Role == null) {
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.pscManageSoftCreditsRoleMissing));
                    return null;
                }
                
                if (sc.fullCredit || sc.partial.Amount__c == opp.Amount) {
                    sc.fullCredit = true; // to prevent the full amount case from creating a new psc!
                    if (sc.partial.Id != null) {
                        toDelete.add(sc.partial);
                    }
                    toUpsertContactRoles.add(sc.contactRole);

                } else {
                    if (sc.partial.Contact__c == null) {
                        sc.partial.Contact__c = sc.contactRole.ContactId;

                    } else if (sc.partial.Contact__c != sc.contactRole.ContactId) {
                        toDelete.add(sc.partial);
                        sc.partial = new Partial_Soft_Credit__c(Contact__c = sc.contactRole.ContactId, Amount__c = sc.partial.Amount__c);
                    }

                    if (sc.partial.Opportunity__c == null) {
                        sc.partial.Opportunity__c = sc.contactRole.OpportunityId;
                    }
                    sc.partial.Role_Name__c = sc.contactRole.Role;
                    toUpsertContactRoles.add(sc.contactRole);
                    upsertedSoftCredits.add(sc);
                }

            } else {
                 // Because we turn off UI requirement validation on the contact 
                 // we need to check on the server side to make sure the contact is populated
                if (sc.contactRole.ContactId == null) {
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, System.Label.pscManageSoftCreditsContactMissing));
                    return null;
                }

                if (sc.partial.Id != null) {
                    toDelete.add(sc.partial);
                }
                if (sc.contactRole.Id != null && !sc.contactRole.IsPrimary) {
                    toDelete.add(sc.contactRole);
                }
            }
        }

        if (!allowTooManySoftCredits && getTotalSoftCreditAmount() > opp.Amount) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.pscManageSoftCreditsReconcileFail));
            return null;
        }
        
        Savepoint sp = Database.setSavepoint(); 
        try {
            delete toDelete;

            upsert toUpsertContactRoles;

            for (SoftCredit sc : upsertedSoftCredits) {
                // full credits should not create a PSC
                if (sc.fullCredit) {
                    continue;
                }

                sc.partial.Contact_Role_ID__c = sc.contactRole.Id;
                if (!isAmount) {
                    sc.partial.Amount__c = convertPercentageToAmount(sc.partial.Amount__c);
                }

                toUpsertPartialCredits.add(sc.partial);
            }
            upsert toUpsertPartialCredits;
            
            if (!isAmount) {
                for (SoftCredit sc : upsertedSoftCredits) {
                    sc.partial.Amount__c = convertPercentageToAmount(sc.partial.Amount__c);
                }
            }
        
            PageReference pageRef = new PageReference('/'+opp.Id);
            pageRef.setRedirect(true);
            pageRef.getParameters().put('t',''+(System.currentTimeMillis()));
            return pageRef;

        } catch (Exception ex) {
            Database.rollback(sp);

            // rollback Opportunity Contact Role and Partial Soft Credits
            for (Integer i = 0, size = softCredits.size(); i < size; i++) {
                softCredits[i].contactRole = rollbackContactRole.get(i);
                softCredits[i].partial = rollbackPartialSoftCredit.get(i);
            }

            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }
    
    /*******************************************************************************************************
    * @description the Id of the Primary Contact or Account, depending on whether its an org gift or not.
    */ 
    public string PrimaryContactId {
        get {
            if (opp.npe01__Is_Opp_From_Individual__c == 'true' && opp.Primary_Contact__c != null) {
                return opp.Primary_Contact__c;
            } else {
                return opp.AccountId;
            }
        } private set;
    }
    
    /*******************************************************************************************************
    * @description the Name of the Primary Contact or Account, depending on whether its an org gift or not.
    */ 
    public string PrimaryContactName {
        get {
            if (opp.npe01__Is_Opp_From_Individual__c == 'true' && opp.Primary_Contact__c != null) {
                return opp.Primary_Contact__r.Name;
            } else {
                return opp.Account.Name;
            }
        } private set;
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
                sc.partial.Amount__c = isAmount ? opp.Amount : 100;
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
                sc.partial.Amount__c = isAmount ? opp.Amount : 100;
            } else {
                sc.partial.Amount__c = isAmount ? convertPercentageToAmount(sc.partial.Amount__c) : convertAmountToPercentage(sc.partial.Amount__c);
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
    private Double getTotalSoftCreditAmount() {
        Double total = 0;
        for (SoftCredit sc : softCredits) {
            if (sc.contactRole.ContactId != null) {
                total += sc.partial.Amount__c != null ? sc.partial.Amount__c : 0;
            }
        }
        return isAmount ? total : (total/100) * opp.Amount;
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

    /**
     * @description Return the currency symbol appropriate for the current
     * user/org/record.  If the org is multi currency enabled, it will use the
     * currency iso code from the related record.  If the org is not multi
     * currency enabled, it will return the symbol for the currency of the org,
     * or the currency iso code if no symbol is known.
     *
     * @return String A currency symbol or currency ISO code
     */
    public String getCurrencySymbol() {
        if (currencySymbol == null) {
            currencySymbol = UTIL_Currency.getInstance().getCurrencySymbol(opp.Id);
        }
        return currencySymbol;
    }

}
