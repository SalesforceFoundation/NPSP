/*
    Copyright (c) 2019, Salesforce.org
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
* @date 2019
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Trigger handler on Allocation object, syncs changes between
*              Opportunity and Payment Allocations.
*/
public class ALLO_PaymentSync_TDTM extends TDTM_Runnable {

    /*******************************************************************************************************
    * @description Trigger Handler on Allocation, dispatches to the correct method based on
    * object type.
    * @param listNew the list of contacts, accounts, or affiliations from trigger new.
    * @param listOld the list of contacts, accounts, or affiliations from trigger old.
    * @param triggerAction Which action triggered the current context. (Before or After; Insert, Update,
    * Delete, or Undelete.)
    * @param objResult The field describe object for the current trigger context.
    * @return dmlWrapper Objects that need to be inserted or updated after the processing of the trigger.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newList, List<SObject> oldList,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        system.debug('njjc trigger ' + triggerAction + newList);
        system.debug('njjc isRecursive ' + TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ALLOC));
        
        if (TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ALLOC)) {
            return null;
        }
        if (!UTIL_CustomSettingsFacade.getAllocationsSettings().Payment_Allocations_Enabled__c) {
            return null;
        }

        Map<Id, Allocation__c> opportunityAllocations = new Map<Id, Allocation__c>();
        Map<Id, Allocation__c> paymentAllocations = new Map<Id, Allocation__c>();

        Set<Id> paymentAllocationsUpdated = new Set<Id>();
        Set<Id> opportunityAllocationsUpdated = new Set<Id>();

        List<Allocation__c> triggerAllocations;
        Map<Id, Allocation__c> oldMap;
        
        if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            triggerAllocations = (List<Allocation__c>) newList;
        }
        if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            triggerAllocations = (List<Allocation__c>) newList;
            oldMap = new Map<Id, Allocation__c>((List<Allocation__c>) oldList);
        }
        if (triggerAction == TDTM_Runnable.Action.AfterDelete) {
            triggerAllocations = (List<Allocation__c>) oldList;
        }

        //only validate and synchronize allocations with substantial updates
        //TODO: exclude closed/won opportunities?
        for (Allocation__c allocation : triggerAllocations) {
            if (allocation.Opportunity__c != null) {
                if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                    if (isSubstantialUpdate(allocation, oldMap.get(allocation.id))) {
                        opportunityAllocations.put(allocation.id, allocation);
                    }
                } else {
                    opportunityAllocations.put(allocation.id, allocation);
                }
            }
            if (allocation.Payment__c != null) {
                if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                    if (isSubstantialUpdate(allocation, oldMap.get(allocation.id))) {
                        paymentAllocations.put(allocation.id, allocation);
                    }
                } else {
                    paymentAllocations.put(allocation.id, allocation);
                }
            }
        }

        ALLO_PaymentSync_SVC service = new ALLO_PaymentSync_SVC(triggerAllocations);

        for (Allocation__c paymentAllocation : paymentAllocations.values()) {
            Id opportunityId = service.opportunityIdByPaymentId.get(paymentAllocation.Payment__c);
            paymentAllocationsUpdated.add(opportunityId);

            for (Allocation__c opportunityAllocation : opportunityAllocations.values()) {
                //validation: verify no updates to payment and opportunity allocations for the same opportunity
                if (opportunityAllocation.Opportunity__c == opportunityId) {
                    opportunityAllocation.addError('Opportunity and Payment Allocations for the same Opportunity record cannot be modified at the same time.');
                }
            }
        }

        for (Allocation__c opportunityAllocation : opportunityAllocations.values()) {
            opportunityAllocationsUpdated.add(opportunityAllocation.Opportunity__c);
        }

        for (Id opportunityId : paymentAllocationsUpdated) {
            system.debug('Syncing payment to opportunity ' + opportunityId);
            service.syncPaymentAllocationsToOpportunity(opportunityId);
        }

        for (Id opportunityId : opportunityAllocationsUpdated) {
            system.debug('Syncing opportunity to payment ' + opportunityId);
            service.syncOpportunityAllocationsToPayments(opportunityId);
        }

        system.debug('njjc: dml ' + service.allocationsChanges);
        
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, true);
        TDTM_TriggerHandler.processDML(service.allocationsChanges);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, false);
        return null;
    }

    //if user edits a custom allocation field or does an update without any changes, don't validate and sync
    private Boolean isSubstantialUpdate(Allocation__c newAllocation, Allocation__c oldAllocation) {
        return 
            newAllocation.Amount__c != oldAllocation.Amount__c ||
            newAllocation.Percent__c != oldAllocation.Percent__c ||
            newAllocation.General_Accounting_Unit__c != oldAllocation.General_Accounting_Unit__c ||
            newAllocation.Opportunity__c != oldAllocation.Opportunity__c ||
            newAllocation.Payment__c != oldAllocation.Payment__c;
    }
/*
pmt to opportunity

underschedule: less than 100% of opportunity amount in payments
    - setting up a schedule with not all payments the same amount, manually without the scheduler
    - shrink a payment, create a new payment for a second payment type--- underscheduled during
    - payment comes in lower/higher than expected amount, could stay underscheduled for a long time
    - writeoff: assume underscheduled

overschedule: more than 100% of opportunity amount payments


so: treat payments as a ratio of the total opportunity amount

sync upwards: writeoffs: not included in scheduled amount

sync down: writeoffs are considered paid, fixed: don't touch the allocations, just like a paid payment
allocating the amounts: count writoff allocations as if they don't exist, but do count the payment amount in totals

|     opportunity   | 100
|     A      |   B  | 60/40 : opportunity allocation ratio for GAU A: .6, GAU B: .4
->
|    A    |    B    | 50/50 : opportunity allocation ratio for GAU A: .5, GAU B: .5

    payments
|----|    |    |    | 25
|AA|B|aa|b|aa|b|aa|b|

paid allocations: A:15, B:10 (total 25)
unpaid allocations : A:35, B:40 (total 75) unpaid allocations to total unpaid allocations ratios: 35/75, 40/75

unpaid / total paid&unpaid ratio = .75

a: 25 * 75/100 * 35/75 = 8.75
b: 25 * 75/100 * 40/75 = 10

unpaid allocations per GAU / total unpaid allocations = 

when syncing Opportunity Allocations changes to unpaid Payments
each unpaid allocation = unpaid payment amount * 
                        unpaid payment ratio (unpaid amount / total payment amount) * 
                        unpaid allocation ratio (unpaid allocations to current GAU / total unpaid allocations) * 
                        schedule ratio (total paid and unpaid / opportunity amount)

total payment allocation = opportunity allocation * schedule ratio
total unpaid allocation = total payment allocation - paid payment allocations

100 opp
110 payment
ratio = 1.1



unpaidPaymentRatio (total unpaid payments / total payment amount (paid+unpaid, not written off))



*/
}