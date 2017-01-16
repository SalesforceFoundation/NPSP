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
* @description Overrides the contact Delete button, to avoid removing the contact from the recycle bin 
*               if the deleted contact is the only member of their household.
*/
public with sharing class CON_DeleteContactOverride_CTRL {

    /** @description The contact id of the record to delete. */
    private final string conId;
    private string retURL;

    /*******************************************************************************************************
    * @description Standard controller constructor.
    */ 
    public CON_DeleteContactOverride_CTRL(ApexPages.StandardController stdController) {
        conId = stdController.getId();
        retURL = ApexPages.currentPage().getParameters().get('returl');
        
        //if we don't have a return URL, go back to Contacts home.
        if (string.isBlank(retURL)) {
            retURL = '/003/o';
        }
    }

    /*******************************************************************************************************
    * @description Action method in Contact Delete Button override, handles deleting a contact and
    * potentially its account if it is a system account (1:1, individual, or household) and is the last 
    * contact in the account.
    * @return pageReference Redirects to the Contacts tab.
    */ 
    public pageReference processDelete() {
        try {
            Contact queryContact = [SELECT Id, AccountId, Account.npe01__SYSTEMIsIndividual__c FROM Contact WHERE Id = :conId];
            string accId = queryContact.AccountId;
            boolean shouldDeleteContactAlone = true;

            if (queryContact.AccountId != null && queryContact.Account.npe01__SYSTEMIsIndividual__c) {
                list<AggregateResult> contactsInHousehold = [SELECT COUNT(id) ct FROM Contact WHERE AccountId = :accId GROUP BY AccountId HAVING COUNT(id) = 1];

                //This contact is alone in a system account, delete the system account and allow the cascading
                //delete to remove the contact
                if (contactsInHousehold.size() == 1 && contactsInHousehold[0].get('ct') == 1) {
                    shouldDeleteContactAlone = false;
                    Account accForDelete = new Account(id=accId);
                    
                    //add cascade to make prettier error message on contact delete page,
                    //but don't want to attempt under normal circumstances 
                    ACCT_CascadeDeleteLookups_TDTM.cascades.addAll(new List<UTIL_CascadeDeleteLookups_TDTM.Cascade>{
                        new UTIL_CascadeDeleteLookups_TDTM.Cascade('Opportunity', 'AccountId', new List<String>{'IsWon','IsClosed'}),
                        new UTIL_CascadeDeleteLookups_TDTM.Cascade('Case', 'AccountId')
                    });
                    
                    delete accForDelete;

                    //if we were returning to the account we just deleted, go back to contacts home
                    if (retURL.contains(accId.substring(0,15))) {
                        retURL = '/003/o';
                    }
                }
            }

            if (shouldDeleteContactAlone) {
                delete queryContact;
            }

            PageReference redirect = new PageReference(retURL);
            redirect.setRedirect(true);
            return redirect;
        } catch (Exception ex){
            ApexPages.addMessages(ex);
            return null;
        }
    }
}