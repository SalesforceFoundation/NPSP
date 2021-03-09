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
* @description Represents household naming exclusions as a set of name/greeting fields from which the Contact should
* be excluded from.
*/
public inherited sharing class HouseholdNamingExclusionsString implements INamingExclusionsString {
    private String value;

    public HouseholdNamingExclusionsString(Contact con) {
        this.value = namingExclusionsStringFor(con) == null ? '' :
                namingExclusionsStringFor(con);
    }

    public String value() {
        return value.removeEnd(';');
    }

    public Boolean hasNamingExclusions() {
        return isExcludedFromName()
                || isExcludedFromFormalGreeting()
                || isExcludedFromInformalGreeting();
    }

    public Boolean isExcludedFromName() {
        return value.contains('Household__c.Name');
    }

    public Boolean isExcludedFromFormalGreeting() {
        return value.contains('Household__c.Formal_Greeting__c');
    }

    public Boolean isExcludedFromInformalGreeting() {
        return value.contains('Household__c.Informal_Greeting__c');
    }

    public Boolean equals(INamingExclusions other) {
        return isExcludedFromName() == other.isExcludedFromName()
                && isExcludedFromFormalGreeting() == other.isExcludedFromFormalGreeting()
                && isExcludedFromInformalGreeting() == other.isExcludedFromInformalGreeting();
    }

    public void synchronizeFrom(INamingExclusions other) {
        this.value = '';
        if (other.isExcludedFromName()) {
            excludeFromName();
        }
        if (other.isExcludedFromFormalGreeting()) {
            excludeFormalGreeting();
        }
        if (other.isExcludedFromInformalGreeting()) {
            excludeInformalGreeting();
        }
    }

    private String namingExclusionsStringFor(Contact con) {
        return con.npo02__Naming_Exclusions__c;
    }

    private void excludeFromName() {
        value += 'Household__c.Name;';
    }

    private void excludeFormalGreeting() {
        value += 'Household__c.Formal_Greeting__c;';
    }

    private void excludeInformalGreeting() {
        value += 'Household__c.Informal_Greeting__c;';
    }

}