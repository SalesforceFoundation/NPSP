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
* @description All services specific to Recurring Donation Change History
*
*/
public inherited sharing class RD2_ChangeHistoryService {

    public static final String CHANGE_TYPE_UPGRADE = 'Upgrade';
    public static final String CHANGE_TYPE_DOWNGRADE = 'Downgrade';

    /***
    * @description Determines if Change History is enabled for the org
    */
    public static Boolean isChangeHistoryEnabled {
        get {
            if (isChangeHistoryEnabled == null) {
                isChangeHistoryEnabled = new RD2_Settings().isChangeHistoryEnabled();
            }
            return isChangeHistoryEnabled;
        }
        set;
    }

    @TestVisible
    private RD2_ChangeHistorySelector changeHistorySelector {
        get {
            if (changeHistorySelector == null) {
                changeHistorySelector = new RD2_ChangeHistorySelector();
            }
            return changeHistorySelector;
        }
        set;
    }

    public RD2_ChangeHistoryView getChangeHistoryView(Id recurringDonationId, Integer recordLimit, String changeTypeFilter) {
        if(!UTIL_Permissions.canRead(String.valueOf(RecurringDonationChangeHistory__c.SObjectType))) {
            throw new UTIL_Permissions.InsufficientPermissionException(Label.commonPermissionErrorMessage);
        }

        Integer limitPlusOne = recordLimit + 1;
        changeHistorySelector.withRecordLimit(limitPlusOne);

        if (changeTypeFilter != null) {
            changeHistorySelector.withChangeTypeFilter(changeTypeFilter);
        }

        List<RecurringDonationChangeHistory__c> changes = changeHistorySelector.getChangeHistories(recurringDonationId);
        RD2_ChangeHistoryView changeHistoryView = buildView(changes, recordLimit);

        return changeHistoryView;
    }

    private RD2_ChangeHistoryView buildView(List<RecurringDonationChangeHistory__c> changes, Integer recordLimit) {
        RD2_ChangeHistoryView changeHistoryView = new RD2_ChangeHistoryView();

        changeHistoryView.settingEnabled = isChangeHistoryEnabled;
        changeHistoryView.rd2Enabled = RD2_EnablementService.isRecurringDonations2Enabled;
        changeHistoryView.hasMore = changes.size() > recordLimit;

        for (Integer i = 0; i < recordLimit && i < changes.size(); i++) {
            RD2_ChangeHistory change = new RD2_ChangeHistory(changes[i]);
            changeHistoryView.changes.add(change.getChangeView());
        }

        return changeHistoryView;
    }

    /***
    * @description Recurring Donation change history service instance
    */
    private ChangeHistoryCreator changeHistoryCreator {
        get {
            if (changeHistoryCreator == null) {
                changeHistoryCreator = new ChangeHistoryCreator();
            }
            return changeHistoryCreator;
        }
        set;
    }

    private List<RecurringDonationChangeHistory__c> changeHistoryList = 
        new List<RecurringDonationChangeHistory__c>();

    /**
     * @description Returns true if any of the key fields used to create Change History has been changed.
     * @param updatedRd Changed Recurring Donation
     * @param originalRd Old Recurring Donation
     * @return Boolean
     */
    public void handleHistoryFieldChanged(RD2_RecurringDonation updatedRd, RD2_RecurringDonation originalRd) {
        RecurringDonationChangeHistory__c changeHistory = 
            new ChangeHistoryComparer(updatedRd, originalRd).setChangedFields();

        if (changeHistory != null) {
            changeHistoryList.add(changeHistory);
        }
    }

    @TestVisible
    private List<RecurringDonationChangeHistory__c> getChangeHistoryRecords() {
        return changeHistoryList;
    }

    public void insertChangeHistoryRecords(){
        if (changeHistoryList.size() > 0) {
            changeHistoryCreator.insertChangeHistoryRecords(getChangeHistoryRecords());
        }
    }

    /***
    * @description Class used to group New and Previous field names for Recurring Donation Change History
    */
    private class ChangeHistoryFieldSet {
        ChangeHistoryFieldSet(SObjectField newField, SObjectField previousField) {
            this.newField = newField;
            this.previousField = previousField;
        }

        SObjectField newField;
        SObjectField previousField;
    }

    /***
    * @description Class used to compare Recurring Donation fields, and return a Change History record
    * if relevant changes were made
    */
    private class ChangeHistoryComparer {

        private final SObjectField RD_AMOUNT_FIELD = npe03__Recurring_Donation__c.npe03__Amount__c;
        private final SObjectField RD_INSTALLMENT_PERIOD_FIELD = npe03__Recurring_Donation__c.npe03__Installment_Period__c;
        private final SObjectField RD_INSTALLMENT_FREQUENCY_FIELD = npe03__Recurring_Donation__c.InstallmentFrequency__c;
        private final SObjectField RD_STATUS_FIELD = npe03__Recurring_Donation__c.Status__c;
        private final SObjectField RD_STATUS_REASON_FIELD = npe03__Recurring_Donation__c.ClosedReason__c;
        private final SObjectField RD_PAYMENT_METHOD_FIELD = npe03__Recurring_Donation__c.PaymentMethod__c;
        private final SObjectField RD_CAMPAIGN_FIELD = npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c;

        private final Map<SObjectField, ChangeHistoryFieldSet> rd2ChangeHistoryFields = new Map<SObjectField, ChangeHistoryFieldSet>{
            RD_AMOUNT_FIELD => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewAmount__c, 
                RecurringDonationChangeHistory__c.PreviousAmount__c),
            RD_INSTALLMENT_PERIOD_FIELD => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewInstallmentPeriod__c, 
                RecurringDonationChangeHistory__c.PreviousInstallmentPeriod__c),
            RD_INSTALLMENT_FREQUENCY_FIELD => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewInstallmentFrequency__c, 
                RecurringDonationChangeHistory__c.PreviousInstallmentFrequency__c),
            RD_STATUS_FIELD => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewStatus__c, 
                RecurringDonationChangeHistory__c.PreviousStatus__c),
            RD_STATUS_REASON_FIELD => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewStatusReason__c, 
                RecurringDonationChangeHistory__c.PreviousStatusReason__c),
            RD_PAYMENT_METHOD_FIELD => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewPaymentMethod__c, 
                RecurringDonationChangeHistory__c.PreviousPaymentMethod__c),
            RD_CAMPAIGN_FIELD => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewCampaign__c, 
                RecurringDonationChangeHistory__c.PreviousCampaign__c)
        };

        RD2_RecurringDonation updatedRd;
        RD2_RecurringDonation originalRd;

        /***
        * @description Constructor to store the Recurring Donations being compared
        * @param updatedRd Changed Recurring Donation, used for "New" fields
        * @param originalRd Old Recurring Donation, used for "Previous" fields
        */
        public ChangeHistoryComparer(RD2_RecurringDonation updatedRd, 
            RD2_RecurringDonation originalRd) {
                this.updatedRd = updatedRd;
                this.originalRd = originalRd;
        }

        /**
         * @description Returns a Recurring Donation Change History record with Previous and New values 
         * filled in based on the Recurring Donations provided.
         * @return RecurringDonationChangeHistory__c The Change History record to represent this change
         */
        public RecurringDonationChangeHistory__c setChangedFields() {

            RecurringDonationChangeHistory__c changeHistory;

            for (SObjectField rdField : rd2ChangeHistoryFields.keySet()) {
                if (isFieldChanged(rdField)) {

                    if (changeHistory == null) {
                        changeHistory = initChangeHistoryRecord();
                    }

                    changeHistory.put(rd2ChangeHistoryFields.get(rdField).previousField, 
                        originalRd.getValue(rdField));
                    changeHistory.put(rd2ChangeHistoryFields.get(rdField).newField, 
                        updatedRd.getValue(rdField));
                }
            }

            return changeHistory;
        }

        /**
         * @description Returns a Recurring Donation Change History record with required and default
         * values filled in.
         * @return RecurringDonationChangeHistory__c A new Change History record
         */
        public RecurringDonationChangeHistory__c initChangeHistoryRecord() {

            String changeType = calculateChangeType();

            RecurringDonationChangeHistory__c rdChangeHistory = new RecurringDonationChangeHistory__c(
                RecurringDonation__c = (Id)updatedRd.getValue(npe03__Recurring_Donation__c.Id),
                EffectiveDate__c = (Date)updatedRd.getValue(npe03__Recurring_Donation__c.StartDate__c),
                NewAmount__c = (Decimal)updatedRd.getValue(RD_AMOUNT_FIELD),
                PreviousAmount__c = (Decimal)originalRd.getValue(RD_AMOUNT_FIELD),
                NewAnnualValue__c = updatedRd.getAnnualValue(),
                PreviousAnnualValue__c = originalRd.getAnnualValue(),
                ChangeType__c = changeType
            );

            if (UserInfo.isMultiCurrencyOrganization()) {
                rdChangeHistory.put('CurrencyIsoCode', updatedRd.getCurrencyIsoCode());
            }

            return rdChangeHistory;
        }

        /**
         * @description Returns a Change Type, based on a User entered value, or calculated from
         * an change in the Annual Value of the Recurring Donation.
         * @param updatedRd Changed Recurring Donation
         * @param originalRd Old Recurring Donation
         * @return String The Change Type for this Change History record
         */
        private String calculateChangeType() {

            String changeType = updatedRd.getChangeType();
            if (changeType != null) {
                return changeType;
            }

            Decimal newAnnualValue = updatedRd.getAnnualValue();
            Decimal previousAnnualValue = originalRd.getAnnualValue();

            if (newAnnualValue > previousAnnualValue) {
                changeType = RD2_ChangeHistoryService.CHANGE_TYPE_UPGRADE;
            } else if (newAnnualValue < previousAnnualValue) {
                changeType = RD2_ChangeHistoryService.CHANGE_TYPE_DOWNGRADE;
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
    * @description Class used for DML operations relating to Recurring Donation Change History.
    * To ensure these operations succeed regardless of User permissions, this Class uses without sharing
    */
    private without sharing class ChangeHistoryCreator {

        /**
         * @description Inserts the provided Change History records, without allowing partial success
         * @param changeHistoryList A List of Change History records to insert, regardless of permissions
         */
        public void insertChangeHistoryRecords(List<RecurringDonationChangeHistory__c> changeHistoryList){
            UTIL_DMLService.insertRecords(changeHistoryList);
        }

    }

}
