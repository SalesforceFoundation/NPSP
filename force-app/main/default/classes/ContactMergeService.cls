/*
    Copyright (c) 2009, Salesforce.org
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
* @date 2011 (2.x)
* @description Handles the heavy lifting of merging contacts. It can be called from the VisualForce page for 
* contact merge, or elsewhere.
* @group ContactMerge
* @group-content ../../ApexDocContent/ContactMerge.htm
*/
public class ContactMergeService {

    @TestVisible
    private ContactMergeSelector contactMergeSelector {
        get {
            if (contactMergeSelector == null) {
                contactMergeSelector = new ContactMergeSelector();
            }
            return contactMergeSelector;
        }
        set;
    }

    @TestVisible
    private OrgConfig orgConfig {
        get {
            if (orgConfig == null) {
                orgConfig = new OrgConfig();
            }
            return orgConfig;
        }
        set;
    }
    
    /*******************************************************************************************************
    * @description Min number of contacts that can be merged.
    */
    public final Integer MERGE_MINIMUM = 2;
    
    /*******************************************************************************************************
    * @description Max number of contacts that can be merged.
    */
    public final Integer MERGE_LIMIT = 3;
    
    /*******************************************************************************************************
    * @description Contact for the winning record.
    */
    public Contact winner {get; set;}
    
    /*******************************************************************************************************
    * @description List for the losing records.
    */
    public List<Contact> losers {get; set;}
    
    /*******************************************************************************************************
    * @description Exception raised by the contact merge process.
    */
    public class ConMergeException extends Exception {} 
        
    /*******************************************************************************************************
    * @description Merges the winner and losers.
    * @param winner The winner record.
    * @param losers The loser records.
    * @return Boolean Whether the merge was successful.
    */
    public Boolean mergeContacts(Contact winningContact, List<Contact> losers) {
        boolean successfulMerge = false;

        List<Account> winnerAccount = new List<Account>();
        Set<Id> loserAccountIds = new Set<Id>();
        List<Account> loserAccounts = new List<Account>();
        List<Account> loserAccountsToBeMerged = new List<Account>();
        List<Account> loserAccountsToBeDeleted = new List<Account>();
    
        Id winningAccountId = null;
        Boolean winnerAccountIsOneToOne = false;
        Contact winner = contactMergeSelector.getContactsWithAccountFields(new List<Contact>{winningContact})[0];

        // detect PersonAccounts
        Boolean isPersonAccountsEnabled = orgConfig.isPersonAccountsEnabled();
        //get winner contact Account
        if (winner.AccountId!=null){
	        winnerAccount = contactMergeSelector.getAccountsFor(new Set<Id>{winner.AccountId});
        }
            
        if (winnerAccount.size()>0) {
            winningAccountId = winnerAccount[0].Id;
            
            if(winnerAccount[0].npe01__SYSTEM_AccountType__c==CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE){
                winnerAccountIsOneToOne = true;
            }
            
            if (isPersonAccountsEnabled && (ID)winnerAccount[0].get('PersonContactId') != null)
                throw new ConMergeException(label.conMergeErrNoPersonAccounts);
        }

        losers = contactMergeSelector.getContactsWithAccountFields(new List<Contact>(losers));

        for (Contact thisloserContact : losers) {
            if (isPersonAccountsEnabled && (boolean)thisloserContact.get('isPersonAccount'))
                throw new ConMergeException(label.conMergeErrNoPersonAccounts);
                
            //don't try to merge null Accounts or Accounts that are the same as the winner's Account
            if (thisloserContact.id!=null && thisloserContact.AccountId!=winner.AccountId) {
                loserAccountIds.add(thisloserContact.AccountId);
            }
        }
        //UTIL_Debug.debug('losers: ' + loserAccountIds);
        //UTIL_Debug.debug('winneraccountid: ' + winner.AccountId);
        
        //get loser contact Accounts that should be merged out.  This includes
        // One2One accounts and Solo Household Accounts
        loserAccountsToBeMerged = contactMergeSelector.getHouseholdAndOrgAccountsFor(loserAccountIds);
        //one-to-one contacts each have an Account, so when merging Contacts we have to merge Accounts as well
        //we merge the Accounts first, if there are any one-to-one Accounts or Solo Household Accounts in the mix
        if (loserAccountsToBeMerged.size() > 0) {
            merge winnerAccount[0] loserAccountsToBeMerged;
            updateWinnerAccountSustainerAfterMerge(winnerAccount[0]);
        }

        //merge the contacts
        
        //there is a Contact delete trigger that deletes the one-to-one Account of a Contact after it is deleted
        //merge deletes the losing Contacts, so their Accounts get deleted, which causes errors
        //to get around this, we detach the Contacts for their Accounts before we merge
        
        //create new contacts for updating as the SOSL returned contacts have read-only fields on them
        Contact winnerMakePrivate = new Contact();
        if(winnerAccountIsOneToOne){            
            winnerMakePrivate = new Contact(Id = winner.id,AccountId = null,npe01__Private__c=true);
        } else {
            winnerMakePrivate = new Contact(Id = winner.id);
        }
        List<Contact> losersMakePrivate = new List<Contact>();
        
        for(Contact contactForUpdate : losers){
        	// only do this for One2One losers
        	if (contactForUpdate.Account.npe01__SYSTEM_AccountType__c == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE) {       
                Contact loserMakePrivate = new Contact(id=contactForUpdate.id,accountId=null,npe01__Private__c=true);
                losersMakePrivate.add(loserMakePrivate);
        	}
        }
            
        //set the account to null and mark private so that trigger won't reset the Account
        if (winningAccountId!=null && winnerAccountIsOneToOne){
            UTIL_DMLService.updateRecord(winnerMakePrivate);
        }
        
        if(losersMakePrivate.size()>0){
            UTIL_DMLService.updateRecords(losersMakePrivate);
        }

        merge winnerMakePrivate losers;

        //set the contact Account Id back to the winning Account Id
        if (winnerAccountIsOneToOne){
            winnerMakePrivate.AccountId = winningAccountId;
            winnerMakePrivate.npe01__Private__c = false;
            UTIL_DMLService.updateRecord(winnerMakePrivate);
        }

        UTIL_Debug.debug('loserAccountsToBeDeleted: ' + loserAccountsToBeDeleted);
        if (loserAccountsToBeDeleted.size() > 0) {
            delete loserAccountsToBeDeleted;
        }

        successfulMerge = true;
        return successfulMerge;
    }

    private void updateWinnerAccountSustainerAfterMerge(Account winnerAccount) {
        DescribeFieldResult sustainerFieldDescribeResult = Account.Sustainer__c.getDescribe();

        if (UTIL_Permissions.canRead(sustainerFieldDescribeResult, false)
            && UTIL_Permissions.canUpdate(sustainerFieldDescribeResult, false)
        ) {
            List<Account> winnerWithSustainerChanged = new RD2_SustainerEvaluationService()
            .withAccounts(new List<Account>{winnerAccount})
            .getAccountsWithSustainerChanged();

            if (winnerWithSustainerChanged.size() != 0) {
                RD2_SustainerEvaluationService.setSustainerUpdateEnabled(true);
                UTIL_DMLService.updateRecords(winnerWithSustainerChanged);
                RD2_SustainerEvaluationService.setSustainerUpdateEnabled(false);
            }
        }
    }
}