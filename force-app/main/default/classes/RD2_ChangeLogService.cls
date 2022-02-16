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
* @group Recurring Donations
* @description All services specific to Recurring Donation Change Logs
*
*/
public inherited sharing class RD2_ChangeLogService {

    /***
    * @description Determines if Recurring Donation Change Log is enabled for the org
    */
    public static Boolean isChangeLogEnabled {
        get {
            if (isChangeLogEnabled == null) {
                isChangeLogEnabled = RD2_Settings.getInstance().isChangeLogEnabled();
            }
            return isChangeLogEnabled;
        }
        set;
    }

    @TestVisible
    private RD2_ChangeLogSelector changeLogSelector {
        get {
            if (changeLogSelector == null) {
                changeLogSelector = new RD2_ChangeLogSelector();
            }
            return changeLogSelector;
        }
        set;
    }

    public RD2_ChangeLogView getChangeLogView(Id recurringDonationId, Integer recordLimit, String changeTypeFilter) {
        if(!UTIL_Permissions.canRead(String.valueOf(RecurringDonationChangeLog__c.SObjectType), false)) {
            throw new UTIL_Permissions.InsufficientPermissionException(Label.commonPermissionErrorMessage);
        }

        Integer limitPlusOne = recordLimit + 1;
        changeLogSelector.withRecordLimit(limitPlusOne);

        if (changeTypeFilter != null) {
            changeLogSelector.withChangeTypeFilter(changeTypeFilter);
        }

        List<RecurringDonationChangeLog__c> changes = changeLogSelector.getChangeLogEntries(recurringDonationId);
        RD2_ChangeLogView changeLogView = buildView(changes, recordLimit);

        return changeLogView;
    }

    private RD2_ChangeLogView buildView(List<RecurringDonationChangeLog__c> changes, Integer recordLimit) {
        RD2_ChangeLogView changeLogView = new RD2_ChangeLogView();

        changeLogView.settingEnabled = isChangeLogEnabled;
        changeLogView.rd2Enabled = RD2_EnablementService.isRecurringDonations2Enabled;
        changeLogView.hasMore = changes.size() > recordLimit;

        for (Integer i = 0; i < recordLimit && i < changes.size(); i++) {
            RD2_ChangeLog change = new RD2_ChangeLog(changes[i]);
            changeLogView.changes.add(change.getChangeView());
        }

        return changeLogView;
    }

    /***
    * @description Recurring Donation Change Log service instance
    */
    private ChangeLogCreator changeLogCreator {
        get {
            if (changeLogCreator == null) {
                changeLogCreator = new ChangeLogCreator();
            }
            return changeLogCreator;
        }
        set;
    }

    private List<RecurringDonationChangeLog__c> changeLogs = 
        new List<RecurringDonationChangeLog__c>();

    /**
     * @description Returns true if any of the key fields used to create Change Logs have been changed.
     * @param updatedRd Changed Recurring Donation
     * @param originalRd Old Recurring Donation
     * @return Boolean
     */
    public void handleLogFieldChanged(RD2_RecurringDonation updatedRd, RD2_RecurringDonation originalRd) {
        RecurringDonationChangeLog__c changeLog = 
            new ChangeLogComparer(updatedRd, originalRd).setChangedFields();

        if (changeLog != null) {
            changeLogs.add(changeLog);
        }
    }

    @TestVisible
    private List<RecurringDonationChangeLog__c> getChangeLogRecords() {
        return changeLogs;
    }

    public void insertChangeLogRecords(){
        if (changeLogs.size() > 0) {
            changeLogCreator.insertChangeLogRecords(getChangeLogRecords());
        }
    }

    /***
    * @description Class used to group New and Previous field names for Recurring Donation Change Logs
    */
    private class ChangeLogFieldSet {
        ChangeLogFieldSet(SObjectField newField, SObjectField previousField) {
            this.newField = newField;
            this.previousField = previousField;
        }

        SObjectField newField;
        SObjectField previousField;
    }

    /***
    * @description Class used to compare Recurring Donation fields, and return a Change Log record
    * if relevant changes were made
    */
    private class ChangeLogComparer {

        private final SObjectField RD_AMOUNT_FIELD = npe03__Recurring_Donation__c.npe03__Amount__c;
        private final SObjectField RD_INSTALLMENT_PERIOD_FIELD = npe03__Recurring_Donation__c.npe03__Installment_Period__c;
        private final SObjectField RD_INSTALLMENT_FREQUENCY_FIELD = npe03__Recurring_Donation__c.InstallmentFrequency__c;
        private final SObjectField RD_STATUS_FIELD = npe03__Recurring_Donation__c.Status__c;
        private final SObjectField RD_STATUS_REASON_FIELD = npe03__Recurring_Donation__c.ClosedReason__c;
        private final SObjectField RD_PAYMENT_METHOD_FIELD = npe03__Recurring_Donation__c.PaymentMethod__c;
        private final SObjectField RD_CAMPAIGN_FIELD = npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c;
        private final SObjectField RD_RECURRING_TYPE_FIELD = npe03__Recurring_Donation__c.RecurringType__c;
        private final SObjectField RD_PLANNED_INSTALLMENTS_FIELD = npe03__Recurring_Donation__c.npe03__Installments__c;

        private final Map<SObjectField, ChangeLogFieldSet> rd2ChangeLogFields = new Map<SObjectField, ChangeLogFieldSet>{
            RD_AMOUNT_FIELD => new ChangeLogFieldSet(RecurringDonationChangeLog__c.NewAmount__c, 
                RecurringDonationChangeLog__c.PreviousAmount__c),
            RD_INSTALLMENT_PERIOD_FIELD => new ChangeLogFieldSet(RecurringDonationChangeLog__c.NewInstallmentPeriod__c, 
                RecurringDonationChangeLog__c.PreviousInstallmentPeriod__c),
            RD_INSTALLMENT_FREQUENCY_FIELD => new ChangeLogFieldSet(RecurringDonationChangeLog__c.NewInstallmentFrequency__c, 
                RecurringDonationChangeLog__c.PreviousInstallmentFrequency__c),
            RD_STATUS_FIELD => new ChangeLogFieldSet(RecurringDonationChangeLog__c.NewStatus__c, 
                RecurringDonationChangeLog__c.PreviousStatus__c),
            RD_STATUS_REASON_FIELD => new ChangeLogFieldSet(RecurringDonationChangeLog__c.NewStatusReason__c, 
                RecurringDonationChangeLog__c.PreviousStatusReason__c),
            RD_PAYMENT_METHOD_FIELD => new ChangeLogFieldSet(RecurringDonationChangeLog__c.NewPaymentMethod__c, 
                RecurringDonationChangeLog__c.PreviousPaymentMethod__c),
            RD_CAMPAIGN_FIELD => new ChangeLogFieldSet(RecurringDonationChangeLog__c.NewCampaign__c, 
                RecurringDonationChangeLog__c.PreviousCampaign__c),
            RD_RECURRING_TYPE_FIELD => new ChangeLogFieldSet(RecurringDonationChangeLog__c.NewRecurringType__c, 
                RecurringDonationChangeLog__c.PreviousRecurringType__c),
            RD_PLANNED_INSTALLMENTS_FIELD => new ChangeLogFieldSet(RecurringDonationChangeLog__c.NewPlannedInstallments__c, 
                RecurringDonationChangeLog__c.PreviousPlannedInstallments__c)
        };

        RD2_RecurringDonation updatedRd;
        RD2_RecurringDonation originalRd;

        /***
        * @description Constructor to store the Recurring Donations being compared
        * @param updatedRd Changed Recurring Donation, used for "New" fields
        * @param originalRd Old Recurring Donation, used for "Previous" fields
        */
        public ChangeLogComparer(RD2_RecurringDonation updatedRd, 
            RD2_RecurringDonation originalRd) {
                this.updatedRd = updatedRd;
                this.originalRd = originalRd;
        }

        /**
         * @description Returns a Recurring Donation Change Log record with Previous and New values 
         * filled in based on the Recurring Donations provided.
         * @return RecurringDonationChangeLog__c The Change Log record to represent this change
         */
        public RecurringDonationChangeLog__c setChangedFields() {

            RecurringDonationChangeLog__c changeLog;

            for (SObjectField rdField : rd2ChangeLogFields.keySet()) {
                if (isFieldChanged(rdField)) {

                    if (changeLog == null) {
                        changeLog = initChangeLogRecord();
                    }

                    changeLog.put(rd2ChangeLogFields.get(rdField).previousField, 
                        originalRd.getValue(rdField));
                    changeLog.put(rd2ChangeLogFields.get(rdField).newField, 
                        updatedRd.getValue(rdField));
                }
            }

            return changeLog;
        }

        /**
         * @description Returns a Recurring Donation Change Log record with required and default
         * values filled in.
         * @return RecurringDonationChangeLog__c A new Change Log record
         */
        public RecurringDonationChangeLog__c initChangeLogRecord() {

            String changeType = calculateChangeType();

            RecurringDonationChangeLog__c changeLog = new RecurringDonationChangeLog__c(
                RecurringDonation__c = (Id)updatedRd.getValue(npe03__Recurring_Donation__c.Id),
                EffectiveDate__c = (Date)updatedRd.getValue(npe03__Recurring_Donation__c.StartDate__c),
                NewAmount__c = (Decimal)updatedRd.getValue(RD_AMOUNT_FIELD),
                PreviousAmount__c = (Decimal)originalRd.getValue(RD_AMOUNT_FIELD),
                NewAnnualValue__c = updatedRd.getAnnualValue(),
                PreviousAnnualValue__c = originalRd.getAnnualValue(),
                NewExpectedTotalValue__c = updatedRd.getExpectedTotalValue(),
                PreviousExpectedTotalValue__c = originalRd.getExpectedTotalValue(),
                ChangeType__c = changeType
            );

            if (UserInfo.isMultiCurrencyOrganization()) {
                changeLog.put('CurrencyIsoCode', updatedRd.getCurrencyIsoCode());
            }

            return changeLog;
        }

        /**
         * @description Returns a Change Type, based on a User entered value, or calculated from
         * a change in the Annual or Total Expected Value of the Recurring Donation.
         * Automatic calculation is ignored if the Recurring Type was changed.
         * @param updatedRd Changed Recurring Donation
         * @param originalRd Old Recurring Donation
         * @return String The Change Type for this Change Log record
         */
        private String calculateChangeType() {

            String changeType = updatedRd.getChangeType();
            if (changeType != null) {
                return changeType;
            } else if (isFieldChanged(RD_RECURRING_TYPE_FIELD)) {
                return null;
            }

            Decimal newValue = updatedRd.isOpenEnded() ? updatedRd.getAnnualValue() 
                : updatedRd.getExpectedTotalValue();
            Decimal previousValue = originalRd.isOpenEnded() ? originalRd.getAnnualValue()
                : originalRd.getExpectedTotalValue();

            if (newValue > previousValue) {
                changeType = RD2_Constants.CHANGE_TYPE_UPGRADE;
            } else if (newValue < previousValue) {
                changeType = RD2_Constants.CHANGE_TYPE_DOWNGRADE;
            }

            return changeType;
        }

        /**
        * @description Return true if the value of the provided field is different between these
        * Recurring Donations
        * @param rdField SObjectField to get the value for
        * @return Boolean
        */
        public Boolean isFieldChanged(SObjectField rdField){
            return updatedRd.getValue(rdField) != originalRd.getValue(rdField);
        }

    }

    /***
    * @description Class used for DML operations relating to Recurring Donation Change Logs.
    * To ensure these operations succeed regardless of User permissions, this Class uses without sharing
    */
    private without sharing class ChangeLogCreator {

        /**
         * @description Inserts the provided Change Log records, without allowing partial success
         * @param changeLogs A List of Change Log records to insert, regardless of permissions
         */
        public void insertChangeLogRecords(List<RecurringDonationChangeLog__c> changeLogs){
            UTIL_DMLService.insertRecords(changeLogs);
        }

    }

}
