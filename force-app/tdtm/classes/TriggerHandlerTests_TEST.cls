@IsTest
private class TriggerHandlerTests_TEST {
    @IsTest(SeeAllData=true)
    static void showTriggerHandlerSchema() {
        List<Trigger_Handler__c> triggerHandlers =
               new TriggerHandlerSelector().getTriggerHandlers();
        System.debug(loggingLevel.Error, '*** triggerHandlers: ' + triggerHandlers);
    }

    @IsTest(SeeAllData=true)
    static void shouldShiftHandlerOrder() {

        TriggerHandlers triggerHandlers = new TriggerHandlers(
                new TriggerHandlerSelector().getTriggerHandlers()
        );

        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>) triggerHandlers.getRecords()) {
            if (triggerHandler.Class__c == 'ADDR_Account_TDTM') {
                System.assert(triggerHandler.Load_Order__c == 1);
                break;
            }
        }

        triggerHandlers.shiftLoadOrder();

        TriggerHandlers triggerHandlersAfterShift = new TriggerHandlers(
                new TriggerHandlerSelector().getTriggerHandlers()
        );

        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>)
                triggerHandlersAfterShift.getRecords()) {
            if (triggerHandler.Class__c == 'ADDR_Account_TDTM') {
                System.assert(triggerHandler.Load_Order__c == 2,
                        'Load Order should be shifted from 1 to 2');
                break;
            }
        }
    }
}