/**
 * @author Roger Mitchell
 * @date 4/12/2019
 * @group TDTM
 * @group-content ../../ApexDocContent/TDTM.htm
 * @description Abstract class that classes to be run from a trigger, according to the TDTM design,
 * need to extend. This differs from TDTM_Runnable in that it allows a developer to mutate the global
 * DmlWrapper collection to which TDTM_TriggerHandler adds records returned from other classes that
 * implement the TDTM_Runnable interface.
 */
global abstract class TDTM_RunnableMutable {

    /*******************************************************************************************************
     * @description Method to be implemented by the classes the extend this abstract class. This is the method
     * that will be called by the trigger handler.
     * @param newlist The records that were passed to the trigger as trigger.new.
     * @param oldlist The records that were passed to the trigger as trigger.old.
     * @param action The event (before insert, after insert,...) that caused the class to run.
     * @param objectResult The type of SObject the class runs for.
     * @param dmlWrapper the global TDTM_Runnable.DmlWrapper collection that is passed from TDTM_TriggerHandler
     * @return void
    */
    global abstract void run(List<SObject> newlist, List<SObject> oldlist, TDTM_Runnable.Action triggerAction,
        Schema.DescribeSObjectResult objResult, TDTM_Runnable.DmlWrapper dmlWrapper);
}