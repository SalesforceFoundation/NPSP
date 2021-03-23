public interface anAddress {

    Boolean isSeasonal();

    String householdId();

    String startDay();

    String startMonth();

    String endDay();

    String endMonth() ;

    Boolean isEqualTo(anAddress other, Boolean includeAddressType);

    Address__c getRecord();

    void copyFrom(anAddress other);

    String getType();

    Boolean isDefault();

    void setAsDefault();

}