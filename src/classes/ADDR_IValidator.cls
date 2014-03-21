public Interface ADDR_IValidator {

    List<Address__c> verifyRecords(list<Address__c> addresses, Boolean rejectAmbiguous);
}