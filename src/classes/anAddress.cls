public interface anAddress {

    Boolean isSeasonal();

    String householdId();

    String startDay();

    String startMonth();

    String endDay();

    String endMonth() ;

    Boolean equals(anAddress other, Boolean includeAddressType);

    Address__c getRecord();
}