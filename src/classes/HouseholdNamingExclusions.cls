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
* @description Domain class for HouseholdNamingExclusions in NPSP.
*/
public inherited sharing class HouseholdNamingExclusions {
    private String value;

    public HouseholdNamingExclusions(String namingExclusionsString) {
        this.value = namingExclusionsString == null ? '' : namingExclusionsString;
    }

    public Boolean isNameExcluded() {
        return value.contains('Household__c.Name');
    }

    public Boolean isFormalGreetingExcluded() {
        return value.contains('Household__c.Formal_Greeting__c');
    }

    public Boolean isInformalGreetingExcluded() {
        return value.contains('Household__c.Informal_Greeting__c');
    }

    public Boolean hasNamingExclusions() {
        return isNameExcluded()
                || isFormalGreetingExcluded()
                || isInformalGreetingExcluded();
    }

    public void excludeName() {
        value += 'Household__c.Name;';
    }

    public void excludeFormalGreeting() {
        value += 'Household__c.Formal_Greeting__c;';
    }

    public void excludeInformalGreeting() {
        value += 'Household__c.Informal_Greeting__c;';
    }

    public String getDisplayValue() {
        prepareFinalValue();
        return value;
    }

    private void prepareFinalValue() {
        if (value.endsWith(';')) {
            value = value.subString(0, value.length() - 1);
        }
    }

    private Boolean isEqualTo(String str) {
        return value == str;
    }

    public Boolean isNotEqualTo(String str) {
        return !isEqualTo(str);
    }
}
