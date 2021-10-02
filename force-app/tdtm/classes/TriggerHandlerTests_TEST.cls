@IsTest
private class TriggerHandlerTests_TEST {
    private static Map<String, Integer> loadOrderByHandlerClass = new Map<String, Integer>();

    @IsTest(SeeAllData=true)
    static void showTriggerHandlerSchema() {
        List<Trigger_Handler__c> triggerHandlers =
                new TriggerHandlerSelector().getTriggerHandlers();
        System.debug(loggingLevel.Error, '*** triggerHandlers: ' + triggerHandlers);
    }

    @IsTest(SeeAllData=true)
    static void shouldShuffleHandlerOrder() {

        TriggerHandlers triggerHandlers = new TriggerHandlers(
                new TriggerHandlerSelector().getTriggerHandlers()
        );
        String triggerAction = 'BeforeInsert';
        SObjectType sObjectType = Contact.SObjectType;
        TriggerHandlers accountBeforeInsertHandlers =
                triggerHandlers.handlersFor(sObjectType).inTriggerAction(triggerAction);

        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>)
                accountBeforeInsertHandlers.handlersFor(sObjectType).inTriggerAction
                        (triggerAction).getRecords()) {
            report(triggerHandler);
            if (triggerHandler.Class__c == 'ADDR_Account_TDTM') {
                System.assert(triggerHandler.Load_Order__c == 1); //default order
            }
            loadOrderByHandlerClass.put(
                    triggerHandler.Class__c,
                    Integer.valueOf(triggerHandler.Load_Order__c));
        }

        accountBeforeInsertHandlers.shuffleLoadOrder();

        TriggerHandlers triggerHandlersAfterShift = new TriggerHandlers(
                new TriggerHandlerSelector().getTriggerHandlers()
        );

        System.debug(LoggingLevel.ERROR, '*** ##### AFTer Shift! ######');
        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>)
                triggerHandlersAfterShift.handlersFor(sObjectType).inTriggerAction(triggerAction).getRecords()) {
            report(triggerHandler);
            if (triggerHandler.Class__c == 'ADDR_Account_TDTM') {
                System.assert(triggerHandler.Load_Order__c != 1,
                        'Load Order should be shifted from 1 to 2');
            }
            if (triggerHandler.Class__c == 'AFFL_Affiliations_TDTM') {
                System.assert(triggerHandler.Load_Order__c != 2,
                        'Load Order should be wrapped around from 2 to 0');
            }
        }
    }

    private static void report(Trigger_Handler__c triggerHandler) {
        System.debug(LoggingLevel.ERROR, '***LoadOrder: ' + triggerHandler.Load_Order__c
                + '*** class: ' + triggerHandler.Class__c);
        System.debug(LoggingLevel.ERROR, '***Actions: ' +
                triggerHandler.Trigger_Action__c);
    }
}