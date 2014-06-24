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
TODO: Replace error text with labels.
enforce percentage only for Campaign? no way to know donation amounts ahead of time.

figure out when the default allocation amount is being updated
verify if I should set hasRunForAllocations = true in certain cases for opportunity trigger handler
do I need to enforce that the default allocation is not percentage based?

do I need to do anything with the default GAU, like readjust the percentage? no.



Questions:
how come throwing an exception doesn't prevent insertion? how can I prevent insertion of bad data?

*/

public class ALLO_Allocations_TDTM extends TDTM_Runnable {
    
    //flag to prevent recursion
    public static boolean hasRunForAllocations = false;
    public static boolean hasRunForOpportunities = false;
    public static boolean hasRunForRecurring = false;


    //holds the default General Accounting Unit if creating default allocations is enabled
    public static id defaultGAU = null;

    //holds all relevant allocations data for this transaction
    public map<id,alloWrapper> mapWrapper;

    //allocations settings
    public Allocations_Settings__c settings = UTIL_CustomSettingsFacade.getAllocationsSettings();

    public class AllocationsException extends Exception {}

    // the main entry point for TDTM to invoke our trigger handlers.
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        System.debug('LookHere: settings: ' + settings);
        System.debug('LookHere: Entering trigger: ' + objResult.getName() + ' ' + triggerAction);
        if (objResult.getName() == 'Allocation__c') 
            system.debug('LookHere: equals for allo, hasRunForAllocations: ' + hasRunForAllocations);
        
        //if allocations are not enabled, do nothing
        if (!settings.Allocations_Enabled__c)
            return null;

        //if default allocations are enabled, verify that we have an ID value for the default fund
        if (settings.Default_Allocations_Enabled__c) {
            if (settings.Default__c == null) {
                throw new AllocationsException('Default Allocations are enabled, but no default General Accounting Unit is selected.');
                return null;
            } else defaultGAU = settings.Default__c;
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

        //list of opps for processing when the opportunity amount changes
        list<Opportunity> listOppsForProcessing = new list<Opportunity>();

        for (integer i=0; i<newList.size(); i++) {
            Opportunity opp = (Opportunity) newlist[i];


            //if this is an insert and default allocations are enabled, create an allocation for the default GAU
            if (triggerAction == TDTM_Runnable.Action.AfterInsert && settings.Default_Allocations_Enabled__c) {
                Allocation__c defaultAllo = new Allocation__c(
                    Opportunity__c = opp.id,
                    Percent__c = 100,
                    Amount__c = Opp.Amount,
                    General_Accounting_Unit__c = defaultGAU
                );
                dmlWrapper.objectsToInsert.add(defaultAllo);
            }

            //if this is an update and the opportunity amount changed, add to the list for processing
            if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                Opportunity oldOpp = (Opportunity) oldlist[i];
                if (opp.Amount != oldOpp.Amount)
                    listOppsForProcessing.add(opp);
            }
        }

        system.debug('LookHere: listOppsForProcessing ' + listOppsForProcessing);

        if (!listOppsForProcessing.isEmpty()) {
            //get related opportunity data
            mapWrapper = fillMapWrapper(listOppsForProcessing);
            system.debug('LookHere: mapWrapper ' + mapWrapper);
            for (Opportunity opp : listOppsForProcessing) {
                alloWrapper wrap = mapWrapper.get(opp.id);
                //update percentage based allocations, adjust default allocations if enabled, and enforce that total allocations don't exceed the opportunity amount

                //if some allocations are percentage based, recalculate those percentages and update them
                if (wrap.totalPercent > 0) {
                    for (Allocation__c allo : wrap.listAllo) {
                        if (allo.Percent__c!=null && allo.Percent__c>0) {
                            //remove the previous amount, recalculate the amount, and add it back
                            wrap.totalAmount -= allo.Amount__c;
                            allo.Amount__c = wrap.parentAmount * allo.Percent__c * .01;
                            wrap.totalAmount += allo.Amount__c;
                            dmlWrapper.objectsToUpdate.put(allo.id, allo);
                            system.debug('LookHere: Recalc Amt: ' + allo);
                        }
                    }
                }
                //if the Default allocation handling is enabled, update the amount to cover 100% of the opportunity
                if (settings.Default_Allocations_Enabled__c) {
                    wrap.totalAmount -= wrap.defaultAllo.Amount__c;
                    wrap.defaultAllo.Amount__c = wrap.parentAmount - wrap.totalAmount;
                    wrap.totalAmount += wrap.defaultAllo.Amount__c;
                    dmlWrapper.objectsToUpdate.put(wrap.defaultAllo.id, wrap.defaultAllo);
                }
                //if the Opportunity amount has decreased, we run the risk of allocations exceeding the total opportunity amount
                if (wrap.totalAmount > wrap.parentAmount)
                    //using addError here because we want to block opportunity update, display the error inline, and block the DML of updating all the related allocations
                    opp.Amount.addError('The allocations for this opportunity are greater than the amount of the opportunity. Please update the allocations before reducing the amount of the Opportunity.');
            }
        }

        return dmlWrapper;
    }

    private DmlWrapper runAllocationTriggerHandler(List<SObject> newlist, List<SObject> oldlist, 
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        list<Allocation__c> triggerList = (list<Allocation__c>) newList;

        for (integer i=0;i<triggerList.size();i++) {
            Allocation__c allo = triggerList[i];
            Allocation__c oldAllo = triggerAction == TDTM_Runnable.Action.BeforeInsert ? new Allocation__c() : (Allocation__c) oldlist[i];
    
            //if we don't have a parent, or have more than one parent, exception thrown
            if (parentError(allo)) {
                //can I throw an error for the specific trigger row?
                allo.AddError('Each Allocation must have a single parent object: Opportunity, Recurring Donation, or Campaign.');
            }
        }

        mapWrapper = fillMapWrapper(triggerList);
        
        for (integer i=0;i<triggerList.size();i++) {
            //current trigger allocation object
            Allocation__c allo = triggerList[i];
            //old version of the trigger object if this is an update, or a blank object for comparisons if this is an insert
            Allocation__c oldAllo = triggerAction == TDTM_Runnable.Action.BeforeInsert ? new Allocation__c() : (Allocation__c) oldlist[i];
            //this allocation's wrapper
            alloWrapper wrap = mapWrapper.get(allo.Opportunity__c);
            
            //if we exceed 100%
            if (wrap.totalPercent > 100) {
                allo.addError('Allocations cannot exceed 100%.');
            }

            //verify the total allocations don't exceed the parent amount
            if (wrap.totalAmount > wrap.parentAmount)
                throw new AllocationsException(Label.alloTotalExceedsOppAmt);

            //if default is enabled and we're not at exactly 100%
            if (settings.Default_Allocations_Enabled__c) {
                if (wrap.isPercentOnly && wrap.totalPercent != 100)
                    allo.addError('If default allocations are enabled, allocations must equal 100% of the parent amount.');
                if (!wrap.isPercentOnly && wrap.totalAmount != wrap.parentAmount)
                    allo.addError('If default allocations are enabled, allocations must equal 100% of the parent amount.');
            }
        }

        return null;
    }

    //wrapper class to hold all allocation and payment information for a single parent (opp, campaign, or recurring donation)
    class alloWrapper {
        boolean isPercentOnly = true;                                        //tracks whether all allocations are percentage based
        boolean isOppOnly = true;                                            //tracks whether all allocations only apply to the opportunity level
        decimal parentAmount = 0;                                            //amount of this allocation's parent
        decimal totalAmount = 0;                                             //holds total allocation amount for this opportunity
        decimal totalPercent = 0;                                            //holds total percentage allocations
        list<Allocation__c> triggerList = new list<Allocation__c>();         //all allocations for this opportunity in the current trigger set
        list<Allocation__c> listAllo = new list<Allocation__c>();            //all allocations for this opportuntiy
        Allocation__c defaultAllo = new Allocation__c();
    }

    //fills the wrapper based on a list of allocations, updates current trigger set amounts to match percentage defined
    public map<Id, alloWrapper> fillMapWrapper (list<Allocation__c> alloList) {

        map<id,alloWrapper> mapIdToWrapper = new map<id,alloWrapper>();
        set<id> setParentId = new set<id>();

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
            mapIdToWrapper.get(allo.Opportunity__c).listAllo.add(allo);
        }

        //fill wrapper with all allocations for this opportunity
        //getting payment and opportunity info here to avoid excess queries
        for (Allocation__c allo : [SELECT Id, Opportunity__c, Opportunity__r.Amount, Amount__c, Percent__c, General_Accounting_Unit__c FROM Allocation__c WHERE Opportunity__c IN :setParentId or Recurring_Donation__c IN :setParentId OR Campaign__c IN :setParentId]) {
            //do we need the default allocation object for anything? if (allo.id == defaultGAU) {}

            alloWrapper wrap = mapIdToWrapper.get(getParentId(allo));
            
            //add this allocation to the list
            wrap.listAllo.add(allo);

            //save the default allocation.
            if (defaultGAU != null && allo.General_Accounting_Unit__c == defaultGAU)
                wrap.defaultAllo = allo;
            
            //add opportunity amount and allocation totals
            wrap.parentAmount = allo.Opportunity__r.Amount;
            wrap.totalAmount += allo.Amount__c;

            //if any allocations don't have a percent, set flag to false
            if (allo.Percent__c == null && allo.General_Accounting_Unit__c != defaultGAU)
                wrap.isPercentOnly = false;
            else
                wrap.totalPercent += allo.Percent__c;
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

    //fills wrapper based on a list of Opportunities
    public map<Id, alloWrapper> fillMapWrapper (list<Opportunity> oppList) {
        map<id,alloWrapper> mapIdToWrapper = new map<id,alloWrapper>();
        set<id> setParentId = new set<id>();
        for (Opportunity opp : oppList) {
            setParentId.add(opp.id);
            mapIdToWrapper.put(opp.id, new alloWrapper());
        }
        for (Allocation__c allo : [SELECT Id, Opportunity__c, Opportunity__r.Amount, Amount__c, Percent__c, General_Accounting_Unit__c FROM Allocation__c WHERE Opportunity__c IN :setParentId ]) {
            alloWrapper wrap = mapIdToWrapper.get(allo.Opportunity__c);
            
            //add this allocation to the list
            wrap.listAllo.add(allo);

            //save the default allocation.
            if (defaultGAU != null && allo.General_Accounting_Unit__c == defaultGAU)
                wrap.defaultAllo = allo;
            
            //add opportunity amount and allocation totals
            wrap.parentAmount = allo.Opportunity__r.Amount;
            wrap.totalAmount += allo.Amount__c;

            //if any allocations don't have a percent, set flag to false
            if (allo.Percent__c == null && allo.General_Accounting_Unit__c != defaultGAU)
                wrap.isPercentOnly = false;
            else
                wrap.totalPercent += allo.Percent__c;
        }
        return mapIdToWrapper;
    }

    //method recalculates percentages and default allocation amount if enabled
    public void recalcAllocations (Allocation__c allo) {

    }

    //method returns the ID of this allocation's parent object
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