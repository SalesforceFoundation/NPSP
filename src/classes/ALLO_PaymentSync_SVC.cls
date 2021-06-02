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

    public class PaymentSyncException extends Exception {}

    public TDTM_Runnable.DmlWrapper allocationsChanges = new TDTM_Runnable.DmlWrapper();

    public Map<Id, Id> opportunityIdByPaymentId = new Map<Id, Id>();
    private Map<Id, SynchronizationContext> contextByOpportunity = new Map<Id, SynchronizationContext>();

    // Does not include default GAU
    private Map<Id, Decimal> allocatedAmountByPayment = new Map<Id, Decimal>();
        // Need to keep track of default allocation(s) by Payment
    private Map<Id, List<Allocation__c>> defaultAllocsByPayment = new Map<Id, List<Allocation__c>>();

    /**
     *  Inner Class to facilitate processing of allocations updates by maintaining maps of allocations, etc.
     */
    private class SynchronizationContext {
        // Opportunity associated with this Synchronization Context
        Opportunity opportunity;
        // List of Payments associated with this Opportunity (with Allocations)
        Map<Id, npe01__OppPayment__c> payments = new Map<Id, npe01__OppPayment__c>();

        //Orig allocations from trigger context, arranged by gau Id
        //This is needed for deletes, where deleted allocation is not available in other context vars
        Map<Id, Allocation__c> triggerAllocationsByGAUId = new Map<Id, Allocation__c>();

        // This is a mapping of the GAU Id to Allocation for the trigger.old for updates and deletes, but trigger.new for insert.
        // This is used for the validation where the we make sure the allocation on the opportunity level
        // isn't removed/updated if there are paid payments associated with it.
        Map<Id, Allocation__c> oldTriggerAllocationsByGAUIdForValidation = new Map<Id, Allocation__c>();

        //list of allocations by GAU
        Map<Id, List<Allocation__c>> opportunityAllocationsByGAU = new Map<Id, List<Allocation__c>>();
        Map<Id, List<Allocation__c>> paymentAllocationsByGAU = new Map<Id, List<Allocation__c>>();

        //sum of allocation amount by GAU
        Map<Id, Decimal> totalOpportunityAllocationsByGAU = new Map<Id, Decimal>();
        Map<Id, Decimal> totalPaymentAllocationsByGAU = new Map<Id, Decimal>();
        Map<Id, Decimal> totalPaidPaymentAllocationsByGAU = new Map<Id, Decimal>();

        //the ratio of the sum of payment amounts (unpaid, not written off) to the opportunity amount
        Decimal scheduleRatio = 0;

        //the ratio of the sum of payment amounts (paid or unpaid, not written off) to the opportunity amount
        Decimal scalingRatio = 0;
        Decimal totalUnpaidPayments = 0;
        Decimal totalPaidUnpaidPayments = 0;
    }

    /*******************************************************************************************************
    * @description Amount to add to the total of the allocations for that payment
    * @param Id paymentId Payment whose allocation amount should be updated
    * @param Decimal allocAmount amount to update total allocation amount by
    ********************************************************************************************************/
    private void addAllocationAmountToPayment(Id paymentId, Decimal allocAmount) {
        Decimal amt = allocatedAmountByPayment.containsKey(paymentId) ? allocatedAmountByPayment.get(paymentId) : 0;
        amt += ((allocAmount != null) ? allocAmount : 0);
        allocatedAmountByPayment.put (paymentId, amt);
    }

    /*******************************************************************************************************
    * @description Amount to remove from the total of the allocations for that payment
    * @param Id paymentId Payment whose allocation amount should be updated
    * @param Decimal allocAmount amount to update total allocation amount by
    ********************************************************************************************************/
    private void removeAllocationAmountFromPayment(Id paymentId, Decimal allocAmount) {
        Decimal amt = allocatedAmountByPayment.containsKey(paymentId) ? allocatedAmountByPayment.get(paymentId) : 0;
        amt -= ((allocAmount != null) ? allocAmount : 0);
        allocatedAmountByPayment.put (paymentId, amt);
    }

    /*******************************************************************************************************
    * @description Constructor for Payment Sync Service
    * @param List<Allocation__c> allocations - a list of Allocations to process
    ********************************************************************************************************/
    public ALLO_PaymentSync_SVC(List<Allocation__c> allocations, List<Allocation__c> allocationsForValidation) {

        Set<Id> paymentIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        Map<Id, List<npe01__OppPayment__c>> paymentsByOpportunityId = new Map<Id, List<npe01__OppPayment__c>>();
        Map<Id, Map<Id, Allocation__c>> triggerAllocationsByGAUByParentId = new Map<Id, Map<Id, Allocation__c>>();
        Map<Id, Map<Id, Allocation__c>> oldTriggerAllocationsByGAUByParentIdForValidation = new Map<Id, Map<Id, Allocation__c>>();

        // Just so we are not repeatedly retrieving it in loops.  It is cached, but still..
        Id defaultGAU = UTIL_CustomSettingsFacade.getAllocationsSettings().Default__c;

        for (Allocation__c allocation : allocations) {
            Map<Id, Allocation__c> allocationsByGAUId = null;

            // Determine if parent of Allocation is Opportunity or Payment
            Id parentId = (allocation.Opportunity__c != null) ? allocation.Opportunity__c : allocation.Payment__c;

            if (parentId != null) {
                allocationsByGAUID = (triggerAllocationsByGAUByParentId.containsKey(parentId)) ? triggerAllocationsByGAUByParentId.get(parentId) : new Map<Id, Allocation__c>();
                if(!triggerAllocationsByGAUByParentId.containsKey(parentId)) {
                    triggerAllocationsByGAUByParentId.put(parentId, allocationsByGAUId);
                }
                allocationsByGAUId.put(allocation.General_Accounting_Unit__c, allocation);
            }

            if (allocation.Opportunity__c != null) {
                paymentsByOpportunityId.put(allocation.Opportunity__c, new List<npe01__OppPayment__c>());
            }

            if (allocation.Payment__c != null) {
                paymentIds.add(allocation.Payment__c);
            }
        }

        for (Allocation__C allocation : allocationsForValidation) {
            Map<Id, Allocation__c> allocationsByGAUId = null;

            // Determine if parent of Allocation is Opportunity or Payment
            Id parentId = (allocation.Opportunity__c != null) ? allocation.Opportunity__c : allocation.Payment__c;

            if (parentId != null) {
                allocationsByGAUID = (oldTriggerAllocationsByGAUByParentIdForValidation.containsKey(parentId)) ? oldTriggerAllocationsByGAUByParentIdForValidation.get(parentId) : new Map<Id, Allocation__c>();
                if(!oldTriggerAllocationsByGAUByParentIdForValidation.containsKey(parentId)) {
                    oldTriggerAllocationsByGAUByParentIdForValidation.put(parentId, allocationsByGAUId);
                }
                allocationsByGAUId.put(allocation.General_Accounting_Unit__c, allocation);
            }
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

        // Retrieve all payments, with associated allocations
        Map<Id, npe01__OppPayment__c> paymentsWithAllocations = retrievePaymentsWithAllocations(paymentIds, paymentsByOpportunityId.keySet());
        for (npe01__OppPayment__c payment : paymentsWithAllocations.values()) {
            opportunityIdByPaymentId.put(payment.Id, payment.npe01__Opportunity__c);

            if (paymentsByOpportunityId.containsKey(payment.npe01__Opportunity__c)) {
                paymentsByOpportunityId.get(payment.npe01__Opportunity__c).add(payment);
            } else {
                paymentsByOpportunityId.put(payment.npe01__Opportunity__c, new List<npe01__OppPayment__c>{payment});
            }
            // Update Map of Default Allocations
            defaultAllocsByPayment.put (payment.Id, filterByGAU(payment.Allocations__r, defaultGAU));

            // Create Initial Total of Allocations by Payment, excluding the default amount
            allocatedAmountByPayment.put (payment.Id, calculateTotalAllocationAmountExcludingDefaultGAU(payment.Allocations__r, defaultGAU));
        }
        // Retrieve all opportunities, with associated allocations
        Map<Id, Opportunity> opportunitiesWithAllocations = retrieveOpportunitiesWithAllocations(paymentsByOpportunityId.keySet());

        for (Opportunity opportunity : opportunitiesWithAllocations.values()) {
            SynchronizationContext context = new SynchronizationContext();
            context.opportunity = opportunity;

            if(triggerAllocationsByGAUByParentId.containsKey(opportunity.Id)) {
                context.triggerAllocationsByGAUId = triggerAllocationsByGAUByParentId.get(opportunity.Id);
            } else {
                context.triggerAllocationsByGAUId = new Map<Id, Allocation__c>();
            }

            if (oldTriggerAllocationsByGAUByParentIdForValidation.containsKey(opportunity.Id)) {
                context.oldTriggerAllocationsByGAUIdForValidation = oldTriggerAllocationsByGAUByParentIdForValidation.get(opportunity.Id);
            } else {
                context.oldTriggerAllocationsByGAUIdForValidation = new Map<Id, Allocation__c>();
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

            // Need this value to accurately calculate the percentage used when recalculating allocations on the Opportunity (from the changes to
            // the payment allocations)
            context.totalPaidUnpaidPayments = totalPaymentsPaidUnpaid;

            if (opportunity.Amount != null && opportunity.Amount != 0) {

                // The schedule ratio should only take into account the unpaid payments that are left since the ratio is for remaining unpaid allocations. 
                // We aren't currently taking into account the paid amount currently, but this may change in the future. 
                context.scheduleRatio = context.totalUnpaidPayments / opportunity.Amount;
                context.scalingRatio = context.totalPaidUnpaidPayments / opportunity.Amount;
            }

            contextByOpportunity.put(context.opportunity.id, context);
        }
    }

    /*******************************************************************************************************
    * @description Given a set of Payment Ids, and a set of Opportunity Ids, this method
    * returns the Payments associated with them, as well as any associated Allocations.
    * @param Set<Id> paymentIds A set of Payment Ids
    * @param Set<Id> opportunityIds A set of Opportunity Ids
    * @return Map<Id, npe01__OppPayment__c> map of Payments with Payment Allocations by Payment Id
    ********************************************************************************************************/
    @testVisible private Map<Id, npe01__OppPayment__c> retrievePaymentsWithAllocations(Set<Id> paymentIds, Set<Id> opportunityIds) {
        Boolean multiCurrencyOrg = UserInfo.isMultiCurrencyOrganization();
        String queryString = 'SELECT    Id, ' +
                                        'Name, ' +
                                        'npe01__Opportunity__c, ' +
                                        'npe01__Payment_Amount__c, '+
                                        'npe01__Paid__c, ' +
                                        'npe01__Written_Off__c, ' +
                                        (multiCurrencyOrg ? 'CurrencyIsoCode, ' : '') +
                                        '(SELECT    Id, ' +
                                                    'Name, ' +
                                                    (multiCurrencyOrg ? 'CurrencyIsoCode, ' : '') +
                                                    'Amount__c, ' +
                                                    'Percent__c, ' +
                                                    'Opportunity__c, ' +
                                                    'Payment__c, ' +
                                                    'General_Accounting_Unit__c ' +
                                        ' FROM Allocations__r) ' +
                                'FROM npe01__OppPayment__c ' +
                                'WHERE  Id IN :paymentIds OR ' +
                                        'npe01__Opportunity__c IN : opportunityIds';

        Map<Id, npe01__OppPayment__c> pmts = new Map<Id, npe01__OppPayment__c>();
        List<SObject> sobjs = Database.query(queryString);

        for (SObject sobj :sobjs) {
            pmts.put (sobj.Id, (npe01__OppPayment__c)sobj);
        }
        return pmts;
    }

    /*******************************************************************************************************
    * @description Given a set of a set of Opportunity Ids, this method returns the Opportunities
    * associated with them, as well as any associated Allocations.
    * @param Set<Id> opportunityIds A set of Opportunity Ids
    * @return Map<Id, npe01__OppPayment__c> map of Opportunities with Opportunity Allocations by Opportunity Id
    ********************************************************************************************************/
    @testVisible private Map<Id, Opportunity> retrieveOpportunitiesWithAllocations(Set<Id> opportunityIds) {
        Boolean multiCurrencyOrg = UserInfo.isMultiCurrencyOrganization();
        String queryString = 'SELECT    Id, ' +
                                        'Name, ' +
                                        'Amount, ' +
                                        (multiCurrencyOrg ? 'CurrencyIsoCode, ' : '') +
                                        '(SELECT    Id, ' +
                                                    'Name, ' +
                                                    (multiCurrencyOrg ? 'CurrencyIsoCode, ' : '') +
                                                    'Amount__c, ' +
                                                    'Percent__c, ' +
                                                    'Opportunity__c, ' +
                                                    'Payment__c, ' +
                                                    'General_Accounting_Unit__c ' +
                                        ' FROM Allocations__r) ' +
                             'FROM Opportunity ' +
                             'WHERE     Id IN :opportunityIds';

        Map<Id, Opportunity> opps = new Map<Id, Opportunity>();
        List<SObject> sobjs = Database.query(queryString);

        for (SObject sobj :sobjs) {
            opps.put(sobj.Id, (Opportunity)sobj);
        }
        return opps;
    }

    /*******************************************************************************************************
    * @description Takes a list of allocations, and the Id of the default GAU, and sums the allocation
    * amounts, excluding any that are for the default allocation.
    * @param List<Allocation__c> allocs The list of allocations to sum
    * @param Id defaultGAU The id of the default GAU
    * @return Decimal total amount of the allocations, excluding ones for the default GAU
    ********************************************************************************************************/
    @testVisible private Decimal calculateTotalAllocationAmountExcludingDefaultGAU(List<Allocation__c> allocs, Id defaultGAU) {
        Decimal totalAllocationAmount = 0;

        for (Allocation__c alloc : allocs) {
            if (alloc.General_Accounting_Unit__c != defaultGAU) {
                totalAllocationAmount += alloc.Amount__c;
            }
        }
        return totalAllocationAmount;
    }

    /*******************************************************************************************************
    * @description Takes a list of allocations, and returns a list of ones that match the specified gau
    * @param List<Allocation__c> allocs The list of allocations to filter
    * @param Id gau The id of the GAU
    * @return List<Allocation__c> the filtered list of allocations
    ********************************************************************************************************/
    @testVisible private List<Allocation__c> filterByGAU(List<Allocation__c> allocs, Id gau) {
        List<Allocation__c> fallocs = new List<Allocation__c>();
        for (Allocation__c alloc : allocs) {
            if (alloc.General_Accounting_Unit__c == gau) {
                fallocs.add(alloc);
            }
        }
        return fallocs;
    }

    /*******************************************************************************************************
    * @description Given an opportunity Id, it recalculates the Opportunity Allocations based
    *  on the Payment Allocations associated with the opportunity
    * @param Id opportunityId Id of the Opportunity to process
    ********************************************************************************************************/
    public void syncPaymentAllocationsToOpportunity(Id opportunityId) {
        SynchronizationContext context = contextByOpportunity.get(opportunityId);

        //get allocations settings
        Allocations_Settings__c alloSettings = UTIL_CustomSettingsFacade.getAllocationsSettings();

        //loop through allocations totals by GAU
        for (Id gau : context.totalPaymentAllocationsByGAU.keySet()) {
            Decimal totalPaymentAllocations = context.totalPaymentAllocationsByGAU.get(gau);
            Decimal totalAllPayments = context.totalPaidUnpaidPayments;
            Decimal percentGAU = (totalAllPayments != 0) ? totalPaymentAllocations / totalAllPayments : 0;

            // Calculate the proposed amount (based on the Opportunity amount, multiplied by the GAU Percentage)
            Decimal newGAUAmtForOpp = (context.opportunity.Amount * percentGAU).setScale(2);

            //if we have opportunity allocations for this GAU
            if (context.opportunityAllocationsByGAU.containsKey(gau)) {

                Decimal totalOpportunityAllocations = context.totalOpportunityAllocationsByGAU.get(gau);

                //check if they need updating
                if (newGAUAmtForOpp != totalOpportunityAllocations) {
                    for (Allocation__c oppAllocation : context.opportunityAllocationsByGAU.get(gau)) {
                        //we want to keep the ratios amongst duplicate opportunity allocations
                        Decimal duplicateAllocationPaidUnpaidAmountRatio = oppAllocation.Amount__c / totalOpportunityAllocations;

                        oppAllocation.Amount__c = newGAUAmtForOpp * duplicateAllocationpaidUnpaidAmountRatio;

                        if (oppAllocation.Percent__c != null) {
                            oppAllocation.Percent__c = (context.Opportunity.Amount != 0) ? oppAllocation.Amount__c / context.opportunity.Amount * 100 : 0;
                        }

                        // Assumption: Opportunity Allocations should be maintained with Currency Type from Opportunity Record
                        if (UserInfo.isMultiCurrencyOrganization()) {
                            oppAllocation.put('CurrencyIsoCode', context.opportunity.get('CurrencyIsoCode'));
                        }

                        //add to update
                        allocationsChanges.objectsToUpdate.add(oppAllocation);
                    }
                }
            //No corresponding opportunity allocation to payment allocations, insert one
            // It will be inserted as a percentage based allocation so it scales properly if the opportunity amount is changed
            } else {
                Allocation__c newOppAllocation = new Allocation__c(
                    General_Accounting_Unit__c = gau,
                    Opportunity__c = context.opportunity.id,
                    Amount__c = newGAUAmtForOpp
                );

                //only add the percent for non-default
                if (!alloSettings.Default_Allocations_Enabled__c
                    || (alloSettings.Default_Allocations_Enabled__c &&  gau != alloSettings.Default__c)) {
                    newOppAllocation.Percent__c = (context.Opportunity.Amount != 0) ? newGAUAmtFOrOpp / context.Opportunity.Amount * 100 : 0;
                }

                // Assumption: Opportunity Allocations should be maintained with Currency Type from Opportunity Record
                if (UserInfo.isMultiCurrencyOrganization()) {
                    newOppAllocation.put('CurrencyIsoCode', context.opportunity.get('CurrencyIsoCode'));
                }
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

    /*******************************************************************************************************
    * @description Given an opportunity Id, it recalculates the Payment Allocations based
    *  on the Opportunity Allocations associated with the opportunity
    * @param Id opportunityId Id of the Opportunity to process
    ********************************************************************************************************/
    public void syncOpportunityAllocationsToPayments(Id opportunityId) {
        SynchronizationContext context = contextByOpportunity.get(opportunityId);

        for (Id gau : context.opportunityAllocationsByGAU.keySet()) {
            Decimal totalOpportunityAllocations = context.totalOpportunityAllocationsByGAU.get(gau);
            Decimal newTotalPaymentAllocations = totalOpportunityAllocations * context.scheduleRatio;
            Decimal newScaledTotalPaymentAllocations = totalOpportunityAllocations * context.scalingRatio;

            // Default Allocation will be handled outside of this loop
            if (gau == UTIL_CustomSettingsFacade.getAllocationsSettings().Default__c) {
                continue;
            }

            //if we have payment allocations for this GAU
            if (context.paymentAllocationsByGAU.containsKey(gau)) {
                Decimal currentTotalPaymentAllocations = context.totalPaymentAllocationsByGAU.get(gau);
                Decimal totalPaidPaymentAllocations = 0;
                
                if (context.totalPaidPaymentAllocationsByGAU.containsKey(gau)) {
                    totalPaidPaymentAllocations = context.totalPaidPaymentAllocationsByGAU.get(gau);
                }

                //validation: if the total of payment allocations already paid is greater than the opportunity
                //allocations for that GAU, we can't sync and must throw an error
                if (totalPaidPaymentAllocations > newScaledTotalPaymentAllocations ||
                    totalPaidPaymentAllocations > totalOpportunityAllocations) {

                    if(context.triggerAllocationsByGAUId.containsKey(gau)) {
                        String gauName = context.triggerAllocationsByGAUId.get(gau).Name;
                        String gauId = context.triggerAllocationsByGAUId.get(gau).Id;
                        throw new PaymentSyncException(String.format(Label.alloPaidPmtsExceedsOpp, new String[] {context.Opportunity.Name, context.Opportunity.Id, gauName, gauId}));
                    }
                    continue;
                }

                //if existing paid payment allocations are equal to the new total, delete any unpaid payment allocations
                if (totalPaidPaymentAllocations == newTotalPaymentAllocations) {
                    for (Allocation__c paymentAllocation : context.paymentAllocationsByGAU.get(gau)) {
                        npe01__OppPayment__c payment = context.payments.get(paymentAllocation.Payment__c);
                        if (!payment.npe01__Paid__c) {
                            allocationsChanges.objectsToDelete.add(paymentAllocation);
                            removeAllocationAmountFromPayment(payment.Id, paymentAllocation.Amount__c);
                        }
                    }
                }

                //if desired end amounts are out of sync, update them
                // Recalculate and update the existing allocations for this GAU. 
                if (currentTotalPaymentAllocations != newTotalPaymentAllocations) {
                    Set<Id> paymentsWithExistingGAU = new Set<Id>();
                    Map<Id, Allocation__c> paymentToAllocationMap = new Map<Id, Allocation__c>();

                    for (Allocation__c paymentAllocation : context.paymentAllocationsByGAU.get(gau)) {
                        npe01__OppPayment__c payment = context.payments.get(paymentAllocation.Payment__c);

                        if (!paymentToAllocationMap.containsKey(payment.Id)) {
                            if (!payment.npe01__Paid__c && payment.npe01__Payment_Amount__c != 0) {
                                paymentsWithExistingGAU.add(payment.Id);
                                Decimal paymentRatio =  context.totalUnpaidPayments / payment.npe01__Payment_Amount__c;

                                // Remove current allocation amount from total as it is changing
                                removeAllocationAmountFromPayment(payment.Id, paymentAllocation.Amount__c);

                                // paymentAllocation.Amount__c = (unpaidAllocationAmount) / (paymentRatio);// * context.scheduleRatio; <- is that needed, since it's already included in the newTotalPaymentAllocations?
                                paymentAllocation.Amount__c = (newTotalPaymentAllocations) / (paymentRatio);

                                //only add the percent for non-default
                                if (gau != UTIL_CustomSettingsFacade.getAllocationsSettings().Default__c) {
                                    paymentAllocation.Percent__c = paymentAllocation.Amount__c / payment.npe01__Payment_Amount__c * 100;
                                }

                                // Add updated allocation amount to total
                                addAllocationAmountToPayment(payment.Id, paymentAllocation.Amount__c);

                                // Assumption: Payment Allocations should be maintained with Currency Type from Payment Record
                                if (UserInfo.isMultiCurrencyOrganization()) {
                                    paymentAllocation.put('CurrencyIsoCode', payment.get('CurrencyIsoCode'));
                                }

                                allocationsChanges.objectsToUpdate.add(paymentAllocation);
                                paymentToAllocationMap.put(payment.Id, paymentAllocation);
                            }
                        } else {
                            allocationsChanges.objectsToDelete.add(paymentAllocation);
                        }
                    }
                    // Now do a second pass looking for ones that did not have this allocation...
                    for (npe01__OppPayment__c payment : context.payments.values()) {
                        if (!payment.npe01__Paid__c && payment.npe01__Payment_Amount__c != 0 && !paymentsWithExistingGAU.contains(payment.Id)) {
                            Decimal paymentRatio = context.totalUnpaidPayments / payment.npe01__Payment_Amount__c;
                            Decimal paymentScale = computePaymentScale(context.totalPaidUnpaidPayments, context.opportunity.Amount);

                            Allocation__c newAllocation = new Allocation__c(
                                Payment__c = payment.Id,
                                General_Accounting_Unit__c = gau,
                                Amount__c = (newTotalPaymentAllocations) / (paymentRatio) // * context.scheduleRatio  <- is that needed, since it's already included in the newTotalPaymentAllocations?
                            );

                            //only add the percent for non-default
                            if (gau != UTIL_CustomSettingsFacade.getAllocationsSettings().Default__c) {
                                newAllocation.Percent__c = newAllocation.Amount__c / payment.npe01__Payment_Amount__c * 100;
                            }

                            // Update the total with the newly added allocation amount
                            addAllocationAmountToPayment(payment.Id, newAllocation.Amount__c);

                            // Assumption: Payment Allocations should be maintained with Currency Type from Payment Record
                            if (UserInfo.isMultiCurrencyOrganization()) {
                                newAllocation.put('CurrencyIsoCode', payment.get('CurrencyIsoCode'));
                            }

                            allocationsChanges.objectsToInsert.add(newAllocation);
                        }
                    }
                }
            //no payment allocations for this GAU; create them
            } else if (context.totalUnpaidPayments > 0) {
                for (npe01__OppPayment__c payment : context.payments.values()) {
                    if (!payment.npe01__Paid__c && payment.npe01__Payment_Amount__c != 0) { // Only process unpaid payments...
                        Decimal paymentRatio = context.totalUnpaidPayments / payment.npe01__Payment_Amount__c;
                        Decimal paymentScale = computePaymentScale(context.totalPaidUnpaidPayments, context.opportunity.Amount);
                        
                        Allocation__c newAllocation = new Allocation__c(
                            Payment__c = payment.Id,
                            General_Accounting_Unit__c = gau,
                            Amount__c = (newTotalPaymentAllocations) / (paymentRatio) // * context.scheduleRatio  <- is that needed, since it's already included in the newTotalPaymentAllocations?
                        );

                        //only add the percent for non-default
                        if (gau != UTIL_CustomSettingsFacade.getAllocationsSettings().Default__c) {
                            newAllocation.Percent__c = newAllocation.Amount__c / payment.npe01__Payment_Amount__c * 100;
                        }

                        // Update the total with the newly added allocation amount
                        addAllocationAmountToPayment(payment.Id, newAllocation.Amount__c);

                        // Assumption: Payment Allocations should be maintained with Currency Type from Payment Record
                        if (UserInfo.isMultiCurrencyOrganization()) {
                            newAllocation.put('CurrencyIsoCode', payment.get('CurrencyIsoCode'));
                        }

                        allocationsChanges.objectsToInsert.add(newAllocation);
                    }
                }
            }
        }

        //handle payment allocations for deleted opportunity allocations
        for (Id gau : context.paymentAllocationsByGAU.keySet()) {
            if (!context.opportunityAllocationsByGAU.containsKey(gau) && gau != UTIL_CustomSettingsFacade.getAllocationsSettings().Default__c) {
                for (Allocation__c paymentAllocation : context.paymentAllocationsByGAU.get(gau)) {
                    npe01__OppPayment__c payment = context.payments.get(paymentAllocation.Payment__c);

                    //since we can't delete paid payment allocations
                    //add error to opportunity allocation if we have paid payment allocations for this GAU

                    if (payment.npe01__Paid__c &&
                        context.oldTriggerAllocationsByGAUIdForValidation.containsKey(gau)) {
                        // flag the allocation we are attempting to delete with an error;
                        // this record is not available in the opportunityAllocationsByGAU map
                        String gauName = context.oldTriggerAllocationsByGAUIdForValidation.get(gau).Name;
                        String gauId = context.oldTriggerAllocationsByGAUIdForValidation.get(gau).Id;
                        throw new PaymentSyncException(String.format(Label.alloRemoveOppWithPmt, new String[] {context.Opportunity.Name, context.Opportunity.Id, gauName, gauId}));
                    } else {
                        if (!payment.npe01__Paid__c) {
                            removeAllocationAmountFromPayment(payment.Id, paymentAllocation.Amount__c);
                            allocationsChanges.objectsToDelete.add(paymentAllocation);
                        }
                    }
                }
            }
        }
        recalcDefaultAllocsForOppToPmt(context);
    }

    /*******************************************************************************************************
    * @description Iterates over the payments associated with a context, updating/adding/removing the
    * Default GAU as necessary
    * @param SynchronizationContext context - The context of the current Opportunity, Allocations and Payments to work with
    ********************************************************************************************************/
    private void recalcDefaultAllocsForOppToPmt (SynchronizationContext context) {

        Id defaultGAU = UTIL_CustomSettingsFacade.getAllocationsSettings().Default__c;

        for (npe01__OppPayment__c payment : context.payments.values()) {
            Decimal allocAmt = (allocatedAmountByPayment.containsKey(payment.Id)) ? allocatedAmountByPayment.get(payment.Id) : 0;
            Decimal paymentAmt = (payment.npe01__Payment_Amount__c != null) ? payment.npe01__Payment_Amount__c : 0;
            Decimal remainder = paymentAmt - allocAmt;
            List<Allocation__c> defaultAllocs = defaultAllocsByPayment.get(payment.Id);
            Allocation__c defaultAlloc = null;

            if ((defaultAllocs != null) && (defaultAllocs.size() > 0)) {
                defaultAlloc = defaultAllocs.get(0);
                for (Integer i = 1; i < defaultAllocs.size(); i++) { // Remove any duplicates
                    allocationsChanges.objectsToDelete.add(defaultAllocs.get(i));
                }
            }

            if ((paymentAmt > 0 && remainder > 0) || (paymentAmt < 0 && remainder < 0)) { // Default Allocation is needed with this amount
                if (defaultAlloc == null) {
                    defaultAlloc = makeAmountBasedAllocation(payment, defaultGAU, remainder);
                    allocationsChanges.objectsToInsert.add(defaultAlloc);
                } else if (defaultAlloc.Amount__c != remainder || (UserInfo.isMultiCurrencyOrganization() && defaultAlloc.get('CurrencyIsoCode') != payment.get('CurrencyIsoCode'))) {
                    defaultAlloc.Amount__c = remainder;
                    if (UserInfo.isMultiCurrencyOrganization()) {
                        defaultAlloc.put('CurrencyIsoCode', payment.get('CurrencyIsoCode'));
                    }
                    allocationsChanges.objectsToUpdate.add(defaultAlloc);
                }
            } else if (remainder == 0) { // Default Allocation should be removed
                if (defaultAlloc != null)
                    allocationsChanges.objectsToDelete.add(defaultAlloc);
            } else { // Payment is overallocated...should never occur...generate an error.
                throw new PaymentSyncException(String.format(Label.alloPaymentOverAllocatedError, new String[] {context.Opportunity.Name, context.Opportunity.Id}));
            }
        }
    }

    /*******************************************************************************************************
    * @description Determines if a scale is necessary for the allocations, and if so what it is.
    * If Opportunity Amount is null/0, the total payment Amount is null/0 or the paymentAmount is < than the Opportunity Amount a scale is
    * considered unnecessary, and a scale of 1 (meaning no scale is returned).  Otherwise, it will return the
    * a percentage to upscale the allocations by, dividing the unsigned value of the total payment amount by the
    * unsigned value of the opportunity amount
    * @param Decimal totalPaymentAmount Decimal Amount of the Payment Total (paid and unpaid)
    * @param Decimal opportunityAmount Decimal Amount of the Opportunity
    * @return Decimal ratio to upscale the allocation by, or 1
    ********************************************************************************************************/
    @testVisible private static Decimal computePaymentScale(Decimal totalPaymentAmount, Decimal opportunityAmount) {
        if (opportunityAmount == null || opportunityAmount == 0 || totalPaymentAmount == 0 || totalPaymentAmount == null) {
            return 1;
        }

        Decimal unsignedOpportunityAmount = Math.abs(opportunityAmount);
        Decimal unsignedTotalPaymentAmount = Math.abs(totalPaymentAmount);

        if (unsignedTotalPaymentAmount <= unsignedOpportunityAmount) {
            return 1;
        }
        return unsignedTotalPaymentAmount / unsignedOpportunityAmount;
    }

    /*******************************************************************************************************
    * @description Creates an amount based allocation for the specified Opportunity/Payment using the specified gau
    * @param SObject parentSObj An Opportunity or Payment.
    * @param Id gau The Id of the GAU to use when creating the allocation
    * @return Allocation__c An allocation for the amount of the Opportunity/Payment.
    ********************************************************************************************************/
    public static Allocation__c makeAmountBasedAllocation(SObject parentSObj, Id gau, Decimal amount) {

        Allocation__c defaultAllo = new Allocation__c(
            General_Accounting_Unit__c = gau
        );

        if (parentSObj instanceof npe01__OppPayment__c) {
            defaultAllo.Payment__c = parentSObj.Id;
        }

        if (parentSObj instanceof Opportunity) {
            defaultAllo.Opportunity__c = parentSObj.Id;
        }

        defaultAllo.Amount__c = (Decimal) amount;

        if (UserInfo.isMultiCurrencyOrganization()) {
            defaultAllo.put('CurrencyIsoCode', parentSObj.get('CurrencyIsoCode'));
        }
        return defaultAllo;
    }
}