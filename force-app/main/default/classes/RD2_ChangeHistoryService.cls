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
public without sharing class RD2_ChangeHistoryService {

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

    SObjectField rdAmountField = npe03__Recurring_Donation__c.npe03__Amount__c;
    SObjectField rdInstallmentPeriodField = npe03__Recurring_Donation__c.npe03__Installment_Period__c;
    SObjectField rdInstallmentFrequencyField = npe03__Recurring_Donation__c.InstallmentFrequency__c;
    SObjectField rdStatusField = npe03__Recurring_Donation__c.Status__c;
    SObjectField rdStatusReasonField = npe03__Recurring_Donation__c.ClosedReason__c;
    SObjectField rdPaymentMethodField = npe03__Recurring_Donation__c.PaymentMethod__c;
    SObjectField rdCampaignField = npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c;

    private List<RecurringDonationChangeHistory__c> changeHistoryList = 
        new List<RecurringDonationChangeHistory__c>();

    private class ChangeHistoryFieldSet {
        ChangeHistoryFieldSet(SObjectField newField, SObjectField previousField) {
            this.newField = newField;
            this.previousField = previousField;
        }

        SObjectField newField;
        SObjectField previousField;
    }

    private Map<SObjectField, ChangeHistoryFieldSet> recurringDonationToChangeHistoryFields = new Map<SObjectField, ChangeHistoryFieldSet>{
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

    /**
     * @description Returns true if any of the key fields used to create Change History has been changed.
     * @param rd Changed Recurring Donation
     * @param oldRd Old Recurring Donation
     * @return Boolean
     */
    public void handleHistoryFieldChanged(RD2_RecurringDonation rd, RD2_RecurringDonation oldRd) {
        RecurringDonationChangeHistory__c rdch;

        for(SObjectField rdField : recurringDonationToChangeHistoryFields.keySet()){

            if(rd.fieldChanged(rdField, oldRd)){
                if(rdch == null){
                    rdch = returnChangeHistory(rd, oldRd);
                }

                rdch.put(recurringDonationToChangeHistoryFields.get(rdField).newField, 
                    rd.getValue(rdField));
                rdch.put(recurringDonationToChangeHistoryFields.get(rdField).previousField, 
                    oldRd.getValue(rdField));
            }
        }

        if(rdch != null){
            changeHistoryList.add(rdch);
        }

    }

    public List<RecurringDonationChangeHistory__c> getChangeHistoryRecords(){
        return changeHistoryList;
    }

    private RecurringDonationChangeHistory__c returnChangeHistory(RD2_RecurringDonation rd, 
        RD2_RecurringDonation oldRd){

        return new RecurringDonationChangeHistory__c(
            RecurringDonation__c = (Id)rd.getValue(npe03__Recurring_Donation__c.Id),
            EffectiveDate__c = (Date)rd.getValue(npe03__Recurring_Donation__c.StartDate__c),
            NewAmount__c = (Decimal)rd.getValue(rdAmountField),
            PreviousAmount__c = (Decimal)oldRd.getValue(rdAmountField),
            NewAnnualValue__c = rd.getAnnualValue(),
            PreviousAnnualValue__c = oldRd.getAnnualValue()
        );
    }

}
