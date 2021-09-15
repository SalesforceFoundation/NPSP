public inherited sharing class LegacyHouseholdId {

    private Id value;

    public LegacyHouseholdId(Id aLegacyHouseholdId) {
        if (aLegacyHouseholdId.getSobjectType() != npo02__Household__c.SObjectType) {
            throw (Exception) new LegacyHouseholdIdException('Must be an npo02__Household__c Id.');
        }
        this.value = aLegacyHouseholdId;
    }

    public Id value(){
        return value;
    }

    private inherited sharing class LegacyHouseholdIdException extends Exception {
    }
}