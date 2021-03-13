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

    private Map<Id, Contact> oldMap;

    public Contacts(List<Contact> records) {
        this(records, null);
    }

    public Contacts(List<Contact> records, List<Contact> oldList) {
        super(records, Contact.SObjectType);
        this.oldMap = oldList != null ?
                new Map<Id, Contact>(oldList) : new Map<Id, Contact>();
    }

    public void onBeforeInsert() {
        synchronizeNamingExclusions();
    }

    public void onBeforeUpdate() {
        applyExclusionsStringChangesToCheckboxes();
    }

    public void onAfterDelete() {
        fireRollupsForMergedContacts();
        if (!contactsInHouseholds().isEmpty()) {
            ContactsInLegacyHouseholds contactsInLegacyHouseholds =
                    new ContactsInLegacyHouseholds(contactsInHouseholds().getRecords());
            contactsInLegacyHouseholds.onAfterDelete();
        }
    }

    public List<Contact> forHouseholdName() {
        List<Contact> contactsForHouseholdNameGeneration = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (isIncludedInHouseholdName(con)) {
                contactsForHouseholdNameGeneration.add(con);
            }
        }
        return contactsForHouseholdNameGeneration;
    }

    public List<Contact> forFormalGreeting() {
        List<Contact> contactsForFormalName = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (isIncludedInFormalGreeting(con)) {
                contactsForFormalName.add(con);
            }
        }
        return contactsForFormalName;
    }

    public List<Contact> forInformalGreeting() {
        List<Contact> listCon = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (isIncludedInInformalGreeting(con)) {
                listCon.add(con);
            }
        }
        return listCon;
    }

    /**
     * @description NPSP Contacts have two forms of tracking which Household Name / Greetings
     * they should be excluded from.  Checkboxes are a newer implementation and have priority.
     * This method aligns the concatenated String with the Checkboxes to keep them in sync.
     */
    public void synchronizeNamingExclusions() {
        for (Contact con : (List<Contact>) getRecords()) {
            INamingExclusionsString exclusionsAsString =
                    new HouseholdNamingExclusionsString(con);
            INamingExclusions exclusionsAsBooleans =
                    new HouseholdNamingExclusionsCheckboxes(con);
            if (!exclusionsAsString.equals(exclusionsAsBooleans)) {
                mergeExclusions(exclusionsAsBooleans, exclusionsAsString);
                setExclusionsStringFor(con, exclusionsAsString.value());
                setExclusionsCheckboxes(con, exclusionsAsBooleans);
            }
        }
    }

    private Boolean isIncludedInHouseholdName(Contact con) {
        HouseholdNamingExclusionsString exclusionsAsString = new
                HouseholdNamingExclusionsString(con);
        return !exclusionsAsString.isExcludedFromName();
    }

    private Boolean isIncludedInFormalGreeting(Contact con) {
        HouseholdNamingExclusionsString exclusionsAsString = new
                HouseholdNamingExclusionsString(con);
        return !exclusionsAsString.isExcludedFromFormalGreeting();
    }

    private Boolean isIncludedInInformalGreeting(Contact con) {
        HouseholdNamingExclusionsString exclusionsAsString = new
                HouseholdNamingExclusionsString(con);
        return !exclusionsAsString.isExcludedFromInformalGreeting();
    }

    private Contacts contactsInHouseholds() {
        List<Contact> consInHouseholds = new List<Contact>();
        for (Contact con : (List<Contact>) getRecords()) {
            if (householdIdFor(con) != null) {
                consInHouseholds.add(con);
            }
        }
        return new Contacts(consInHouseholds);
    }

    private void applyExclusionsStringChangesToCheckboxes() {
        for (Contact con : (List<Contact>) getRecords()) {
            HouseholdNamingExclusionsString namingExclusionsString =
                    new householdNamingExclusionsString(con);
            HouseholdNamingExclusionsString oldNamingExclusionsString =
                    new HouseholdNamingExclusionsString(oldVersionOf(con));
            if (!namingExclusionsString.equals(oldNamingExclusionsString)) {
                HouseholdNamingExclusionsCheckboxes exclusionsAsCheckboxes = new HouseholdNamingExclusionsCheckboxes(con);
                exclusionsAsCheckboxes.updateFrom(namingExclusionsString);
                setExclusionsCheckboxes(con, exclusionsAsCheckboxes);
            }
        }
    }

    private void setExclusionsStringFor(Contact contact, String val) {
        contact.npo02__Naming_Exclusions__c = val;
    }

    /**
     * @param exclusionsAsBooleans Checkbox implemenation of Household Naming Exclusions
     * @param exclusionsAsString Concatenated string implementation of Household Naming
     * Exclusions
     * @description Checks any exclusions checkboxes to true that are included in the
     * concatenated string, and then updates the string to include exclusions (field names)
     * for any Exclusion checkboxes that are marked TRUE for the Contact.
     */
    private void mergeExclusions(INamingExclusions exclusionsAsBooleans,
            INamingExclusions exclusionsAsString) {
        // Prioritize booleans by syncing from picklists first
        exclusionsAsBooleans.synchronizeFrom(exclusionsAsString);
        exclusionsAsString.synchronizeFrom(exclusionsAsBooleans);
    }

    private void setExclusionsCheckboxes(Contact con, INamingExclusions exclusions) {
        con.Exclude_from_Household_Name__c = exclusions.isExcludedFromName();
        con.Exclude_from_Household_Formal_Greeting__c = exclusions.isExcludedFromFormalGreeting();
        con.Exclude_from_Household_Informal_Greeting__c = exclusions.isExcludedFromInformalGreeting();
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

    private Id householdIdFor(Contact con) {
        return con.npo02__Household__c;
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

        ContactAndOrgSettings contactAndOrgSettings = new ContactAndOrgSettings();
        if (contactAndOrgSettings.isHouseholdAccountModel()) {
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