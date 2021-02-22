public with sharing class StatusChangeEventHandler {

    DataImportsService dataImportsService;

    public StatusChangeEventHandler() {}

    public StatusChangeEventHandler(DataImportsService service) { // Would also inject and
        // use PaymentsService
        this.dataImportsService = service != null ? service : new DataImportsService();
    }

    public void handle(List<StatusChange__e> statusChangeEvents) {
        Set<String> elevateTransactionsToMarkPaid =
                getElevateTransactionsToMarkPaid(statusChangeEvents);

        if (!elevateTransactionsToMarkPaid.isEmpty()) {
            DataImportsService service = new DataImportsService();
            service.markElevatePaymentsPaid(elevateTransactionsToMarkPaid);
        }
    }

    private Set<String> getElevateTransactionsToMarkPaid(List<StatusChange__e> statusChangeEvents) {
        Set<String> elevateTransactionsToMarkPaid = new Set<String>();
        for (StatusChange__e event : statusChangeEvents) {
            System.debug(LoggingLevel.ERROR, '*** variable value: ' + event.Status__c);
            System.debug(LoggingLevel.ERROR, '^^^^^^ event.Status__c ^^^^^^');
            System.debug(LoggingLevel.ERROR, '*** variable value: ' + event.Id__c);
            System.debug(LoggingLevel.ERROR, '^^^^^^ event.Id__c ^^^^^^');
            System.debug(LoggingLevel.ERROR, '*** variable value: ' + event.Paid__c);
            System.debug(LoggingLevel.ERROR, '^^^^^^ event.Paid__c ^^^^^^');

            if (event.Paid__c) {
                elevateTransactionsToMarkPaid.add(event.Id__c);
            }
        }
        return elevateTransactionsToMarkPaid;
    }
}