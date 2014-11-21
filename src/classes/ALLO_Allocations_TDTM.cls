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
* @description Trigger handler on Allocation object, forces allocations for a single parent to not exceed the parent amount,
*              and calculates amount for percentage based allocations.
*/
public class ALLO_Allocations_TDTM extends TDTM_Runnable {

    //flags to prevent recursion
    public static boolean hasRunForAllocationsBefore = false;
    public static boolean hasRunForAllocationsAfter = false;
    public static boolean hasRunForOpportunities = false;

    //holds all relevant allocations data for this transaction
    public map<id,alloWrapper> mapWrapper = new map<id,alloWrapper>();
    public DmlWrapper dmlWrapper = new dmlWrapper();

    //allocations settings
    public static Allocations_Settings__c settings = UTIL_CustomSettingsFacade.getAllocationsSettings();

    //holds the default General Accounting Unit if creating default allocations is enabled
    public static id idDefaultGAU = null;

    //wrapper class to hold all allocation and payment information for a single parent (opp, campaign, or recurring donation)
    private class alloWrapper {
        boolean isPercentOnly = true;                                        //tracks whether all allocations are percentage based
        decimal parentAmount = null;                                         //amount of this allocation's parent
        decimal totalAmount = 0;                                             //holds total allocation amount
        decimal totalPercent = 0;                                            //holds total percentage allocations
        list<Allocation__c> triggerList = new list<Allocation__c>();         //all allocations for this opportunity in the current trigger set
        list<Allocation__c> listAllo = new list<Allocation__c>();            //all non-default allocations for this parent object
        Allocation__c defaultAllo = null;                                    //the default allocation for this parent object
        boolean defaultInTrigger = false;                                    //is the default allocation in the current trigger set?
    }

    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        //if default allocations are enabled, verify that we have an ID value for the default fund
        if (settings.Default_Allocations_Enabled__c) {
            if (settings.Default__c == null) {
                sObject obj = newList.isEmpty() ? oldList[0] : newList[0];
                obj.addError(Label.alloDefaultGAUMissing);
            } else
                idDefaultGAU = settings.Default__c;
        }

        // dispatch to the correct handler
        if (objResult.getName() == UTIL_Namespace.StrTokenNSPrefix('Allocation__c') && !hasRunForAllocationsBefore && 
            (triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate)) {

            runAllocationBeforeTriggerHandler(newlist, oldlist, triggerAction, objResult);
            hasRunForAllocationsBefore = true;
        } else if (objResult.getName() == UTIL_Namespace.StrTokenNSPrefix('Allocation__c') && !hasRunForAllocationsAfter && 
            (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterDelete)) {

            runAllocationAfterTriggerHandler(newlist, oldlist, triggerAction, objResult);
            //setting before to true for afterDelete case, to avoid running triggers on DML wrapper objects
            hasRunForAllocationsBefore = true;
            hasRunForAllocationsAfter = true;
        } else if (objResult.getName() == 'Opportunity' && !hasRunForOpportunities) {

            runOpportunityTriggerHandler(newlist, oldlist, triggerAction, objResult);
            hasRunForOpportunities = true;
            hasRunForAllocationsBefore = true;
            hasRunForAllocationsAfter = true;
        }
        return dmlWrapper;
    }
        
    private void runOpportunityTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        set<id> oppRecordTypesToExclude = new set<id>();
        set<string> oppTypesToExclude = new set<string>();
        if (settings.Excluded_Opp_RecTypes__c!=null) 
            oppRecordTypesToExclude = UTIL_RecordTypes.GetRecordTypeIdSet('Opportunity', new set<string>(settings.Excluded_Opp_RecTypes__c.split(';')));
        if (settings.Excluded_Opp_Types__c!=null)
            oppTypesToExclude = new set<string>(settings.Excluded_Opp_Types__c.split(';'));

        list<Opportunity> listOppsForProcessing = new list<Opportunity>();
        for (integer i=0; i<newList.size(); i++) {
            Opportunity opp = (Opportunity) newlist[i];


            //skip excluded opp types and recordtypes
            if (oppRecordTypesToExclude.contains((id)opp.get('RecordTypeId')) || oppTypesToExclude.contains(opp.Type))
                continue;

            //INSERT case: Verify associated Campaign and Recurring Donations to auto create allocations
            if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
                //don't do anything on insert if we don't have an amount
                if (opp.Amount == null)
                    continue;
                //if this new opportunity has a Campaign or RD, add to list for processing
                else if (opp.CampaignId != null || opp.npe03__Recurring_Donation__c != null)
                    listOppsForProcessing.add(opp);
                //create a default allocation for the total amount, only if there's no possibility of other allocations from related objects
                else if (settings.Default_Allocations_Enabled__c) {
                    dmlWrapper.objectsToInsert.add(makeDefaultAllocation(opp));
                }
            }

            //UPDATE case: if the opportunity amount changed, or the opp went to a closed/won stage: add to the list for processing
            if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                if (opp.Amount != oldlist[i].get('Amount')) {
                    listOppsForProcessing.add(opp);
                }
                //if currency has changed, reset allocation currencies
                if (ALLO_Multicurrency_TDTM.isMultiCurrency()) {
                    if (opp.get('CurrencyIsoCode') != oldlist[i].get('CurrencyIsoCode')) {
                        listOppsForProcessing.add(opp);
                    }
                }
            }
        }

        if (!listOppsForProcessing.isEmpty()) {
            fillMapWrapper(listOppsForProcessing);
            
            if (triggerAction == TDTM_Runnable.Action.AfterInsert)
                copyRecurringDonationCampaignAllocations(listOppsForProcessing);
            
            else if (triggerAction == TDTM_Runnable.Action.AfterUpdate)
                opportunityAmountCurrencyChange(listOppsForProcessing);
        }
    }

    private void runAllocationBeforeTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        
        list<Allocation__c> triggerList = (list<Allocation__c>) newList;

        for (integer i=0; i<triggerList.size(); i++) {  
            Allocation__c allo = triggerlist[i];

            //if we don't have a parent, or have more than one parent, exception thrown
            if (parentError(allo))
                allo.AddError(Label.alloSingleParent);
            //neither an amount nor a percent is defined
            if (allo.Amount__c == null && allo.Percent__c == null)
                allo.addError(Label.alloAmountOrPercent);
            //negative amount
            if (allo.Amount__c != null && allo.Amount__c < 0)
                allo.addError(Label.alloNegativeAmount);
            //negative percent
            if (allo.Percent__c != null && allo.Percent__c < 0)
                allo.addError(Label.alloNegativePercent);
            //manually updated currency
            if (triggerAction == TDTM_Runnable.Action.BeforeUpdate && ALLO_Multicurrency_TDTM.isMultiCurrency() && allo.get('CurrencyIsoCode') != oldList[i].get('CurrencyIsoCode'))
                allo.addError(Label.alloModifyCurrency);

        }


        fillMapWrapper(triggerList);
        
        //verify that we're not over the total amount, and that everything is equalized
        for (Allocation__c allo : triggerList) {  

            alloWrapper wrap = mapWrapper.get(getParentId(allo));
            
            //if we exceed 100%
            if (wrap.totalPercent > 100) {
                allo.addError(Label.alloPercentExceed100);
            }

            //skip this check for Campaign and Recurring Donation allocations
            if (wrap.parentAmount==null) 
                continue;

            //verify the total allocations don't exceed the parent amount
            if (wrap.totalAmount > wrap.parentAmount)
                allo.addError(Label.alloTotalExceedsOppAmt);

        }

        //if this org is multicurrency and this is an insert, set currency ISO code based on parent ISO code
        if (triggerAction == TDTM_Runnable.Action.BeforeInsert && ALLO_Multicurrency_TDTM.isMultiCurrency())
            ALLO_Multicurrency_TDTM.updateAllocationCurrency(triggerList);

        //TODO: don't let users change allocation currency manually

    }

    //when a recurring donation allocation is modified, create or modify all allocations for open opportunities under that recurring donations' schedule to match the RD allocations
    private void runAllocationAfterTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        
        list<Opportunity> listOpps = new list<Opportunity>();
        set<id> setRecDonId = new set<id>();
        set<id> setOppIds = new set<id>();

        for (Allocation__c allo : triggerAction == TDTM_Runnable.Action.AfterDelete ? (list<Allocation__c>) oldList : (list<Allocation__c>) newList) {
            //if this allocation is for a recurring donation, save the Id for updating open opportunities under that RD schedule
            if (allo.Recurring_Donation__c != null)
                setRecDonId.add(allo.Recurring_Donation__c);
            //if this is an opportunity allocation and defaults are enabled, adjust/create/delete the default
            if (settings.Default_Allocations_Enabled__c && allo.Opportunity__c!=null)
                setOppIds.add(allo.Opportunity__c);
        }
        

        if (!setRecDonId.isEmpty() || !setOppIds.isEmpty()) {
            string oppQuery = 'SELECT Id, Amount, npe03__Recurring_Donation__c, CampaignId';
            if (ALLO_Multicurrency_TDTM.isMultiCurrency())
                oppQuery += ', CurrencyIsoCode';
            oppQuery+=' FROM Opportunity WHERE (Opportunity.isClosed = FALSE AND npe03__Recurring_Donation__c IN :setRecDonId) OR ID IN :setOppIds';
            listOpps = database.query(oppQuery);
        }

        if (!listOpps.isEmpty()) {

            fillMapWrapper(listOpps);

            //if we have any opportunity allocations and default handling is enabled, adjust the opps' default allocation
            list<Opportunity> listRecDonOpps = new list<Opportunity>();
            if (!setOppIds.isEmpty()) {
                for (Opportunity opp : listOpps) {
                    //we have allocations for this opportunity
                    if (setOppIds.contains(opp.Id)) {
                        //this opp has allocations, check for default cases
                        if (mapWrapper.containsKey(opp.Id)) {
                            alloWrapper oppWrap = mapWrapper.get(opp.id);
                            //adjust default allocation, and add to DML wrapper if needed
                            decimal amountDifferential = opp.Amount - oppWrap.totalAmount;

                            //no remainder: delete default allocation
                            if (amountDifferential == 0 && oppWrap.defaultAllo!=null) {
                                dmlWrapper.objectsToDelete.add(oppWrap.defaultAllo);
                            } else if (amountDifferential > 0) {
                                //create a default allocation if we don't have one
                                if (oppWrap.defaultAllo == null) {
                                    oppWrap.defaultAllo = makeDefaultAllocation(opp);
                                    oppWrap.defaultAllo.Amount__c = amountDifferential;
                                    dmlWrapper.objectsToInsert.add(oppWrap.defaultAllo);
                                } else if (oppWrap.defaultAllo.Amount__c != amountDifferential) {
                                    oppWrap.defaultAllo.Amount__c = amountDifferential;
                                    dmlWrapper.objectsToUpdate.add(oppWrap.defaultAllo);
                                }
                            }          
                        //this opp has no allocations, just create the default
                        } else dmlWrapper.objectsToInsert.add(makeDefaultAllocation(opp));
                    //if this was a recurring donation allocation, add to list for processing
                    } else listRecDonOpps.add(opp);
                }
            //no opportunity default cases, just copy the list over
            } else listRecDonOpps = listOpps;

            //after insert/update/delete of Recurring Donation allocations: delete and recreate all open opportunities' allocations
            if (!listRecDonOpps.isEmpty()) {

                //first, delete all existing opp allocations
                for (Opportunity opp : listRecDonOpps) {
                    if (mapWrapper.containsKey(opp.id)){
                        alloWrapper oppWrap = mapWrapper.get(opp.id);
                        dmlWrapper.objectsToDelete.addAll((list<sObject>)oppWrap.listAllo);
                        if (settings.Default_Allocations_Enabled__c && oppWrap.defaultAllo!=null)
                            dmlWrapper.objectsToDelete.add(oppWrap.defaultAllo);
                    }
                }

                //then, recreate them based on the recurring donation
                copyRecurringDonationCampaignAllocations(listRecDonOpps);
            }
        }
    }

    //for a list of opportunities, makes campaign and recurring donation allocatoins and adds them for insert
    //handles default allocations
    private void copyRecurringDonationCampaignAllocations(list<Opportunity> listOpps) {
        
        for (Opportunity opp : listOpps) {
            //if we have recurring donation or campaign allocations
            if ((opp.npe03__Recurring_Donation__c != null && mapWrapper.containsKey(opp.npe03__Recurring_Donation__c)) ||
                (opp.CampaignId != null && mapWrapper.containsKey(opp.CampaignId))) {

                alloWrapper wrap;
                //get wrapper for parent object, preferring recurring donation over campaign allocations if they exist
                if (opp.npe03__Recurring_Donation__c != null && mapWrapper.containsKey(opp.npe03__Recurring_Donation__c))
                    wrap = mapWrapper.get(opp.npe03__Recurring_Donation__c);
                else 
                    wrap = mapWrapper.get(opp.CampaignId);

                list<Allocation__c> listAlloForInsert = new list<Allocation__c>();
                
                //add only allocations to active GAUs
                for (Allocation__c allo : wrap.listAllo.deepclone())
                    if (allo.General_Accounting_Unit__r.Active__c)
                        listAlloForInsert.add(allo);

                decimal remainder = opp.Amount;

                //reparent the cloned allocation to the opportunity
                for (Allocation__c allo : listAlloForInsert) {
                    allo.Recurring_Donation__c = null;
                    allo.Campaign__c = null;
                    allo.Opportunity__c = opp.id;
                    
                    //if this is a multicurrency org, recalculate the amount and set the CurrencyIsoCode
                    if (ALLO_Multicurrency_TDTM.isMultiCurrency()) {
                        if (allo.Amount__c!=null) {
                            allo.Amount__c = ALLO_Multicurrency_TDTM.convertCurrency(
                                (string)allo.get('CurrencyIsoCode'), 
                                (string)opp.get('CurrencyIsoCode'), 
                                allo.Amount__c
                            );
                        }
                        allo.put('CurrencyIsoCode',opp.get('CurrencyIsoCode'));
                    }

                    if (allo.Percent__c != null)
                        allo.Amount__c = (Opp.Amount * allo.Percent__c * .01).setScale(2);
                    remainder -= allo.Amount__c;
                }
                
                //if our remainder is negative, only create percentage based allocations
                if (remainder < 0) {
                    remainder = opp.Amount;
                    //TODO: log error: not able to create allocations. chatter post?
                    for (Allocation__c allo : listAlloForInsert) {
                        if (allo.Percent__c!=null) {
                            dmlWrapper.objectsToInsert.add(allo);
                            remainder-=allo.Amount__c;
                        }
                    }
                    if (settings.Default_Allocations_Enabled__c) {
                        Allocation__c defaultAllo = makeDefaultAllocation(opp);
                        defaultAllo.Amount__c = remainder;
                        dmlWrapper.objectsToInsert.add(defaultAllo);
                    }

                //create default allocation if needed
                } else if (settings.Default_Allocations_Enabled__c && remainder > 0) {
                    Allocation__c defaultAllo = makeDefaultAllocation(opp);
                    defaultAllo.Amount__c = remainder;
                    dmlWrapper.objectsToInsert.add(defaultAllo);
                    dmlWrapper.objectsToInsert.addAll((list<sObject>)listAlloForInsert);
                //add objects to DML wrapper in all other cases (no remainder, or positive remainder without default allocations enabled)
                } else {
                    dmlWrapper.objectsToInsert.addAll((list<sObject>)listAlloForInsert);
                }
            //if we have no campaign or recurring donation allocations and defaults are enabled, create them for each opportunity
            } else if (settings.Default_Allocations_Enabled__c) {
                dmlWrapper.objectsToInsert.add(makeDefaultAllocation(opp));
            }
        }
    }

    //opportunity amount has changed or currency has changed. retrieve this opps allocations, adjust amounts and currencies
    //adjust percentage based allocations, adjust default allocations if enabled, 
    //enforce that total allocations don't exceed the opportunity amount
    private void opportunityAmountCurrencyChange(list<Opportunity> listOpps){
        
        for (Opportunity opp : listOpps) {
        
            if (mapWrapper.containsKey(opp.id)) {
                alloWrapper oppWrap = mapWrapper.get(opp.id);

                //null amount: delete all associated allocations
                if (opp.Amount == null) {
                    dmlWrapper.objectsToDelete.addAll((list<sObject>)oppWrap.listAllo);
                    if (settings.Default_Allocations_Enabled__c && oppWrap.defaultAllo!=null)
                        dmlWrapper.objectsToDelete.add(oppWrap.defaultAllo);
                } else {

                    for (Allocation__c allo : oppWrap.listAllo) {
                        //if the percentage changed, recalculate the amount
                        if (allo.Percent__c!=null && allo.Percent__c>0 && allo.Amount__c != (oppWrap.parentAmount * allo.Percent__c * .01).setScale(2)) {
                            //remove the previous amount, recalculate the amount, and add it back
                            oppWrap.totalAmount -= allo.Amount__c;
                            allo.Amount__c = (oppWrap.parentAmount * allo.Percent__c * .01).setScale(2);
                            oppWrap.totalAmount += allo.Amount__c;
                            
                            if (ALLO_Multicurrency_TDTM.isMultiCurrency())
                                allo.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));

                            dmlWrapper.objectsToUpdate.add(allo);
                        //if just the currency changed, recalculate the currency
                        } else if (ALLO_Multicurrency_TDTM.isMultiCurrency() && allo.get('CurrencyIsoCode') != opp.get('CurrencyIsoCode')) {
                            allo.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
                            dmlWrapper.objectsToUpdate.add(allo);
                        }
                    }
                    //if the Default allocation handling is enabled, create/update/delete the default allocation to cover 100% of the opportunity
                    if (settings.Default_Allocations_Enabled__c) {
                        decimal remainder = oppWrap.parentAmount - oppWrap.totalAmount;
                        if (remainder==0) {
                            if (oppWrap.defaultAllo!=null)
                                dmlWrapper.objectsToDelete.add(oppWrap.defaultAllo);
                        } else if (remainder > 0) {
                            if (oppWrap.defaultAllo==null) {
                                oppWrap.defaultAllo = makeDefaultAllocation(opp);
                                oppWrap.defaultAllo.Amount__c = remainder;
                                dmlWrapper.objectsToInsert.add(oppWrap.defaultAllo);
                            } else if (oppWrap.defaultAllo.Amount__c != remainder || (ALLO_Multicurrency_TDTM.isMultiCurrency() && oppWrap.defaultAllo.get('CurrencyIsoCode') != opp.get('CurrencyIsoCode'))) {
                                oppWrap.defaultAllo.Amount__c = remainder;
                                if (ALLO_Multicurrency_TDTM.isMultiCurrency())
                                    oppWrap.defaultAllo.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
                                dmlWrapper.objectsToUpdate.add(oppWrap.defaultAllo);
                            }
                        }
                    }
                    //if the Opportunity amount has decreased, we run the risk of allocations exceeding the total opportunity amount
                    if (oppWrap.totalAmount > oppWrap.parentAmount)
                        //using addError here because we want to block opportunity update, display the error inline, and block the DML of updating all the related allocations
                        opp.Amount.addError(Label.alloExceedsOppAmount);
                }
            //if we have no allocations for this opportunity, defaults are enabled, and the opportunity has an amount, make a default allocation
            } else if (settings.Default_Allocations_Enabled__c && opp.Amount != null) {
                dmlWrapper.objectsToInsert.add(makeDefaultAllocation(opp));
            }
        }
    }

    //fills the wrapper based on a list of allocations, updates current trigger set amounts to match percentage defined
    public void fillMapWrapper (list<Allocation__c> alloList) {

        set<id> setParentId = new set<id>();
        set<id> setExistingAlloId = new set<id>();

        //build a list of related object Ids to fill wrapper with data
        for (Allocation__c allo : alloList) {
            setParentId.add(getParentId(allo));

            //create wrapper object and add to map
            if (!mapWrapper.containsKey(getParentId(allo))) {
                alloWrapper wrapper = new alloWrapper();
                mapWrapper.put(getParentId(allo), wrapper);
            }
        }

        //fill wrapper with current trigger set allocations
        for (Allocation__c allo : alloList) {
            alloWrapper wrap = mapWrapper.get(getParentId(allo));
            wrap.triggerList.add(allo);
            
            //Add any allocation with an id to be excluded from calculations in the query
            if (allo.id != null)
                setExistingAlloId.add(allo.id);
            if (settings.Default_Allocations_Enabled__c && allo.General_Accounting_Unit__c == idDefaultGAU) {
                if (allo.Percent__c != null && allo.Opportunity__c != null)
                    allo.addError(Label.alloDefaultNotPercent);
                if (wrap.defaultAllo == null)
                    wrap.defaultAllo = allo;
                wrap.defaultInTrigger = true;
                continue;
            }

            if (allo.Amount__c!=null)
                wrap.totalAmount += allo.Amount__c;
            
            //if any allocations don't have a percent, set flag to false
            if (allo.Percent__c == null)
                wrap.isPercentOnly = false;
            else
                wrap.totalPercent += allo.Percent__c;
        }

        //fill wrapper with all allocations for this opportunity
        //getting payment and opportunity info here to avoid excess queries
        for (Allocation__c allo : [SELECT Id, Opportunity__c, Opportunity__r.Amount, Amount__c, Percent__c, General_Accounting_Unit__c, Recurring_Donation__c, Campaign__c FROM Allocation__c 
                WHERE (Opportunity__c IN :setParentId or Recurring_Donation__c IN :setParentId OR Campaign__c IN :setParentId) 
                AND Id NOT IN :setExistingAlloId]) {

            alloWrapper wrap = mapWrapper.get(getParentId(allo));
            
            //add opportunity amount and allocation totals
            wrap.parentAmount = allo.Opportunity__r.Amount;

            //save the default allocation.
            if (settings.Default_Allocations_Enabled__c && allo.General_Accounting_Unit__c == idDefaultGAU) {
                wrap.defaultAllo = allo;
                //keep the default allocation from listAllo
                continue;
            }

            if (allo.Amount__c!=null)
                wrap.totalAmount += allo.Amount__c;

            //add this allocation to the list
            wrap.listAllo.add(allo);

            //if any allocations don't have a percent, set flag to false
            if (allo.Percent__c == null)
                wrap.isPercentOnly = false;
            else if (allo.Percent__c!=null)
                wrap.totalPercent += allo.Percent__c;
        }

        set<id> setOppIds = new set<id>();

        //if we arrive here without a parent amount for an opportunity, we need another query for the parent info.
        for (Allocation__c allo : alloList) {
            alloWrapper wrap = mapWrapper.get(getParentId(allo));
            if (wrap.parentAmount == null && allo.Opportunity__c!=null) 
                setOppIds.add(allo.Opportunity__c);
        }

        //we have opportunities we need to query for a parent amount
        if (!setOppIds.isEmpty()) {
            for (Opportunity opp : [SELECT Id, Amount FROM Opportunity WHERE Id IN :setOppIds]) {
                mapWrapper.get(opp.id).parentAmount = opp.Amount;
            }
        }

        //verify the current trigger set has correct amounts based on the percentage chosen
        for (Allocation__c allo : alloList) {
            alloWrapper wrap = mapWrapper.get(getParentId(allo));
            if (allo.Percent__c!=null && wrap.parentAmount!=null) {
                //we don't have an amount yet, add it. we're only dealing with before triggers so we can just update the allocation
                if (allo.Amount__c==null) {
                    allo.Amount__c = (wrap.parentAmount * allo.Percent__c * .01).setScale(2);
                    wrap.totalAmount += allo.Amount__c;
                //we have an amount not equal to the percentage of the total, so update it and the total
                } else if (allo.Amount__c != (wrap.parentAmount * allo.Percent__c * .01).setScale(2)) {
                    //remove the previous amount, recalculate the amount, and add it back
                    wrap.totalAmount -= allo.Amount__c;
                    allo.Amount__c = (wrap.parentAmount * allo.Percent__c * .01).setScale(2);
                    wrap.totalAmount += allo.Amount__c;
                }
            }
        }
    }

    //fills wrapper based on Opportunities with or without parent objects (Campaigns or Recurring donations)
    public void fillMapWrapper (list<Opportunity> oppList) {
        set<id> setParentId = new set<id>();
        //create set of Campaign IDs, Recurring Donation Ids, and Opp Ids for query
        for (Opportunity opp : oppList) {
            if (opp.CampaignId != null)
                setParentId.add(opp.CampaignId);
            if (opp.npe03__Recurring_Donation__c != null)
                setParentId.add(opp.npe03__Recurring_Donation__c);
            setParentId.add(opp.id);
        }
            
        string alloQueryString = 'SELECT Id, Opportunity__c, Opportunity__r.Amount, Campaign__c, Recurring_Donation__c, ' + 
            'Amount__c, Percent__c, General_Accounting_Unit__c, General_Accounting_Unit__r.Active__c';
        
        //query for multicurrency string if multicurrency org
        if (ALLO_Multicurrency_TDTM.isMultiCurrency())
            alloQueryString += ', CurrencyIsoCode';

        alloQueryString += ' FROM Allocation__c WHERE (Opportunity__c IN :setParentId OR Campaign__c IN :setParentId OR Recurring_Donation__c IN :setParentId)';
        //alloQueryString += ' AND General_Accounting_Unit__r.Active__c = TRUE';

        for (Allocation__c allo : database.query(alloQueryString)) {
        
            //create wrapper if it doesn't exist yet
            if (!mapWrapper.containsKey(getParentId(allo)))
                mapWrapper.put(getParentId(allo), new alloWrapper());

            alloWrapper wrap = mapWrapper.get(getParentId(allo));
            
            //add opportunity amount and allocation totals
            if (allo.Opportunity__c != null) {
                wrap.parentAmount = allo.Opportunity__r.Amount;
            }
            
            //save the default allocation.
            if (settings.Default_Allocations_Enabled__c && allo.General_Accounting_Unit__c == idDefaultGAU) {
                wrap.defaultAllo = allo;
                continue;
            }

            if (allo.Amount__c!=null)    
                wrap.totalAmount += allo.Amount__c;

            //if any allocations don't have a percent, set flag to false
            if (allo.Percent__c == null)
                wrap.isPercentOnly = false;
            else if (allo.Percent__c != null)
                wrap.totalPercent += allo.Percent__c;

            wrap.listAllo.add(allo);

        }
    }

    //method returns the ID of this allocation's parent object (Opportunity, Recurring Donation, or Campaign)
    public static id getParentId (Allocation__c allo) {
        if (allo.Opportunity__c!=null) 
            return allo.Opportunity__c;
        if (allo.Recurring_Donation__c!=null)
            return allo.Recurring_Donation__c;
        if (allo.Campaign__c!=null)
            return allo.Campaign__c;
        return null;
    }

    //method returns true this allocation doesn't have exactly one parent object
    public boolean parentError (Allocation__c allo) {
        integer cParts=0;
        if (allo.Opportunity__c!=null) 
            cParts++;
        if (allo.Recurring_Donation__c!=null)
            cParts++;
        if (allo.Campaign__c!=null)
            cParts++;
        if (cParts==1) 
            return false;
        else
            return true;
    }

    //method returns a default allocation for a specifid opportunity
    public Allocation__c makeDefaultAllocation(Opportunity opp) {
        Allocation__c defaultAllo = new Allocation__c(
            Opportunity__c = opp.id,
            Amount__c = opp.Amount,
            General_Accounting_Unit__c = idDefaultGAU
        );
        if (ALLO_Multicurrency_TDTM.isMultiCurrency())
            defaultAllo.put('CurrencyIsoCode',opp.get('CurrencyIsoCode'));
        return defaultAllo;
    }

    //method resets static flags to specified state
    public static void resetFlags(boolean b) {
        hasRunForOpportunities = b;
        hasRunForAllocationsAfter = b;
        hasRunForAllocationsBefore = b;
    }
}