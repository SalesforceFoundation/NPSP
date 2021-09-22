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

    public void createAddressAfterInsertUpdate(TDTM_Runnable.DmlWrapper dmlWrapper) {

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
            NPSP_Contact npspContact = new NPSP_Contact(contact);
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
                    if (!npspContact.hasAddressOverride() && !npspMatchingAddress.isDefault()) {
                        npspMatchingAddress.setAsDefault();
                    }
                    addressUpdated = true;
                }
                // exact match. we aren't specifying override, so the address should become the new hh default address
                else if (!npspContact.hasAddressOverride() && !npspMatchingAddress.isDefault()) {
                    npspMatchingAddress.setAsDefault();
                    addressUpdated = true;
                }
                if (addressUpdated) {
                    addressesToUpdate.add(npspMatchingAddress.getRecord());
                }
            } else {
                // no match, not an override, make it a new default hh address
                npspAddress.setAsDefault();
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
    }

    private Boolean shouldUpdateAddressUndeliverableStatusFromContact(NPSP_Contact npspContact) {
        return npspContact.isUndeliverableStatusChanged();
    }

}