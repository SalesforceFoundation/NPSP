public inherited sharing class TriggerHandlers extends fflib_SObjects {

    public static TriggerHandlers newInstance() {
        return new TriggerHandlers(
                selector.getTriggerHandlers()
        );
    }

    private enum Action {
        BeforeInsert,
        AfterInsert,
        BeforeUpdate,
        AfterUpdate,
        BeforeDelete,
        AfterDelete,
        AfterUndelete
    }

    public void reportHandlersByContextFor(SObjectType sObjectType) {
        System.debug(LoggingLevel.ERROR, '*** ##### ' + sObjectType + ' ######');
        for (Action action : Action.values()) {
            System.debug(LoggingLevel.ERROR, '*** ##### ************************************************* ######');
            System.debug(LoggingLevel.ERROR, '*** ##### Context: '+action.name()+' ######');
            for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>) getRecords()) {
                if (triggerHandler.Object__c == String.valueOf(sObjectType)
                        && triggerHandler.Trigger_Action__c.contains(action.name())) {
                    System.debug(LoggingLevel.ERROR, '*** Class:' + triggerHandler.Class__c + 
                            ': Load Order:' + triggerHandler.Load_Order__c);
                }
            }
        }
    }

    public void report(SObjectType sObjectType, String context) {
        System.debug(LoggingLevel.ERROR, '*** ##### ' + sObjectType + ' ######');
        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>) getRecords()) {
            if (triggerHandler.Object__c == String.valueOf(sObjectType)
                    && triggerHandler.Trigger_Action__c.contains(context)) {
                System.debug(LoggingLevel.ERROR, '*** triggerHandler.Name: ' +
                        triggerHandler.Class__c + ': Load Order:' + triggerHandler.Load_Order__c);
            }
        }
    }
    
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

    @TestVisible
    private static UnitOfWork uow {
        get {
            if (uow == null) {
                uow = new UnitOfWork();
            }
            return uow;
        }
        private set;
    }

    public TriggerHandlers(List<Trigger_Handler__c> triggerHandlers) {
        super(triggerHandlers, Trigger_Handler__c.SObjectType);
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

    /**
     * @description Randomize load order of handlers
     */
    public void shuffleLoadOrder() {
        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>) getRecords()) {
            //todo: prevent from being same as orig
            triggerHandler.Load_Order__c = getRandomInteger();
            uow.registerDirty(new List<SObject>{
                    triggerHandler
            });
        }
        uow.save();
    }

    /**
     * @description Randomize which handlers are active
     */
    public void randomizeIsActive() {
        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>) getRecords()) {
            triggerHandler.Active__c = Math.mod(getRandomInteger(), 2) == 0;
            uow.registerDirty(new List<SObject>{
                    triggerHandler
            });
        }
        uow.save();
    }

    /**
     * @description Randomize which handlers run async
     */
    public void randomizeAsync() {
        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>) getRecords()) {
            triggerHandler.Asynchronous__c =
                    Boolean.valueOf(Math.mod(getRandomInteger(), 2) == 0);
            uow.registerDirty(new List<SObject>{
                    triggerHandler
            });
        }
        uow.save();
    }

    private Integer getRandomInteger() {
        return Integer.valueOf((Math.random() * 100));
    }

    public void reset() {
        TriggerHandlers triggerHandlers = TriggerHandlers.newInstance();
        delete triggerHandlers.getRecords();
        insert TDTM_DefaultConfig.getDefaultRecords();
    }

    public List<TriggerHandler> getTriggerHandlers() {
        List<TriggerHandler> triggerHandlers = new List<TriggerHandler>();
        for (Trigger_Handler__c triggerHandlerSObj : (List<Trigger_Handler__c>) getRecords()) {
            triggerHandlers.add(new TriggerHandler(triggerHandlerSObj));
        }
        return triggerHandlers;
    }
}