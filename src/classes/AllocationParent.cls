/*
    Copyright (c) 2021, Salesforce.org
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
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Holds behavior for Allocation__c parent objects.
*/
public inherited sharing class AllocationParent {
    private Id id;
    private SObjectType objectType = null;
    private SObject record;
    private Decimal donationAmount = 0;
    private String currencyCode;
    private String keyPrefix;
    private String objectApiName;
    private String objectLabelPlural;

    private final String OPPORTUNITY_AMOUNT = String.valueOf(Opportunity.SObjectType.fields.Amount);
    private final String PAYMENT_AMOUNT = String.valueOf(npe01__OppPayment__c.SObjectType.fields.npe01__Payment_Amount__c);
    private final String OPPORTUNITY_LOOKUP = String.valueOf(Allocation__c.SObjectType.fields.Opportunity__c);
    private final String CAMPAIGN_LOOKUP = String.valueOf(Allocation__c.SObjectType.fields.Campaign__c);
    private final String RECURRING_DONATION_LOOKUP = String.valueOf(Allocation__c.SObjectType.fields.Recurring_Donation__c);
    private final String PAYMENT_LOOKUP = String.valueOf(Allocation__c.SObjectType.fields.Payment__c);

    public AllocationParent(Id parentId) {
        id = parentId;
        objectType = id.getSObjectType();
        record = getRecord();
        setPropertiesFromDescribe();

        if (UserInfo.isMultiCurrencyOrganization()) {
            currencyCode = (String)record.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
        }
    }

    public SObjectType objectType() {
        return objectType;
    }

    public String currencyCode() {
        return currencyCode;
    }

    public Id getId() {
        return id;
    }

    public String getKeyPrefix() {
        return keyPrefix;
    }

    public String getObjectLabelPlural() {
        return objectLabelPlural;
    }

    public String getObjectApiName() {
        return objectApiName;
    }

    public String getRecordName() {
        return (String)record?.get('Name');
    }

    public String getAllocationLookupApiName() {
        return allocationLookupApiNameBySObjectType.get(objectType);
    }

    public Boolean isOpportunity() {
        return objectType == Opportunity.SObjectType;
    }

    public Boolean isPayment() {
        return objectType == npe01__OppPayment__c.SObjectType;
    }

    public Boolean hasAmountField() {
        return isOpportunity() || isPayment();
    }

    public Boolean isOpportunityWithZeroAmount() {
        return isOpportunity() && getAmount() == 0;
    }

    public Decimal getAmount() {
        if (donationAmount == 0 || donationAmount == null) {

            Boolean shouldBeAmountFromOpportunity = isOpportunity() && record?.get(OPPORTUNITY_AMOUNT) != null;
            if (shouldBeAmountFromOpportunity) {
                donationAmount = (Decimal)record.get(OPPORTUNITY_AMOUNT);
            }

            Boolean shouldBeAmountFromPayment = isPayment() && record?.get(PAYMENT_AMOUNT) != null;
            if (shouldBeAmountFromPayment) {
                donationAmount = (Decimal)record.get(PAYMENT_AMOUNT);
            }
        }

        return donationAmount;
    }

    private void setPropertiesFromDescribe() {
        DescribeSObjectResult describe = objectType.getDescribe();
        keyPrefix = describe.getKeyPrefix();
        objectLabelPlural = describe.getLabelPlural();
        objectApiName = describe.getName();
    }

    private SObject getRecord() {
        Set<String> fields = getSelectFieldsFor(objectType);

        UTIL_Query soql = new UTIL_Query();
        String queryString = soql
            .withFrom(objectType)
            .withSelectFields(fields)
            .withMultiCurrencyField()
            .withWhere('Id = :id')
            .withLimit(1)
            .build();

        return Database.query(queryString);
    }

    private Set<String> getSelectFieldsFor(SObjectType objectType) {
        Set<String> selectFields = new Set<String>{'Id', 'Name'};
        List<String> additionalFields = selectFieldsBySObjectType.get(objectType);

        if (additionalFields != null) {
            selectFields.addAll(additionalFields);
        }

        if (currencyCode != null) {
            selectFields.add(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
        }

        return selectFields;
    }

    private Map<SObjectType, List<String>> selectFieldsBySObjectType = new Map<SObjectType, List<String>> {
        Opportunity.SObjectType => new List<String>{'Amount'},
        npe01__OppPayment__c.SObjectType => new List<String>{'npe01__Payment_Amount__c'}
    };

    private Map<SObjectType, String> allocationLookupApiNameBySObjectType = new Map<SObjectType, String> {
        Opportunity.SObjectType => OPPORTUNITY_LOOKUP,
        Campaign.SObjectType => CAMPAIGN_LOOKUP,
        npe03__Recurring_Donation__c.SObjectType => RECURRING_DONATION_LOOKUP,
        npe01__OppPayment__c.SObjectType => PAYMENT_LOOKUP
    };
}