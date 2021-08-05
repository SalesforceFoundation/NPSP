public with sharing class RD2_ChangeHistory {

    private RecurringDonationChangeHistory__c record;

    public RD2_ChangeHistory(RecurringDonationChangeHistory__c record) {
        this.record = record;
    }

    public RD2_ChangeView getChangeView() {
        RD2_ChangeView view = new RD2_ChangeView();
        view.changeType = this.record.ChangeType__c;
        if (this.record.NewStatusReason__c != null) {
            view.statusReason = this.record.NewStatusReason__c;
        }

        view.effectiveDate = this.record.EffectiveDate__c;
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
        view.displayType = RD2_FieldChangeView.DISPLAY_TYPE.LOOKUP;
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
        view.displayType = RD2_FieldChangeView.DISPLAY_TYPE.MONEY;
        return view;
    }

    private RD2_FieldChangeView getAnnualValueChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.oldValue = this.record.PreviousAnnualValue__c;
        if (this.isAnnualValueChanged()) {
            view.newValue = this.record.NewAnnualValue__c;
        }
        view.label = Label.RDCH_Annual_Value;
        view.displayType = RD2_FieldChangeView.DISPLAY_TYPE.MONEY;
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
        view.displayType = RD2_FieldChangeView.DISPLAY_TYPE.TEXT;
        return view;
    }

    private RD2_FieldChangeView getFrequencyChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewInstallmentFrequency__c;
        view.oldValue = this.record.PreviousInstallmentFrequency__c;
        view.displayType = RD2_FieldChangeView.DISPLAY_TYPE.TEXT;
        view.label = Label.RDCH_Frequency;

        return view;
    }

    private RD2_FieldChangeView getPeriodChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewInstallmentPeriod__c;
        view.oldValue = this.record.PreviousInstallmentPeriod__c;
        view.label = Label.pmtWizardIntervalPeriod;
        view.displayType = RD2_FieldChangeView.DISPLAY_TYPE.NUMERIC;
        return view;
    }

    private RD2_FieldChangeView getPaymentMethodChange() {
        RD2_FieldChangeView view = new RD2_FieldChangeView();
        view.newValue = this.record.NewPaymentMethod__c;
        view.oldValue = this.record.PreviousPaymentMethod__c;

        view.label = UTIL_Describe.getFieldLabel(
                'npe03__Recurring_Donation__c',
                String.valueOf(npe03__Recurring_Donation__c.PaymentMethod__c)
        );
        view.displayType = RD2_FieldChangeView.DISPLAY_TYPE.TEXT;
        return view;
    }

    private List<RD2_FieldChangeView> buildFieldChangeViews() {
        List<RD2_FieldChangeView> fieldChanges = new List<RD2_FieldChangeView>();
        fieldChanges.add(getAmountChange());
        fieldChanges.add(getAnnualValueChange());

        if (this.isCampaignChanged()) {
            fieldChanges.add(getCampaignChange());
        }

        if (this.isStatusChanged()) {
            fieldChanges.add(getStatusChange());
        }

        if (this.isFrequencyChanged()) {
            fieldChanges.add(getFrequencyChange());
        }

        if (this.isPeriodChanged()) {
            fieldChanges.add(getPeriodChange());
        }

        if (this.isPaymentMethodChanged()) {
            fieldChanges.add(getPaymentMethodChange());
        }

        return fieldChanges;
    }

    private Boolean isAmountChanged() {
        return this.record.NewAmount__c != this.record.PreviousAmount__c;
    }

    private Boolean isAnnualValueChanged() {
        return this.record.PreviousAnnualValue__c != this.record.NewAnnualValue__c;
    }

    private Boolean isFrequencyChanged() {
        return this.record.PreviousInstallmentFrequency__c != this.record.NewInstallmentFrequency__c;
    }

    private Boolean isPeriodChanged() {
        return this.record.PreviousInstallmentPeriod__c != this.record.NewInstallmentPeriod__c;
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
}