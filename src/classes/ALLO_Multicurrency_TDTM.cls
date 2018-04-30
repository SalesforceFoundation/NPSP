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
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Class for multicurrency triggers and allocations rollup multicurrency related code.
*/
public class ALLO_Multicurrency_TDTM extends TDTM_Runnable {

    /** @description Map holds exchange rates to avoid multiple queries. */
    public static map<string, decimal> exchangeRates = new map<string,decimal>();
    
    /** @description This organization's default corporate currency. */
    public static string currCorporate = UTIL_Currency.getInstance().getOrgDefaultCurrency();

    /** @description DmlWrapper to hold object changes. */
    public DmlWrapper wrapper = new DmlWrapper();

    /*******************************************************************************************************
    * @description Trigger handler on Campaign and Recurring Donation for updating child allocation currency
    * when the parent currency is changed.
    * @param listNew The list of campaigns or recurring donations from trigger new. 
    * @param listOld The list of campaigns or recurring donations from trigger old. 
    * @param triggerAction Which action triggered the current context. (Before or After; Insert, Update, 
    * Delete, or Undelete.)
    * @param objResult The field describe object for the current trigger context. 
    * @return dmlWrapper Objects that need to be inserted or updated after the processing of the trigger.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        //if this is a multicurrency org, update child objects 
        if (UTIL_Currency.getInstance().isMultiCurrencyOrganization() && !TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ALLOC)) {
            wrapper.objectsToUpdate.addAll((list<sObject>) updateAllocationCurrencyFromParent(newlist, oldlist));

            // Increment the recursion flag to prevent the allocation triggers from running,
            // process the DML, and then decrement the recursion flag
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, true);
            TDTM_TriggerHandler.processDML(wrapper);
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, false);
        }
        return null;
    }

    /*******************************************************************************************************
    * @description For any given list of allocation parent objects, (Opportunity, Campaign, or Recurring 
    * Donation,) queries for child allocations and updates currency to match parent.
    * @param listNew The list of opportunities, campaigns, or recurring donations from trigger new. 
    * @param listOld The list of opportunities, campaigns, or recurring donations from trigger old. 
    * @return list<Allocation__c> Allocations with modified currency that need updating via DML.
    ********************************************************************************************************/
    public static list<Allocation__c> updateAllocationCurrencyFromParent(list<sObject> newlist, list<sObject> oldlist) {
        list<Allocation__c> results = new list<Allocation__c>();
        //map holds object id to currency iso code
        map<id,string> mapIdToISO = new map<id,string>();

        //if the parent currency has changed, add to map
        for (integer i=0;i<newlist.size();i++) {
            if (newlist[i].get('CurrencyIsoCode')!=oldlist[i].get('CurrencyIsoCode')) {
                mapIdToISO.put((id)newlist[i].get('id'),(string)newlist[i].get('CurrencyIsoCode'));
            }
        }

        //can't put mapIdToISO.keySet() in dynamic soql query, so creating new set to hold the IDs
        set<id> parentIds = mapIdToISO.keySet();

        string alloQuery = 'SELECT Id, Amount__c, Opportunity__c, Campaign__c, Recurring_Donation__c, CurrencyIsoCode FROM Allocation__c '+
            'WHERE Opportunity__c IN :parentIds OR Campaign__c IN :parentIds OR Recurring_Donation__c IN :parentIds';
        
        //query all allocations associated with the parents, update their ISO code and their amount if needed 
        for (Allocation__c allo : database.query(alloQuery)) {
            string parentCurrency = mapIdToISO.get(ALLO_Allocations_TDTM.getParentId(allo));
            
            /*Not updating allocation amounts, as Salesforce only updates the currency and does not convert the amount
            if (allo.Amount__c!=null)
                allo.Amount__c = convertCurrency(parentCurrency, (string)allo.get('CurrencyIsoCode'), allo.Amount__c);
            */
            allo.put('CurrencyIsoCode', parentCurrency);
            results.add(allo);
        }

        return results;
    }

    /*******************************************************************************************************
    * @description For a list of allocations, set the currency based on the parent object, and if the setting
    *   has been configured when ACM is enabled also store the applied dated exchange rate on the record.
    * @param listAllo The list of allocations. 
    * @return void This method modifies the list of allocations directly and returns nothing.
    ********************************************************************************************************/
    public static void updateAllocationCurrency(List<Allocation__c> listAllo) {
        Map<Id,SObject> mapIdToParentObject = new Map<Id,SObject>();

        // collect parent Ids
        Set<Id> parentIds = new Set<Id>();
        for (Allocation__c allo : listAllo) {
            parentIds.add(ALLO_Allocations_TDTM.getParentId(allo));
        }

        // Get parent SObject (with IsoCode)
        mapIdToParentObject = getParentFromIdSet(parentIds);

        for (Allocation__c allo : listAllo) {
            // Update allocation ISO code to match parent
            String parentCurrCode = (String)mapIdToParentObject.get(ALLO_Allocations_TDTM.getParentId(allo)).get('CurrencyIsoCode');
            allo.put('CurrencyIsoCode', parentCurrCode);
        }
    }

    /*******************************************************************************************************
    * @description For any set of ids of any sObject, gets the sObject's currency code.
    * @param setId A set of ids of any sObjects.
    * @return Map<Id,SObject> A map from the Id of the object to the parent SObject with the currency code
    *   and optionally the CloseDate
    ********************************************************************************************************/
    private static Map<Id,SObject> getParentFromIdSet (Set<Id> setId) {
        Map<Id,SObject> results = new Map<Id,SObject>();
        Set<string> parentTypes = new Set<string>();

        //get parent object names for query
        for (Id thisId : setId)
            parentTypes.add(thisId.getSObjectType().getDescribe().getName());

        //query for ISO codes, fill out map
        for (string parent : parentTypes) {
            string query = 'SELECT Id, CurrencyIsoCode';
            if (parent == 'Opportunity') {
                query += ', CloseDate';
            }
            query += ' FROM ' + parent + ' WHERE Id IN :setId';
            for (sObject sobj : database.query(query))
                results.put((Id)sobj.get('Id'),sobj);
        }

        return results;
    }

    /**
     * @description Wrapper for the utility method to determine if multi-currency is enabled in the org
     * The target utility class can be mocked for unit tests.
     * @return True if multi-currency is enabled in the org
     */
    public static Boolean isMultiCurrency() {
        return UTIL_Currency.getInstance().isMultiCurrencyOrganization();
    }
}