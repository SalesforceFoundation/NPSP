/*
    Copyright (c) 2014, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/

/**
* @author Salesforce.org
* @date 2014
* @group API
* @group-content ../../ApexDocContent/API.htm
* @description API class that exposes the TDTM (Table-Driven Trigger Management) configuration.
*/
global class TDTM_Config_API {

    /*******************************************************************************************************
    * @description Returns the default TDTM configuration. 
    * @return List<Trigger_Handler__c> a list of trigger handler records with the default values. The records
    * have not yet been inserted in the database. You can manipulate them, if necessary, and insert 
    * them. If no Trigger_Handler__c records exist, the application will insert the defaults when any 
    * of the NPSP triggers run. 
    */
    global static List<Trigger_Handler__c> getDefaultRecords() {
        return TDTM_DefaultConfig.getDefaultRecords(); 
    }

    /*******************************************************************************************************
    * @description Returns the list of current cached trigger handler records
    * @return List<Trigger_Handler__c> a list of cached trigger handler records with current values.  SI's
    * may modify this list in the current execution context to temporarily change the functionality of
    * tdtm triggers - disable triggers, enable triggers, or even add a new row to the collection
    * that is not committed to the database.
    */
    global static List<Trigger_Handler__c> getCachedRecords() {
        // need to handle scenario where this is called before any DML has occurred that would set the
        // initial defaults records (ie, in tests).
        if (Test.isRunningTest() && TDTM_ObjectDataGateway.listTH.isEmpty()) {
            insert getDefaultRecords();
            // reset listTH to null so it will get refilled in the correct sort order
            TDTM_ObjectDataGateway.listTH = null;
        }
        return TDTM_ObjectDataGateway.listTH;
    }

    /*******************************************************************************************************
    * @description Method to be called from each of the triggers (only one per object) that follow the TDTM 
    * design. Figures out which classes need to be called, and calls them.
    * @param isBefore Are we in a before trigger context.
    * @param isAfter Are we in an after trigger context.
    * @param isInsert Did the trigger run in response to an insert operation.
    * @param isUpdate Did the trigger run in response to an update operation.
    * @param isDelete Did the trigger run in response to a delete operation.
    * @param isUnDelete Did the trigger run in response to an undelete operation.
    * @param newList The records that were passed to the trigger as trigger.new.
    * @param oldList The records that were passed to the trigger as trigger.old.
    * @param describeObj The type of SObject the class runs for.
    * @return void
    */
    global static void run(Boolean isBefore, Boolean isAfter, Boolean isInsert, Boolean isUpdate,
    Boolean isDelete, Boolean isUnDelete, List<SObject> newList, List<SObject> oldList, 
    Schema.DescribeSObjectResult describeObj) {
        TDTM_TriggerHandler.run(isBefore, isAfter, isInsert, isUpdate, isDelete, isUnDelete, newList, oldList, describeObj, new TDTM_ObjectDataGateway());
    }

    /**
     * @description Method to disable all NPSP roll-up triggers for the current code execution context.
     */
    @InvocableMethod(Label='Disable NPSP Rollup Triggers')
    global static void disableAllRollupTriggers() {
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'RLLP_OppRollup_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'CRLP_Rollup_TDTM', false);
        TDTM_ProcessControl.toggleTriggerState('npe01__OppPayment__c', 'CRLP_Rollup_TDTM', false);
    }

}