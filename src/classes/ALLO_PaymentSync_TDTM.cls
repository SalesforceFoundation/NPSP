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
* @date 2018
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Trigger handler on Allocation object, syncs changes between
*              Opportunity and Payment Allocations.
*/
public class ALLO_PaymentSync_TDTM extends TDTM_Runnable {

    private class SynchronizationContext {
        Opportunity opportunity;
        Map<Id, npe01__OppPayment__c> payments;

        //list of allocations by GAU
        Map<Id, List<Allocation__c>> opportunityAllocationsByGAU = new Map<Id, List<Allocation__c>>();
        Map<Id, List<Allocation__c>> paymentAllocationsByGAU = new Map<Id, List<Allocation__c>>();

        //sum of allocation amount by GAU
        Map<Id, Decimal> totalOpportunityAllocationsByGAU = new Map<Id, Decimal>();
        Map<Id, Decimal> totalPaymentAllocationsByGAU = new Map<Id, Decimal>();

        //the ratio of the sum of payment amounts (paid and unpaid, not written off) to the opportunity amount
        Decimal amountRatio = 0;
    }

    private Map<Id, SynchronizationContext> contextByOpportunity = new Map<Id, SynchronizationContext>();
    private Map<Id, Id> opportunityIdByPaymentId = new Map<Id, Id>();

    private DmlWrapper allocationsChanges = new DmlWrapper();

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

        //validation: verify no updates to payment and opportunity allocations for the same opportunity
        for (Allocation__c paymentAllocation : paymentAllocations.values()) {
            Id opportunityId = opportunityIdByPaymentId.get(paymentAllocation.Payment__c);
            for (Allocation__c opportunityAllocation : opportunityAllocations.values()) {
                if (opportunityAllocation.Opportunity__c == opportunityId) {
                    opportunityAllocation.addError('Opportunity and Payment Allocations for the same Opportunity record cannot be edited at the same time.');
                }
            }
        }

        makeSynchronizationContexts(triggerAllocations);

        for (Allocation__c paymentAllocation : paymentAllocations.values()) {
            Id opportunityId = opportunityIdByPaymentId.get(paymentAllocation.Payment__c);
            SynchronizationContext context = contextByOpportunity.get(opportunityId);
            syncPaymentAllocationsToOpportunity(context);
        }

        for (Allocation__c opportunityAllocation : opportunityAllocations.values()) {
            SynchronizationContext context = contextByOpportunity.get(opportunityAllocation.Opportunity__c);
            syncOpportunityAllocationsToPayments(context);
        }

        //TODO: 
            //move services to SVC class
            //move queries to SEL class

        system.debug('njjc: dml ' + allocationsChanges);
        
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, true);
        TDTM_TriggerHandler.processDML(allocationsChanges);
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, false);
        return null;
    }

    private void makeSynchronizationContexts(List<Allocation__c> allocations) {
        Set<Id> paymentIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, List<npe01__OppPayment__c>> paymentsByOpportunityId = new Map<Id, List<npe01__OppPayment__c>>();

        for (Allocation__c allocation : allocations) {
            if (allocation.Opportunity__c != null) {
                paymentsByOpportunityId.put(allocation.Opportunity__c, new List<npe01__OppPayment__c>());
            }
            if (allocation.Payment__c != null) {
                paymentIds.add(allocation.Payment__c);
            }
        }

        Map<Id, npe01__OppPayment__c> paymentsWithAllocations = new Map<Id, npe01__OppPayment__c>([
            SELECT Id, npe01__Opportunity__c, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Written_Off__c,
                (SELECT Id, Amount__c, Percent__c, General_Accounting_Unit__c FROM Allocations__r)
            FROM npe01__OppPayment__c 
            WHERE Id IN :paymentIds OR npe01__Opportunity__c IN :paymentsByOpportunityId.keySet()
            ORDER BY npe01__Opportunity__c
        ]);

        for (npe01__OppPayment__c payment : paymentsWithAllocations.values()) {
            opportunityIdByPaymentId.put(payment.Id, payment.npe01__Opportunity__c);

            if (paymentsByOpportunityId.containsKey(payment.npe01__Opportunity__c)) {
                paymentsByOpportunityId.get(payment.npe01__Opportunity__c).add(payment);
            } else {
                paymentsByOpportunityId.put(payment.npe01__Opportunity__c, new List<npe01__OppPayment__c>{payment});
            }
        }

        Map<Id, Opportunity> opportunitiesWithAllocations = new Map<Id, Opportunity>([
            SELECT Id, Amount,
                (SELECT Id, Amount__c, Percent__c, General_Accounting_Unit__c FROM Allocations__r)
            FROM Opportunity WHERE Id IN :paymentsByOpportunityId.keySet()
        ]);
        
        for (Opportunity opportunity : opportunitiesWithAllocations.values()) {
            SynchronizationContext context = new SynchronizationContext();
            context.opportunity = opportunity;

            for (Allocation__c oppAllocation : opportunity.Allocations__r) {
                Id gau = oppAllocation.General_Accounting_Unit__c;
                
                if (context.opportunityAllocationsByGAU.containsKey(gau)) {
                    context.opportunityAllocationsByGAU.get(gau).add(oppAllocation);
                } else {
                    context.opportunityAllocationsByGAU.put(gau, new List<Allocation__c>{oppAllocation});
                }

                if (context.totalOpportunityAllocationsByGAU.containsKey(gau)) {
                    Decimal currentTotal = context.totalOpportunityAllocationsByGAU.get(gau);
                    context.totalOpportunityAllocationsByGAU.put(gau, currentTotal + oppAllocation.Amount__c);
                } else {
                    context.totalOpportunityAllocationsByGAU.put(gau, oppAllocation.Amount__c);
                }
            }
            
            Decimal totalPaymentsNotWrittenOff = 0;
            
            for (npe01__OppPayment__c payment : paymentsByOpportunityId.get(opportunity.id)) {
                //don't count payments that have been written off
                if (payment.npe01__Written_Off__c) {
                    continue;
                }
                totalPaymentsNotWrittenOff += payment.npe01__Payment_Amount__c;

                for (Allocation__c pmtAllocation : payment.Allocations__r) {
                    Id gau = pmtAllocation.General_Accounting_Unit__c;

                    if (context.paymentAllocationsByGAU.containsKey(gau)) {
                        context.paymentAllocationsByGAU.get(gau).add(pmtAllocation);
                    } else {
                        context.paymentAllocationsByGAU.put(gau, new List<Allocation__c>{pmtAllocation});
                    }

                    if (context.totalPaymentAllocationsByGAU.containsKey(gau)) {
                        Decimal currentTotal = context.totalPaymentAllocationsByGAU.get(gau);
                        context.totalPaymentAllocationsByGAU.put(gau, currentTotal + pmtAllocation.Amount__c);
                    } else {
                        context.totalPaymentAllocationsByGAU.put(gau, pmtAllocation.Amount__c);
                    }
                }
            }

            if (opportunity.Amount != null && opportunity.Amount != 0) {
                context.amountRatio = totalPaymentsNotWrittenOff / opportunity.Amount;
            }

            contextByOpportunity.put(context.opportunity.id, context);
        }
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

    private void syncPaymentAllocationsToOpportunity(SynchronizationContext context) {
        //loop through allocations totals by GAU
        for (Id gau : context.totalPaymentAllocationsByGAU.keySet()) {
            Decimal totalPaymentAllocations = context.totalPaymentAllocationsByGAU.get(gau);
            //if we have corresponding opportunity allocations
            if (context.opportunityAllocationsByGAU.containsKey(gau)) {
                
                Decimal totalOpportunityAllocations = context.totalOpportunityAllocationsByGAU.get(gau);
                //check if they need updating
                if (totalPaymentAllocations * context.amountRatio != totalOpportunityAllocations) {
                    for (Allocation__c oppAllocation : context.opportunityAllocationsByGAU.get(gau)) {
                        //we want to keep the ratios amongst duplicate opportunity allocations
                        Decimal duplicateAllocationAmountRatio = totalOpportunityAllocations / context.opportunity.Amount;
                        oppAllocation.Amount__c = totalPaymentAllocations * duplicateAllocationAmountRatio;
                        if (oppAllocation.Percent__c != null) {
                            oppAllocation.Percent__c = context.Opportunity.Amount / oppAllocation.Amount__c;
                        }
                        //add to update
                        allocationsChanges.objectsToUpdate.add(oppAllocation);
                    }
                }
            //no corresponding opportunity allocation to payment allocations, insert one
            } else {
                Allocation__c newOppAllocation = new Allocation__c(
                    General_Accounting_Unit__c = gau,
                    Opportunity__c = context.opportunity.id,
                    Amount__c = totalPaymentAllocations / context.amountRatio
                );
                allocationsChanges.objectsToInsert.add(newOppAllocation);
            }
        }
        //if there are opportunity allocations not reflected in payment allocations, delete them
        for (Id gau : context.opportunityAllocationsByGAU.keySet()) {
            if (!context.paymentAllocationsByGAU.containsKey(gau)) {
                allocationsChanges.objectsToDelete.addAll(context.opportunityAllocationsByGAU.get(gau));
            }
        }
    }

    private void syncOpportunityAllocationsToPayments(SynchronizationContext context) {
        for (Id gau : context.opportunityAllocationsByGAU.keySet()) {

        }
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

*/
}