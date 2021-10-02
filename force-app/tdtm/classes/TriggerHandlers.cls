public inherited sharing class TriggerHandlers extends fflib_SObjects {

    @TestVisible
    private static TriggerHandlerSelector selector {
        get {
            if (selector == null) {
                selector = new TriggerHandlerSelector();
            }
            return selector;
        }
        private set;
    }

    public TriggerHandlers(List<Trigger_Handler__c> triggerHandlers) {
        super(triggerHandlers, Trigger_Handler__c.SObjectType);
    }

    /**
     * @description Randomize load order of handlers
     */
    public void shuffleLoadOrder() {
        UnitOfWork unitOfWork = new UnitOfWork();
        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>) getRecords()) {
            //todo: prevent from being same as orig
            Integer newRandomLoadOrder = Integer.valueOf((Math.random() * 100));
            triggerHandler.Load_Order__c = newRandomLoadOrder;
            unitOfWork.registerDirty(new List<SObject>{
                    triggerHandler
            });
        }
        unitOfWork.save();
    }

    /**
     * @description Randomize which handlers are active
     */
    public void randomizeIsActive() {
        UnitOfWork unitOfWork = new UnitOfWork();
        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>) getRecords()) {
            Integer newRandomLoadOrder = Integer.valueOf((Math.random() * 100));
            triggerHandler.Active__c = Math.mod(newRandomLoadOrder, 2) == 0;
            unitOfWork.registerDirty(new List<SObject>{
                    triggerHandler
            });
        }
        unitOfWork.save();
    }

    public TriggerHandlers inTriggerAction(String triggerAction) {
        List<Trigger_Handler__c> triggerHandlers = new List<Trigger_Handler__c>();
        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>) getRecords()) {
            if (triggerHandler.Trigger_Action__c.contains(triggerAction)) {
                triggerHandlers.add(triggerHandler);
            }
        }
        return new TriggerHandlers(triggerHandlers);
    }

    public TriggerHandlers handlersFor(SObjectType sObjectType) {
        return new TriggerHandlers(
                selectByFieldValue(Trigger_Handler__c.Object__c, String.valueOf(sObjectType))
                        .getRecords()
        );
    }

    public void reset() {
        TriggerHandlers triggerHandlers = TriggerHandlers.newInstance();
        delete triggerHandlers.getRecords();
        insert TDTM_DefaultConfig.getDefaultRecords();
    }

    public static TriggerHandlers newInstance() {
        return new TriggerHandlers(
                selector.getTriggerHandlers()
        );
    }
}