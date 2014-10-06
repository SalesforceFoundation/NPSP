/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
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
* @author Salesforce.com Foundation
* @date 2014
* @description Class for multicurrency triggers and allocations rollup multicurrency related code.
*/
public with sharing class ALLO_Multicurrency_TDTM extends TDTM_Runnable {
	
/*
AFTER UPDATE Opportunity / Campaign / RD currency change: copy currency to allocation.
    add opp case
*/

    //set when multicurrency check is called, holds the field string/sobject mapping
    public static Map<String, SObjectField> mcFieldValues = new Map<String, SObjectField>();
    public static boolean multiCurrency;
    //exchangerate store
    static map<string, decimal> exchangeRates = new map<string,decimal>();
    //corporate currency
    public static string currCorporate;

    public DmlWrapper wrapper = new DmlWrapper();

    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        //if this is a multicurrency org, update child objects 
        if (isMultiCurrency())
            wrapper.objectsToUpdate.addAll((list<sObject>)updateAllocationCurrencyFromParent(newlist,oldlist));

        return wrapper;
    }

    // for any list of allocation parent objects (Opportunity, Campaign, Recurring Donation),
    // gets a list of their child allocations, updates their CurrencyIsoCode
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

        string alloQuery = 'SELECT Id, Amount__c, Opportunity__c, Campaign__c, Recurring_Donation__c, CurrencyIsoCode FROM Allocation__c '+
            'WHERE Opportunity__c IN :mapIdToISO OR Campaign__c IN :mapIdToISO OR Recurring_Donation__c IN :mapIdToISO';
        
        //query all allocations associated with the parents, update their ISO code and their amount if needed 
        for (Allocation__c allo : database.query(alloQuery)) {
            string parentCurrency = mapIdToISO.get(ALLO_Allocations_TDTM.getParentId(allo));
            
            /*Not updating allocagion amounts, as Salesforce only updates the currency and does not convert the amount
            if (allo.Amount__c!=null)
                allo.Amount__c = convertCurrency(parentCurrency, (string)allo.get('CurrencyIsoCode'), allo.Amount__c);
            */
            allo.put('CurrencyIsoCode', parentCurrency);
            results.add(allo);
        }

        return results;
    }

    //for a list of allocations, set the currency ISO code from the parent object
    public static void updateAllocationCurrency(list<Allocation__c> listAllo) {
        map<id,string> mapIdToISO = new map<id,string>();

        //collect parent Ids
        for (Allocation__c allo : listAllo) {
            mapIdToISO.put(ALLO_Allocations_TDTM.getParentId(allo),null);
        }

        //get iso codes of parents
        mapIdToISO = getISOFromIdSet(mapIdToISO.keySet());

        //update allocation ISO code to match parent
        for (Allocation__c allo : listAllo) {
            allo.put('CurrencyIsoCode',mapIdToISO.get(ALLO_Allocations_TDTM.getParentId(allo)));
        }
    }

    //for any set of Ids, gets the sObject's currency ISO code
    public static map<id,string> getISOFromIdSet (set<id> setId) {
        map<id,string> results = new map<id,string>();
        set<string> parentTypes = new set<string>();

        //get parent object names for query
        for (id thisId : setId)
            parentTypes.add(thisId.getSObjectType().getDescribe().getName());

        //query for ISO codes, fill out map
        for (string parent : parentTypes) {
            string query = 'SELECT Id, CurrencyIsoCode FROM ' + parent + ' WHERE Id IN :setId';
            for (sObject sobj : database.query(query))
                results.put((id)sobj.get('id'),(string)sobj.get('CurrencyIsoCode'));
        }

        return results;
    }

    //returns a boolean if we are in a multi-currency org or not.
    //on first execution sets up static variables etc
    public static boolean isMultiCurrency(){                    
        if (multiCurrency==null){
            //create currency field handles for later dynamic dml
            mcFieldValues.put('Opportunity', Schema.sObjectType.Opportunity.fields.getMap().get('CurrencyIsoCode'));
            mcFieldValues.put('Allocation__c', Schema.sObjectType.Account.fields.getMap().get('CurrencyIsoCode'));
            mcFieldValues.put('General_Accounting_Unit__c', Schema.sObjectType.Contact.fields.getMap().get('CurrencyIsoCode'));

            String queryExchangeRates = 'select IsoCode,ConversionRate,IsCorporate from CurrencyType';
            SObjectType soCurrencyType = Schema.getGlobalDescribe().get('CurrencyType'); 

            //are we in a multi-currency org?
            if (mcFieldValues.get('Opportunity') != null && mcFieldValues.get('Allocation__c') != null && 
                mcFieldValues.get('General_Accounting_Unit__c') != null && soCurrencyType != null){
                multiCurrency = true;
 
                map<string,SObjectField> ctFields = soCurrencyType.getDescribe().fields.getMap();
                SObjectField ctIsoCode = ctFields.get('IsoCode');
                SObjectField ctConversionRate = ctFields.get('ConversionRate');
                SObjectField ctCorporate = ctFields.get('IsCorporate');

                //iterate over all the currencies in the org (inc. inactive ones as they may have been used previously)
                //this allows us to put them in a map and use the ISO code as key and also set the corporate
                for(sObject ct: Database.query(queryExchangeRates)){
                    exchangeRates.put((string)ct.get(ctIsoCode),(decimal)ct.get(ctConversionRate));
                    if((boolean)ct.get(ctCorporate))currCorporate=(string)ct.get(ctIsoCode);
                }
            }
            else
                multiCurrency = false; 
        }        
        return multiCurrency;
    }

    //do a conversion from amount in corporate currency to the currency specified by the ISO code
    public static decimal convertFromCorporate(String ISO,Decimal amt){
        if(currCorporate == ISO || currCorporate == null) // no need to convert
            return amt;
        else //return value to 2DP
            return (amt * exchangeRates.get(ISO)).setScale(2) ;
    }

    public static decimal convertCurrency(String fromISO, String toISO, Decimal amt){
        if(fromISO == toISO) // no need to convert
            return amt;
        else //return value to 2DP
            return ((amt / exchangeRates.get(fromISO)) * exchangeRates.get(toISO)).setScale(2) ;
    }

}