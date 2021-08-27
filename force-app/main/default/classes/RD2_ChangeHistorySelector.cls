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
                .withMultiCurrencyField()
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