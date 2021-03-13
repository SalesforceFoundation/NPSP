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
* @description Value object for the String used to signify which Household Name / Greeting
* fields are controlled by the User and should therefore not be overridden by NPSP custom
* Household Naming logic. The value is the concatenated list of field names that the User is
* controlling and is currently stored in the npo02__SYSTEM_CUSTOM_NAMING__c field.
*/
public inherited sharing class HouseholdNamingUserControlledFields {
    private String value;
    private SObject household;
    private SObject oldRecord;

    public HouseholdNamingUserControlledFields(String str) {
        this.value = str == null ? ';' : str + ';';
    }

    public HouseholdNamingUserControlledFields(SObject household, SObject oldRecord) {
        this.value = userControlledNamingFieldsFor(household) == null ? ';' :
                userControlledNamingFieldsFor(household) + ';';
        this.household = household;
        this.oldRecord = oldRecord;
        buildUserControlledNamingString();
    }

    public String asConcatenatedString() {
        return this.value;
    }

    public Boolean isInformalGreetingControlledByUser() {
        return contains('Informal_Greeting__c');
    }

    public Boolean isFormalGreetingControlledByUser() {
        return contains('Formal_Greeting__c');
    }

    public Boolean isNameControlledByUser() {
        return contains('Name');
    }

    private String userControlledNamingFieldsFor(SObject household) {
        return (String) household.get
                ('npo02__SYSTEM_CUSTOM_NAMING__c');
    }

    private void buildUserControlledNamingString() {
        removeOrAppendName();
        removeOrAppendInformalGreeting();
        removeOrAppendFormalGreeting();
    }

    private void removeOrAppendFormalGreeting() {
        if (isFormalGreetingReplaceable()) {
            removeFormalGreeting();
        } else if (isFormalGreetingChanged()) {
            appendFormalGreeting();
        }
    }

    private void removeOrAppendInformalGreeting() {
        if (isInformalGreetingReplaceable()) {
            removeInformalGreeting();
        } else if (isInformalGreetingChanged()) {
            appendInformalGreeting();
        }
    }

    private void removeOrAppendName() {
        if (isNameReplaceable()) {
            removeName();
        } else if (isNameChanged()) {
            appendName();
        }
    }

    private Boolean isReplaceable(String fieldApiName) {
        String fieldValue = (String) household.get(fieldApiName);
        return fieldValue == null || fieldValue == '' || fieldValue == nameReplacementText();
    }

    private Boolean isFormalGreetingChanged() {
        return isFieldValueChanged('npo02__Formal_Greeting__c');
    }

    private Boolean isInformalGreetingChanged() {
        return isFieldValueChanged('npo02__Informal_Greeting__c');
    }

    private Boolean isNameChanged() {
        return isFieldValueChanged('Name');
    }

    private Boolean isFormalGreetingReplaceable() {
        return isReplaceable('npo02__Formal_Greeting__c');
    }

    private Boolean isInformalGreetingReplaceable() {
        return isReplaceable('npo02__Informal_Greeting__c');
    }

    private Boolean isNameReplaceable() {
        return isReplaceable('Name');
    }

    private Boolean isFieldValueChanged(String fieldApiName) {
        return (String) household.get(fieldApiName) != oldRecord.get(fieldApiName);
    }

    private Set<String> userControlledFieldSet() {
        return new Set<String>(
                new List<String>(
                        value.split(';')));
    }

    private void replace(String searchVal, String newVal) {
        if (userControlledFieldSet().contains(searchVal)) {
            value = value.replace(searchVal, newVal);
        }
    }

    private void append(String val) {
        if (!userControlledFieldSet().contains(val)) {
            value += val + ';';
        }
    }

    private Boolean contains(String val) {
        return userControlledFieldSet().contains(val);
    }

    private void removeName() {
        replace('Name;', ';');
    }

    private void removeFormalGreeting() {
        replace('Formal_Greeting__c;', ';');
    }

    private void removeInformalGreeting() {
        replace('Informal_Greeting__c;', ';');
    }

    private void appendFormalGreeting() {
        append('Formal_Greeting__c');
    }

    private void appendInformalGreeting() {
        append('Informal_Greeting__c');
    }

    private void appendName() {
        append('Name');
    }

    private String nameReplacementText() {
        return System.Label.npo02.NameReplacementText;
    }
}