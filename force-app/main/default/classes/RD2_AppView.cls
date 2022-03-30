/*
 *
 *     Copyright (c) 2022, Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 */
/**
* @author Salesforce.org
* @date 2022
* @description Main View class for the Recurring Donations App
*/
public class RD2_AppView {
    @AuraEnabled public Boolean isAutoNamingEnabled;
    @AuraEnabled public Boolean isMultiCurrencyEnabled;
    @AuraEnabled public String parentSObjectType;
    @AuraEnabled public Map<String, Boolean> InstallmentPeriodPermissions;
    @AuraEnabled public Map<String, Boolean> InstallmentFrequencyPermissions;
    @AuraEnabled public List<InputFieldView> customFieldSets;
    @AuraEnabled public Boolean isElevateCustomer;
    @AuraEnabled public Boolean isChangeLogEnabled;
    @AuraEnabled public Map<String, Integer> periodToYearlyFrequencyMap;
    @AuraEnabled public List<String> closedStatusValues;
    @AuraEnabled public String defaultDayOfMonth;
    @AuraEnabled public String defaultRecurringType;
    @AuraEnabled public String defaultInstallmentPeriod;
    @AuraEnabled public List<Map<String, String>> installmentPeriodOptions;
    @AuraEnabled public Id parentId;
    @AuraEnabled public Boolean hasRequiredPermissions;

    @AuraEnabled public RD2_RecordView record;


    public RD2_AppView() {
        this.record = new RD2_RecordView();
    }

    public void withRecord(npe03__Recurring_Donation__c record) {
        this.record = new RD2_RecordView(record);
        this.populateCustomFieldValues(record);
    }

    public void withParentId(Id parentId) {
        this.record = new RD2_RecordView();
        SObjectType parentSobjectType = parentId.getSobjectType();
        if(parentSobjectType == Account.SObjectType) {
            this.record.accountId = parentId;
            this.record.donorType = RD2_Constants.DONOR_TYPE_ACCOUNT;
        } else if(parentSobjectType == Contact.SObjectType) {
            this.record.contactId = parentId;
            this.record.donorType = RD2_Constants.DONOR_TYPE_CONTACT;
        }
    }

    private void populateCustomFieldValues(npe03__Recurring_Donation__c record) {
        for(InputFieldView f : this.customFieldSets) {
            Object val = record.get(f.apiName);
            f.value = val;
        }
    }

    public void setRecordCreateDefaults() {
        if (this.defaultInstallmentPeriod != null && this.record.recurringPeriod == null) {
            this.record.recurringPeriod = this.defaultInstallmentPeriod;
        }

        if (this.defaultRecurringType != null && this.record.recurringType == null) {
            this.record.recurringType = this.defaultRecurringType;
        }

        if (this.defaultDayOfMonth != null && this.record.dayOfMonth == null) {
            this.record.dayOfMonth = this.defaultDayOfMonth;
        } else if (this.record.dayOfMonth == null) {
            String currentDay = String.valueOf(Date.today().day());
            this.record.dayOfMonth = currentDay == '31' ? RD2_Constants.DAY_OF_MONTH_LAST_DAY : currentDay;
        }
    }
}