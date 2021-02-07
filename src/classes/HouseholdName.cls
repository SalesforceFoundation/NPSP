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
* @description Household Name value object in NPSP.
*/
public with sharing class HouseholdName {

    SObject household;
    SObject oldRecord;
    Contacts contacts;
    CustomFormat customFormat;
    HH_INaming service;
    HouseholdSettings settings;
    String nameReplacementText = System.Label.npo02.NameReplacementText;

    public HouseholdName(SObject h, List<Contact> contacts) {
        this(h, null, contacts, null, null);
    }

    public HouseholdName(SObject h, SObject oldRecord, List<Contact> contacts, HH_INaming
            service) {
        this(h, oldRecord, contacts, service, null);
    }

    public HouseholdName(SObject h, SObject oldRecord, List<Contact> contacts,
            HH_INaming service, HouseholdSettings settings) {
        this.household = h;
        this.oldRecord = oldRecord;
        this.contacts = contacts == null ?
                new Contacts(new List<Contact>()) : new Contacts(contacts);
        this.service = service == null ? new HH_NameSpec() : service;
        this.settings = settings == null ? new HouseholdSettings() : settings;
        this.customFormat = new CustomFormat(h);
    }

    public String customNameString {
        get {
            return customFormat.value;
        }
    }

    public void processReplacementText() {
        if (isReplaceable(household, 'Name')) {
            customFormat.replace('Name;', ';');
            household.put('Name', nameReplacementText);
        } else if (isFieldValueChanged(household, 'Name', oldRecord)) {
            customFormat.append('Name');
        }

        if (isReplaceable(household, 'npo02__Informal_Greeting__c')) {
            customFormat.replace('Informal_Greeting__c;', ';');
            household.put('npo02__Informal_Greeting__c', nameReplacementText);
        } else if (isFieldValueChanged(household, 'npo02__Informal_Greeting__c', oldRecord)) {
            customFormat.append('Informal_Greeting__c');
        }

        if (isReplaceable(household, 'npo02__Formal_Greeting__c')) {
            customFormat.replace('Formal_Greeting__c;', ';');
            household.put('npo02__Formal_Greeting__c', nameReplacementText);
        } else if (isFieldValueChanged(household, 'npo02__Formal_Greeting__c', oldRecord)) {
            customFormat.append('Formal_Greeting__c');
        }
    }

    public void setNameFieldValuesOnHousehold() {
        if (!customFormat.contains('Name')) {
            household.put('Name', getHHName());
        }
        if (!customFormat.contains('Formal_Greeting__c')) {
            household.put('npo02__Formal_Greeting__c', getFormalName());
        }
        if (!customFormat.contains('Informal_Greeting__c')) {
            household.put('npo02__Informal_Greeting__c', getInformalName());
        }
    }

    /*******************************************************************************************************
    * @description returns the Household Name for the list of Contacts
    * @return String
    */
    public String getHHName() {
        List<Contact> listCon = new List<Contact>();
        for (Contact con : (List<Contact>) contacts.getRecords()) {
            if (con.npo02__Naming_Exclusions__c == null || !con.npo02__Naming_Exclusions__c.contains('Name'))
                listCon.add(con);
        }
        return service.getHouseholdName(listCon);
    }

    /*******************************************************************************************************
    * @description returns the Informal Greeting for the list of Contacts
    * @return String
    */
    public String getInformalName() {
        return service.getHouseholdInformalGreeting(getContactsForInformalName());
    }

    private List<Contact> getContactsForInformalName() {
        List<Contact> listCon = new List<Contact>();
        for (Contact con : (List<Contact>) contacts.getRecords()) {
            if (isIncludedInInformalGreeting(con))
                listCon.add(con);
        }
        return listCon;
    }

    private Boolean isIncludedInInformalGreeting(Contact con) {
        return con.npo02__Naming_Exclusions__c == null || !con.npo02__Naming_Exclusions__c.contains('Informal_Greeting__c');
    }

    /*******************************************************************************************************
    * @description returns the Formal Greeting for the list of Contacts
    * @return String
    */
    public String getFormalName() {
        return service.getHouseholdFormalGreeting(getContactsForFormalName());
    }

    private List<Contact> getContactsForFormalName() {
        List<Contact> contactsForFormalName = new List<Contact>();
        for (Contact con : (List<Contact>) contacts.getRecords()) {
            if (isIncludedInFormalGreeting(con))
                contactsForFormalName.add(con);
        }
        return contactsForFormalName;
    }

    private Boolean isIncludedInFormalGreeting(Contact con) {
        return con.npo02__Naming_Exclusions__c == null || !con.npo02__Naming_Exclusions__c.contains('Formal_Greeting__c');
    }


    private Boolean isFieldValueChanged(SObject h, String fieldApiName, SObject oldRecord) {
        return (String) h.get(fieldApiName) != oldRecord.get(fieldApiName);
    }

    private Boolean isReplaceable(SObject household, String fieldApiName) {
        String fieldValue = (String) household.get(fieldApiName);
        return fieldValue == null || fieldValue == '' || fieldValue == nameReplacementText;
    }

    private class CustomFormat {
        String value { get; private set; }
        Set<String> customNameSet {
            get {
                return new Set<String>(
                        new List<String>(
                                value.split(';')));
            }
        }
        public CustomFormat(SObject h) {
            this.value = getCustomName(h);
        }

        private String getCustomName(SObject h) {
            return h.get('npo02__SYSTEM_CUSTOM_NAMING__c') == null ? ';' :
                    h.get('npo02__SYSTEM_CUSTOM_NAMING__c') + ';';
        }

        public void replace(String searchVal, String newVal) {
            if (customNameSet.contains(searchVal)) {
                value = value.replace(searchVal, newVal);
            }
        }

        public void append(String val) {
            if (!customNameSet.contains(val)) {
                value += val + ';';
            }
        }

        public Boolean contains(String val) {
            return this.customNameSet.contains(val);
        }
    }
}