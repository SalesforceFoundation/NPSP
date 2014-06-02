/*
    Copyright (c) 2009, Salesforce.com Foundation
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
* @description Trigger handler on Allocation object.
*/

public class ALLO_Allocations_TDTM extends TDTM_Runnable {
    
    //flag to prevent recursion
    public static boolean isRunning;

    //which fund is considered default, query custom setting
    public id defaultFund;

    public map<id,alloWrapper> mapWrapper;

    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
    
        list<Allocation__c> triggerList = (list<Allocation__c>) newList;


        mapWrapper = fillMapWrapper(triggerList);
        
        for (integer i=0;i<triggerList.size();i++) {
            //current trigger allocation object
            Allocation__c allo = triggerList[i];
            //old version of the trigger object if this is an update, or a blank object for comparisons if this is an insert
            Allocation__c oldAllo = triggerAction == TDTM_Runnable.Action.BeforeInsert ? new Allocation__c() : (Allocation__c) oldlist[i];
            //this allocation's wrapper
            alloWrapper wrap = mapWrapper.get(allo.Opportunity__c);
            
            //Percent has changed, or this is a new allocation with a percentage
            if (allo.Percent__c!=null && allo.Percent__c!=oldAllo.Percent__c) {

            }

            //verify the total allocations don't exceed the opportunity amount
            if (allo.Payment__c==null && wrap.totalOppAllocations > wrap.oppAmount)
                allo.addError(Label.alloTotalExceedsOppAmt);
            //verify the total payment allocations don't exceed the payment amount
            if (allo.Payment__c!=null && wrap.mapTotalPaymentAllocations.get(allo.Payment__c) > wrap.mapPaymentAmounts.get(allo.Payment__c))
                allo.addError(Label.alloPaymentTotalExceedsPaymentAmt);
        }


        return null;
    }

    //wrapper class to hold all allocation and payment information for a single opportunity
    class alloWrapper {
        boolean isPercentOnly = true;                                        //tracks whether all allocations are percentage based
        boolean isOppOnly = true;                                            //tracks whether all allocations only apply to the opportunity level
        decimal oppAmount = 0;                                               //opportunity amount
        decimal totalOppAllocations = 0;                                     //holds total allocation amount for this opportunity
        map<id,decimal> mapPaymentAmounts = new map<id,decimal>();           //holds the payment amounts
        map<id,decimal> mapTotalPaymentAllocations = new map<id,decimal>();  //holds total allocation amounts for all paymenst related to this opportunity
        list<Allocation__c> triggerList = new list<Allocation__c>();         //all allocations for this opportunity in the current trigger set
        list<Allocation__c> listAllo = new list<Allocation__c>();            //all allocations for this opportuntiy

    }

    //fills the wrapper with data
    public map<Id, alloWrapper> fillMapWrapper (list<Allocation__c> triggerList) {

        map<id,alloWrapper> mapIdToWrapper = new map<id,alloWrapper>();
        set<id> setOppId = new set<id>();

        //build a list of opportunity Ids to fill wrapper with data
        for (Allocation__c allo : triggerList) {
            setOppId.add(allo.Opportunity__c);
            
            //create wrapper object and add to map
            if (!mapIdToWrapper.containsKey(allo.Opportunity__c)) {
                alloWrapper wrapper = new alloWrapper();
                mapIdToWrapper.put(allo.Opportunity__c, wrapper);    
            }
        }

        //fill wrapper with current trigger set allocations
        for (Allocation__c allo : triggerList) {
            mapIdToWrapper.get(allo.Opportunity__c).triggerList.add(allo);
        }

        //fill wrapper with all allocations for this opportunity
        //getting payment and opportunity info here to avoid excess queries
        for (Allocation__c allo : [SELECT Id, Opportunity__c, Opportunity__r.Amount, Payment__c, Payment__r.npe01__Payment_Amount__c, Amount__c, Percent__c FROM Allocation__c WHERE Opportunity__c IN :setOppId]) {
            alloWrapper wrap = mapIdToWrapper.get(allo.Opportunity__c);
            
            //add this allocation to the list
            wrap.listAllo.add(allo);
            
            //add opportunity amount and allocation totals
            wrap.oppAmount = allo.Opportunity__r.Amount;
            wrap.totalOppAllocations += allo.Amount__c;
            
            //add payment amount and allocation totals to maps
            if (allo.Payment__c != null) {
                //any allocation with a payment sets this flag to false
                wrap.isOppOnly = false;

                //get payment amount
                if (!wrap.mapPaymentAmounts.containsKey(allo.Payment__c))
                    wrap.mapPaymentAmounts.put(allo.Payment__c, allo.Payment__r.npe01__Payment_Amount__c);
                //create or add to payment total map
                if (!wrap.mapTotalPaymentAllocations.containsKey(allo.Payment__c))
                    wrap.mapTotalPaymentAllocations.put(allo.Payment__c, allo.Amount__c);
                else wrap.mapTotalPaymentAllocations.put(allo.Payment__c, wrap.mapTotalPaymentAllocations.get(allo.Payment__c) + allo.Amount__c);
            }

            //if any allocations don't have a percent, set flag to false
            if (allo.Percent__c == null)
                wrap.isPercentOnly = false;
        }
        return mapIdToWrapper;
    }
}