public inherited sharing class TriggerHandlers extends fflib_SObjects {

   public TriggerHandlers(List<Trigger_Handler__c> triggerHandlers){
      super(triggerHandlers, Trigger_Handler__c.SObjectType);
   }

    public void shiftLoadOrder() {
        UnitOfWork unitOfWork = new UnitOfWork();
        for (Trigger_Handler__c triggerHandler : (List<Trigger_Handler__c>) getRecords()) {
            Integer currentLoadOrder = Integer.valueOf(triggerHandler.Load_Order__c);
            Integer newLoadOrder = currentLoadOrder + 1;
            triggerHandler.Load_Order__c = newLoadOrder;
            unitOfWork.registerDirty(new List<SObject>{
                    triggerHandler
            });
        }
        unitOfWork.save();
    }
}