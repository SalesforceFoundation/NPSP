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
* @description Service syncs changes between Opportunity and Payment 
*              Allocations.
*/
public class ALLO_PaymentSync_SVC {

    public TDTM_Runnable.DmlWrapper allocationsChanges = new TDTM_Runnable.DmlWrapper();

    public Map<Id, Id> opportunityIdByPaymentId = new Map<Id, Id>();

    private Map<Id, SynchronizationContext> contextByOpportunity = new Map<Id, SynchronizationContext>();

    private class SynchronizationContext {
        Opportunity opportunity;
        Map<Id, npe01__OppPayment__c> payments = new Map<Id, npe01__OppPayment__c>();

        //Orig allocations from trigger context, arranged by gau Id
        //This is needed for deletes, where deleted allocation is not available in other context vars
        Map<Id, Allocation__c> triggerAllocationsByGAUId = new Map<Id, Allocation__c>();

        //list of allocations by GAU
        Map<Id, List<Allocation__c>> opportunityAllocationsByGAU = new Map<Id, List<Allocation__c>>();
        Map<Id, List<Allocation__c>> paymentAllocationsByGAU = new Map<Id, List<Allocation__c>>();

        //sum of allocation amount by GAU
        Map<Id, Decimal> totalOpportunityAllocationsByGAU = new Map<Id, Decimal>();
        Map<Id, Decimal> totalPaymentAllocationsByGAU = new Map<Id, Decimal>();
        Map<Id, Decimal> totalPaidPaymentAllocationsByGAU = new Map<Id, Decimal>();

        //the ratio of the sum of payment amounts (paid or unpaid, not written off) to the opportunity amount
        Decimal scheduleRatio = 0;
        Decimal totalUnpaidPayments = 0;
    }

    public ALLO_PaymentSync_SVC(List<Allocation__c> allocations) {

        Set<Id> paymentIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, List<npe01__OppPayment__c>> paymentsByOpportunityId = new Map<Id, List<npe01__OppPayment__c>>();
        Map<Id, Map<Id, Allocation__c>> triggerAllocationsByGAUByParentId = new Map<Id, Map<Id, Allocation__c>>();

        for (Allocation__c allocation : allocations) {
            Map<Id, Allocation__c> allocationsByGAUId = new Map<Id, Allocation__c>();
            if (allocation.Opportunity__c != null) {
                paymentsByOpportunityId.put(allocation.Opportunity__c, new List<npe01__OppPayment__c>());
                if(!triggerAllocationsByGAUByParentId.containsKey(allocation.Opportunity__c)) {
                    triggerAllocationsByGAUByParentId.put(allocation.Opportunity__c, allocationsByGAUId);
                }
            }
            if (allocation.Payment__c != null) {
                paymentIds.add(allocation.Payment__c);
                if(!triggerAllocationsByGAUByParentId.containsKey(allocation.Payment__c)) {
                    triggerAllocationsByGAUByParentId.put(allocation.Payment__c, allocationsByGAUId);
                }            
            }
            allocationsByGAUId.put(allocation.General_Accounting_Unit__c, allocation);
        }

        //unfortunately, we need to first gather the opportunity IDs of all payment allocations changes in order to query for all child payments
        List<npe01__OppPayment__c> paymentsWithOppIds = [
            SELECT Id, npe01__Opportunity__c
            FROM npe01__OppPayment__c 
            WHERE Id IN :paymentIds OR npe01__Opportunity__c IN :paymentsByOpportunityId.keySet()
        ];

        for (npe01__OppPayment__c payment : paymentsWithOppIds) {
            paymentsByOpportunityId.put(payment.npe01__Opportunity__c, new List<npe01__OppPayment__c>());
        }

        Map<Id, npe01__OppPayment__c> paymentsWithAllocations = new Map<Id, npe01__OppPayment__c>([
            SELECT Id, npe01__Opportunity__c, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Written_Off__c,
                (SELECT Id, Amount__c, Percent__c, Opportunity__c, Payment__c, General_Accounting_Unit__c FROM Allocations__r)
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
                (SELECT Id, Amount__c, Percent__c, Opportunity__c, Payment__c, General_Accounting_Unit__c FROM Allocations__r)
            FROM Opportunity WHERE Id IN :paymentsByOpportunityId.keySet()
        ]);
        
        for (Opportunity opportunity : opportunitiesWithAllocations.values()) {
            SynchronizationContext context = new SynchronizationContext();
            context.opportunity = opportunity;

            if(triggerAllocationsByGAUByParentId.containsKey(opportunity.Id)) {
                context.triggerAllocationsByGAUId = triggerAllocationsByGAUByParentId.get(opportunity.Id);
            } else {
                context.triggerAllocationsByGAUId = new Map<Id, Allocation__c>();
            }

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

            Decimal totalPaymentsPaidUnpaid = 0;

            for (npe01__OppPayment__c payment : paymentsByOpportunityId.get(opportunity.id)) {
                //ignore payments that have been written off
                if (payment.npe01__Written_Off__c) {
                    continue;
                }
                //ignore payments with null or 0 amount
                if (payment.npe01__Payment_Amount__c == null || payment.npe01__Payment_Amount__c == 0) {
                    continue;
                }

                context.payments.put(payment.id, payment);

                totalPaymentsPaidUnpaid += payment.npe01__Payment_Amount__c;

                if (!payment.npe01__Paid__c) {
                    context.totalUnpaidPayments += payment.npe01__Payment_Amount__c;
                }

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

                    if (payment.npe01__Paid__c) {
                        if (context.totalPaidPaymentAllocationsByGAU.containsKey(gau)) {
                            Decimal currentTotal = context.totalPaidPaymentAllocationsByGAU.get(gau);
                            context.totalPaidPaymentAllocationsByGAU.put(gau, currentTotal + pmtAllocation.Amount__c);
                        } else {
                            context.totalPaidPaymentAllocationsByGAU.put(gau, pmtAllocation.Amount__c);
                        }

                    }
                }
            }

            if (opportunity.Amount != null && opportunity.Amount != 0) {
                context.scheduleRatio = totalPaymentsPaidUnpaid / opportunity.Amount;
            }

            contextByOpportunity.put(context.opportunity.id, context);
            System.debug('context' + json.serializePretty(context));
        }
    }

    public void syncPaymentAllocationsToOpportunity(Id opportunityId) {
        SynchronizationContext context = contextByOpportunity.get(opportunityId);
        //loop through allocations totals by GAU
        for (Id gau : context.totalPaymentAllocationsByGAU.keySet()) {
            Decimal totalPaymentAllocations = context.totalPaymentAllocationsByGAU.get(gau);
            //if we have opportunity allocations for this GAU
            if (context.opportunityAllocationsByGAU.containsKey(gau)) {
                
                Decimal totalOpportunityAllocations = context.totalOpportunityAllocationsByGAU.get(gau);
                Decimal adjustedTotalPaymentAllocations = totalPaymentAllocations * context.scheduleRatio;
                
                System.debug('njjc totalOpportunityAllocations ' + totalOpportunityAllocations + ' adjustedTotalPaymentAllocations ' + 
                    adjustedTotalPaymentAllocations);

                //check if they need updating
                if (adjustedTotalPaymentAllocations != totalOpportunityAllocations) {
                    for (Allocation__c oppAllocation : context.opportunityAllocationsByGAU.get(gau)) {
                        //we want to keep the ratios amongst duplicate opportunity allocations
                        Decimal duplicateAllocationPaidUnpaidAmountRatio = oppAllocation.Amount__c / totalOpportunityAllocations;
                        System.debug('njjc duplicateAllocationPaidUnpaidAmountRatio ' + duplicateAllocationPaidUnpaidAmountRatio + 
                            ' calculatedAmount ' + totalPaymentAllocations * duplicateAllocationpaidUnpaidAmountRatio);

                        oppAllocation.Amount__c = totalPaymentAllocations * duplicateAllocationpaidUnpaidAmountRatio;
                        if (oppAllocation.Percent__c != null) {
                            oppAllocation.Percent__c = oppAllocation.Amount__c / context.Opportunity.Amount * 100;
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
                    Amount__c = totalPaymentAllocations / context.scheduleRatio
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

    public void syncOpportunityAllocationsToPayments(Id opportunityId) {
        SynchronizationContext context = contextByOpportunity.get(opportunityId);
        for (Id gau : context.opportunityAllocationsByGAU.keySet()) {
            Decimal totalOpportunityAllocations = context.totalOpportunityAllocationsByGAU.get(gau);
            Decimal newTotalPaymentAllocations = totalOpportunityAllocations * context.scheduleRatio;

            //if we have payment allocations for this GAU 
            if (context.paymentAllocationsByGAU.containsKey(gau)) {
                Decimal currentTotalPaymentAllocations = context.totalPaymentAllocationsByGAU.get(gau);
                Decimal totalPaidPaymentAllocations = 0;
                if (context.totalPaidPaymentAllocationsByGAU.containsKey(gau)) {
                    totalPaidPaymentAllocations = context.totalPaidPaymentAllocationsByGAU.get(gau);
                }

                //validation: if the total of payment allocations already paid is greater than the opportunity 
                //allocations for that GAU, we can't sync and must throw an error
                if (totalPaidPaymentAllocations > newTotalPaymentAllocations || 
                    totalPaidPaymentAllocations > totalOpportunityAllocations) {
                    
                    if(context.triggerAllocationsByGAUId.containsKey(gau)) {
                        context.triggerAllocationsByGAUId.get(gau).addError(System.Label.alloPaidPmtsExceedsOpp);
                    }
                    continue;
                }

                //if existing paid payment allocations are equal to the new total, delete any unpaid payment allocations
                if (totalPaidPaymentAllocations == newTotalPaymentAllocations) {
                    for (Allocation__c paymentAllocation : context.paymentAllocationsByGAU.get(gau)) {
                        npe01__OppPayment__c payment = context.payments.get(paymentAllocation.Payment__c);
                        if (!payment.npe01__Paid__c) {
                            allocationsChanges.objectsToDelete.add(paymentAllocation);
                        }
                    }
                }

                //if desired end amounts are out of sync, update them
                if (currentTotalPaymentAllocations != newTotalPaymentAllocations) {

                    for (Allocation__c paymentAllocation : context.paymentAllocationsByGAU.get(gau)) {
                        npe01__OppPayment__c payment = context.payments.get(paymentAllocation.Payment__c);

                        if (!payment.npe01__Paid__c && payment.npe01__Payment_Amount__c != 0) {
                            Decimal unpaidAllocationAmount = newTotalPaymentAllocations - totalPaidPaymentAllocations;
                            Decimal paymentRatio = payment.npe01__Payment_Amount__c / context.totalUnpaidPayments;

                            paymentAllocation.Amount__c = unpaidAllocationAmount * paymentRatio;// * context.scheduleRatio; <- is that needed, since it's already included in the newTotalPaymentAllocations?
                            
                            //only add the percent for non-default
                            if (gau != UTIL_CustomSettingsFacade.getAllocationsSettings().Default__c) {
                                paymentAllocation.Percent__c = paymentAllocation.Amount__c / payment.npe01__Payment_Amount__c * 100;
                            }

                            allocationsChanges.objectsToUpdate.add(paymentAllocation);
                        }
                    }
                }
            //no payment allocations for this GAU; create them
            } else if (context.totalUnpaidPayments > 0) {
                for (npe01__OppPayment__c payment : context.payments.values()) {
                    Decimal paymentRatio = payment.npe01__Payment_Amount__c / context.totalUnpaidPayments;
                    Allocation__c newAllocation = new Allocation__c(
                        Payment__c = payment.Id,
                        General_Accounting_Unit__c = gau,
                        Amount__c = newTotalPaymentAllocations * paymentRatio // * context.scheduleRatio  <- is that needed, since it's already included in the newTotalPaymentAllocations?
                    );

                    //only add the percent for non-default
                    if (gau != UTIL_CustomSettingsFacade.getAllocationsSettings().Default__c) {
                        newAllocation.Percent__c = newAllocation.Amount__c / payment.npe01__Payment_Amount__c * 100;
                    }

                    allocationsChanges.objectsToInsert.add(newAllocation);
                }
            }
        }

        //handle payment allocations for deleted opportunity allocations
        for (Id gau : context.paymentAllocationsByGAU.keySet()) {
            if (!context.opportunityAllocationsByGAU.containsKey(gau)) {
                for (Allocation__c paymentAllocation : context.paymentAllocationsByGAU.get(gau)) {
                    npe01__OppPayment__c payment = context.payments.get(paymentAllocation.Payment__c);
                    //since we can't delete paid payment allocations
                    //add error to opportunity allocation if we have paid payment allocations for this GAU
                    if (payment.npe01__Paid__c && context.triggerAllocationsByGAUId.containsKey(gau)) {
                        // flag the allocation we are attempting to delete with an error; this record is
                        // not available in the opportunityAllocationsByGAU map
                        context.triggerAllocationsByGAUId.get(gau).addError(System.Label.alloRemoveOppWithPmt);
                    } else {
                        allocationsChanges.objectsToDelete.add(paymentAllocation);
                    }
                }
            }
        }
    }
}