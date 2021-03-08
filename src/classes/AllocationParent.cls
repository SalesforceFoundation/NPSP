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

    @TestVisible
    private AllocationParent() {}

    public AllocationParent(Id parentId) {
        id = parentId;
        objectType = id.getSObjectType();
        record = getRecord();
        setPropertiesFromDescribe();

        if (UserInfo.isMultiCurrencyOrganization()) {
            currencyCode = (String)record.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
        }
    }

    public Id getId() {
        return id;
    }

    public SObjectType getSObjectType() {
        return objectType;
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

    public String getCurrencyCode() {
        return currencyCode;
    }

    public String getAllocationLookupApiName() {
        return allocationLookupApiNameBySObjectType.get(objectType);
    }

    public Boolean isAnOpportunity() {
        return objectType == Opportunity.SObjectType;
    }

    public Boolean isAPayment() {
        return objectType == npe01__OppPayment__c.SObjectType;
    }

    public Boolean hasAnAmountField() {
        return isAnOpportunity() || isAPayment();
    }

    public Boolean hasAnAmountGreaterThanZero() {
        return hasAnAmountField() && getAmount() > 0;
    }

    public Decimal getAmount() {
        if (donationAmount == 0 || donationAmount == null) {

            Boolean shouldBeAmountFromOpportunity = isAnOpportunity() && record?.get(OPPORTUNITY_AMOUNT) != null;
            if (shouldBeAmountFromOpportunity) {
                donationAmount = (Decimal)record.get(OPPORTUNITY_AMOUNT);
            }

            Boolean shouldBeAmountFromPayment = isAPayment() && record?.get(PAYMENT_AMOUNT) != null;
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
            .withWhere('Id = :id')
            .withLimit(1)
            .build();

        return Database.query(queryString);
    }

    private Set<String> getSelectFieldsFor(SObjectType objectType) {
        Set<String> selectFields = new Set<String>{'Id', 'Name'};
        List<String> additionalFields = selectFieldsBySObjectType.get(objectType);
        if (additionalFields != null) {
            selectFields.addAll(selectFieldsBySObjectType.get(objectType));
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