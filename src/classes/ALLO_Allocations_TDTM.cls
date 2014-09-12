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
* @description Trigger handler on Allocation object, forces allocations for a single parent to not exceed the parent amount,
*              and calculates amount for percentage based allocations.
*/

/*
TODO: 

Default behavior when we're over opp amount: only copy percentage allocations
after delete of allocations?

verify that Recurring Donation allocations are correctly handled and validated 

*/

public class ALLO_Allocations_TDTM extends TDTM_Runnable {
    
    //flags to prevent recursion
    
    public static boolean hasRunForAllocationsBefore = false;
    public static boolean hasRunForAllocationsAfter = false;
    public static boolean hasRunForOpportunities = false;

    public static void resetFlags() {
        hasRunForOpportunities = false;
        hasRunForAllocationsAfter = false;
        hasRunForAllocationsBefore = false;
    }

    //holds the default General Accounting Unit if creating default allocations is enabled
    public static id idDefaultGAU = null;

    //holds all relevant allocations data for this transaction
    public map<id,alloWrapper> mapWrapper;

    //allocations settings
    public static Allocations_Settings__c settings = UTIL_CustomSettingsFacade.getAllocationsSettings();

    public class AllocationsException extends Exception {}

    //wrapper class to hold all allocation and payment information for a single parent (opp, campaign, or recurring donation)
    private class alloWrapper {
        boolean isPercentOnly = true;                                        //tracks whether all allocations are percentage based
        decimal parentAmount = null;                                         //amount of this allocation's parent
        decimal totalAmount = 0;                                             //holds total allocation amount
        decimal totalPercent = 0;                                            //holds total percentage allocations
        list<Allocation__c> triggerList = new list<Allocation__c>();         //all allocations for this opportunity in the current trigger set
        list<Allocation__c> listAllo = new list<Allocation__c>();            //all non-default allocations for this parent object
        Allocation__c defaultAllo = new Allocation__c();                     //the default allocation for this parent object
        boolean defaultInTrigger = false;                                    //is the default allocation in the current trigger set?
    }

    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        System.debug('LookHere: settings: ' + settings);
        System.debug('LookHere: Entering trigger: ' + objResult.getName() + ' ' + triggerAction);
        
        //if allocations are not enabled, do nothing
        if (!settings.Allocations_Enabled__c)
            return null;

        //if default allocations are enabled, verify that we have an ID value for the default fund
        if (settings.Default_Allocations_Enabled__c) {
            if (settings.Default__c == null) {
                throw new AllocationsException(Label.alloDefaultGAUMissing);
                return null;
            } else idDefaultGAU = settings.Default__c;
        }

        // dispatch to the correct handler
        if (objResult.getName() == 'Allocation__c' && !hasRunForAllocationsBefore && 
            (triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate)) {
            DmlWrapper wrapper;
            wrapper = runAllocationBeforeTriggerHandler(newlist, oldlist, triggerAction, objResult);
            hasRunForAllocationsBefore = true;
            return wrapper;
        
        } else if (objResult.getName() == 'Allocation__c' && !hasRunForAllocationsAfter && 
            (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterDelete)) {
            DmlWrapper wrapper;
            wrapper = runAllocationAfterTriggerHandler(newlist, oldlist, triggerAction, objResult);
            hasRunForAllocationsAfter = true;
            return wrapper;

        } else if (objResult.getName() == 'Opportunity' && !hasRunForOpportunities) {
            DmlWrapper wrapper = runOpportunityTriggerHandler(newlist, oldlist, triggerAction, objResult);
            hasRunForOpportunities = true;
            //we're recalculating allocations amounts in the opportunity trigger handler and don't want to run twice
            hasRunForAllocationsBefore = true;
            hasRunForAllocationsAfter = true;
            return wrapper;
        } else {
            return null;
        }
    }
        
    private DmlWrapper runOpportunityTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        DmlWrapper dmlWrapper = new DmlWrapper();

        System.debug('LookHere: Made it to Opportunity trigger.' + newList[0].get('Amount') + ' ' + triggerAction);

        list<Opportunity> listOppsForProcessing = new list<Opportunity>();
        list<Opportunity> listOldOpps = new list<Opportunity>();

        for (integer i=0; i<newList.size(); i++) {
            Opportunity opp = (Opportunity) newlist[i];

            //INSERT case: Verify associated Campaign and Recurring Donations to auto create allocations
            if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
                //if this new opportunity has a Campaign, add to list for campaign processing
                if (opp.CampaignId != null || opp.npe03__Recurring_Donation__c != null)
                    listOppsForProcessing.add(opp);
                //create a default allocation for the total amount, only if there's no possibility of other allocations from related objects
                else if (settings.Default_Allocations_Enabled__c) {
                    dmlWrapper.objectsToInsert.add(makeDefaultAllocation(opp));
                }
            }

            //UPDATE case: if the opportunity amount changed, or the opp went to a closed/won stage: add to the list for processing
            if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                Opportunity oldOpp = (Opportunity) oldlist[i];
                if (opp.Amount != oldOpp.Amount || (opp.isWon && !oldOpp.isWon)) {
                    listOppsForProcessing.add(opp);
                    listOldOpps.add(oldOpp);
                }
            }
        }

        //INSERT case: new Opp with associated Campaign or Recurring donation. Create allocations from Recurring Donation or Campaign objects. Prefers Recurring Donation allocations.
        if (!listOppsForProcessing.isEmpty()) {
            //Don't return a wrapper object if there are no allocations
            mapWrapper = fillMapWrapper(listOppsForProcessing);
            system.debug('LookHere: mapWrapper ' + mapWrapper);
            
            for (integer i=0; i<listOppsForProcessing.size(); i++) {
                Opportunity opp = listOppsForProcessing[i];
                //system.debug('LookHere: oppWrap ' + oppWrap);

                //Recurring Donation / Campaign cases: if this is an insert, create allocations to match the campaign or recurring donation. if there are non and defaults are enabled, create the default allocation
                if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
                    if ((opp.npe03__Recurring_Donation__c != null && mapWrapper.containsKey(opp.npe03__Recurring_Donation__c)) ||
                        (opp.CampaignId != null && mapWrapper.containsKey(opp.CampaignId))) {

                        alloWrapper wrap;
                        //get wrapper for parent object, preferring recurring donation over campaign allocations if they exist
                        if (opp.npe03__Recurring_Donation__c != null && mapWrapper.containsKey(opp.npe03__Recurring_Donation__c))
                            wrap = mapWrapper.get(opp.npe03__Recurring_Donation__c);
                        else 
                            wrap = mapWrapper.get(opp.CampaignId);

                        list<Allocation__c> listAlloForInsert = wrap.listAllo.deepclone();

                        decimal remainder = opp.Amount;

                        //reparent the cloned allocation to the opportunity
                        for (Allocation__c allo : listAlloForInsert) {
                            allo.Recurring_Donation__c = null;
                            allo.Campaign__c = null;
                            allo.Opportunity__c = opp.id;
                            if (allo.Percent__c != null)
                                allo.Amount__c = Opp.Amount * allo.Percent__c * .01;
                            remainder -= allo.Amount__c;
                        }
                        
                        //if our remainder is negative, don't insert allocations, as they would exceed the opportunity amount
                        if (remainder < 0) {
                            //TODO: Figure out better default behavior. Maybe only create percentage based allocations, and document it well.
                            //Send an email & post to chatter?
                            //throw new AllocationsException(Label.alloCampaignExceedsOppAmount + ' ' + opp.id);
                            if (settings.Default_Allocations_Enabled__c) {
                                dmlWrapper.objectsToInsert.add(makeDefaultAllocation(opp));
                            }

                        //create default allocation if needed
                        } else if (settings.Default_Allocations_Enabled__c && remainder > 0) {
                            dmlWrapper.objectsToInsert.add((sObject)makeDefaultAllocation(opp));
                            dmlWrapper.objectsToInsert.addAll((list<sObject>)listAlloForInsert);
                        //add objects to DML wrapper in all other cases (no remainder, or positive remainder without default allocations enabled)
                        } else {
                            dmlWrapper.objectsToInsert.addAll((list<sObject>)listAlloForInsert);
                        }
                    } else if (settings.Default_Allocations_Enabled__c) {
                        dmlWrapper.objectsToInsert.add(makeDefaultAllocation(opp));
                    }
                }
                //UPDATE case: opportunity amount has changed. retrieve this opps allocations, adjust amounts and/or generate errors
                //adjust percentage based allocations, adjust default allocations if enabled, and enforce that total allocations don't exceed the opportunity amount
                if (triggerAction == TDTM_Runnable.Action.AfterUpdate && opp.Amount != listOldOpps[i].Amount && mapWrapper.containsKey(opp.id)) {
                    alloWrapper oppWrap = mapWrapper.get(opp.id);

                    //if some allocations are percentage based, recalculate those percentages and update them
                    if (oppWrap.totalPercent > 0) {
                        for (Allocation__c allo : oppWrap.listAllo) {
                            if (allo.Percent__c!=null && allo.Percent__c>0) {
                                //remove the previous amount, recalculate the amount, and add it back
                                oppWrap.totalAmount -= allo.Amount__c;
                                allo.Amount__c = oppWrap.parentAmount * allo.Percent__c * .01;
                                oppWrap.totalAmount += allo.Amount__c;
                                dmlWrapper.objectsToUpdate.add(allo);
                                system.debug('LookHere: Recalc Amt: ' + allo);
                            }
                        }
                    }
                    //if the Default allocation handling is enabled, update the amount to cover 100% of the opportunity
                    if (settings.Default_Allocations_Enabled__c) {
                        oppWrap.totalAmount -= oppWrap.defaultAllo.Amount__c;
                        oppWrap.defaultAllo.Amount__c = oppWrap.parentAmount - oppWrap.totalAmount;
                        oppWrap.totalAmount += oppWrap.defaultAllo.Amount__c;
                        if (oppWrap.defaultAllo.Amount__c==0)
                            dmlWrapper.objectsToDelete.add(oppWrap.defaultAllo);
                        else
                            dmlWrapper.objectsToUpdate.add(oppWrap.defaultAllo);
                    }
                    //if the Opportunity amount has decreased, we run the risk of allocations exceeding the total opportunity amount
                    if (oppWrap.totalAmount > oppWrap.parentAmount)
                        //using addError here because we want to block opportunity update, display the error inline, and block the DML of updating all the related allocations
                        opp.Amount.addError(Label.alloExceedsOppAmount);
                }
            }
        }

        system.debug('LookHere: dmlWrapper ' + dmlWrapper);
        return dmlWrapper;
    }

    private DmlWrapper runAllocationBeforeTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        
        DmlWrapper dmlWrapper = new DmlWrapper();
        list<Allocation__c> triggerList = (list<Allocation__c>) newList;

        for (integer i=0;i<triggerList.size();i++) {
            Allocation__c allo = triggerList[i];    
            //if we don't have a parent, or have more than one parent, exception thrown
            if (parentError(allo))
                allo.AddError(Label.alloSingleParent);
            if (allo.Amount__c == null && allo.Percent__c == null)
                allo.addError(Label.alloAmountOrPercent);
        }

        mapWrapper = fillMapWrapper(triggerList);
        
        //adjust default allocation, and add to DML wrapper if needed
        if (settings.Default_Allocations_Enabled__c) {
            for (alloWrapper wrap : mapWrapper.values()) {
                //skip this check for Campaign and RD allocations
                if (wrap.parentAmount==null) 
                    continue;
                decimal amountDifferential = wrap.parentAmount - wrap.totalAmount;
                if (amountDifferential != 0) {
                
                    wrap.defaultAllo.Amount__c += amountDifferential;
                    wrap.totalAmount += amountDifferential;
                    
                    //if the default allocation has an amount of 0, delete it
                    if (wrap.defaultAllo.Amount__c == 0) {
                        dmlWrapper.objectsToDelete.add(wrap.defaultAllo);
                    } else if (wrap.defaultAllo.Amount__c > 0) {
                        //equalize total amount to parent amount                        
                        //if this default isn't in the trigger set, add it to DML wrapper
                        if (!wrap.defaultInTrigger)
                            dmlWrapper.objectsToUpdate.add(wrap.defaultAllo);
                    }
                }                    
            }
        }

        //verify that we're not over the total amount, and that everything is equalized
        for (integer i=0;i<triggerList.size();i++) {
            //current trigger allocation object
            Allocation__c allo = triggerList[i];

            //this allocation's wrapper
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

            //if default is enabled and we're not at exactly 100%
            if (settings.Default_Allocations_Enabled__c) {
                if (wrap.isPercentOnly && wrap.totalPercent != 100)
                    allo.addError(Label.alloDefaultEqual100);
                if (!wrap.isPercentOnly && wrap.totalAmount != wrap.parentAmount)
                    allo.addError(Label.alloDefaultEqual100);
            }
        }

        return dmlWrapper;
    }

    //when a recurring donation allocation is modified, create or modify all allocations for open opportunities under that recurring donations' schedule to match the RD allocations
    private DmlWrapper runAllocationAfterTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        
        system.debug('LookHere: Entered after trigger handler');

        DmlWrapper dmlWrapper = new DmlWrapper();
        list<Opportunity> listOpps = new list<Opportunity>();
        set<id> setRecDonId = new set<id>();
        set<id> setOppIds = new set<id>();


        for (Allocation__c allo : (list<Allocation__c>) newList) {
            //if this allocation is for a recurring donation, save the Id for updating open opportunities under that RD schedule
            if (allo.Recurring_Donation__c != null)
                setRecDonId.add(allo.Recurring_Donation__c);
            //if this is an opportunity allocation deletion and defaults are enabled, adjust/create the default
            if (triggerAction==TDTM_Runnable.Action.AfterDelete && settings.Default_Allocations_Enabled__c && allo.Opportunity__c!=null)
                setOppIds.add(allo.Opportunity__c);
        }
        

        if (!setRecDonId.isEmpty() || !setOppIds.isEmpty()) 
            listOpps = [SELECT Id, Amount, npe03__Recurring_Donation__c, CampaignId FROM Opportunity WHERE (Opportunity.isClosed = FALSE AND npe03__Recurring_Donation__c IN :setRecDonId) OR ID IN :setOppIds];
        if (!listOpps.isEmpty()) {



            system.debug('LookHere: listOpps ' + listOpps);
            mapWrapper = fillMapWrapper(listOpps);
            system.debug('LookHere: mapWrapper ' + mapWrapper);
            
            //if we have any deletion of opportunity allocations and default handling is enabled, adjust the opps' default allocation
            list<Opportunity> listRecDonOpps = new list<Opportunity>();
            if (!setOppIds.isEmpty()) {
                for (Opportunity opp : listOpps) {
                    
                    //we have allocations for this opportunity
                    if (setOppIds.contains(opp.Id)) {
                        //this opp has allocations, check for default cases
                        if (mapWrapper.containsKey(opp.Id)) {
                            alloWrapper oppWrap = mapWrapper.get(opp.id);
                            //if we have a default allocation, update the amount
                            if (oppWrap.defaultAllo!=null) {
                                oppWrap.defaultAllo.Amount__c = opp.Amount - oppWrap.totalAmount;
                                dmlWrapper.objectsToUpdate.add(oppWrap.defaultAllo);
                            //if we don't have a default allocation, create one
                            } else {
                                oppWrap.defaultAllo = makeDefaultAllocation(opp);
                                oppWrap.defaultAllo.Amount__c = opp.Amount - oppWrap.totalAmount;
                                dmlWrapper.objectsToInsert.add(oppWrap.defaultAllo);
                            }
                        //this opp has no allocations, just create the default
                        } else dmlWrapper.objectsToInsert.add(makeDefaultAllocation(opp));
                    //if this was a recurring donation allocation, add to list for processing
                    } else listRecDonOpps.add(opp);
                }
            //no deletion cases, just copy the list over
            } else listRecDonOpps = listOpps;


            //after insert/update/delete of Recurring Donation allocations: adjust all open opportunities
            //check each opp's allocations, make them match the allocations for this RD
            for (Opportunity opp : listOpps) {
                alloWrapper rdWrap = mapWrapper.get(opp.npe03__Recurring_Donation__c);
                //temporary lists in case we exceed the opportunity amount and need to revert to percentage allocations only
                list<Allocation__c> listAlloForInsert = new list<Allocation__c>();
                list<Allocation__c> listAlloForUpdate = new list<Allocation__c>();
                list<Allocation__c> listAlloForDelete = new list<Allocation__c>();


                //this opp has allocations, modify them to match the recurring donations' allocations
                alloWrapper oppWrap = mapWrapper.get(opp.Id);
                integer oppSize = 0;
                if (oppWrap != null)
                    oppSize = oppWrap.listAllo.size();
                integer rdSize = rdwrap.listallo.size();
                integer maxSize = oppSize > rdSize ? oppSize : rdSize;
                decimal remainder = opp.Amount;
                
                //case1: opp has same amount as RD
                    //modify existing allocations
                //case2: opp has fewer allocations than RD
                    //modify and update existing allocations, insert new ones
                //case3: opp has more allocations than RD
                    //modify existing allocations, delete remainder

                //I can assume the opportunity has a default allocation
                //the RD may or may not have a default allocation
                
                for (integer i=0;i<maxSize;i++) {
                    //copy allocations from rd to opp, update opp allocations
                    if (i<oppSize && i<rdSize) {
                        Allocation__c oppAllo = oppWrap.listAllo[i];
                        oppAllo = rdWrap.listAllo[i].clone(false,true,false,false);
                        oppAllo.Opportunity__c = opp.id;
                        oppAllo.Recurring_Donation__c = null;
                        if (oppAllo.Percent__c!=null)
                            oppAllo.Amount__c = opp.Amount * oppAllo.Percent__c * .01;
                        remainder -= oppAllo.Amount__c;
                        listAlloForUpdate.add(oppAllo);
                    //create new allo, copy info from rd, insert it
                    } else if (i>=oppSize && i<rdSize) {
                        Allocation__c newAllo = rdWrap.listAllo[i].clone(false,true,false,false);
                        newAllo.Opportunity__c = opp.id;
                        newAllo.Recurring_Donation__c = null;
                        if (newAllo.Percent__c!=null)
                            newAllo.Amount__c = opp.Amount * newAllo.Percent__c * .01;
                        remainder -= newAllo.Amount__c;
                        listAlloForInsert.add(newAllo);
                    //add to delete
                    } else if (i<oppSize && i>=rdSize) {
                        listAlloForDelete.add(oppWrap.listAllo[i]);
                    }
                }
                
                //we have more allocations than the opportunity amount, only create percent based allocations
                if (remainder < 0) {
                    //TODO
                    listAlloForUpdate = new list<Allocation__c>();
                    listAlloForInsert = new list<Allocation__c>();
                    listAlloForDelete = new list<Allocation__c>();



                //our remainder is blank, if we have a default allocation, delete it
                } else if (remainder == 0 && oppWrap!=null) {
                    if (oppWrap.defaultAllo!=null)
                        listAlloForDelete.add(oppWrap.defaultAllo);
                } else if (settings.Default_Allocations_Enabled__c && remainder > 0) {
                    if (oppWrap!=null && oppWrap.defaultAllo != null) {
                        oppWrap.defaultAllo.Amount__c = remainder;
                        listAlloForUpdate.add(oppWrap.defaultAllo);
                    } else {
                        Allocation__c defaultAllo = new Allocation__c(
                            Opportunity__c = opp.id,
                            Amount__c = remainder,
                            General_Accounting_Unit__c = idDefaultGAU
                        );
                        listAlloForInsert.add(defaultAllo);
                    }
                }

                for (Allocation__c allo : listAlloForUpdate)
                    dmlWrapper.objectsToUpdate.add(allo);
                dmlWrapper.objectsToInsert.addAll((list<sObject>)listAlloForInsert);
                dmlWrapper.objectsToDelete.addAll((list<sObject>)listAlloForDelete);
                system.debug('LookHere: dmlWrapper ' + dmlWrapper);

            }
            return dmlWrapper;
        }
        return null;
    }


    //fills the wrapper based on a list of allocations, updates current trigger set amounts to match percentage defined
    public map<Id, alloWrapper> fillMapWrapper (list<Allocation__c> alloList) {

        map<id,alloWrapper> mapIdToWrapper = new map<id,alloWrapper>();
        set<id> setParentId = new set<id>();
        set<id> setExistingAlloId = new set<id>();

        //build a list of related object Ids to fill wrapper with data
        for (Allocation__c allo : alloList) {
            setParentId.add(getParentId(allo));

            //create wrapper object and add to map
            if (!mapIdToWrapper.containsKey(getParentId(allo))) {
                alloWrapper wrapper = new alloWrapper();
                mapIdToWrapper.put(getParentId(allo), wrapper);
            }
        }

        //fill wrapper with current trigger set allocations
        for (Allocation__c allo : alloList) {
            alloWrapper wrap = mapIdToWrapper.get(getParentId(allo));
            wrap.triggerList.add(allo);
            
            //Add any allocation with an id to be excluded from calculations in the query
            if (allo.id != null)
                setExistingAlloId.add(allo.id);
            if (idDefaultGAU != null && allo.General_Accounting_Unit__c == idDefaultGAU) {
                if (allo.Percent__c != null)
                    allo.addError(Label.alloDefaultNotPercent);
                wrap.defaultAllo = allo;
                wrap.defaultInTrigger = true;
            }
            if (allo.Amount__c!=null)
                wrap.totalAmount += allo.Amount__c;
            
            //if any allocations don't have a percent, set flag to false
            if (allo.Percent__c == null && allo.General_Accounting_Unit__c != idDefaultGAU)
                wrap.isPercentOnly = false;
            else if (allo.Percent__c != null && allo.General_Accounting_Unit__c != idDefaultGAU)
                wrap.totalPercent += allo.Percent__c;
        }

        //fill wrapper with all allocations for this opportunity
        //getting payment and opportunity info here to avoid excess queries
        for (Allocation__c allo : [SELECT Id, Opportunity__c, Opportunity__r.Amount, Amount__c, Percent__c, General_Accounting_Unit__c 
                FROM Allocation__c WHERE (Opportunity__c IN :setParentId or Recurring_Donation__c IN :setParentId OR Campaign__c IN :setParentId) AND Id NOT IN :setExistingAlloId]) {

            alloWrapper wrap = mapIdToWrapper.get(getParentId(allo));
            
            //add opportunity amount and allocation totals
            wrap.parentAmount = allo.Opportunity__r.Amount;

            wrap.totalAmount += allo.Amount__c;

            //save the default allocation.
            if (idDefaultGAU != null && allo.General_Accounting_Unit__c == idDefaultGAU) {
                wrap.defaultAllo = allo;
                //keep the default allocation from listAllo
                continue;
            }

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
            alloWrapper wrap = mapIdToWrapper.get(getParentId(allo));
            if (wrap.parentAmount == null && allo.Opportunity__c!=null) 
                setOppIds.add(allo.Opportunity__c);
        }

        //we have opportunities we need to query for a parent amount
        if (!setOppIds.isEmpty()) {
            for (Opportunity opp : [SELECT Id, Amount FROM Opportunity WHERE Id IN :setOppIds]) {
                mapIdToWrapper.get(opp.id).parentAmount = opp.Amount;
            }
        }

        //verify the current trigger set has correct amounts based on the percentage chosen
        for (Allocation__c allo : alloList) {
            alloWrapper wrap = mapIdToWrapper.get(getParentId(allo));
            if (allo.Percent__c!=null && wrap.parentAmount!=null) {
                //we don't have an amount yet, add it. we're only dealing with before triggers so we can just update the allocation
                if (allo.Amount__c==null) {
                    allo.Amount__c = wrap.parentAmount * allo.Percent__c * .01;
                    wrap.totalAmount += allo.Amount__c;
                //we have an amount not equal to the percentage of the total, so update it and the total
                } else if (wrap.parentAmount * allo.Percent__c * .01 != allo.Amount__c) {
                    //remove the previous amount, recalculate the amount, and add it back
                    wrap.totalAmount -= allo.Amount__c;
                    allo.Amount__c = wrap.parentAmount * allo.Percent__c * .01;
                    wrap.totalAmount += allo.Amount__c;
                }
            }
        }

        return mapIdToWrapper;
    }

    //fills wrapper based on Opportunities with or without parent objects (Campaigns or Recurring donations)
    public map<Id, alloWrapper> fillMapWrapper (list<Opportunity> oppList) {
        map<id,alloWrapper> mapIdToWrapper = new map<id,alloWrapper>();
        set<id> setParentId = new set<id>();
        //create set of Campaign IDs, Recurring Donation Ids, and Opp Ids for query
        for (Opportunity opp : oppList) {
            if (opp.CampaignId != null)
                setParentId.add(opp.CampaignId);
            if (opp.npe03__Recurring_Donation__c != null)
                setParentId.add(opp.npe03__Recurring_Donation__c);
            setParentId.add(opp.id);
        }
        
        list<Allocation__c> queryAllo = [SELECT Id, Opportunity__c, Opportunity__r.Amount, Campaign__c, Recurring_Donation__c, 
            Recurring_Donation__r.npe03__Amount__c, Amount__c, Percent__c, General_Accounting_Unit__c 
            FROM Allocation__c WHERE Opportunity__c IN :setParentId OR Campaign__c IN :setParentId OR Recurring_Donation__c IN :setParentId ];
        system.debug('LookHere: queryAllo' + queryAllo);

        for (Allocation__c allo : queryAllo) {
            system.debug('LookHere: Allocation queried: ' + allo);
        
            //create wrapper if it doesn't exist yet
            if (!mapIdToWrapper.containsKey(getParentId(allo)))
                mapIdToWrapper.put(getParentId(allo), new alloWrapper());

            alloWrapper wrap = mapIdToWrapper.get(getParentId(allo));
            
            //add opportunity amount and allocation totals
            if (allo.Opportunity__c != null) {
                wrap.parentAmount = allo.Opportunity__r.Amount;
            }
            
            if (allo.Amount__c!=null)    
                wrap.totalAmount += allo.Amount__c;

            //save the default allocation.
            if (idDefaultGAU != null && allo.General_Accounting_Unit__c == idDefaultGAU) {
                wrap.defaultAllo = allo;
                continue;
            }

            //if any allocations don't have a percent, set flag to false
            if (allo.Percent__c == null)
                wrap.isPercentOnly = false;
            else if (allo.Percent__c != null)
                wrap.totalPercent += allo.Percent__c;

            wrap.listAllo.add(allo);

        }
        return mapIdToWrapper;
    }

    //method returns the ID of this allocation's parent object (Opportunity, Recurring Donation, or Campaign)
    public id getParentId (Allocation__c allo) {
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

    public Allocation__c makeDefaultAllocation(Opportunity opp) {
        Allocation__c defaultAllo = new Allocation__c(
            Opportunity__c = opp.id,
            Amount__c = opp.Amount,
            General_Accounting_Unit__c = idDefaultGAU
        );
        return defaultAllo;
    }
}