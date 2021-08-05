public with sharing class RD2_ChangeHistoryController {
    public static RD2_ChangeHistoryView getChangeHistory(Id recurringDonationId, Integer recordLimit, String filter) {
        RD2_ChangeHistoryService service = new RD2_ChangeHistoryService();
        try {
            return service.getChangeHistoryView(recurringDonationId, recordLimit, filter);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}