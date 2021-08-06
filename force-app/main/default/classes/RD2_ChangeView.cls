public with sharing class RD2_ChangeView {
    @AuraEnabled public List<RD2_FieldChangeView> fields;
    @AuraEnabled public Id id;
    @AuraEnabled public Date changeDate;
    @AuraEnabled public String changeType;
    @AuraEnabled public String statusReason;
}