public with sharing class RD2_ChangeHistorySelector {

    private Integer recordLimit = 3;
    private List<String> changeTypesFilter;

    private List<String> fields = new List<String>{
            String.valueOf(RecurringDonationChangeHistory__c.ChangeType__c),
            String.valueOf(RecurringDonationChangeHistory__c.EffectiveDate__c),
            String.valueOf(RecurringDonationChangeHistory__c.Id),
            String.valueOf(RecurringDonationChangeHistory__c.CreatedDate),
            String.valueOf(RecurringDonationChangeHistory__c.NewAmount__c),
            String.valueOf(RecurringDonationChangeHistory__c.NewCampaign__c),
            'NewCampaign__r.Name',
            String.valueOf(RecurringDonationChangeHistory__c.NewInstallmentFrequency__c),
            String.valueOf(RecurringDonationChangeHistory__c.NewInstallmentPeriod__c),
            String.valueOf(RecurringDonationChangeHistory__c.NewPaymentMethod__c),
            String.valueOf(RecurringDonationChangeHistory__c.NewStatus__c),
            String.valueOf(RecurringDonationChangeHistory__c.NewStatusReason__c),
            String.valueOf(RecurringDonationChangeHistory__c.NewAnnualValue__c),
            String.valueOf(RecurringDonationChangeHistory__c.PreviousAmount__c),
            String.valueOf(RecurringDonationChangeHistory__c.PreviousCampaign__c),
            'PreviousCampaign__r.Name',
            String.valueOf(RecurringDonationChangeHistory__c.PreviousInstallmentFrequency__c),
            String.valueOf(RecurringDonationChangeHistory__c.PreviousInstallmentPeriod__c),
            String.valueOf(RecurringDonationChangeHistory__c.PreviousPaymentMethod__c),
            String.valueOf(RecurringDonationChangeHistory__c.PreviousStatus__c),
            String.valueOf(RecurringDonationChangeHistory__c.PreviousStatusReason__c),
            String.valueOf(RecurringDonationChangeHistory__c.PreviousAnnualValue__c),
            String.valueOf(RecurringDonationChangeHistory__c.RecurringDonation__c)
    };

    public List<RecurringDonationChangeHistory__c> getChangeHistories(Id recurringDonationId) {
        UTIL_Query query = new UTIL_Query()
                .withSelectFields(fields)
                .withFrom(RecurringDonationChangeHistory__c.SObjectType)
                .withWhere('RecurringDonation__c = :recurringDonationId')
                .withLimit(this.recordLimit)
                .withOrderBy('EffectiveDate__c DESC, CreatedDate DESC');

        if(changeTypesFilter != null) {
            query.withWhere(getChangeTypeWhereClause());
        }

        return Database.query(query.build());
    }

    public RD2_ChangeHistorySelector withRecordLimit(Integer recordLimit) {
        this.recordLimit = recordLimit;
        return this;
    }

    public RD2_ChangeHistorySelector withChangeTypeFilter(String filter) {
        this.changeTypesFilter = filter.split(';');
        return this;
    }

    private String getChangeTypeWhereClause() {
        String fieldName = String.valueOf(RecurringDonationChangeHistory__c.ChangeType__c);
        return fieldName + ' IN (\'' + String.join(changeTypesFilter, '\',\'') + '\')';
    }
}