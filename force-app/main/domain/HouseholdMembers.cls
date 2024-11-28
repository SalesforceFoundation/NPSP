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
* @description Domain class for HouseholdMembers in NPSP.
*/
public inherited sharing class HouseholdMembers implements IHouseholdMembers {

    List<Contact> records;
    public HouseholdMembers(List<Contact> records) {
        this.records = records;
    }

    public Map<Id, Contact> oldMap;
    public HouseholdMembers(List<Contact> records, Map<Id, Contact> oldMap) {
        this.records = records;
        this.oldMap = oldMap != null ?
                new Map<Id, Contact>(oldMap) : new Map<Id, Contact>();
    }

    public List<Contact> forHouseholdName() {
        List<Contact> contactsForHouseholdNameGeneration = new List<Contact>();
        for (Contact con : records) {
            if (isIncludedInHouseholdName(con)) {
                contactsForHouseholdNameGeneration.add(con);
            }
        }
        return contactsForHouseholdNameGeneration;
    }

    public List<Contact> forFormalGreeting() {
        List<Contact> contactsForFormalName = new List<Contact>();
        for (Contact con : records) {
            if (isIncludedInFormalGreeting(con)) {
                contactsForFormalName.add(con);
            }
        }
        return contactsForFormalName;
    }

    public List<Contact> forInformalGreeting() {
        List<Contact> listCon = new List<Contact>();
        for (Contact con : records) {
            if (isIncludedInInformalGreeting(con)) {
                listCon.add(con);
            }
        }
        return listCon;
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

    public void createAndUpdateHouseholdAddresses() {
        TDTM_Runnable.DmlWrapper dmlWrapper = new TDTM_Runnable.DmlWrapper();

        // Strategy:
        // create a new (unsaved) address for each contact.
        // see if there is an existing address that matches each new address.
        //
        // for existing addresses we match
        //     process during BeforeInsert/Update
        //     update appropriate fields on contact
        //
        // for new addresses that won't be a default (ie, the contact has override set)
        //     process during BeforeInsert/Update
        //     create the address now
        //     update appropriate fields on contact
        //
        // for new addresses that will be a default address
        //     process during AfterInsert/Update
        //     mark the new address as default
        //     put it on dmlWrapper
        //

        Map<Contact, Address__c> addressesByContact = new Map<Contact, Address__c>();
        List<Contact> listCon = new List<Contact>();

        for (Contact contact : records) {
            listCon.add(contact);
            NPSP_Address npspAddressFromContact = new NPSP_Address(contact);
            addressesByContact.put(contact, npspAddressFromContact.getRecord());
        }

        // look for duplicates for our proposed new addresses
        Map<Address__c, Address__c> addressMatchesByAddress = Addresses.getExistingAddresses(
                addressesByContact.values());

        // maps & lists to keep track of the addresses we must insert or update
        List<Address__c> addressesToUpdate = new List<Address__c>();
        List<Address__c> addressesToInsert = new List<Address__c>();

        for (Contact contact : listCon) {
            NPSP_Address npspAddress = new NPSP_Address(addressesByContact.get(contact));
            NPSP_Address npspMatchingAddress = new NPSP_Address(addressMatchesByAddress.get(npspAddress.getRecord()));
            NPSP_Contact npspContact = new NPSP_Contact(contact, oldVersionOf(contact));
            Boolean addressUpdated = false;

            // if found a match
            if (npspMatchingAddress.getRecord() != null) {
                // record the match in the contact
                // if it is a fuzzy match, not exact, then we want to update the existing address.
                if (shouldUpdateAddressUndeliverableStatusFromContact(npspContact)) {
                    npspMatchingAddress.setUndeliverable(npspContact.isUndeliverableMailingAddress());
                    addressUpdated = true;
                }
                if (!npspAddress.isEqualToIncludingAddressType(npspMatchingAddress, true)) {
                    npspMatchingAddress.copyFrom(npspAddress);
                    if (!npspContact.hasAddressOverride() && !npspMatchingAddress.isDefault() && !isSeasonalAddress(npspMatchingAddress.getRecord())) {
                        npspMatchingAddress.setAsDefault();
                    }
                    addressUpdated = true;
                }
                // exact match. we aren't specifying override, so the address should become the new hh default address
                else if (!npspContact.hasAddressOverride() && !npspMatchingAddress.isDefault() && !isSeasonalAddress(npspMatchingAddress.getRecord())) {
                    npspMatchingAddress.setAsDefault();
                    addressUpdated = true;
                }
                if (addressUpdated) {
                    addressesToUpdate.add(npspMatchingAddress.getRecord());
                }
            } else {
                // no match, not an override, make it a new default hh address
                if (!isSeasonalAddress(npspAddress.getRecord())) {
                    npspAddress.setAsDefault();
                }
                npspAddress.setUndeliverable(npspContact.isUndeliverableMailingAddress());
                addressesToInsert.add(npspAddress.getRecord());
            }
        }

        if (addressesToUpdate.size() > 0) {
            for (Address__c addr : addressesToUpdate) {
                dmlWrapper.objectsToUpdate.add(addr);
            }
        }
        if (addressesToInsert.size() > 0) {
            dmlWrapper.objectsToInsert.addAll((List<SObject>) addressesToInsert);
        }
        TDTM_TriggerHandler.processDML(dmlWrapper);
    }

    private Boolean isSeasonalAddress(Address__c address) {
        return address.Seasonal_Start_Day__c != null && address.Seasonal_Start_Month__c != null &&
               address.Seasonal_End_Day__c != null && address.Seasonal_End_Month__c != null;
    }

    private Boolean shouldUpdateAddressUndeliverableStatusFromContact(NPSP_Contact npspContact) {
        return npspContact.isUndeliverableStatusChanged();
    }

    /*******************************************************************************************************
    * @description for the map of addresses, update any contact's mailing fields that are using the address as an override.
    * @param addressesById a map of Address Id's to Addresses
    * @param dmlWrapper to hold the Contacts to update
    */
    public static void syncAddressChangesToContactOverrides(Map<Id, Address__c> addressesById,
            TDTM_Runnable.DmlWrapper dmlWrapper) {

        List<Contact> contactsWithAddressOverrides = ContactSelector.getContactOverridesForAddressesIn(
                addressesById.keySet()
        );

        for (Contact contact : contactsWithAddressOverrides) {
            NPSP_Contact npspContact = new NPSP_Contact(contact);
            NPSP_Address npspAddress = new NPSP_Address(addressesById.get(npspContact.currentAddress()));

            npspContact.mailingAddress(npspAddress);
            npspContact.setUndeliverableMailingAddress(npspAddress.isUndeliverable());

            dmlWrapper.objectsToUpdate.add(npspContact.getRecord());
        }
    }

    public void resetAddressUsingHouseholdAddress() {
        Map<Id, Address__c> addressesByAccountId = new Map<Id, Address__c>();
        for (Contact con : records) {
            addressesByAccountId.put(con.AccountId, null);
        }

        // get the default and seasonal address for each HH
        Map<Id, Addresses.HouseholdInfo> addressHouseholdInfoByAccountId =
                Addresses.syncAddressesForAccountsAndContacts(addressesByAccountId,
                        null, true);

        // reset the Contact's address fields with the appropriate address
        for (Contact contact : records) {
            Addresses.HouseholdInfo householdInfo = addressHouseholdInfoByAccountId.get(contact.AccountId);
            if (householdInfo != null) {
                Address__c address = householdInfo.seasonalAddress;
                if (address == null) {
                    address = householdInfo.defaultAddress;
                }
                if (address != null) {
                    NPSP_Address npspAddress = new NPSP_Address(address);
                    NPSP_Contact npspContact = new NPSP_Contact(contact);
                    npspContact.setCurrentAddress(npspAddress);
                    npspContact.setUndeliverableMailingAddress(npspAddress.isUndeliverable());
                }
            }
        }
    }

    public Contact oldVersionOf(Contact con) {
        return oldMap.get(con.Id);
    }

}