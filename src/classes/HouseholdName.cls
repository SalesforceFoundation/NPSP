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
public inherited sharing class HouseholdName {

    private SObject household;
    private SObject oldRecord;
    private Contacts contacts;
    private HouseholdCustomNamingString customNamingString;
    private HH_INaming service;
    private HouseholdSettings settings;
    private String nameReplacementText = System.Label.npo02.NameReplacementText;

    public HouseholdName(SObject household, List<Contact> contacts) {
        this(household, null, contacts, null, null);
    }

    public HouseholdName(SObject household, SObject oldRecord, List<Contact> contacts, HH_INaming
            service) {
        this(household, oldRecord, contacts, service, null);
    }

    public HouseholdName(SObject household, SObject oldRecord, List<Contact> contacts,
            HH_INaming service, HouseholdSettings settings) {
        this.household = household;
        this.oldRecord = oldRecord;
        this.contacts = contacts == null ?
                new Contacts(new List<Contact>()) : new Contacts(contacts);
        this.service = service == null ? new HH_NameSpec() : service;
        this.settings = settings == null ? new HouseholdSettings() : settings;
        this.customNamingString = new HouseholdCustomNamingString(customNamingStringFor(household));
    }

    private String customNamingStringFor(SObject household) {
        return (String) household.get
                ('npo02__SYSTEM_CUSTOM_NAMING__c');
    }

    public String getCustomNamingString() {
        processHouseholdNamingReplacements();
        return this.customNamingString.value;
    }

    public void processHouseholdNamingReplacements() {
        if (isNameReplaceable()) {
            customNamingString.removeName();
            replaceHouseholdName();
        } else if (isNameChanged()) {
            customNamingString.appendName();
        }

        if (isInformalGreetingReplaceable()) {
            customNamingString.removeInformalGreeting();
            replaceHouseholdInformalGreeting();
        } else if (isInformalGreetingChanged()) {
            customNamingString.appendInformalGreeting();
        }

        if (isFormalGreetingReplaceable()) {
            customNamingString.removeFormalGreeting();
            replaceHouseholdFormalGreeting();
        } else if (isFormalGreetingChanged()) {
            customNamingString.appendFormalGreeting();
        }
    }

    private Boolean isFormalGreetingChanged() {
        return isFieldValueChanged(household, 'npo02__Formal_Greeting__c', oldRecord);
    }

    private Boolean isInformalGreetingChanged() {
        return isFieldValueChanged(household, 'npo02__Informal_Greeting__c', oldRecord);
    }

    private Boolean isNameChanged() {
        return isFieldValueChanged(household, 'Name', oldRecord);
    }

    private Boolean isFormalGreetingReplaceable() {
        return isReplaceable(household, 'npo02__Formal_Greeting__c');
    }

    private Boolean isInformalGreetingReplaceable() {
        return isReplaceable(household, 'npo02__Informal_Greeting__c');
    }

    private Boolean isNameReplaceable() {
        return isReplaceable(household, 'Name');
    }

    private void replaceHouseholdFormalGreeting() {
        household.put('npo02__Formal_Greeting__c', nameReplacementText);
    }

    private void replaceHouseholdInformalGreeting() {
        household.put('npo02__Informal_Greeting__c', nameReplacementText);
    }

    private void replaceHouseholdName() {
        household.put('Name', nameReplacementText);
    }

    public void setNameFieldValuesOnHousehold() {
        if (!customNamingString.contains('Name')) {
            household.put('Name', getHHName());
        }
        if (!customNamingString.contains('Formal_Greeting__c')) {
            household.put('npo02__Formal_Greeting__c', getFormalName());
        }
        if (!customNamingString.contains('Informal_Greeting__c')) {
            household.put('npo02__Informal_Greeting__c', getInformalName());
        }
    }

    /*******************************************************************************************************
    * @description returns the Household Name for the list of Contacts
    * @return String
    */
    private String getHHName() {
        List<Contact> listCon = new List<Contact>();
        for (Contact con : (List<Contact>) contacts.getRecords()) {
            if (con.npo02__Naming_Exclusions__c == null
                    || !con.npo02__Naming_Exclusions__c.contains('Name'))
                listCon.add(con);
        }
        return service.getHouseholdName(listCon);
    }

    /*******************************************************************************************************
    * @description returns the Informal Greeting for the list of Contacts
    * @return String
    */
    private String getInformalName() {
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
        return con.npo02__Naming_Exclusions__c == null
                || !con.npo02__Naming_Exclusions__c.contains('Informal_Greeting__c');
    }

    /*******************************************************************************************************
    * @description returns the Formal Greeting for the list of Contacts
    * @return String
    */
    private String getFormalName() {
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
        return con.npo02__Naming_Exclusions__c == null
                || !con.npo02__Naming_Exclusions__c.contains('Formal_Greeting__c');
    }


    private Boolean isFieldValueChanged(SObject household, String fieldApiName, SObject oldRecord) {
        return (String) household.get(fieldApiName) != oldRecord.get(fieldApiName);
    }

    private Boolean isReplaceable(SObject household, String fieldApiName) {
        String fieldValue = (String) household.get(fieldApiName);
        return fieldValue == null || fieldValue == '' || fieldValue == nameReplacementText;
    }

    private class HouseholdCustomNamingString {
        String value { get; private set; }
        Set<String> customNameSet {
            get {
                return new Set<String>(
                        new List<String>(
                                value.split(';')));
            }
        }

        public HouseholdCustomNamingString(String str) {
            this.value = str == null ? ';' : str + ';';
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
            return customNameSet.contains(val);
        }

        public void removeName() {
            replace('Name;', ';');
        }

        public void removeFormalGreeting() {
            replace('Formal_Greeting__c;', ';');
        }

        public void removeInformalGreeting() {
            replace('Informal_Greeting__c;', ';');
        }

        public void appendFormalGreeting() {
            append('Formal_Greeting__c');
        }

        public void appendInformalGreeting() {
            append('Informal_Greeting__c');
        }

        public void appendName() {
            append('Name');
        }
    }
}