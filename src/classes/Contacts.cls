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
* @description Domain class for Contacts in NPSP.
*/
public inherited sharing class Contacts extends fflib_SObjects {

    private HouseholdSettings settings;
    private Map<Id, Contact> oldMap;

    public Contacts(List<Contact> records) {
        this(records, null, null);
    }

    public Contacts(List<Contact> records, List<Contact> oldList) {
        this(records, oldList, null);
    }

    @TestVisible
    private Contacts(List<Contact> records, List<Contact> oldList, HouseholdSettings
            settings) {
        super(records, Contact.SObjectType);
        this.oldMap = oldList != null ?
                new Map<Id, Contact>(oldList) : new Map<Id, Contact>();
        this.settings = settings == null ? new HouseholdSettings() : settings;
    }

    public void onBeforeInsert() {
        synchronizeNamingExclusionsFieldsBeforeInsert();
    }

    public void onBeforeUpdate() {
        synchronizeNamingExclusionsFieldsBeforeUpdate();
    }

    public void onAfterInsert() {
        ContactsInLegacyHouseholds contactsInLegacyHouseholds =
                new ContactsInLegacyHouseholds(
                        getRecords(),
                        this.settings
                );
        contactsInLegacyHouseholds.onAfterInsert();
    }

    private Id householdIdFor(Contact con) {
        return con.npo02__Household__c;
    }

    private void synchronizeNamingExclusionsFieldsBeforeUpdate() {
        for (Contact con : (List<Contact>) getRecords()) {
            //first, copy values from checkboxes to the multiselect picklist if checkboxes have changed
            //then, copy from multiselect to checkboxes if multiselect has changed
            //if both have changed, prefers checkboxes
            if (shouldCopyNamingExclusionsFromCheckboxes(con)) {
                copyNamingExclusionsFromCheckboxes(con);
            } else if (shouldCopyNamingExclusionsFromMultiSelectPicklist(con)) {
                synchronizeNamingExclusionStringToCheckboxes(
                        new HouseholdNamingExclusionsString(namingExclusionsFor(con)), con);
            }
        }
    }

    private Boolean shouldCopyNamingExclusionsFromMultiSelectPicklist(Contact con) {
        HouseholdNamingExclusionsString consHouseholdNamingExclusions =
                new HouseholdNamingExclusionsString(namingExclusionsFor(con));
        return consHouseholdNamingExclusions.isNotEqualTo(
                namingExclusionsFor(oldVersionOf(con)));
    }

    private Boolean shouldCopyNamingExclusionsFromCheckboxes(Contact con) {
        return isExcludedFromHouseholdName(con) != isExcludedFromHouseholdName(oldVersionOf(con)) ||
                isExcludedFromInformalGreeting(con) != isExcludedFromInformalGreeting(oldVersionOf(con)) ||
                isExcludedFromFormalGreeting(con) != isExcludedFromFormalGreeting(oldVersionOf(con));
    }

    private Boolean isExcludedFromFormalGreeting(Contact con) {
        return con.Exclude_from_Household_Formal_Greeting__c;
    }

    private Boolean isExcludedFromInformalGreeting(Contact con) {
        return con.Exclude_from_Household_Informal_Greeting__c;
    }

    private Boolean isExcludedFromHouseholdName(Contact con) {
        return con.Exclude_from_Household_Name__c;
    }

    private void synchronizeNamingExclusionsFieldsBeforeInsert() {
        for (Contact con : (List<Contact>) getRecords()) {
            HouseholdNamingExclusionsString exclusions =
                    new HouseholdNamingExclusionsString(namingExclusionsFor(con));
            if (exclusions.hasNamingExclusions()) {
                synchronizeNamingExclusionStringToCheckboxes(exclusions, con);
            }
            if (hasExclusionCheckboxesChecked(con)) {
                copyNamingExclusionsFromCheckboxes(con);
            }
        }
    }

    private Boolean hasExclusionCheckboxesChecked(Contact con) {
        return isExcludedFromHouseholdName(con)
                || isExcludedFromInformalGreeting(con)
                || isExcludedFromFormalGreeting(con);
    }

    private void synchronizeNamingExclusionStringToCheckboxes(
            HouseholdNamingExclusionsString exclusions, Contact con) {
        con.Exclude_from_Household_Name__c = exclusions.isNameExcluded();
        con.Exclude_from_Household_Formal_Greeting__c = exclusions.isFormalGreetingExcluded();
        con.Exclude_from_Household_Informal_Greeting__c = exclusions.isInformalGreetingExcluded();
    }

    private String namingExclusionsFor(Contact con) {
        return con.npo02__Naming_Exclusions__c;
    }

    /*******************************************************************************************************
    * @description Copies the values from the naming exclusions checkboxes to the multiselect picklist.
    ********************************************************************************************************/
    public void copyNamingExclusionsFromCheckboxes() {
        for (SObject sobj : getRecords()) {
            Contact con = (Contact) sobj;
            copyNamingExclusionsFromCheckboxes(con);
        }
    }

    private void copyNamingExclusionsFromCheckboxes(Contact con) {
        HouseholdNamingExclusionsString exclusions = buildNamingExclusionsFromCheckboxesFor(con);
        con.npo02__Naming_Exclusions__c = exclusions.getDisplayValue();
    }

    private HouseholdNamingExclusionsString buildNamingExclusionsFromCheckboxesFor(Contact con) {
        HouseholdNamingExclusionsString exclusions = new HouseholdNamingExclusionsString(null);
        if (isExcludedFromHouseholdName(con)) {
            exclusions.excludeName();
        }
        if (isExcludedFromFormalGreeting(con)) {
            exclusions.excludeFormalGreeting();
        }
        if (isExcludedFromInformalGreeting(con)) {
            exclusions.excludeInformalGreeting();
        }
        return exclusions;
    }


    public void handleAfterUpdate() {
        new ContactsInLegacyHouseholds(getRecords(), oldMap, this.settings)
                .onAfterUpdate();
    }

    public void onAfterDelete() {
        fireRollupsForMergedContacts();
        List<Contact> contactsInHouseholds = contactsInHouseholds();
        if (!contactsInHouseholds.isEmpty()) {
            new ContactsInLegacyHouseholds(contactsInHouseholds, this.settings)
                    .onAfterDelete();
        }
    }

    private void fireRollupsForMergedContacts() {
        Set<Id> mergedWinningContact = getMergedWinningContactIds();
        if (mergedWinningContact.size() > 0) {
            // this fires off opp rollups, which we aren't going to move to dmlWrapper!
            rollupContactsAndHouseholdsAfterMerge(mergedWinningContact);
        }
    }

    private Set<Id> getMergedWinningContactIds() {
        Set<Id> mergedWinningContactIds = new Set<Id>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (isLosingRecordInMergeOperation(con)) {
                mergedWinningContactIds.add(con.MasterRecordId);
            }
        }
        return mergedWinningContactIds;
    }

    private List<Contact> contactsInHouseholds() {
        List<Contact> consInHouseholds = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (householdIdFor(con) != null) {
                consInHouseholds.add(con);
            }
        }
        return consInHouseholds;
    }

    private Boolean isLosingRecordInMergeOperation(Contact con) {
        return con.MasterRecordId != null;
    }

    private Contact oldVersionOf(Contact con) {
        return oldMap.get(con.Id);
    }

    /*******************************************************************************************************
     * @description kicks off Opportunity Rollups after contacts have been merged, but only if NOT using
     * the Household Account model
     * @param winningContacts Set of Contact Id's
     ********************************************************************************************************/
    @TestVisible
    private static void rollupContactsAndHouseholdsAfterMerge(Set<Id> winningContacts) {

        npe01__Contacts_And_Orgs_Settings__c contactsAndOrgsSettings =
                UTIL_CustomSettingsFacade.getContactsSettings();
        if (contactsAndOrgsSettings.npe01__Account_Processor__c ==
                CAO_Constants.HH_ACCOUNT_PROCESSOR) {
            return;
        }

        Set<Id> oppIds = getOppIdsForWinningContacts(winningContacts);
        if (!oppIds.isEmpty()) {
            if (System.isFuture() || System.isBatch()) {
                RLLP_OppRollup.rollupContactsandHouseholdsForTrigger(oppIds);
            } else {
                RLLP_OppRollup.rollupContactsandHouseholdsForTriggerFuture(oppIds);
            }
        }
    }

    private static Set<Id> getOppIdsForWinningContacts(Set<Id> winningContacts) {
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityContactRole ocr : [
                SELECT OpportunityId
                FROM OpportunityContactRole
                WHERE ContactId IN :winningContacts AND IsPrimary = TRUE
        ]
        ) {
            oppIds.add(ocr.OpportunityId);
        }
        return oppIds;
    }

}