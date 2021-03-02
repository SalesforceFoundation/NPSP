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
* @description Domain class for Households in NPSP.
*/
public inherited sharing class Households extends fflib_SObjects {

    private Map<Id, npo02__Household__c> oldMap;
    @TestVisible
    private HouseholdNamingService householdNamingService {
        get {
            if (householdNamingService == null) {
                householdNamingService = new HouseholdNamingService();
            }
            return householdNamingService;
        }
        set;
    }
    @TestVisible
    private HouseholdSettings settings {
        get {
            if (settings == null) {
                settings = new HouseholdSettings();
            }
            return settings;
        }
        set;
    }

    public Households(Set<Id> ids) {
        this(getHouseholdsById(ids), null);
    }

    private static List<npo02__Household__c> getHouseholdsById(Set<Id> ids) {
        return [
                SELECT Id, (
                        SELECT Id
                        FROM npo02__Contacts__r
                )
                FROM npo02__Household__c
                WHERE Id IN :ids
        ];
    }

    public Map<Id, Integer> getHouseholdCountMap() {
        Map<Id, Integer> householdCountMap = new Map<Id, Integer>();
        for (npo02__Household__c household : (List<npo02__Household__c>) getRecords()) {
            householdCountMap.put(household.Id, household.npo02__Contacts__r.size());
        }
        return householdCountMap;
    }

    public Households(List<npo02__Household__c> records, List<npo02__Household__c> oldlist) {
        super(records, npo02__Household__c.SObjectType);
        oldMap = oldlist == null ? new Map<Id, npo02__Household__c>() : new Map<Id,
                npo02__Household__c>(oldlist);
    }

    public void onBeforeUpdate() {
        if (!isHouseholdTriggerContext() && isAdvancedHouseholdNamingEnabled()) {
            setCustomNamingField();
            setNameAndGreetingsToReplacementText();
        }
    }

    private void setNameAndGreetingsToReplacementText() {
        householdNamingService.setNameAndGreetingsToReplacementText(getRecords());
    }

    private void setCustomNamingField() {
        householdNamingService.setCustomNamingField(getRecords(), oldMap);
    }

    private Boolean isAdvancedHouseholdNamingEnabled() {
        return settings.isAdvancedHouseholdNaming();
    }

    public void onAfterUpdate() {
        if (!isHouseholdTriggerContext() && isAdvancedHouseholdNamingEnabled()) {
            renameHouseholdAccountsNeedingNameUpdates();
        }
    }

    private void renameHouseholdAccountsNeedingNameUpdates() {
        householdNamingService.renameHouseholdAccounts(getHouseholdsNeedingNameUpdates());
    }

    private List<Id> getHouseholdsNeedingNameUpdates() {
        List<Id> householdsNeedingNameUpdates =
                householdNamingService.getHouseholdsNeedingNameUpdates(
                        getRecords(), oldMap
                );
        return householdsNeedingNameUpdates;
    }

    private Boolean isHouseholdTriggerContext() {
        return TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.HH);
    }

}