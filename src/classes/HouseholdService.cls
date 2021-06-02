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
public inherited sharing class HouseholdService {

    @TestVisible
    private HouseholdSettings settings {
        get {
            if (settings == null) {
                settings = new HouseholdSettings();
            }
            return settings;
        }
        set;
    }

    @TestVisible
    private HouseholdNamingService householdNamingServiceInst {
        get {
            if (householdNamingServiceInst == null) {
                householdNamingServiceInst = new HouseholdNamingService();
            }
            return householdNamingServiceInst;
        }
        set;
    }

    private static final String RECORD_TYPE_ID = 'RecordTypeId';

    @TestVisible
    private UnitOfWork unitOfWorkInst {
        get {
            if (unitOfWorkInst == null) {
                unitOfWorkInst = new UnitOfWork();
            }
            return unitOfWorkInst;
        }
        set;
    }

    public Set<String> fieldsUsedForHouseholdNaming() {
        return householdNamingServiceInst.getHouseholdNamingContactFields();
    }

    public void createHouseholdsFor(
            ContactsInLegacyHouseholds contactsInLegacyHouseholds) {
        if (allContactsGetHouseholds()) {
            insertHouseholdsForContacts(
                    contactsInLegacyHouseholds.contactsWithoutHouseholds());
        }
        if (allIndividualContactsGetHouseholds()) {
            insertHouseholdsForContacts(
                    contactsInLegacyHouseholds.contactsInIndividualAccountsWithoutHouseholds());
        }
    }

    public void deleteEmptyHouseholdsFor(ContactsInLegacyHouseholds contactsInLegacyHouseholds) {
        Households oldHouseholds = new Households(
                new Set<Id>(contactsInLegacyHouseholds.oldHouseholdIds()),
                new HouseholdSelector());
        oldHouseholds.deleteEmptyHouseholds();
    }

    /**
     * @description Static flag used to prevent hitting governor limits when this method
     * runs multiple times during Contact merges.
     */
    private static Integer numberOfTimesUpdateHouseholdNamesHasRun = 0;
    public void updateHouseholdNamesFor(ContactsInLegacyHouseholds contactsInLegacyHouseholds) {
        if (contactsInLegacyHouseholds.householdsWithMembershipOrNamingFieldChanges().size() > 0
                && numberOfTimesUpdateHouseholdNamesHasRun < 2) {
            if (isFutureEligible()) {
                HouseholdNamingService.updateHouseholdNameAndMemberCountAsynchronously(
                        contactsInLegacyHouseholds
                                .householdsWithMembershipOrNamingFieldChanges());
            } else {
                HouseholdNamingService householdNamingService = new HouseholdNamingService();
                householdNamingService.updateHouseholdNameAndMemberCount(
                        contactsInLegacyHouseholds
                                .householdsWithMembershipOrNamingFieldChanges());
            }
            numberOfTimesUpdateHouseholdNamesHasRun++;
        }
    }

    private Boolean isFutureEligible() {
        return settings.isAsyncEnabled()
                && !System.isFuture() && !System.isBatch();
    }

    public void fireHouseholdRollupsFor(ContactsInLegacyHouseholds contactsInLegacyHouseholds) {
        if (contactsInLegacyHouseholds.householdsWithMembershipChanges().isEmpty()) {
            return; //No need to fire rollups if no Contacts changed Households
        }
        Households householdsWithMembershipChanges =
                new Households(
                        contactsInLegacyHouseholds.householdsWithMembershipChanges(),
                        new HouseholdSelector());
        householdsWithMembershipChanges.calculateLegacyHouseholdRollups();
    }

    public void processOldHouseholdsAfterDeletingContacts(
            ContactsInLegacyHouseholds contactsInLegacyHouseholds) {
        Households oldHouseholds =
                new Households(contactsInLegacyHouseholds.householdIds(),
                        new HouseholdSelector());
        oldHouseholds.deleteEmptyHouseholds();
        oldHouseholds.updateHouseholdNameAndMemberCount();
    }

    private Boolean allIndividualContactsGetHouseholds() {
        return settings.isAllIndividualsProcessor();
    }

    private Boolean allContactsGetHouseholds() {
        return settings.isAllProcessor();
    }

    /*******************************************************************************************************
    * @description Creates a new Household Object for each contact, unless excluded by recordType
    * @param contacts List of Contacts
    * @param isInsertTrigger Whether called from the afterInsert trigger (vs. afterUpdate trigger) on Contacts
    ********************************************************************************************************/
    private void insertHouseholdsForContacts(List<Contact> contacts) {
        List<npo02__Household__c> households = getHouseholdsForInsert(contacts);
        if (households.size() > 0) {
            unitOfWorkInst.registerNew((List<SObject>) households);
            Database.SaveResult[] householdSaveResults = unitOfWorkInst.save();
            if (householdSaveResults != null && !householdSaveResults.isEmpty()) {
                putHouseholdIdOntoContacts(contacts, householdSaveResults);
                updateNamesAfterHouseholdInsert(householdSaveResults);
            }
        }
    }

    private void putHouseholdIdOntoContacts(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId =
                getContactsToBeUpdatedWithNewHouseholdId(contacts, householdSaveResults);
        update contactsToBeUpdatedWithHouseholdId;
    }

    private void updateNamesAfterHouseholdInsert(Database.SaveResult[] lsr) {
        List<Id> householdIdsNeedingNamesUpdated =
                getHouseholdIdsNeedingNamesUpdatedFromSaveResult(lsr);
        if (!householdIdsNeedingNamesUpdated.isEmpty()) {
            if (isFutureEligible()) {
                HouseholdNamingService.updateHouseholdNameAndMemberCountAsynchronously(
                        householdIdsNeedingNamesUpdated
                );
            } else {
                HouseholdNamingService householdNamingService = new HouseholdNamingService();
                householdNamingService.updateHouseholdNameAndMemberCount(
                        householdIdsNeedingNamesUpdated
                );
            }
        }
    }

    private List<Id> getHouseholdIdsNeedingNamesUpdatedFromSaveResult(
            Database.SaveResult[] lsr) {
        List<Id> householdIdsNeedingNamesUpdated = new List<Id>();
        for (Database.SaveResult sr : lsr) {
            if (sr.isSuccess()) {
                householdIdsNeedingNamesUpdated.add(sr.getID());
            }
        }
        return householdIdsNeedingNamesUpdated;
    }

    private List<Contact> getContactsToBeUpdatedWithNewHouseholdId(List<Contact> contacts,
            Database.SaveResult[] householdSaveResults) {
        List<Contact> contactsToBeUpdatedWithHouseholdId = new List<Contact>();
        Integer i = 0;
        for (Contact con : getContactsThatAreNotExcludedByRecordType(contacts)) {
            Database.SaveResult saveResult = householdSaveResults[i];
            if (saveResult.isSuccess() == true) {
                //write the new Household Ids to the Contacts
                Contact cloneContact = con.Clone(true, false);
                cloneContact.npo02__household__c = saveResult.getId();
                contactsToBeUpdatedWithHouseholdId.add(cloneContact);
            } else {
                Database.Error err = saveResult.getErrors()[0];
                con.addError(err.getMessage());
            }
            i += 1;
        }
        return contactsToBeUpdatedWithHouseholdId;
    }

    private List<npo02__Household__c> getHouseholdsForInsert(List<Contact> contacts) {
        List<npo02__household__c> households = new List<npo02__household__c>();
        for (Contact con : getContactsThatAreNotExcludedByRecordType(contacts)) {
            households.add(getHouseholdForInsertFromContact(con));
        }
        return households;
    }

    private List<Contact> getContactsThatAreNotExcludedByRecordType(List<Contact> contacts) {
        List<Contact> contactsThatAreNotExcludedByRecordType = new List<Contact>();
        for (Contact con : contacts) {
            if (isNotExcludedByRecordType(con)) {
                contactsThatAreNotExcludedByRecordType.add(con);
            }
        }
        return contactsThatAreNotExcludedByRecordType;
    }

    private npo02__Household__c getHouseholdForInsertFromContact(Contact con) {
        npo02__household__c household =
                new npo02__household__c(Name = getDefaultHouseholdName(con));
        syncPrimaryAddressBlock(household, con);
        return household;
    }

    private void syncPrimaryAddressBlock(npo02__Household__c household, Contact con) {
        household.npo02__MailingStreet__c = con.MailingStreet;
        household.npo02__MailingCity__c = con.MailingCity;
        household.npo02__MailingState__c = con.MailingState;
        household.npo02__MailingPostalCode__c = con.MailingPostalCode;
        household.npo02__MailingCountry__c = con.MailingCountry;
        household.npo02__HouseholdPhone__c = con.HomePhone;
        household.npo02__HouseholdEmail__c = con.Email;
    }

    private String getDefaultHouseholdName(Contact con) {
        String hName = con.LastName;
        return hName += ' ' + System.Label.npo02.DefaultHouseholdName;
    }

    private Boolean isNotExcludedByRecordType(Contact con) {
        return !isRecordTypeInUseOnContacts
                || !settings.contactRecordTypesToExclude().contains(recordTypeIdFor(con));
    }

    private Id recordTypeIdFor(Contact con) {
        return (Id) con.get(RECORD_TYPE_ID);
    }

    private static Boolean isRecordTypeInUseOnContacts {
        get {
            if (isRecordTypeInUseOnContacts == NULL) {
                isRecordTypeInUseOnContacts =
                        Schema.sObjectType.Contact.fields.getMap().get(RECORD_TYPE_ID) != null;
            }
            return isRecordTypeInUseOnContacts;
        }
        set;
    }

}