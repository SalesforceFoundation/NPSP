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

Replace error text with labels.
verify that Recurring Donation allocations are correctly handled and validated 
Create and enforce default GAU with Recurring donation parent? Or do it when creating allocations for the opp?


figure out when the default allocation amount is being updated
do I need to enforce that the default allocation is not percentage based?
do I need to do anything with the default GAU, like readjust the percentage? no.

*/

public class ALLO_Allocations_TDTM extends TDTM_Runnable {
    
    //flag to prevent recursion
    public static boolean hasRunForAllocations = false;
    public static boolean hasRunForOpportunities = false;
    public static boolean hasRunForRecurring = false;

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
        boolean isOppOnly = true;                                            //tracks whether all allocations only apply to the opportunity level
        decimal parentAmount = null;                                         //amount of this allocation's parent
        decimal totalAmount = 0;                                             //holds total allocation amount for this opportunity
        decimal totalPercent = 0;                                            //holds total percentage allocations
        list<Allocation__c> triggerList = new list<Allocation__c>();         //all allocations for this opportunity in the current trigger set
        list<Allocation__c> listAllo = new list<Allocation__c>();            //all allocations for this opportuntiy
        Allocation__c defaultAllo = new Allocation__c();
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
        if (objResult.getName() == 'Allocation__c' && !hasRunForAllocations) {
            System.debug('LookHere: newlist before changes: ' + newlist);
            DmlWrapper wrapper = runAllocationTriggerHandler(newlist, oldlist, triggerAction, objResult);
            hasRunForAllocations = true;
            System.debug('LookHere: newlist after changes: ' + newlist);
            system.debug('LookHere: wrapper ' + wrapper);

            return wrapper;
        } else if (objResult.getName() == 'Opportunity' && !hasRunForOpportunities) {
            DmlWrapper wrapper = runOpportunityTriggerHandler(newlist, oldlist, triggerAction, objResult);
            hasRunForOpportunities = true;
            //we're recalculating allocations amounts in the opportunity trigger handler and don't want to run twice
            hasRunForAllocations = true;
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
                    Allocation__c defaultAllo = new Allocation__c(
                        Opportunity__c = opp.id,
                        Amount__c = opp.Amount,
                        General_Accounting_Unit__c = idDefaultGAU
                    );
                    dmlWrapper.objectsToInsert.add(defaultAllo);
                }
            }

            //UPDATE case: if the opportunity amount changed, or the opp went to a closed/won stage: add to the list for processing
            if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                Opportunity oldOpp = (Opportunity) oldlist[i];
                if (opp.Amount != oldOpp.Amount || (opp.isWon && !oldOpp.isWon) )
                    listOppsForProcessing.add(opp);
                    listOldOpps.add(oldOpp);
            }
        }

        system.debug('LookHere: listOppsForProcessing ' + listOppsForProcessing);

        
        //INSERT case: new Opp with associated Campaign or Recurring donation. Create allocations from Recurring Donation or Campaign objects. Prefers Recurring Donation allocations.
        if (!listOppsForProcessing.isEmpty()) {
            //Don't return a wrapper object if there are no allocations
            mapWrapper = fillMapWrapper(listOppsForProcessing);
            system.debug('LookHere: mapWrapper ' + mapWrapper);
            
            for (integer i=0; i<listOppsForProcessing.size(); i++) {
                Opportunity opp = listOppsForProcessing[i];
                alloWrapper oppWrap = mapWrapper.get(opp.id);
                system.debug('LookHere: oppWrap ' + oppWrap);

                //Recurring Donation case: if this is an insert, or the opp just became Closed/Won and doesn't have any non-default allocations, create them
                if (opp.npe03__Recurring_Donation__c != null && mapWrapper.containsKey(opp.npe03__Recurring_Donation__c)) {

                    alloWrapper rdWrap = mapWrapper.get(opp.npe03__Recurring_Donation__c);                    

                    //verify that there are no allocations or the only allocation is the default before copying the recurring donation's allocations
                    if (oppWrap == null || oppWrap.listAllo.size() == 0 || (settings.Default_Allocations_Enabled__c && oppWrap.listAllo.size() == 1)) {
                        list<Allocation__c> listAlloForInsert = RDwrap.listAllo.deepClone();

                        //reparent the cloned allocation to the opportunity
                        for (Allocation__c allo : listAlloForInsert) {
                            allo.Recurring_Donation__c = null;
                            allo.Opportunity__c = opp.id;

                        }

                        //check for default allocation cases:
                        //if we already have a default allocation for the opportunity, remove the default from the insert list
                        //if we don't have a default allocation for the opportunity, set it as the default in the opp's wrapper
                        for (integer j = 0; j < listAlloForInsert.size(); j++) {
                            if (idDefaultGAU != null && listAlloForInsert[j].General_Accounting_Unit__c == idDefaultGAU) {
                                if (oppWrap.defaultAllo != null) {
                                    listAlloForInsert.remove(i);
                                } else {
                                    oppWrap.defaultAllo = listAlloForInsert[j];
                                }
                                break;                                    
                            }
                        }

                        dmlWrapper.objectsToInsert.addAll((list<sObject>)listAlloForInsert);

                        //create default or modify default allocation if needed
                        if (settings.Default_Allocations_Enabled__c && Opp.Amount > RDwrap.totalAmount) {
                            if (oppWrap.defaultAllo != null) {
                                oppWrap.defaultAllo.Amount__c = Opp.Amount - RDwrap.totalAmount;
                                
                                //add for update if this allocation isn't already in the insert list
                                if (oppWrap.defaultAllo.id != null)
                                    dmlWrapper.objectsToUpdate.put(oppWrap.defaultAllo.id, oppWrap.defaultAllo);
                            } else {
                                Allocation__c defaultAllo = new Allocation__c(
                                    Opportunity__c = opp.id,
                                    Amount__c = Opp.Amount - RDwrap.totalAmount,
                                    General_Accounting_Unit__c = idDefaultGAU
                                );
                                dmlWrapper.objectsToInsert.add(defaultAllo);
                            }
                        }
                    }
                } else if (opp.CampaignId != null && mapWrapper.containsKey(opp.CampaignId)) {
                    //TODO: check for update case: opp just got the campaignID. verify there are no allocations or the only allocation is the default before copying

                    alloWrapper campaignWrap = mapWrapper.get(opp.CampaignId);
                    //verify that there are no allocations or the only allocation is the default before copying the campaign's allocations
                    if (oppWrap == null || oppWrap.listAllo.size() == 0 || (settings.Default_Allocations_Enabled__c && oppWrap.listAllo.size() == 1)) {

                        list<Allocation__c> listAlloForInsert = campaignWrap.listAllo.deepClone();

                        decimal remainder = opp.Amount;

                        //reparent the cloned allocation to the opportunity
                        for (Allocation__c allo : listAlloForInsert) {
                            allo.Campaign__c = null;
                            allo.Opportunity__c = opp.id;
                            if (allo.Amount__c == null)
                                allo.Amount__c = Opp.Amount * allo.Percent__c * .01;
                            remainder -= allo.Amount__c;
                        }

                        //if we have a positive remainder and default allocations are enabled, create a default allocation for the remainder
                        if (remainder > 0 && settings.Default_Allocations_Enabled__c) {
                            Allocation__c defaultAllo = new Allocation__c(
                                Opportunity__c = opp.id,
                                Amount__c = remainder,
                                General_Accounting_Unit__c = idDefaultGAU
                            );
                            dmlWrapper.objectsToInsert.add(defaultAllo);
                        } 
                        
                        //if our remainder is negative, throw an exception and don't insert allocations, as they would exceed the opportunity amount
                        if (remainder < 0) {
                            throw new AllocationsException('Campaign Allocations for the following opportunity exceeded the opportunity amount, and were not created.' + opp);
                            if (settings.Default_Allocations_Enabled__c) {
                                Allocation__c defaultAllo = new Allocation__c(
                                    Opportunity__c = opp.id,
                                    Amount__c = opp.Amount,
                                    General_Accounting_Unit__c = idDefaultGAU
                                );
                                dmlWrapper.objectsToInsert.add(defaultAllo);
                            }
                        } else {
                            dmlWrapper.objectsToInsert.addAll((list<sObject>)listAlloForInsert);
                        }
                    }
                }
                //UPDATE case: opportunity amount has changed. retrieve this opps allocations, adjust amounts and/or generate errors
                //adjust percentage based allocations, adjust default allocations if enabled, and enforce that total allocations don't exceed the opportunity amount
                if (triggerAction == TDTM_Runnable.Action.AfterUpdate && opp.Amount != listOldOpps[i].Amount) {
                    system.debug('LookHere: entered amt change ' + oppWrap);
                    //if some allocations are percentage based, recalculate those percentages and update them
                    if (oppWrap.totalPercent > 0) {
                        for (Allocation__c allo : oppWrap.listAllo) {
                            if (allo.Percent__c!=null && allo.Percent__c>0) {
                                //remove the previous amount, recalculate the amount, and add it back
                                oppWrap.totalAmount -= allo.Amount__c;
                                allo.Amount__c = oppWrap.parentAmount * allo.Percent__c * .01;
                                oppWrap.totalAmount += allo.Amount__c;
                                dmlWrapper.objectsToUpdate.put(allo.id, allo);
                                system.debug('LookHere: Recalc Amt: ' + allo);
                            }
                        }
                    }
                    //if the Default allocation handling is enabled, update the amount to cover 100% of the opportunity
                    if (settings.Default_Allocations_Enabled__c) {
                        oppWrap.totalAmount -= oppWrap.defaultAllo.Amount__c;
                        oppWrap.defaultAllo.Amount__c = oppWrap.parentAmount - oppWrap.totalAmount;
                        oppWrap.totalAmount += oppWrap.defaultAllo.Amount__c;
                        dmlWrapper.objectsToUpdate.put(oppWrap.defaultAllo.id, oppWrap.defaultAllo);
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

    private DmlWrapper runAllocationTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        
        DmlWrapper dmlWrapper = new DmlWrapper();
        list<Allocation__c> triggerList = (list<Allocation__c>) newList;

        for (integer i=0;i<triggerList.size();i++) {
            Allocation__c allo = triggerList[i];
            Allocation__c oldAllo = triggerAction == TDTM_Runnable.Action.BeforeInsert ? new Allocation__c() : (Allocation__c) oldlist[i];
    
            //if we don't have a parent, or have more than one parent, exception thrown
            if (parentError(allo)) {
                allo.AddError(Label.alloSingleParent);
            }
        }

        mapWrapper = fillMapWrapper(triggerList);
        
        //adjust default allocation, and add to DML wrapper if needed
        if (settings.Default_Allocations_Enabled__c) {
            for (alloWrapper wrap : mapWrapper.values()) {
                decimal amountDifferential = wrap.totalAmount - wrap.parentAmount;
                if (amountDifferential != 0) {
                    wrap.defaultAllo.Amount__c -= amountDifferential;
                    
                    //if the default allocation has an amount of 0, delete it
                    if (wrap.defaultAllo.Amount__c == 0) {
                        dmlWrapper.objectsToDelete.add(wrap.defaultAllo);
                        wrap.totalAmount -= amountDifferential;
                    } else if (wrap.defaultAllo.Amount__c > 0) {
                        //if this default isn't in the trigger set, add it to DML wrapper
                        wrap.totalAmount -= amountDifferential;
                        if (!wrap.defaultInTrigger)
                            dmlWrapper.objectsToUpdate.put(wrap.defaultAllo.id, wrap.defaultAllo);
                    }
                }                    
            }
        }

        //verify that we're not over the total amount, and that everything is equalized
        for (integer i=0;i<triggerList.size();i++) {
            //current trigger allocation object
            Allocation__c allo = triggerList[i];
            //this allocation's wrapper
            alloWrapper wrap = mapWrapper.get(allo.Opportunity__c);
            
            //if we exceed 100%
            if (wrap.totalPercent > 100) {
                allo.addError(Label.alloPercentExceed100);
            }

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

    //fills the wrapper based on a list of allocations, updates current trigger set amounts to match percentage defined
    public map<Id, alloWrapper> fillMapWrapper (list<Allocation__c> alloList) {

        map<id,alloWrapper> mapIdToWrapper = new map<id,alloWrapper>();
        set<id> setParentId = new set<id>();
        set<id> setExistingAlloId = new set<id>();

        //build a list of related object Ids to fill wrapper with data
        for (Allocation__c allo : alloList) {
            setParentId.add(getParentId(allo));

            //create wrapper object and add to map
            if (!mapIdToWrapper.containsKey(allo.Opportunity__c)) {
                alloWrapper wrapper = new alloWrapper();
                mapIdToWrapper.put(allo.Opportunity__c, wrapper);
            }
        }

        //fill wrapper with current trigger set allocations
        for (Allocation__c allo : alloList) {
            alloWrapper wrap = mapIdToWrapper.get(getParentId(allo));
            wrap.triggerList.add(allo);
            
            //Add any allocation with an id to be excluded from the existing allocation query
            if (allo.id != null)
                setExistingAlloId.add(allo.id);
            if (idDefaultGAU != null && allo.General_Accounting_Unit__c == idDefaultGAU) {
                if (allo.Percent__c != null)
                    allo.addError('The default allocation must not be percentage based.');
                wrap.defaultAllo = allo;
                wrap.defaultInTrigger = true;
            }
            if (allo.Amount__c!=null)
                wrap.totalAmount += allo.Amount__c;
            
            //if any allocations don't have a percent, set flag to false
            if (allo.Percent__c == null && allo.General_Accounting_Unit__c != idDefaultGAU)
                wrap.isPercentOnly = false;
            else
                wrap.totalPercent += allo.Percent__c;
        }

        //fill wrapper with all allocations for this opportunity
        //getting payment and opportunity info here if possible to avoid excess queries
        for (Allocation__c allo : [SELECT Id, Opportunity__c, Opportunity__r.Amount, Amount__c, Percent__c, General_Accounting_Unit__c FROM Allocation__c WHERE Id NOT IN :setExistingAlloId AND (Opportunity__c IN :setParentId or Recurring_Donation__c IN :setParentId OR Campaign__c IN :setParentId)]) {
            //TODO: can I get parent amounts from this query



            //do we need the default allocation object for anything? if (allo.id == idDefaultGAU) {}
            alloWrapper wrap = mapIdToWrapper.get(getParentId(allo));
            
            //add this allocation to the list
            wrap.listAllo.add(allo);

            //save the default allocation.
            if (idDefaultGAU != null && allo.General_Accounting_Unit__c == idDefaultGAU)
                wrap.defaultAllo = allo;
            
            //add opportunity amount and allocation totals
            wrap.parentAmount = allo.Opportunity__r.Amount;
            wrap.totalAmount += allo.Amount__c;

            //if any allocations don't have a percent, set flag to false
            if (allo.Percent__c == null && allo.General_Accounting_Unit__c != idDefaultGAU)
                wrap.isPercentOnly = false;
            else
                wrap.totalPercent += allo.Percent__c;
        }

        set<id> setOppIds = new set<id>();
        set<id> setRecDonIds = new set<id>();

        //if we arrive here without a parent amount, we need another query for the parent info.
        for (Allocation__c allo : alloList) {
            alloWrapper wrap = mapIdToWrapper.get(getParentId(allo));
            if (wrap.parentAmount == null) {
                if (allo.Opportunity__c!=null)
                    setOppIds.add(allo.Opportunity__c);
                if (allo.Recurring_Donation__c!=null)
                    setRecDonIds.add(allo.Recurring_Donation__c);
            }
        }

        //we have opportunities we need to query for a parent amount
        if (!setOppIds.isEmpty()) {
            for (Opportunity opp : [SELECT Id, Amount FROM Opportunity WHERE Id IN :setOppIds]) {
                mapIdToWrapper.get(opp.id).parentAmount = opp.Amount;
            }
        }

        //we have recurring donations we need to query for a parent amount
        if (!setRecDonIds.isEmpty()) {
            for (npe03__Recurring_Donation__c recDon : [SELECT Id, npe03__Amount__c FROM npe03__Recurring_Donation__c WHERE Id IN :setRecDonIds]) {
                mapIdToWrapper.get(recDon.id).parentAmount = recDon.npe03__Amount__c;
            }
        }        

        //verify the current trigger set has correct amounts based on the percentage chosen
        for (Allocation__c allo : alloList) {
            if (allo.Percent__c!=null) {
                alloWrapper wrap = mapIdToWrapper.get(getParentId(allo));
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
        
        list<Allocation__c> queryAllo = [SELECT Id, Opportunity__c, Opportunity__r.Amount, Campaign__c, Recurring_Donation__c, Recurring_Donation__r.npe03__Amount__c, Amount__c, Percent__c, General_Accounting_Unit__c FROM Allocation__c];// WHERE Campaign__c IN :setParentId OR Recurring_Donation__c IN :setParentId ];
        system.debug('LookHere: queryAllo' + queryAllo);

        for (Allocation__c allo : queryAllo) {
            system.debug('LookHere: Allocation queried: ' + allo);
        
            if (!mapIdToWrapper.containsKey(getParentId(allo)))
                mapIdToWrapper.put(getParentId(allo), new alloWrapper());
            alloWrapper wrap = mapIdToWrapper.get(getParentId(allo));
            
            wrap.listAllo.add(allo);

            //save the default allocation.
            if (idDefaultGAU != null && allo.General_Accounting_Unit__c == idDefaultGAU)
                wrap.defaultAllo = allo;
            
            //add opportunity amount and allocation totals
            if (allo.Opportunity__c != null) {
                wrap.parentAmount = allo.Opportunity__r.Amount;
                wrap.totalAmount += allo.Amount__c;
            }

            //calculate recurring donation total amount and parent amount. This has to be done later for each opportunity receiving Campaign allocations as campaigns don't have a set amount.
            if (allo.Recurring_Donation__c != null) {
                wrap.parentAmount = allo.Recurring_Donation__r.npe03__Amount__c;
                wrap.totalAmount += allo.Amount__c;
            }

            //if any allocations don't have a percent, set flag to false
            if (allo.Percent__c == null && allo.General_Accounting_Unit__c != idDefaultGAU)
                wrap.isPercentOnly = false;
            else
                wrap.totalPercent += allo.Percent__c;
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
}