public inherited sharing class AllocationParent {
    public Id id;

    private SObjectType objectType = null;
    private SObject record;
    private Decimal donationAmount = 0;
    private String currencyCode;
    private String keyPrefix;
    private String objectApiName;
    private String objectLabelPlural;

    private final String OPPORTUNITY_AMOUNT = String.valueOf(Opportunity.SObjectType.fields.Amount);
    private final String PAYMENT_AMOUNT = String.valueOf(npe01__OppPayment__c.SObjectType.fields.npe01__Payment_Amount__c);

    public AllocationParent() {}

    public AllocationParent(Id parentId) {
        id = parentId;
        objectType = id.getSObjectType();
        record = getRecord(objectType);
        setPropertiesFromDescribe();

        if (UserInfo.isMultiCurrencyOrganization()) {
            currencyCode = (String)record.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
        }
    }

    public Id getParentId() {
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

    private SObject getRecord(SObjectType objectType) {
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
        selectFields.addAll(selectFieldsBySObjectType.get(objectType));
        if (currencyCode != null) {
            selectFields.add(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
        }
        return selectFields;
    }

    private Map<SObjectType, List<String>> selectFieldsBySObjectType = new Map<SObjectType, List<String>> {
        Opportunity.SObjectType => new List<String>{'Amount'},
        Campaign.SObjectType => new List<String>(),
        npe03__Recurring_Donation__c.SObjectType => new List<String>(),
        npe01__OppPayment__c.SObjectType => new List<String>{'npe01__Payment_Amount__c'}
    };

    private Map<SObjectType, String> allocationLookupApiNameBySObjectType = new Map<SObjectType, String> {
        Opportunity.SObjectType => String.valueOf(Allocation__c.SObjectType.fields.Opportunity__c),
        Campaign.SObjectType => String.valueOf(Allocation__c.SObjectType.fields.Campaign__c),
        npe03__Recurring_Donation__c.SObjectType => String.valueOf(Allocation__c.SObjectType.fields.Recurring_Donation__c),
        npe01__OppPayment__c.SObjectType => String.valueOf(Allocation__c.SObjectType.fields.Payment__c)
    };
}