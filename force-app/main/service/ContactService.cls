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
* @description Contact Service class in NPSP.
*/
public with sharing class ContactService {

    @TestVisible
    private AddressService addressServiceInstance {
        get {
            if (addressServiceInstance == null) {
                addressServiceInstance = new AddressService();
            }
            return addressServiceInstance;
        }
        set;
    }


    @TestVisible
    private HouseholdService householdService {
        get {
            if (householdService == null) {
                householdService = new HouseholdService();
            }
            return householdService;
        }
        set;
    }

    public void moveOppsToNewContactAccount(Map<Id, Id> newAcctIdByContactId, Map<Id, Id> oldAcctIdByContactId) {
       moveOppsToContactAccount(newAcctIdByContactId, oldAcctIdByContactId);
    }

    /*******************************************************************************************************
    * @description Moves all opps for the Primary OCR provided contacts to their new account.  Note that it
    * is the caller's responsibility to decide whether moving opps is appropriate for the involved accounts.
    * @param newHouseholdIdByContactId a map of Contact Id to Account Id, for the Accounts to move opps to
    * @param oldHouseholdIdByContactId a map of Contact Id to Account Id, for the Accounts to move opps from
    */
    private static void moveOppsToContactAccount(Map<Id,Id> newHouseholdIdByContactId, Map<Id,Id>
            oldHouseholdIdByContactId) {
        if (newHouseholdIdByContactId.isEmpty()) {
            return;
        }

        List<Opportunity> opportunities = new List<Opportunity>();
        Set<Id> oppIds = new Set<Id>();

        for (OpportunityContactRole role : [
                SELECT ContactId, OpportunityId, Opportunity.AccountId
                FROM OpportunityContactRole
                WHERE IsPrimary = TRUE
                AND Opportunity.AccountId IN :oldHouseholdIdByContactId.values()
                AND ContactId IN :newHouseholdIdByContactId.keySet()
        ]) {
            Boolean shouldMoveOpp = oldHouseholdIdByContactId.get(role.ContactId) == role.Opportunity.AccountId
                    && oppIds.add(role.OpportunityId);

            if (shouldMoveOpp) {
                opportunities.add(new Opportunity(
                        Id = role.OpportunityId,
                        AccountId = newHouseholdIdByContactId.get(role.ContactId)));
            }
        }

        if (!opportunities.isEmpty()) {
            UTIL_DMLService.updateRecords(opportunities);
        }
    }

    public List<Id> moveOppsForContactsSwitchingAccounts(Contacts contacts) {
        Map<Id, Id> oldHouseholdIdByContactId = new Map<Id, Id>();
        Map<Id, Id> newHouseholdIdByContactId = new Map<Id, Id>();

        List<Id> householdIdsToUpdate = new List<Id>();
        for (Contact contactRecord : (List<Contact>) contacts.getRecords()) {
            Contact oldContact = contacts.oldVersionOf(contactRecord);

            if (contactRecord.AccountId != oldContact.AccountId) {
                addHouseholdIds(householdIdsToUpdate, newHouseholdIdByContactId, contactRecord);
                addHouseholdIds(householdIdsToUpdate, oldHouseholdIdByContactId, oldContact);

            }
        }

        moveOppsToContactAccount(newHouseholdIdByContactId,
                oldHouseholdIdByContactId);
        return householdIdsToUpdate;
    }

    /**
     * addHouseholdIds Adds the account ids from all of the contacts belonging to a household
     * @param  householdIds           The collection of householdIds to add the account ids to
     * @param  householdIdByContactId The map of household by their id.
     * @param  contactRecord          The contact to extract the id from.
     */
    private static void addHouseholdIds(List<Id> householdIds, Map<Id, Id>
            householdIdByContactId, Contact contactRecord) {
        if (contactRecord.npe01__Organization_Type__c == CAO_Constants.HH_ACCOUNT_TYPE) {
            householdIds.add(contactRecord.AccountId);
            householdIdByContactId.put(contactRecord.Id, contactRecord.AccountId);
        }
    }

}