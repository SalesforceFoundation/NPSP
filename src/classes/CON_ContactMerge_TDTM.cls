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
* @author Salesforce.org
* @date 2015
*
* @group ContactMerge
*
* @description Trigger Handler on Contact that handles detecting when a Contact Merge 
* has completed, in order to fixup an assortment of affected information.
*/
public class CON_ContactMerge_TDTM extends TDTM_Runnable {
    @TestVisible
    private static RLLP_OppRollup oppRollup = new RLLP_OppRollup();
    
    /*******************************************************************************************************
    * @description Trigger Handler on Contact that handles detecting when an Contact Merge 
    * has completed, in order to fixup an assortment of affected information.
    * @param listNew the list of Contacts from trigger new. 
    * @param listOld the list of Contacts from trigger old. 
    * @param triggerAction which trigger event (BeforeInsert, AfterInsert, etc.). 
    * @param objResult the describe for Contacts 
    * @return dmlWrapper.  always null.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> listNew, List<SObject> listOld, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        
        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();    

        if (triggerAction == TDTM_Runnable.Action.AfterDelete) {
            List<String> mergeKeys = new List<String>();
        
            for (SObject so : listOld) {
                Contact con = (Contact)so;
                if (con != null && con.MasterRecordId != null)
                    mergeKeys.add(mergeKey(con.Id, con.AccountId, con.MasterRecordId));
            }
            
            if (mergeKeys.size() > 0)
                handleContactMergeFixupsFuture(mergeKeys);
        }        
        
        return dmlWrapper; 
    }
    
    /*******************************************************************************************************
    * @description returns a unique key for a tracking a losing Contact, their account, and the winning Contact.
    * @param contactIdLoser The losing Contact's Id
    * @param accountIdLoser The losing Contact's Account Id
    * @param contactIdWinner The winning Contact's Id
    * @return string
    ********************************************************************************************************/
    private static string mergeKey(string contactIdLoser, string accountIdLoser, string contactIdWinner) {
        return (contactIdLoser + ':' + accountIdLoser + ':' + contactIdWinner);
    }
    
    /*******************************************************************************************************
    * @description returns the object Id at the specified index of a mergeKey
    * @param mergeKey The mergeKey to extract an Id from
    * @param index The index of which Id to return.  values should be 0 - contactIdLoser, 1 - accountIdLower, 
    * 2 - contactIdWinner
    * @return Id
    ********************************************************************************************************/
    private static string idFromMergeKey(string mergeKey, integer index) {
        if (mergeKey == null || index < 0 || index > 2)
            return null;
        List<String> listId = mergeKey.split(':');
        string strId = listId[index];
        if (strId == 'null') strId = null;
        return strId;
    }

    /*******************************************************************************************************
    * @description After a Contact Merge, call this Future routine to perform assorted fixups that need to
    * occur which include:
    *   - update the Account name and greetings 
    *   - move Opps to the Winner's Account 
    *   - recalculate Household Soft Credit OCRs 
    *   - recalculate Opportunity Rollups
    *
    * @param mergeKeys The list of mergeKeys that provide contactIdLoser, accountIdLoser, and contactIdWinner
    * @return null
    ********************************************************************************************************/
    @Future
    private static void handleContactMergeFixupsFuture(List<String> mergeKeys) {
        List<String> losingContactIds = new List<String>();
        List<String> losersAccountIds = new List<String>();
        List<String> winningContactIds = new List<String>();
        extractIds(losingContactIds, losersAccountIds, winningContactIds, mergeKeys);

        List<Contact> winningContacts = getContacts(winningContactIds);
        Map<Id,Id> winnersAcctIdByConId = new Map<Id,Id>();
        Map<Id,Id> losersAcctIdByConId = new Map<Id,Id>();
        List<Id> hhAcctIds = new List<Id>();
        extractIds(hhAcctIds, winnersAcctIdByConId, winningContacts);
        extractIds(hhAcctIds, losersAcctIdByConId, losersAccountIds, winningContactIds);

        cleanupAccounts(hhAcctIds, winnersAcctIdByConId, losersAcctIdByConId);
        cleanupContacts(winningContactIds, winningContacts);
    }

    /*******************************************************************************************************
    * @description Extract the ids from the winning contacts relevant to the collections provied
    *
    * @param hhAcctIds The collection of account Ids from the winning contact if they belong to a household
    * @param winnersAcctIdByConId The collection of winning contact's account Ids by the contact's Id
    * if they belong to any type of individual account
    * @param winningContacts the collection of contacts to extract the ids from
    ********************************************************************************************************/
    private static void extractIds(List<Id> hhAcctIds, Map<Id, Id> winnersAcctIdByConId, List<Contact> winningContacts) {
        String winnersAcctType;

        for (Contact winningContact : winningContacts) {
            winnersAcctType = winningContact.Account.npe01__SYSTEM_AccountType__c;

            if (isHousehold(winnersAcctType)) {
               hhAcctIds.add(winningContact.AccountId);
            }

            if (isAnyIndividual(winnersAcctType)) {
                winnersAcctIdByConId.put(winningContact.Id, winningContact.AccountId);
            }
        }
    }

    /*******************************************************************************************************
    * @description Extract the ids from the losers accounts and their new winning contactIds relevant
    * to the collections provied
    *
    * @param hhAcctIds The collection of account Ids from the losing contacts account if they belonged
    * to a household
    * @param losersAcctIdByConId The collection of loser's contact's account Ids by the winning contact's Id
    * if the losing contact belonged to any type of individual account
    * @param losersAccountIds the colleciton of the losing contacts account ids
    * @param winningContactIds the collection of winning contact ids
    ********************************************************************************************************/
    private static void extractIds(List<Id> hhAcctIds, Map<Id, Id> losersAcctIdByConId, List<Id> losersAccountIds, List<Id> winningContactIds) {
        Map<Id, Account> losersAccountById = new Map<Id, Account>(getAccounts(losersAccountIds));
        String losersAcctType;

        for (integer i = 0; i < losersAccountIds.size(); i++) {
            if (losersAccountIds[i] != null) {
                Account losersAccount = losersAccountById.get(losersAccountIds[i]);
                losersAcctType = losersAccount.npe01__SYSTEM_AccountType__c;

                if (losersAccount == null) {
                    continue;
                }

                if (isHousehold(losersAcctType)) {
                    hhAcctIds.add(losersAccount.Id);
                }

                if (isAnyIndividual(losersAcctType)) {
                    losersAcctIdByConId.put(winningContactIds[i], losersAccountIds[i]);
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Extract the ids from the list of merge keys provided.
    *
    * @param losingContactIds The collection of Ids from the losing contacts
    * @param losersAccountIds The collection of account ids the losing contacts belonged to
    * @param winningContactIds the collection of winning contact ids
    * @param mergeKeys A list of merged Ids, each merge key is expected to have an id for each collection
    ********************************************************************************************************/
    private static void extractIds(List<Id> losingContactIds, List<Id> losersAccountIds, List<Id> winningContactIds, List<String> mergeKeys) {
        // extract out our Contact and Account Id's from the mergeKeys
        for (String mergeKey : mergeKeys) {
            losingContactIds.add(idFromMergeKey(mergeKey, 0));
            losersAccountIds.add(idFromMergeKey(mergeKey, 1));
            winningContactIds.add(idFromMergeKey(mergeKey, 2));
        }
    }

    /*******************************************************************************************************
    * @description Determines if the account type provided matches the Household Account Type
    *
    * @param acctType The account type to compare
    * @return Boolean true if the string passed in matches the Household Account Type
    ********************************************************************************************************/
    private static Boolean isHousehold(String acctType) {
        return acctType == CAO_Constants.HH_ACCOUNT_TYPE;
    }

    /*******************************************************************************************************
    * @description Determines if the account type provided matches any of the Individual Account Types
    *
    * @param acctType The account type to compare
    * @return Boolean true if the string passed in matches any of the Individual Account Types
    ********************************************************************************************************/
    private static Boolean isAnyIndividual(String acctType) {
        return isHousehold(acctType)
            || acctType == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE
            || acctType == CAO_Constants.BUCKET_ORGANIZATION_TYPE;
    }

    /*******************************************************************************************************
    * @description Performs rollups, affiliation and relationship cleanup on the winning contacts
    *
    * @param winningContactIds the collection of winning contact ids
    * @param winningContacts the collection of winning contacts
    ********************************************************************************************************/
    private static void cleanupContacts(List<Id> winningContactIds, List<Contact> winningContacts) {
        // recalc Contact Rollups
        if (CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
            CRLP_RollupQueueable.runRollupsForIds(winningContactIds);
        } else {
            oppRollup.rollupContacts(new Map<Id, Contact>(winningContacts));
        }

        // fixup duplicate Affiliations & Primary Affiliation
        AFFL_Affiliations_TDTM.cleanupContactAffiliations(winningContacts);
        // remove duplicate Relationships
        REL_Relationships_TDTM.cleanupContactRelationships(winningContacts);
    }

    /*******************************************************************************************************
    * @description Performs household naming, moves opportunities from the losers accounts to the winners
    * accounts, recreates Household Soft Credits and performs rollups on all Accounts
    *
    * @param hhAcctIds the collection of account ids that are the household type
    * @param winnersAcctIdByConId the collection of winning contact ids to their account ids
    * @param losersAcctIdByConId the collection of winning contact ids to the losing contacts account id
    ********************************************************************************************************/
    private static void cleanupAccounts(List<Id> hhAcctIds, Map<Id, Id> winnersAcctIdByConId, Map<Id, Id> losersAcctIdByConId) {
        // create a list of both Winning and Losing Accounts
        List<Id> accountIds = new List<Id>();
        accountIds.addAll(losersAcctIdByConId.values());
        accountIds.addAll(winnersAcctIdByConId.values());

        // if we have any winning Contacts in Household or 1:1 Accounts...
        if (accountIds.size() > 0) {    
            // refresh account naming
            ACCT_IndividualAccounts_TDTM.renameHHAccounts(hhAcctIds);

            // move any Contact Opps to winning Accounts
            ACCT_IndividualAccounts_TDTM.moveOppsToContactAccount(winnersAcctIdByConId, losersAcctIdByConId, null);

            // recreate Soft Credits 
            HH_OppContactRoles_TDTM.recreateHouseholdSoftCredits(accountIds);

            // recalc Account Rollups
            ACCT_IndividualAccounts_TDTM.rollupAccounts(accountIds);
        }
    }

    /*******************************************************************************************************
    * @description Uses the opp rollup util to build the query then modifies the query to include additional
    * fields necessary for processing merged contacts
    *
    * @return List<Contact> the list of contacts that match the ids provided
    ********************************************************************************************************/
    private static List<Contact> getContacts(List<Id> contactIds) {
        // get the winning Contacts (with the fields we need)
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL(); 
        String query = oppRollupUtil.buildContactQuery();
        query = query.replace('from Contact', '');
        query += ', AccountId, Account.npe01__SYSTEM_AccountType__c, Primary_Affiliation__c FROM Contact WHERE Id IN :contactIds';
        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description Queries for the accounts and fields needed for processing
    *
    * @return List<Account> the list of accounts that match the ids provided
    ********************************************************************************************************/
    private static List<Account> getAccounts(List<Id> accountIds) {
        return [SELECT Id, npe01__SYSTEM_AccountType__c FROM Account WHERE Id IN :accountIds];
    }
}