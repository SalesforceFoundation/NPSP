global with sharing class ADDR_Validator_REST {

    webService static void verifyRecord(String addressId) {
        Set<Id> addressIds = new Set<Id>();
        addressIds.add(Id.valueOf(addressId));
        ADDR_Validator.verifyRecords(addressIds);
    }
}