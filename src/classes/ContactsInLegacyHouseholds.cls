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
* @description Domain class for Contacts that use the legacy Household__c object in NPSP.
*/
public inherited sharing class ContactsInLegacyHouseholds {

    private HouseholdSettings settings;
    private List<Contact> contactsInHouseholds;
    public ContactsInLegacyHouseholds(List<Contact> records, HouseholdSettings settings) {
        this.contactsInHouseholds = records;
        this.settings = settings;
    }

    public List<Contact> getRecords() {
        return this.contactsInHouseholds;
    }

    public void onAfterDelete() {
        Map<Id, Integer> householdCountMap = getHouseholdCountMap(getRecords());
        deleteEmptyHouseholds(getRecords(), householdCountMap);
        updateOldHouseholdNames(getRecords(), householdCountMap);
    }

    private Map<Id, Integer> getHouseholdCountMap(List<Contact> contacts) {
        Map<Id, Integer> householdCountMap = new Map<Id, Integer>();
        for (Contact con : contacts) {
            if (householdIdFor(con) != null)
                householdCountMap.put(householdIdFor(con), 0);
        }
        for (Contact con : getContactsWithHouseholdIds(householdCountMap)) {
            Integer lastCount = householdCountMap.get(householdIdFor(con));
            lastCount += 1;
            householdCountMap.put(householdIdFor(con), lastCount);
        }
        return householdCountMap;
    }

    private List<Contact> getContactsWithHouseholdIds(Map<Id, Integer> householdCountMap) {
        return [
                SELECT Id, npo02__Household__c
                FROM Contact
                WHERE npo02__Household__c IN :householdCountMap.keyset()
        ];
    }

    private void updateOldHouseholdNames(List<Contact> cons, Map<Id, Integer> householdCountMap) {
        List<Id> nonEmptyHouseholdIds = getNonEmptyHouseholdIds(cons, householdCountMap);
        if (nonEmptyHouseholdIds.size() > 0) {
            updateHouseholdNames(nonEmptyHouseholdIds);
        }
    }

    private void deleteEmptyHouseholds(List<Contact> cons, Map<Id, Integer> householdCountMap) {
        List<npo02__Household__c> emptyHouseholds = getEmptyHouseholds(cons, householdCountMap);
        delete emptyHouseholds;
    }

    private List<Id> getNonEmptyHouseholdIds(List<Contact> cons,
            Map<Id, Integer> householdCountMap) {
        List<id> householdIdsNeedingNameUpdates = new List<id>();
        for (Contact con : cons) {
            if (!householdIsEmpty(householdCountMap, con)) {
                householdIdsNeedingNameUpdates.add(householdIdFor(con));
            }
        }
        return householdIdsNeedingNameUpdates;
    }

    private List<npo02__Household__c> getEmptyHouseholds(List<Contact> cons,
            Map<Id, Integer> householdCountMap
    ) {
        List<npo02__Household__c> emptyHouseholds = new List<SObject>();
        for (Contact con : cons) {
            if (householdIsEmpty(householdCountMap, con)) {
                emptyHouseholds.add(new npo02__Household__c(Id = householdIdFor(con)));
            }
        }
        return emptyHouseholds;
    }

    private Boolean householdIsEmpty(Map<Id, Integer> householdCountMap, Contact con) {
        return householdCountMap.get(householdIdFor(con)) < 1;
    }

    private Id householdIdFor(Contact con) {
        return con.npo02__Household__c;
    }

    private void updateHouseholdNames(List<Id> contactsNeedingHouseholdNamesUpdated) {
        if (isFutureEligible()) {
            HH_HouseholdNaming.updateHouseholdNamesAsynchronously(contactsNeedingHouseholdNamesUpdated);
        } else {
            HH_HouseholdNaming hn = new HH_HouseholdNaming();
            hn.updateHouseholdNameAndMemberCount(contactsNeedingHouseholdNamesUpdated);
        }
    }

    private Boolean isFutureEligible() {
        return settings.isAsyncEnabled()
                && !System.isFuture() && !System.isBatch();
    }
}