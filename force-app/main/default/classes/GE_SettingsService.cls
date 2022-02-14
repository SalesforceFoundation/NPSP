/*
    Copyright (c) 2022 Salesforce.org
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
* @date 2022
* @group Gift Entry
* @description Gift Entry Settings Service
*
*/
public with sharing class GE_SettingsService {

    private static GE_SettingsService geSettingsServiceInstance;

    public static GE_SettingsService getInstance() {
        if (geSettingsServiceInstance == null) {
            geSettingsServiceInstance = new GE_SettingsService();
        }
        return geSettingsServiceInstance;
    }

    @TestVisible
    private static void setInstance(GE_SettingsService instance) {
        geSettingsServiceInstance = instance;
    }

    public Boolean isRecurringGiftsEnabled() {
        AdvancedMappingEnablementService advancedMappingEnablementService = new AdvancedMappingEnablementService();
        GiftEntryEnablementService giftEntryEnablementService = new GiftEntryEnablementService();

        return advancedMappingEnablementService.isEnabled()
            && giftEntryEnablementService.isEnabled()
            && RD2_EnablementService.getInstance().isRecurringDonations2Enabled()
            && canAccessRecurringDonationFields();
    }

    public Boolean canMakeGiftsRecurring() {
        try {
            fflib_SecurityUtils.checkFieldIsUpdateable(DataImportBatch__c.SObjectType,
                DataImportBatch__c.SObjectType.fields.Allow_Recurring_Donations__c);
        } catch (fflib_SecurityUtils.SecurityException e) {
            return false;
        }
        return true;
    }

    private Boolean canAccessRecurringDonationFields() {
        List<SObjectField> giftScheduleFieldApiNames = new List<Schema.SObjectField>{
            DataImport__c.SObjectType.fields.Recurring_Donation_Recurring_Type__c,
            DataImport__c.SObjectType.fields.Recurring_Donation_Date_Established__c,
            DataImport__c.SObjectType.fields.Recurring_Donation_Day_of_Month__c,
            DataImport__c.SObjectType.fields.Recurring_Donation_Planned_Installments__c,
            DataImport__c.SObjectType.fields.Recurring_Donation_Installment_Period__c,
            DataImport__c.SObjectType.fields.Recurring_Donation_Installment_Frequency__c,
            DataImport__c.SObjectType.fields.Recurring_Donation_Effective_Date__c,
            DataImport__c.SObjectType.fields.Recurring_Donation_Amount__c,
            DataImport__c.SObjectType.fields.Recurring_Donation_End_Date__c,
            DataImport__c.SObjectType.fields.Donation_Amount__c,
            DataImport__c.SObjectType.fields.Donation_Date__c
        };

        try {
            fflib_SecurityUtils.checkRead(DataImportBatch__c.SObjectType, giftScheduleFieldApiNames);
            fflib_SecurityUtils.checkUpdate(DataImportBatch__c.SObjectType, giftScheduleFieldApiNames);
        } catch (fflib_SecurityUtils.SecurityException e) {
            return false;
        }
        return true;
    }
}
