public with sharing class RD2_ChangeView {
    @AuraEnabled public List<RD2_FieldChangeView> fields;
    @AuraEnabled public Date effectiveDate;
    @AuraEnabled public String changeType;
    @AuraEnabled public String statusReason;
}