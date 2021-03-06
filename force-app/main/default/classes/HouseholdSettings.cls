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
* @description Household Settings class in NPSP.
*/
public inherited sharing class HouseholdSettings {

    npo02__Households_Settings__c settings;
    private static final String defaultNamingService = 'HH_NameSpec';

    public HouseholdSettings() {
        this(UTIL_CustomSettingsFacade.getHouseholdsSettings());
    }

    @TestVisible
    private HouseholdSettings(npo02__Households_Settings__c settings) {
        this.settings = settings;
    }

    public Boolean isAsyncEnabled() {
        return settings.npo02__Async_Household_Naming__c;
    }

    public Boolean isAllIndividualsProcessor() {
        return settings.npo02__Household_Rules__c == HH_Households.ALL_INDIVIDUALS_PROCESSOR;
    }

    public Boolean isAllProcessor() {
        return settings.npo02__Household_Rules__c == HH_Households.ALL_PROCESSOR;
    }

    public Set<Id> contactRecordTypesToExclude() {
        if (hasRecordTypeExclusions()) {
            return getRecordTypeIdsToExclude();
        } else {
            return new Set<Id>();
        }
    }

    private Set<Id> getRecordTypeIdsToExclude() {
        return new Set<Id>(
                (List<Id>) settings.npo02__Household_Creation_Excluded_Recordtypes__c.split(';'));
    }

    private Boolean hasRecordTypeExclusions() {
        return settings.npo02__Household_Creation_Excluded_Recordtypes__c != null;
    }

    public Boolean isAdvancedHouseholdNaming() {
        return settings != null && settings.npo02__Advanced_Household_Naming__c == true;
    }

    public String getImplementingClass() {
        String implementingClass = namingSettings.Implementing_Class__c;
        return String.isBlank(implementingClass) ? defaultNamingService : implementingClass;
    }

    /*******************************************************************************************************
    * @description our cached copy of the Household Naming Settings
    */
    private Household_Naming_Settings__c namingSettings {
        get {
            if (namingSettings == null) {
                namingSettings =
                        UTIL_CustomSettingsFacade.getHouseholdNamingSettings();
            }
            return namingSettings;
        }
        set;
    }

}