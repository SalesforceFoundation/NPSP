/*
    Copyright (c) 2016, Salesforce.org
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
 * @date 2016
 * @group Util
 * @description Trigger handler allowing cascade delete and undelete of child objects through lookup relationships.
 * The only difference in functionality with standard cascade deletion is that child records show up separately from
 * their parent in the recycle bin.
 * To enable cascade delete for a new relationship, add it to the "cascades" map. When adding a new object type, also
 * add a corresponding trigger handler.
 * NOTE: Since standard cascade deletes don't run triggers on deleted children, records in the "cascades" map can also
 * be created for children further down the chain, e.g. grandchildren, great-grandchildren, etc. The relationship to 
 * the deleted parent object can be provided to allow cascade functionality for those parent objects.
 */
public with sharing class UTIL_CascadeDeleteLookups_TDTM extends TDTM_Runnable {

    /** @description Static list of sobjects for stashing objects for cascade deletion between before and after triggers */
    private static List<SObject> forDelete = new List<SObject>();

    /*******************************************************************************************************
    * @description This map contains a keyset of object types that trigger cascade deletes, and values that store child
    * objects that should be cascade deleted, and their lookup relationship to the parent object. Values are stored as a 
    * list of strings; each string is of the format ObjectName.LookupFieldName, and multiple strings may be added to the 
    * list
    */
    private final Map<SObjectType, List<String>> cascades = new Map<SObjectType, List<String>>{
        Contact.SObjectType                      =>  new List<String>{'npe03__Recurring_Donation__c|npe03__Contact__c'},
        Account.SObjectType                      =>  new List<String>{'npe03__Recurring_Donation__c|npe03__Organization__c',
                                                                      'npe03__Recurring_Donation__c|npe03__Contact__r.AccountId',
                                                                      'Allocation__c|Opportunity__r.AccountId'},
        Opportunity.SObjectType                  =>  new List<String>{'Allocation__c|Opportunity__c'},
        Campaign.SObjectType                     =>  new List<String>{'Allocation__c|Campaign__c'},
        npe03__Recurring_Donation__c.SObjectType =>  new List<String>{'Allocation__c|Recurring_Donation__c'}
    };

    /*******************************************************************************************************
    * @description Run method checks if there is a cascade deletion for the current trigger and runs the
    * cascade method for each entry.
    * @param listNew The list of sobjects from trigger new.
    * @param listOld The list of sobjects from trigger old.
    * @param triggerAction Which action triggered the current context. (Before or After; Insert, Update, 
    * Delete, or Undelete.)
    * @param objResult The field describe object for the current trigger set.
    * @return dmlWrapper Objects that need to be inserted or updated after the processing of the trigger.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        if (cascades.containsKey(objResult.getSObjectType())) {
            for (String childLookup : cascades.get(objResult.getSObjectType())) {
                try {
                    cascadeDelete(newlist, oldlist, childLookup, triggerAction);
                } catch (Exception ex) {
                    ERR_Handler.processError(ex, 'TDTM');
                }        
            }
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Performs cascade delete for lookup fields. Stashes records, deletes records, or undeletes
    * records depending on trigger action.
    * @param listNew The list of sobjects from trigger new.
    * @param listOld The list of sobjects from trigger old.
    * @param objResult The field describe object for the current trigger set.
    * @param triggerAction Which action triggered the current context. (Before or After; Insert, Update, 
    * Delete, or Undelete.)
    * @return void This method deletes or undeletes records inline and returns nothing.
    ********************************************************************************************************/
    private void cascadeDelete(List<SObject> newlist, List<SObject> oldlist, 
        String childLookup, TDTM_Runnable.Action triggerAction) {

        String childObjectName = childLookup.split('\\|')[0];
        String lookupFieldName = childLookup.split('\\|')[1];
        List<SObject> deletedParents = (triggerAction == TDTM_Runnable.Action.AfterUndelete) ? newlist : oldlist;

        String childQuery = 'SELECT ID FROM ' + childObjectName + ' WHERE ' + lookupFieldName + ' IN :deletedParents';

        if (triggerAction == TDTM_Runnable.Action.BeforeDelete) {
            //cache related records before delete
            forDelete.addAll(Database.query(childQuery));
        
        } else if (triggerAction == TDTM_Runnable.Action.AfterDelete && !forDelete.isEmpty()) {
            //do the delete in the parent record's afterdelete trigger, which allows cascading of deletes
            List<Database.DeleteResult> delResults = Database.delete(forDelete, false);
            //allow partial success, process errors
            ERR_Handler.Errors errorResult = ERR_Handler.getErrors(delResults, forDelete);
            if (errorResult.errorsExist) {
                ERR_Handler.processErrors(errorResult.errorRecords, 'TDTM');
            }
            //avoid recursion by blanking out stashed objects
            forDelete = new List<SObject>();
        
        } else if (triggerAction == TDTM_Runnable.Action.AfterUndelete) {
            List<SObject> forUndelete = Database.query(childQuery + ' AND IsDeleted = true ALL ROWS');
            //undelete child records on parent undelete, allow partial success
            List<Database.UndeleteResult> undelResults = Database.undelete(forUndelete, false);
            //process potential errors
            ERR_Handler.Errors errorResult = ERR_Handler.getErrors(undelResults, forUndelete);
            if (errorResult.errorsExist) {
                ERR_Handler.processErrors(errorResult.errorRecords, 'TDTM');
            }
        }
    }
}