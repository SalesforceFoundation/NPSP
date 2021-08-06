public with sharing class RD2_FieldChangeView {
    @AuraEnabled public Object newValue;
    @AuraEnabled public Object oldValue;
    @AuraEnabled public Id newId;
    @AuraEnabled public Id oldId;
    @AuraEnabled public String label;
    @AuraEnabled public String displayType;

    public enum DISPLAY_TYPE {
        LOOKUP,
        TEXT,
        NUMERIC,
        MONEY
    }

    public void setDisplayType(DISPLAY_TYPE displayType) {
        this.displayType = displayType.name();
    }
}