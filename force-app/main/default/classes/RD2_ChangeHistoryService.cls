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

    /***
    * @description Determines if Change History is enabled for the org
    */
    public Boolean isChangeHistoryEnabled {
        get {
            if (isChangeHistoryEnabled == null) {
                isChangeHistoryEnabled = new RD2_Settings().isChangeHistoryEnabled();
            }
            return isChangeHistoryEnabled;
        }
        set;
    }

    /***
    * @description Instance of ChangeHistoryCreator to create Change History without sharing
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
        RecurringDonationChangeHistory__c changeHistory;

        changeHistory = changeHistoryCreator.setChangedFields(changeHistory, updatedRd, originalRd);

        if (changeHistory != null) {
            changeHistoryList.add(changeHistory);
        }
    }

    public List<RecurringDonationChangeHistory__c> getChangeHistoryRecords(){
        return changeHistoryList;
    }

    public void insertChangeHistoryRecords(){
        if (changeHistoryList.size() > 0) {
            changeHistoryCreator.insertChangeHistoryRecords(getChangeHistoryRecords());
        }
    }

    private class ChangeHistoryFieldSet {
        ChangeHistoryFieldSet(SObjectField newField, SObjectField previousField) {
            this.newField = newField;
            this.previousField = previousField;
        }

        SObjectField newField;
        SObjectField previousField;
    }

    private without sharing class ChangeHistoryCreator {

        private final SObjectField rdAmountField = npe03__Recurring_Donation__c.npe03__Amount__c;
        private final SObjectField rdInstallmentPeriodField = npe03__Recurring_Donation__c.npe03__Installment_Period__c;
        private final SObjectField rdInstallmentFrequencyField = npe03__Recurring_Donation__c.InstallmentFrequency__c;
        private final SObjectField rdStatusField = npe03__Recurring_Donation__c.Status__c;
        private final SObjectField rdStatusReasonField = npe03__Recurring_Donation__c.ClosedReason__c;
        private final SObjectField rdPaymentMethodField = npe03__Recurring_Donation__c.PaymentMethod__c;
        private final SObjectField rdCampaignField = npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c;    

        private final Map<SObjectField, ChangeHistoryFieldSet> rd2ChangeHistoryFields = new Map<SObjectField, ChangeHistoryFieldSet>{
            rdAmountField => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewAmount__c, 
                RecurringDonationChangeHistory__c.PreviousAmount__c),
            rdInstallmentPeriodField => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewInstallmentPeriod__c, 
                RecurringDonationChangeHistory__c.PreviousInstallmentPeriod__c),
            rdInstallmentFrequencyField => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewInstallmentFrequency__c, 
                RecurringDonationChangeHistory__c.PreviousInstallmentFrequency__c),
            rdStatusField => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewStatus__c, 
                RecurringDonationChangeHistory__c.PreviousStatus__c),
            rdStatusReasonField => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewStatusReason__c, 
                RecurringDonationChangeHistory__c.PreviousStatusReason__c),
            rdPaymentMethodField => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewPaymentMethod__c, 
                RecurringDonationChangeHistory__c.PreviousPaymentMethod__c),
            rdCampaignField => new ChangeHistoryFieldSet(RecurringDonationChangeHistory__c.NewCampaign__c, 
                RecurringDonationChangeHistory__c.PreviousCampaign__c)
        };

        public RecurringDonationChangeHistory__c setChangedFields(RecurringDonationChangeHistory__c changeHistory,
            RD2_RecurringDonation updatedRd, RD2_RecurringDonation originalRd) {

                for (SObjectField rdField : rd2ChangeHistoryFields.keySet()) {
                    if (updatedRd.fieldChanged(rdField, originalRd)) {
                        
                        if (changeHistory == null) {
                            changeHistory = initChangeHistoryRecord(updatedRd, originalRd);
                        }

                        changeHistory.put(rd2ChangeHistoryFields.get(rdField).newField, 
                            updatedRd.getValue(rdField));
                        changeHistory.put(rd2ChangeHistoryFields.get(rdField).previousField, 
                            originalRd.getValue(rdField));
                    }
                }

                return changeHistory;
        }

        public RecurringDonationChangeHistory__c initChangeHistoryRecord(RD2_RecurringDonation updatedRd, 
            RD2_RecurringDonation originalRd){

                return new RecurringDonationChangeHistory__c(
                    RecurringDonation__c = (Id)updatedRd.getValue(npe03__Recurring_Donation__c.Id),
                    EffectiveDate__c = (Date)updatedRd.getValue(npe03__Recurring_Donation__c.StartDate__c),
                    NewAmount__c = (Decimal)updatedRd.getValue(rdAmountField),
                    PreviousAmount__c = (Decimal)originalRd.getValue(rdAmountField),
                    NewAnnualValue__c = updatedRd.getAnnualValue(),
                    PreviousAnnualValue__c = originalRd.getAnnualValue()
                );
        }

        public void insertChangeHistoryRecords(List<RecurringDonationChangeHistory__c> changeHistoryList){
            insert changeHistoryList;
        }

    }

}
