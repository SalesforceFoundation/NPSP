public with sharing class RD2_ChangeHistoryController {

    @AuraEnabled
    public static RD2_ChangeHistoryView getChangeHistory(Id recurringDonationId, Integer recordLimit, String changeTypeFilter) {
        RD2_ChangeHistoryService service = new RD2_ChangeHistoryService();
        try {
            return service.getChangeHistoryView(recurringDonationId, recordLimit, changeTypeFilter);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}