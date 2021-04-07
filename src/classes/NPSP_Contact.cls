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
* @description Contact entity class in NPSP.
*/
public inherited sharing class NPSP_Contact {

    private Contact contact;
    private Contact oldContact;

    @TestVisible
    private ContactService contactService {
        get {
            if (contactService == null) {
                contactService = new ContactService();
            }
            return contactService;
        }
        set;
    }

    @TestVisible
    private AddressService addressService {
        get {
            if (addressService == null) {
                addressService = new AddressService();
            }
            return addressService;
        }
        set;
    }

    public NPSP_Contact(Contact contact, Contact oldContact) {
        this.contact = contact;
        this.oldContact = oldContact;
    }

    public NPSP_Contact(Contact contact) {
        this.contact = contact;
    }

    public Contact getRecord() {
        return this.contact;
    }

    public void currentAddress(NPSP_Address npspAddress) {
        contact.Current_Address__c = npspAddress.getRecord().Id;
        mailingAddress(npspAddress);
    }

    public Id currentAddress() {
        return contact.Current_Address__c;
    }

    public Boolean hasAddressOverride() {
        return contact.is_Address_Override__c;
    }

    public Boolean accountChanged() {
        return (oldContact != null && oldContact.AccountId != contact.AccountId);
    }

    public Boolean isAddressChanged() {
        return contactService.isContactAddressChanged(contact, oldContact);
    }

    public Boolean isAddressEmpty() {
        return contactService.isContactAddressEmpty(contact);
    }

    public Boolean addressOverrideChanged() {
        return contact.is_Address_Override__c != oldContact.is_Address_Override__c;
    }

    public Boolean currentAddressChanged() {
        return contact.Current_Address__c != oldContact.Current_Address__c;
    }

    public Boolean hasAccount() {
        return contact.AccountId != null;
    }

    public Boolean householdAndAccountDiffer() {
        return contact.HHId__c != contact.AccountId;
    }

    public Id accountId() {
        return contact.AccountId;
    }

    public Boolean isMovingToANewHousehold() {
        return accountChanged() && !isAddressEmpty();
    }

    public void mailingAddress(NPSP_Address npspAddress) {
        npspAddress.copyOntoSObject(contact, 'Mailing','npe01__Primary_Address_Type__c');
    }

    public Boolean mailingAddressIsDifferentFrom(NPSP_Address npspAddress) {
       return addressService.isSObjectAddressDifferent(contact, npspAddress.getRecord());
    }

}