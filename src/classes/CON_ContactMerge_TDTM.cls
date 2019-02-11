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

            for (SObject sObj : listOld) {
                Contact deletedContact = (Contact)sObj;
                if (skipContactMergeFixup(deletedContact)) {
                    continue;
                }

                mergeKeys.add(mergeKey(deletedContact.Id, deletedContact.AccountId, deletedContact.MasterRecordId));
            }

            handleContactMergeFixupsFuture(mergeKeys);
        }

        return dmlWrapper;
    }

    /*******************************************************************************************************
    * @description Determine if the record provided should be skipped.
    * @param record - the Contact to check if merge fixup is required.
    *
    * @return Boolean - true when contact merge fixup is not needed
    ********************************************************************************************************/
    private Boolean skipContactMergeFixup(Contact record) {
        return record == null || record.MasterRecordId == null;
    }

    /*******************************************************************************************************
    * @description returns a unique key for a tracking a losing Contact, their account, and the winning Contact.
    * @param contactIdLoser The losing Contact's Id
    * @param accountIdLoser The losing Contact's Account Id
    * @param contactIdWinner The winning Contact's Id
    * @return string
    ********************************************************************************************************/
    private String mergeKey(string contactIdLoser, string accountIdLoser, string contactIdWinner) {
        return (contactIdLoser + ':' + accountIdLoser + ':' + contactIdWinner);
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
        if (mergeKeys == null || mergeKeys.isEmpty()) {
            return;
        }
        ContactMergeProcessor mergeProcessor = new ContactMergeProcessor(mergeKeys);
        mergeProcessor.fixup();
    }

    /*******************************************************************************************************
    * @description Fixes records related to merged contacts
    ********************************************************************************************************/
    private class ContactMergeProcessor {
        private List<String> losingContactIds = new List<String>();
        private List<String> losersAccountIds = new List<String>();
        private List<String> winningContactIds = new List<String>();
        private Map<Id, Id> newAcctIdForOppsByWinningContactId = new Map<Id, Id>();
        private Map<Id, Id> oldAcctIdForOppsByWinningContactId = new Map<Id, Id>();
        private List<Id> householdAcctIds = new List<Id>();

        /*******************************************************************************************************************
        * @description Constructor
        * @param mergeKeys - the ids releveant to the merge process
        */
        private ContactMergeProcessor(List<String> mergeKeys) {
            splitMergeKeys(mergeKeys);
        }

        /*******************************************************************************************************************
        * @description Fixes records involved in the merge process
        */
        private void fixup() {
            List<Contact> winningContacts = getContacts(winningContactIds);

            setIds();
            setIds(winningContacts);
            fixupAccountData();
            fixupContactData(winningContacts);
        }

        /*******************************************************************************************************
        * @description Set the ids from the losing contacts accounts
        ********************************************************************************************************/
        private void setIds() {
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
                        householdAcctIds.add(losersAccount.Id);
                    }

                    if (isAnyIndividualType(losersAcctType)) {
                        oldAcctIdForOppsByWinningContactId.put(winningContactIds[i], losersAccountIds[i]);
                    }
                }
            }
        }

        /*******************************************************************************************************
        * @description Set the ids from the winning contacts provided
        *
        * @param winningContacts the collection of contacts to extract the ids from
        ********************************************************************************************************/
        private void setIds(List<Contact> winningContacts) {
            String winnersAcctType;

            for (Contact winningContact : winningContacts) {
                winnersAcctType = winningContact.Account.npe01__SYSTEM_AccountType__c;

                if (isHousehold(winnersAcctType)) {
                householdAcctIds.add(winningContact.AccountId);
                }

                if (isAnyIndividualType(winnersAcctType)) {
                    newAcctIdForOppsByWinningContactId.put(winningContact.Id, winningContact.AccountId);
                }
            }
        }

        /*******************************************************************************************************
        * @description Determines if the account type provided matches the Household Account Type
        *
        * @param acctType The account type to compare
        * @return Boolean true if the string passed in matches the Household Account Type
        ********************************************************************************************************/
        private Boolean isHousehold(String acctType) {
            return acctType == CAO_Constants.HH_ACCOUNT_TYPE;
        }

        /*******************************************************************************************************
        * @description Determines if the account type provided matches any of the Individual Account Types
        *
        * @param acctType The account type to compare
        * @return Boolean true if the string passed in matches any of the Individual Account Types
        ********************************************************************************************************/
        private Boolean isAnyIndividualType(String acctType) {
            return isHousehold(acctType)
                || acctType == CAO_Constants.ONE_TO_ONE_ORGANIZATION_TYPE
                || acctType == CAO_Constants.BUCKET_ORGANIZATION_TYPE;
        }

        /*******************************************************************************************************
        * @description Performs household naming, moves opportunities from the losers accounts to the winners
        * accounts, recreates Household Soft Credits and performs rollups on all Accounts
        *
        ********************************************************************************************************/
        private void fixupAccountData() {
            List<Id> accountIds = new List<Id>();
            accountIds.addAll(oldAcctIdForOppsByWinningContactId.values());
            accountIds.addAll(newAcctIdForOppsByWinningContactId.values());
            if (accountIds.isEmpty()) {
                return;
            }

            ACCT_IndividualAccounts_TDTM.renameHHAccounts(householdAcctIds);
            ACCT_IndividualAccounts_TDTM.moveOppsToContactAccount(newAcctIdForOppsByWinningContactId, oldAcctIdForOppsByWinningContactId, null);
            HH_OppContactRoles_TDTM.recreateHouseholdSoftCredits(accountIds);
            ACCT_IndividualAccounts_TDTM.rollupAccounts(accountIds);
        }

        /*******************************************************************************************************
        * @description Performs rollups, affiliation and relationship cleanup on the winning contacts
        *
        * @param winningContacts the collection of winning contacts
        ********************************************************************************************************/
        private void fixupContactData(List<Contact> winningContacts) {
            if (CRLP_Rollup_SVC.isCustomizableRollupEngineEnabled) {
                CRLP_RollupQueueable.runRollupsForIds(winningContactIds);

            } else {
                oppRollup.rollupContacts(new Map<Id, Contact>(winningContacts));
            }

            AFFL_Affiliations_TDTM.cleanupContactAffiliations(winningContacts);
            REL_Relationships_TDTM.cleanupContactRelationships(winningContacts);
        }

        /*******************************************************************************************************
        * @description Queries for the accounts and fields needed for processing
        *
        * @return List<Account> the list of accounts that match the ids provided
        ********************************************************************************************************/
        private List<Account> getAccounts(List<Id> accountIds) {
            return [SELECT Id, npe01__SYSTEM_AccountType__c FROM Account WHERE Id IN :accountIds];
        }

        /*******************************************************************************************************
        * @description Uses the opp rollup util to build the query then modifies the query to include additional
        * fields necessary for processing merged contacts
        *
        * @return List<Contact> the list of contacts that match the ids provided
        ********************************************************************************************************/
        private List<Contact> getContacts(List<Id> contactIds) {
            RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL(); 
            String query = oppRollupUtil.buildContactQuery();

            query = query.replace('from Contact', '');
            query += ', AccountId, Account.npe01__SYSTEM_AccountType__c, Primary_Affiliation__c FROM Contact WHERE Id IN :contactIds';
            return Database.query(query);
        }

        /*******************************************************************************************************
        * @description Splits the ids from the list of merge keys provided.
        *
        * @param mergeKeys A list of merged Ids, each merge key is expected to have an id for each collection
        ********************************************************************************************************/
        private void splitMergeKeys(List<String> mergeKeys) {
            for (String mergeKey : mergeKeys) {
                List<String> ids = mergeKey.split(':');
                if (ids == null || ids.size() < 3) {
                    continue;
                }

                losingContactIds.add(ids[0]);
                losersAccountIds.add(ids[1]);
                winningContactIds.add(ids[2]);
            }
        }
    }

}