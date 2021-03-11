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
* @description Domain class for Addresses in NPSP.
*/
public inherited sharing class Addresses extends fflib_SObjects {

    private Map<Id, Address__c> oldMap;

    public Addresses(List<Address__c> addresses) {
        super(addresses, Address__c.SObjectType);
    }

    public Addresses(List<Address__c> addresses, List<Address__c> oldList) {
        super(addresses, Address__c.SObjectType);
        this.oldMap = oldList == NULL ?
                new Map<Id, Address__c>() :
                new Map<Id, Address__c>(oldList);
    }

    /********************************************************************************************************
    * @description Retreive the defined default address type picklist value to use when creating a new
    * Address record.
    */
    public static String defaultAddressType {
        get {
            if (defaultAddressType == null) {
                for (Schema.PicklistEntry pv: Address__c.Address_Type__c.getDescribe().getPicklistValues()) {
                    if (pv.isDefaultValue()) {
                        defaultAddressType = pv.getValue();
                        break;
                    }
                }
            }
            return defaultAddressType;
        } private set;
    }

    public Map<Id, Address__c> getMapAddressesByAcctId() {
        Map<Id, Address__c> mapAddressesByAcctId = new Map<Id, Address__c>(); // map of HH Accounts, and their default Address
        for (Address__c address : (List<Address__c>) getRecords()) {
            Id accId = address.Household_Account__c;
            if (accId != null) {
                mapAddressesByAcctId.put(accId, null);
            }
        }
        return mapAddressesByAcctId;
    }

    public void onBeforeInsert() {
        setLatestDatesOnDefaults();
    }

    public void onBeforeUpdate() {
        updateLatestDatesForDefaultChanges();
    }

    private void setLatestDatesOnDefaults() {
        for (Address__c addr : (List<Address__c>) defaultAddresses().getRecords()) {
            resetLatestStartDateFor(addr);
            resetLatestEndDateFor(addr);
        }
    }

    private void resetLatestEndDateFor(Address__c address) {
        address.Latest_End_Date__c = NULL;
    }

    private void resetLatestStartDateFor(Address__c address) {
        address.Latest_Start_Date__c = system.today();
    }

    private Addresses defaultAddresses() {
        fflib_SObjects defaultAddresses = selectByFieldValue(
                Address__c.Default_Address__c, TRUE);
        return new Addresses(defaultAddresses.getRecords());
    }

    private void updateLatestDatesForDefaultChanges() {
        for (Address__c addr :
                (List<Address__c>) addressesWithDefaultChanges().getRecords()) {
            // when an address changes Default, we update its latest date fields
            if (isDefault(addr)) {
                resetLatestStartDateFor(addr);
                resetLatestEndDateFor(addr);
            } else {
                setEndDateFor(addr);
            }
        }
    }

    private Addresses addressesWithDefaultChanges() {
        List<Address__c> addressesWithDefaultChanges = new List<Address__c>();
        for (Address__c addr : (List<Address__c>) getRecords()) {
            if (isDefaultChanged(addr)) {
                addressesWithDefaultChanges.add(addr);
            }
        }
        return new Addresses(addressesWithDefaultChanges);
    }

    private void setEndDateFor(Address__c addr) {
        addr.Latest_End_Date__c = system.today();
    }

    private Boolean isDefaultChanged(Address__c addr) {
        return isDefault(addr) != isDefault(oldVersionOf(addr));
    }

    private Boolean isDefault(Address__c addr) {
        return addr.Default_Address__c;
    }

    private Address__c oldVersionOf(Address__c addr) {
        return oldMap.get(addr.Id);
    }

}