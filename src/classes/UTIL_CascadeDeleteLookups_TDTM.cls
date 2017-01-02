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

    /*******************************************************************************************************
    * @description Static map of child sobjects per parent object type, used stashing objects for cascade deletion 
    * between before and after triggers 
    */
    private static Map<SObjectType, List<SObject>> forDelete = new Map<SObjectType, List<SObject>>();

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
        npe03__Recurring_Donation__c.SObjectType =>  new List<String>{'Allocation__c|Recurring_Donation__c',
                                                                      'Opportunity|npe03__Recurring_Donation__c'}
    };

    /*******************************************************************************************************
    * @description Performs cascade delete for lookup fields. Stashes records, deletes records, or undeletes
    * records depending on trigger action.
    * @param listNew The list of sobjects from trigger new.
    * @param listOld The list of sobjects from trigger old.
    * @param triggerAction Which action triggered the current context. (Before or After; Insert, Update, 
    * Delete, or Undelete.)
    * @param objResult The field describe object for the current trigger set.
    * @return dmlWrapper Objects that need to be inserted or updated after the processing of the trigger.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        SObjectType objType = objResult.getSObjectType();
        
        if (triggerAction == TDTM_Runnable.Action.BeforeDelete) {
            doStash(objType, oldlist);
        }

        if (triggerAction == TDTM_Runnable.Action.AfterDelete && forDelete.containsKey(objType)) {
            doDelete(objType);
        }

        if (triggerAction == TDTM_Runnable.Action.AfterUndelete) {
            doUndelete(objType, newlist);
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Stashes child objects for cascade deletion in the before delete event, for deletion in the
    * after delete event.
    * @param objType The SObject type of the parent object being deleted
    * @param deletedParents The list of sobjects of deleted parent objects.
    * @return void This method stashes child objects for deletions in the static variable and returns nothing.
    ********************************************************************************************************/
    private void doStash(SObjectType objType, List<SObject> deletedParents) {
        if (cascades.containsKey(objType)) {
            for (String childLookup : cascades.get(objType)) {
                String childQuery = getQuery(childLookup);
                List<SObject> queryResult = Database.query(childQuery);

                if (!queryResult.isEmpty()) {
                    if (!forDelete.containsKey(objType)) {
                        forDelete.put(objType, new List<SObject>());
                    }
                    forDelete.get(objType).addAll(queryResult);
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Performs cascade delete an object type, allowing for partial success and recording errors.
    * @param objType The SObject type of the parent object being deleted
    * @return void This method deletes records inline and returns nothing.
    ********************************************************************************************************/
    private void doDelete(SObjectType objType) {
        List<Database.DeleteResult> delResults = Database.delete(forDelete.get(objType), false);
        ERR_Handler.Errors errorResult = ERR_Handler.getErrors(delResults, forDelete.get(objType));
        if (errorResult.errorsExist) {
            ERR_Handler.processErrors(errorResult.errorRecords, 'TDTM');
        }
        forDelete.remove(objType);
    }

    /*******************************************************************************************************
    * @description Performs cascade undelete for lookup fields.
    * @param objType The SObject type of the parent object being deleted
    * @param deletedParents The list of sobjects of undeleted parent objects.
    * @return void This method undeletes records inline and returns nothing.
    ********************************************************************************************************/
    private void doUndelete(SObjectType objType, List<SObject> deletedParents) {
        if (cascades.containsKey(objType)) {
            for (String childLookup : cascades.get(objType)) {
                String childQuery = getQuery(childLookup) + ' AND IsDeleted = true ALL ROWS';

                List<SObject> forUndelete = Database.query(childQuery);
                List<Database.UndeleteResult> undelResults = Database.undelete(forUndelete, false);
                ERR_Handler.Errors errorResult = ERR_Handler.getErrors(undelResults, forUndelete);
                if (errorResult.errorsExist) {
                    ERR_Handler.processErrors(errorResult.errorRecords, 'TDTM');
                }
            }
        }
    }

    /*******************************************************************************************************
    * @description Creates query for objects to delete or undelete.
    * @param childLookup The combo key containing the to query and the relationship to the parent object.
    * @return String The query.
    ********************************************************************************************************/
    private String getQuery(String childLookup) {
        String childObjectName = childLookup.split('\\|')[0];
        String lookupFieldName = childLookup.split('\\|')[1];

        String childQuery = 'SELECT ID FROM ' + childObjectName;
        childQuery += ' WHERE ' + lookupFieldName + ' IN :deletedParents';

        return childQuery;
    }
}