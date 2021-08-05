public with sharing class RD2_ChangeHistoryView {
    @AuraEnabled public List<RD2_ChangeView> changes;
    @AuraEnabled public Boolean settingEnabled;
    @AuraEnabled public Boolean hasMore;

    public RD2_ChangeHistoryView() {
        this.changes = new List<RD2_ChangeView>();
    }
}