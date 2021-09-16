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
public with sharing class RD2_ChangeLog {

    private RecurringDonationChangeLog__c record;

    private static final String changeLogSObjectName = String.valueOf(RecurringDonationChangeLog__c.SObjectType);

    public RD2_ChangeLog(RecurringDonationChangeLog__c record) {
        this.record = record;
    }

    public RD2_ChangeView getChangeView() {
        RD2_ChangeView view = new RD2_ChangeView();
        view.changeType = this.record.ChangeType__c;
        view.id = this.record.Id;

        if (this.record.NewStatusReason__c != null) {
            view.statusReason = this.record.NewStatusReason__c;
        }

        view.changeDate = this.record.EffectiveDate__c;
        view.fields = buildFieldChangeViews();

        return view;
    }

    private RD2_FieldChangeView getCampaignChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newId = this.record.NewCampaign__c;
        view.oldId = this.record.PreviousCampaign__c;
        view.newValue = this.record.NewCampaign__r.Name;
        view.oldValue = this.record.PreviousCampaign__r.Name;

        view.label = UTIL_Describe.getFieldLabel(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.npe03__Recurring_Donation_Campaign__c)
        );
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.LOOKUP);
        return view;
    }

    private RD2_FieldChangeView getAmountChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.oldValue = this.record.PreviousAmount__c;
        if (this.isAmountChanged()) {
            view.newValue = this.record.NewAmount__c;
        }
        view.label = UTIL_Describe.getFieldLabel(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.npe03__Amount__c)
        );
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.MONEY);
        if (UserInfo.isMultiCurrencyOrganization()) {
            view.currencyCode = (String)this.record.get('CurrencyIsoCode');
        }
        return view;
    }

    private RD2_FieldChangeView getAnnualValueChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.MONEY);

        handleDisplayWhenRecurringTypeChanges(view, String.valueOf(RecurringDonationChangeLog__c.NewAnnualValue__c),
                String.valueOf(RecurringDonationChangeLog__c.PreviousAnnualValue__c), Label.RDCL_Annual_Value);

        if (UserInfo.isMultiCurrencyOrganization()) {
            view.currencyCode = (String)this.record.get('CurrencyIsoCode');
        }
        return view;
    }

    private RD2_FieldChangeView getExpectedTotalValueChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.MONEY);

        handleDisplayWhenRecurringTypeChanges(view, String.valueOf(RecurringDonationChangeLog__c.NewExpectedTotalValue__c),
                String.valueOf(RecurringDonationChangeLog__c.PreviousExpectedTotalValue__c), Label.RDCL_Expected_Total_Value);

        if (UserInfo.isMultiCurrencyOrganization()) {
            view.currencyCode = (String)this.record.get('CurrencyIsoCode');
        }
        return view;
    }

    private RD2_FieldChangeView getStatusChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewStatus__c;
        view.oldValue = this.record.PreviousStatus__c;
        view.label = UTIL_Describe.getFieldLabel(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.Status__c)
        );
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.TEXT);
        return view;
    }

    private RD2_FieldChangeView getFrequencyChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewInstallmentFrequency__c;
        view.oldValue = this.record.PreviousInstallmentFrequency__c;
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.NUMERIC);
        view.label = Label.RDCL_Frequency;

        return view;
    }

    private RD2_FieldChangeView getPeriodChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewInstallmentPeriod__c;
        view.oldValue = this.record.PreviousInstallmentPeriod__c;
        view.label = Label.pmtWizardIntervalPeriod;
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.TEXT);
        return view;
    }

    private RD2_FieldChangeView getPlannedInstallmentsChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.NUMERIC);
        String plannedInstallmentsLabel = UTIL_Describe.getFieldLabel(
            'npe03__Recurring_Donation__c',
            String.valueOf(npe03__Recurring_Donation__c.npe03__Installments__c)
        );

        handleDisplayWhenRecurringTypeChanges(view, String.valueOf(RecurringDonationChangeLog__c.NewPlannedInstallments__c),
            String.valueOf(RecurringDonationChangeLog__c.PreviousPlannedInstallments__c), plannedInstallmentsLabel);

        return view;
    }

    private RD2_FieldChangeView getPaymentMethodChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewPaymentMethod__c;

        if (this.record.NewPaymentMethod__c != null) {
            view.newValue = this.record.NewPaymentMethod__c;
        } else {
            view.newValue = Label.stgLabelFieldValueNone;
        }

        if (this.record.PreviousPaymentMethod__c != null) {
            view.oldValue = this.record.PreviousPaymentMethod__c;
        } else {
            view.oldValue = Label.stgLabelFieldValueNone;
        }

        view.label = UTIL_Describe.getFieldLabel(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.PaymentMethod__c)
        );
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.TEXT);
        return view;
    }

    private RD2_FieldChangeView getRecurringTypeChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewRecurringType__c;
        view.oldValue = this.record.PreviousRecurringType__c;
        view.label = UTIL_Describe.getFieldLabel(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.RecurringType__c)
        );
        view.setDisplayType(RD2_FieldChangeView.DISPLAY_TYPE.TEXT);
        return view;
    }

    /***
    * @description Determines which Label to use when only one of New or Previous
    * is available. Only relevant when the Recurring Type changes.
    */
    private void handleDisplayWhenRecurringTypeChanges(RD2_FieldChangeView view, 
            String newField, String previousField, String defaultLabel){

        if (this.record.get(newField) == null) {
            view.oldValue = this.record.get(previousField);
            view.label = UTIL_Describe.getFieldLabel(changeLogSObjectName, previousField);
        } else if (this.record.get(previousField) == null) {
            view.oldValue = this.record.get(newField);
            view.label = UTIL_Describe.getFieldLabel(changeLogSObjectName, newField);
        } else {
            view.oldValue = this.record.get(previousField);
            if (this.record.get(newField) != this.record.get(previousField)) {
                view.newValue = this.record.get(newField);
            }
            view.label = defaultLabel;
        }
    }

    private List<RD2_FieldChangeView> buildFieldChangeViews() {
        List<RD2_FieldChangeView> fieldChanges = new List<RD2_FieldChangeView>();

        if (hasAmountPermissions()) {
            fieldChanges.add(getAmountChange());
        }

        if (isRecurringTypeChanged() && hasRecurringTypePermissions()) {
            fieldChanges.add(getRecurringTypeChange());
        }

        if (hasAnnualValue() && hasAnnualValuePermissions()) {
            fieldChanges.add(getAnnualValueChange());
        }

        if (hasExpectedTotalValue() && hasExpectedTotalValuePermissions()) {
            fieldChanges.add(getExpectedTotalValueChange());
        }

        if (isCampaignChanged() && hasCampaignPermissions()) {
            fieldChanges.add(getCampaignChange());
        }

        if (isStatusChanged() && hasStatusPermissions()) {
            fieldChanges.add(getStatusChange());
        }

        if (isFrequencyChanged() && hasFrequencyPermissions()) {
            fieldChanges.add(getFrequencyChange());
        }

        if (isPeriodChanged() && hasPeriodPermissions()) {
            fieldChanges.add(getPeriodChange());
        }

        if (isPlannedInstallmentsChanged() && hasPlannedInstallmentsPermissions()) {
            fieldChanges.add(getPlannedInstallmentsChange());
        }

        if (isPaymentMethodChanged() && hasPaymentPermissions()) {
            fieldChanges.add(getPaymentMethodChange());
        }

        return fieldChanges;
    }

    private Boolean hasAnnualValuePermissions() {
        return canReadChangeLogFields(RecurringDonationChangeLog__c.NewAnnualValue__c,
                RecurringDonationChangeLog__c.PreviousAnnualValue__c);
    }

    private Boolean hasExpectedTotalValuePermissions() {
        return canReadChangeLogFields(RecurringDonationChangeLog__c.NewExpectedTotalValue__c,
                RecurringDonationChangeLog__c.PreviousExpectedTotalValue__c);
    }

    private Boolean hasAmountPermissions() {
        return canReadChangeLogFields(RecurringDonationChangeLog__c.PreviousAmount__c,
                RecurringDonationChangeLog__c.NewAmount__c);
    }

    private Boolean hasPaymentPermissions() {
        return canReadChangeLogFields(RecurringDonationChangeLog__c.PreviousPaymentMethod__c,
                RecurringDonationChangeLog__c.NewPaymentMethod__c);
    }

    private Boolean hasPlannedInstallmentsPermissions() {
        return canReadChangeLogFields(RecurringDonationChangeLog__c.NewPlannedInstallments__c,
                RecurringDonationChangeLog__c.PreviousPlannedInstallments__c);
    }

    private Boolean hasPeriodPermissions() {
        return canReadChangeLogFields(RecurringDonationChangeLog__c.PreviousInstallmentPeriod__c,
                RecurringDonationChangeLog__c.NewInstallmentPeriod__c);
    }

    private Boolean hasFrequencyPermissions() {
        return canReadChangeLogFields(RecurringDonationChangeLog__c.PreviousInstallmentFrequency__c,
                RecurringDonationChangeLog__c.NewInstallmentFrequency__c);
    }

    private Boolean hasStatusPermissions() {
        return canReadChangeLogFields(RecurringDonationChangeLog__c.PreviousStatus__c,
                RecurringDonationChangeLog__c.NewStatus__c);
    }

    private Boolean hasCampaignPermissions() {
        return canReadChangeLogFields(RecurringDonationChangeLog__c.PreviousCampaign__c,
                RecurringDonationChangeLog__c.NewCampaign__c);
    }

    private Boolean hasRecurringTypePermissions() {
        return canReadChangeLogFields(RecurringDonationChangeLog__c.PreviousRecurringType__c,
                RecurringDonationChangeLog__c.NewRecurringType__c);
    }

    private Boolean hasExpectedTotalValue() {
        return this.record.NewExpectedTotalValue__c != null 
            || this.record.PreviousExpectedTotalValue__c != null;
    }

    private Boolean hasAnnualValue() {
        return this.record.NewAnnualValue__c != null 
            || this.record.PreviousAnnualValue__c != null;
    }

    private Boolean canReadChangeLogFields(Schema.SObjectField newField, Schema.SObjectField oldField) {
        return UTIL_Permissions.canRead(changeLogSObjectName, String.valueOf(newField))
                && UTIL_Permissions.canRead(changeLogSObjectName, String.valueOf(oldField));
    }

    private Boolean isAmountChanged() {
        return this.record.NewAmount__c != this.record.PreviousAmount__c;
    }

    private Boolean isFrequencyChanged() {
        return this.record.PreviousInstallmentFrequency__c != this.record.NewInstallmentFrequency__c;
    }

    private Boolean isPeriodChanged() {
        return this.record.PreviousInstallmentPeriod__c != this.record.NewInstallmentPeriod__c;
    }

    private Boolean isPlannedInstallmentsChanged() {
        return this.record.PreviousPlannedInstallments__c != this.record.NewPlannedInstallments__c;
    }

    private Boolean isStatusChanged() {
        return this.record.PreviousStatus__c != this.record.NewStatus__c;
    }

    private Boolean isCampaignChanged() {
        return this.record.NewCampaign__c != this.record.PreviousCampaign__c;
    }

    private Boolean isPaymentMethodChanged() {
        return this.record.NewPaymentMethod__c != this.record.PreviousPaymentMethod__c;
    }

    private Boolean isRecurringTypeChanged() {
        return this.record.NewRecurringType__c != this.record.PreviousRecurringType__c;
    }
}