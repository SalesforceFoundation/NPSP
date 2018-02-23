/*
    Copyright (c) 2014, Salesforce.org
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
* @date 2015
* @group Contacts
* @group-content ../../ApexDocContent/Contacts.htm
* @description Overrides the contact Delete button.
* Avoids leaving orphaned accounts or contacts unrecoverable from the recycle bin by providing an interstitial confirmation dialog
* for deleting the account instead of the contact if they are alone in their household or 1-1 account.
* Also cascade deletes a Contact's Opportunities, and provides validation if any are closed/won or attributed to an organization.
*/
public with sharing class CON_DeleteContactOverride_CTRL {
    /** @description Contact home page. */
    private static final String CONTACT_HOME = '/003/o';
    /** @description LEx navigation value to go back. */
    private static final String LEX_BACK = 'back';
    /** @description LEx navigation value to go to Contact Home. */
    private static final String LEX_HOME = 'home';

    /** @description The contact record the user is attempting to delete. */
    private Contact queryContact;
    /** @description The id of the contact's account. */
    private String accountId;
    /** @description The return URL. */
    @TestVisible
    private String retURL;
    /** @description The URL to be navigated to on Cancel. It is not provided every time (as it was the case for cancelUrl). */
    @TestVisible
    private String failRetUrl;
    /** @description for LEx and SF1 set navigation instructions for JS - navigate back if only del contact and not from contact */ 
    public String sforceNav {get; private set;}

    /** @description Boolean that is set to true if user theme is LEx or SF1 */
    @TestVisible 
    private Boolean sforceUser {
        get {
            return sforceUser = sforceUser == null 
                ? UserInfo.getUiThemeDisplayed().contains('Theme4')
                : sforceUser;
        }
        set;
    }

    /** @description Flag to tell the page which operation we're doing. */
    public Boolean shouldDeleteContactAlone {get;set;}
    /** @description Flag indicating if only this Contact should be deleted while leaving empty Account. */
    private Boolean isDeleteContactLeaveAccount = false;
    
    /** @description Boolean for disabling the account deletion button if there are errors preventing deletion. */
    public Boolean hasPageMessages {
        get {
            return ApexPages.hasMessages();
        }
        set;
    }

    /*******************************************************************************************************
    * @description Standard controller constructor. Queries for contact, verifies whether the contact or its
    * account should be deleted.
    */ 
    public CON_DeleteContactOverride_CTRL(ApexPages.StandardController stdController) {
        setNavigationParams(ApexPages.currentPage().getParameters());

        queryContact = [SELECT Id, Name, FirstName, LastName, AccountId, Account.Name, Account.npe01__SYSTEMIsIndividual__c FROM Contact WHERE Id = :stdController.getId()];

        shouldDeleteContactAlone = true;

        if (queryContact.AccountId != null && queryContact.Account.npe01__SYSTEMIsIndividual__c) {
            accountId = queryContact.AccountId;
            list<AggregateResult> contactsInHousehold = [SELECT COUNT(id) ct FROM Contact WHERE AccountId = :accountId GROUP BY AccountId HAVING COUNT(id) = 1];

            //This contact is alone in a system account, delete the system account and allow the cascading
            //delete to remove the contact
            if (contactsInHousehold.size() == 1 && contactsInHousehold[0].get('ct') == 1) {
                shouldDeleteContactAlone = false;

                String helpDeleteAccountInstead = String.format(Label.ConfirmDeleteAccount, new List<String>{queryContact.Name, queryContact.Account.Name});
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, helpDeleteAccountInstead));
            }
        }
    }

    /*******************************************************************************************************
    * @description Determines if the page is used in LEx or Classic.
    * Retrieves retUrl and failRetUrl values from the page params.
    * @return void
    */ 
    @TestVisible 
    private void setNavigationParams(Map<String, String> params) {
        // In LEx and SF1 the returl param name differs from classic
        String param = sforceUser ? 'vfRetURLInSFX' : 'retURL';
        retURL = params.get(param);

        //if we don't have a return URL, go back to Contacts home.
        if (String.isBlank(retURL)) {
            retURL = CONTACT_HOME;
        }

        failRetUrl = params.get('failRetURL');
    }

    /*******************************************************************************************************
    * @description Action method in Contact Delete Button override, handles deleting a contact or prompting
    * user to delete its account if it is a system account (1:1, individual, or household) and is the last 
    * contact in the account.
    * @return pageReference Redirects to the Contacts tab if the contact has been deleted, otherwise stays
    * on the page and displays error messages.
    */ 
    public PageReference processDelete() {
        try {
            return deleteContact();
        } catch (Exception ex){
            if (!hasPageMessages) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }
            return null;
        }
    }

    /*******************************************************************************************************
    * @description Deletes a contact, leaving empty Household Account, once the user has accepted to do so,
    * after adding cascade deletion records for related opportunities and recurring donations. 
    * Validates opportunities and adds error messages where appropriate.
    * @return pageReference Redirects to the Contacts tab if the contact has been deleted, otherwise stays
    * on the page and displays error messages.
    */ 
    public PageReference deleteContactOnly() {
        isDeleteContactLeaveAccount = true;

        try {
            return deleteContact();
        } catch (Exception ex) {
            isDeleteContactLeaveAccount = false;
            if (!hasPageMessages) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            }
            return null;
        }
    }

    /*******************************************************************************************************
    * @description Deletes a contact, after adding cascade delete Loader and Validator to load and checks the 
    * related opportunities, cases and recurring donations. Prevents the deletion if there are closed won 
    * opportunities and cases.
    * @return pageReference Redirects to the Contacts tab if the contact has been deleted, otherwise stays
    * on the page and displays error messages.
    */ 
    public PageReference deleteContact() {
        if (isDeleteContactOnly()) {

            ContactCascadeDelete cascadeDelete = new ContactCascadeDelete(queryContact);
            cascadeDelete.validate();
            cascadeDelete.deleteOpportunities();
            cascadeDelete.deleteRecurringDonations();
            
            delete queryContact;

            if (sforceUser) {
                sforceNav = retURL.contains(queryContact.Id) ? LEX_HOME : LEX_BACK;
                return null;
            } else {
                return getRedirect();
            }
        }
        return null;
    }

    /*******************************************************************************************************
    * @description Determines if only this Contact can be deleted.
    * @return Boolean
    */ 
    private Boolean isDeleteContactOnly() {
        return shouldDeleteContactAlone || isDeleteContactLeaveAccount;
    }

    /*******************************************************************************************************
    * @description Deletes contact's account once the user has accepted to do so. Adds cascade delete Loader
    * and Validator for validating that there are no related closed/won opportunities or cases associated with this
    * Account. Although the platform handles this validation, the error message returned in this custom page
    * wasn't friendly; the cascade deletion framework displays helpful errors with links to the offending records.
    * @return pageReference Redirects to the Contacts tab if the account has been deleted, otherwise stays
    * on the page and displays error messages.
    */ 
    public PageReference deleteAccount() {
        Account account =  [SELECT Id, Name FROM Account WHERE Id = :accountId];
        
        try {
            AccountCascadeDelete cascadeDelete = new AccountCascadeDelete(account);
            cascadeDelete.validate();

            delete account;
        } catch (Exception ex){
            if (!hasPageMessages)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }

        if (sforceUser) {
            sforceNav = LEX_HOME;
            return null;

        } else {
            //if we were returning to the account we just deleted, go back to contacts home
            if (retURL.contains(accountId.substring(0,15))) {
                retURL = CONTACT_HOME;
            }
            return getRedirect();
        }
    }

    /*******************************************************************************************************
    * @description Returns redirect PageReference based on failRetUrl or retUrl for Classic.
    * Returns a value to navigate back for LEx.
    * @return PageReference 
    */ 
    public PageReference onCancel() {
        if (sforceUser) {
            sforceNav = LEX_BACK;
            return null;

        } else {
            String url = String.isNotBlank(failRetUrl) ? failRetUrl : retURL;
            return getRedirect(url);
        }
    }

    /*******************************************************************************************************
    * @description Returns a redirect enabled PageReference for the return URL
    * @return PageReference The PageReference with redirect enabled.
    */ 
    private PageReference getRedirect() {
        return getRedirect(retUrl);
    }

    /*******************************************************************************************************
    * @description Returns a redirect enabled PageReference for a URL
    * @return PageReference The PageReference with redirect enabled.
    */ 
    private PageReference getRedirect(String url) {
        PageReference redirect = new PageReference(url);
        redirect.setRedirect(true);
        return redirect;
    }

    /*******************************************************************************************************
    * @description Class that retrieves and validates the children of the Contacts to delete.
    ********************************************************************************************************/
    class ContactCascadeDelete {

        private Contact contactToDelete;
        private List<Case> relatedCases;
        private List<Opportunity> relatedOpportunities;
        private List<npe03__Recurring_Donation__c> relatedRecurringDonations;

        /*******************************************************************************************************
        * @description Constructor.
        * Retrieves the Cases, Opportunities and Recurring Donations of the deleted Contacts. 
        * @param Contact The Contact to delete.
        ********************************************************************************************************/
        public ContactCascadeDelete(Contact contactToDelete) {
            this.contactToDelete = contactToDelete;

            relatedCases = [
                SELECT CaseNumber, ContactId
                FROM Case
                WHERE ContactId = :contactToDelete.Id
            ];
            relatedOpportunities = [
                SELECT Name, AccountId, Primary_Contact__c, Primary_Contact__r.AccountId, IsWon, IsClosed
                FROM Opportunity
                WHERE Primary_Contact__c = :contactToDelete.Id
            ];
            relatedRecurringDonations = [
                SELECT Name, npe03__Contact__c
                FROM npe03__Recurring_Donation__c
                WHERE npe03__Contact__c = :contactToDelete.Id
            ];
        }

        /*******************************************************************************************************
        * @description Validates the children of the Contacts.
        * @return void
        ********************************************************************************************************/
        public void validate() {
            CDL_CascadeDeleteLookups.Error error = new CDL_CascadeDeleteLookups.Error(
                (contactToDelete.Firstname != null ? contactToDelete.Firstname : '') + ' ' + contactToDelete.LastName);

            for (Opportunity currentOpportunity : relatedOpportunities) {
                if (currentOpportunity.IsClosed && currentOpportunity.IsWon) {
                    error.addChildError(Label.ClosedWonOpportunities, currentOpportunity.Id, currentOpportunity.Name);
                }
            }
            for (Opportunity currentOpportunity : relatedOpportunities) {
                if (currentOpportunity.AccountId != currentOpportunity.Primary_Contact__r.AccountId) {
                    error.addChildError(Label.OrganizationalOpportunities, currentOpportunity.Id, currentOpportunity.Name);
                }
            }
            for (Case currentCase : relatedCases) {
                error.addChildError(Case.SObjectType.getDescribe().getLabelPlural(), currentCase.Id, currentCase.CaseNumber);
            }

            String errorMessage = error.getMessage();
            if (String.isNotBlank(errorMessage)) {
                throw new CascadeDeleteException(errorMessage);
            }
        }

        /*******************************************************************************************************
        * @description Deletes the Contact Opportunities.
        * @return void
        ********************************************************************************************************/
        public void deleteOpportunities() {
            delete relatedOpportunities;
        }

        /*******************************************************************************************************
        * @description Deletes the Contact Recurring Donations.
        * @return void
        ********************************************************************************************************/
        public void deleteRecurringDonations() {
            delete relatedRecurringDonations;
        }
    }

    /*******************************************************************************************************
    * @description Class that retrieves and validates the children of the Account to delete
    ********************************************************************************************************/
    class AccountCascadeDelete {
        Account accountToDelete;
        private List<Case> relatedCases;
        private List<Opportunity> relatedOpportunities;

        /*******************************************************************************************************
        * @description AccountCascadeDelete Constructor.
        * @param Account The Account to delete.
        ********************************************************************************************************/
        public AccountCascadeDelete(Account accountToDelete) {
            this.accountToDelete = accountToDelete;

            relatedCases = [
                SELECT CaseNumber, AccountId
                FROM Case
                WHERE AccountId = :accountToDelete.Id
            ];
            relatedOpportunities = [
                SELECT Name, AccountId, IsWon, IsClosed
                FROM Opportunity
                WHERE AccountId = :accountToDelete.Id
            ];
        }

        /*******************************************************************************************************
        * @description Validates the children of the Account.
        * @return void.
        ********************************************************************************************************/
        public void validate() {
            CDL_CascadeDeleteLookups.Error error = new CDL_CascadeDeleteLookups.Error(accountToDelete.Name);

            for (Case currentCase : relatedCases) {
                error.addChildError(Case.SObjectType.getDescribe().getLabelPlural(), currentCase.Id, currentCase.CaseNumber);
            }
            for (Opportunity currentOpportunity : relatedOpportunities) {
                if (currentOpportunity.IsClosed && currentOpportunity.IsWon) {
                    error.addChildError(Label.ClosedWonOpportunities, currentOpportunity.Id, currentOpportunity.Name);
                }
            }

            String errorMessage = error.getMessage();
            if (String.isNotBlank(errorMessage)) {
                throw new CascadeDeleteException(errorMessage);
            }
        }
    }

    /*******************************************************************************************************
    * @description Account and Contact override Cascade Delete custom exception
    ********************************************************************************************************/
    class CascadeDeleteException extends Exception {}
}