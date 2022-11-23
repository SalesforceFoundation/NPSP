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
* @date 2014
* @group Allocations
* @group-content ../../ApexDocContent/Allocations.htm
* @description Trigger handler on Allocation object, forces allocations for a single parent to not exceed the parent amount,
*              and calculates amount for percentage based allocations.
*/
public class ALLO_Allocations_TDTM extends TDTM_Runnable {

    /** @description A map of allocation parent id to alloWrapper class; holds all relevant allocations data for this transaction. */
    public Map<Id,alloWrapper> mapWrapper = new Map<Id,alloWrapper>();
    /** @description Allocations settings. */
    public DmlWrapper dmlWrapper = new dmlWrapper();

    /** @description Contains Record Ids for Any Opportunities whose Allocations were recreated as a result of a Recurring Donation Allocation change */
    public Set<Id> updatedRecurringDonationOppIds {
       public get {
            if (updatedRecurringDonationOppIds == null) {
                updatedRecurringDonationOppIds = new Set<Id>();
            }
            return updatedRecurringDonationOppIds;
        }
        private set;
    }

    /** @description Allocations settings. */
    public static Allocations_Settings__c settings = UTIL_CustomSettingsFacade.getAllocationsSettings();

    /** @description  Retrieve and cache the household settings the first time this class is loaded only */
    public static final npo02__Households_Settings__c householdSettings = UTIL_CustomSettingsFacade.getHouseholdsSettings();

    /** @description The id of the default General Accounting Unit if default allocations are enabled */
    public static id idDefaultGAU {
        get {
            return settings.Default__c;
        }
        set;
    }

    /*******************************************************************************************************
    * @description wrapper class to hold all allocation and opportunity information for a single parent:
    * Opportunity, Campaign, or Recurring Donation.
    */
    private class alloWrapper {
        boolean isPercentOnly = true;                                        //tracks whether all allocations are percentage based
        Decimal parentAmount = null;                                         //amount of this allocation's parent
        Decimal totalAmount = 0;                                             //holds total allocation amount
        Decimal totalPercent = 0;                                            //holds total percentage allocations
        List<Allocation__c> triggerList = new List<Allocation__c>();         //all allocations for this opportunity in the current trigger set
        List<Allocation__c> listAllo = new List<Allocation__c>();            //all non-default allocations for this parent object
        Map<Id, Allocation__c> defaultDupesById = new Map<Id, Allocation__c>();//duplicate default allocations, if any
        Allocation__c defaultAllo = null;                                    //the default allocation for this parent object
        boolean defaultInTrigger = false;                                    //is the default allocation in the current trigger set?
    }

    /*******************************************************************************************************
    * @description Trigger Handler on Opportunity and Allocation, dispatches to the correct method based on
    * object type.
    * @param listNew the list of contacts, accounts, or affiliations from trigger new.
    * @param listOld the list of contacts, accounts, or affiliations from trigger old.
    * @param triggerAction Which action triggered the current context. (Before or After; Insert, Update,
    * Delete, or Undelete.)
    * @param objResult The field describe object for the current trigger context.
    * @return dmlWrapper Objects that need to be inserted or updated after the processing of the trigger.
    ********************************************************************************************************/
    public override DmlWrapper run(List<SObject> newlist, List<SObject> oldlist,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        //if default allocations are enabled, verify that we have an ID value for the default fund
        if (settings.Default_Allocations_Enabled__c && settings.Default__c == null) {
            SObject obj = newList.isEmpty() ? oldList[0] : newList[0];
            obj.addError(Label.alloDefaultGAUMissing);
        }

        // dispatch to the correct handler
        if (objResult.getSObjectType() == Allocation__c.sObjectType && !TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ALLOC) &&
            (triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate)) {

            runAllocationBeforeTriggerHandler(newlist, oldlist, triggerAction, objResult);
        } else if (objResult.getSObjectType() == Allocation__c.sObjectType && !TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ALLOC) &&
            (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate || triggerAction == TDTM_Runnable.Action.AfterDelete)) {

            runAllocationAfterTriggerHandler(newlist, oldlist, triggerAction, objResult);
            //setting before to true for afterDelete case, to avoid running triggers on DML wrapper objects
        } else if (objResult.getSObjectType() == Opportunity.sObjectType && !TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ALLOC)) {

            runOpportunityTriggerHandler(newlist, oldlist, triggerAction, objResult);
        } else if (objResult.getSObjectType() == npe01__OppPayment__c.sObjectType && !TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.ALLOC)) {
            runPaymentTriggerHandler(newlist, oldlist, triggerAction, objResult);
        }

        // Increment the recursion flag, process the DML, and then decrement the recursion flag
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, true);
        TDTM_TriggerHandler.processDML(dmlWrapper);
        dmlWrapper = null;

        // Post processing of payment allocations is required if Payment Allocations is enabled and Recurring Donation Allocations were updated
        recreateScheduledPaymentAllocationsIfNecessary();

        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.ALLOC, false);

        return null;
    }

    /*******************************************************************************************************
    * @description Allocations trigger handler on Opportunity. Creates allocations as needed, by copying
    * from Campaign or Recurring Donation, and creating a default if enabled. Also updates existing
    * allocations if the opportunity amount or currency is changed.
    * @param listNew The list of opportunities from trigger new.
    * @param listOld The list of opportunities from trigger old.
    * @param triggerAction Which action triggered the current context. (Before or After; Insert, Update,
    * Delete, or Undelete.)
    * @param objResult The field describe object for Opportunity.
    * @return dmlWrapper Objects that need to be inserted or updated after the processing of the trigger.
    ********************************************************************************************************/
    private void runOpportunityTriggerHandler(List<SObject> newlist, List<SObject> oldlist,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        Set<Id> oppRecordTypesToExclude = new Set<Id>();
        Set<String> oppTypesToExclude = new Set<String>();
        if (settings.Excluded_Opp_RecTypes__c!=null)
            oppRecordTypesToExclude = new Set<Id>((List<Id>)settings.Excluded_Opp_RecTypes__c.split(';'));
        if (settings.Excluded_Opp_Types__c!=null)
            oppTypesToExclude = new Set<String>(settings.Excluded_Opp_Types__c.split(';'));

        List<Opportunity> listOppsForProcessing = new List<Opportunity>();
        List<Opportunity> oppsWithNullOldAmount = new List<Opportunity>();

        for (integer i=0; i<newList.size(); i++) {
            Opportunity opp = (Opportunity) newlist[i];

            //skip excluded opp types and recordtypes
            if (oppRecordTypesToExclude.contains((Id)opp.get('RecordTypeId')) || oppTypesToExclude.contains(opp.Type))
                continue;

            //INSERT case: Verify associated Campaign and Recurring Donations to auto create allocations
            if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
                //don't do anything on insert if we don't have an amount
                if (opp.Amount == null) {
                    continue;
                //if this new opportunity has a Campaign or RD, add to list for processing
                } else if (opp.CampaignId != null || opp.npe03__Recurring_Donation__c != null)
                    listOppsForProcessing.add(opp);
                //create a default allocation for the total amount, only if there's no possibility of other allocations from related objects
                else if (settings.Default_Allocations_Enabled__c) {
                    dmlWrapper.objectsToInsert.add(makeDefaultAllocation(opp));
                }
            }

            //UPDATE case: if the opportunity amount changed, or the opp went to a closed/won stage: add to the list for processing
            if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                Decimal oldAmount = (Decimal) oldlist[i].get('Amount');

                if (oldAmount == null && opp.Amount != null) {
                    oppsWithNullOldAmount.add(opp);

                } else if (opp.Amount != oldAmount) {
                    listOppsForProcessing.add(opp);
                }

                //if currency has changed, reset allocation currencies
                if (UserInfo.isMultiCurrencyOrganization()) {
                    if (opp.get('CurrencyIsoCode') != oldlist[i].get('CurrencyIsoCode')) {
                        listOppsForProcessing.add(opp);
                    }
                }
            }
        }

        if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            fillMapWrapper(listOppsForProcessing);

            copyRecurringDonationCampaignAndPaymentAllocations(listOppsForProcessing);

        } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            List<Opportunity> opps = new List<Opportunity>(listOppsForProcessing);
            opps.addAll(oppsWithNullOldAmount);
            fillMapWrapper(opps);

            copyRecurringDonationCampaignAndPaymentAllocations(oppsWithNullOldAmount);
            opportunityAmountCurrencyChange(listOppsForProcessing);
        }
    }

    /*******************************************************************************************************
    * @description Allocations trigger handler on Payment. Creates allocations as needed, by copying
    * from Opportunity, Campaign or Recurring Donation, and creating a default if enabled. Also updates existing
    * allocations if the payment amount or currency is changed.
    * @param listNew The list of payments from trigger new.
    * @param listOld The list of payments from trigger old.
    * @param triggerAction Which action triggered the current context. (Before or After; Insert, Update,
    * Delete, or Undelete.)
    * @param objResult The field describe object for Payment.
    * @return dmlWrapper Objects that need to be inserted or updated after the processing of the trigger.
    ********************************************************************************************************/
    private void runPaymentTriggerHandler(List<SObject> newlist, List<SObject> oldlist,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {


        //do not run if Payment allocations are disabled
        if (isPaymentAllocationsEnabled()) {
            processPaymentAllocations(newlist, oldlist, triggerAction);
        }
    
        if (triggerAction == TDTM_Runnable.Action.AfterInsert || triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            handleAllocationsAndOpportunities(newList, oldList);
        }
    }

    private void processPaymentAllocations(List<SObject> newlist, List<SObject> oldlist, TDTM_Runnable.Action triggerAction) {
        List<npe01__OppPayment__c> listPmtsForProcessing = new List<npe01__OppPayment__c>();
        List<npe01__OppPayment__c> pmtsWithNullOldAmount = new List<npe01__OppPayment__c>();
        List<npe01__OppPayment__c> pmtsNeedingAllocations = new List<npe01__OppPayment__c>();


        for (integer i=0; i<newList.size(); i++) {
            npe01__OppPayment__c pmt = (npe01__OppPayment__c) newlist[i];

            //INSERT case
            if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
                //Don't do anything on insert if we don't have an amount
                if ((pmt.npe01__Payment_Amount__c != null)) {
                    pmtsNeedingAllocations.add(pmt);
                }
            }

            //UPDATE case: if the payment amount changed, add to the list for processing
            if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
                Decimal oldAmount = (Decimal) oldlist[i].get('npe01__Payment_Amount__c');
                Decimal newAmount = pmt.npe01__Payment_Amount__c;

                if ((oldAmount == null) && (newAmount != null)) { // Need to redo the Allocations for this payment as if it were a new payment
                    pmtsNeedingAllocations.add(pmt);
                } else {
                    if (pmt.npe01__Payment_Amount__c != oldAmount) {
                        listPmtsForProcessing.add(pmt);
                    }

                    //if currency has changed, reset allocation currencies
                    if (UserInfo.isMultiCurrencyOrganization()) {
                        if (pmt.get('CurrencyIsoCode') != oldlist[i].get('CurrencyIsoCode')) {
                            listPmtsForProcessing.add(pmt);
                        }
                    }
                }

            }
        }

        if (pmtsNeedingAllocations.size() > 0) {
            fillMapWrapper(pmtsNeedingAllocations);
            copyRecurringDonationCampaignAndPaymentAllocations(pmtsNeedingAllocations);
        }

        if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            List<npe01__OppPayment__c> pmts = new List<npe01__OppPayment__c>(listPmtsForProcessing);
            pmts.addAll(pmtsWithNullOldAmount);
            fillMapWrapper(pmts);

            paymentAmountCurrencyChange(pmts);
            //paymentAmountCurrencyChange(listPmtsForProcessing);
        }
    }

    private void handleAllocationsAndOpportunities(
        List<npe01__OppPayment__c> newList,
        List<npe01__OppPayment__c> oldList
    ) {
        List<npe01__OppPayment__c> refunds = new List<npe01__OppPayment__c>();
        List<npe01__OppPayment__c> oldRefunds = new List<npe01__OppPayment__c>();
        for (Integer i = 0; i < newList.size(); i++) {
            if (newList[i].npe01__Payment_Amount__c < 0 && String.isBlank(newList[i].Elevate_Payment_ID__c)) {
                refunds.add(newList[i]);
                if ( oldList != null) {
                    oldRefunds.add(oldList[i]);
                }
            }
        }

        if (refunds.isEmpty()) {
            return;
        }

        PMT_RefundService refundService = new PMT_RefundService()
            .withRefundRecords(refunds)
            .withOldRefundRecords(oldRefunds);

        refundService.adjustAllocationsAndOpportunities()
            .updateAllocationsAndOpportunities();

        List<ErrorRecord> errorRecords = refundService.getErrors();

        for (ErrorRecord error : errorRecords) {
            if (error.hasError()) {
                error.getRecord().addError(error.getFirstError());
            }
        }
    }

    /*******************************************************************************************************
    * @description Allocations before trigger handler on GAU Allocation. Validates allocation data per
    * object and per parent object to avoid badly created allocations, exceeding opportunity amount,
    * exceeding 100%, negative amounts or percents, etc.
    * In multicurrency orgs, also verifies currency matches the parent object's currency.
    * @param listNew The list of allocations from trigger new.
    * @param listOld The list of allocations from trigger old.
    * @param triggerAction Which action triggered the current context. (Before or After; Insert, Update,
    * Delete, or Undelete.)
    * @param objResult The field describe object for GAU Allocation.
    * @return dmlWrapper Objects that need to be inserted or updated after the processing of the trigger.
    ********************************************************************************************************/
    private void runAllocationBeforeTriggerHandler(List<SObject> newlist, List<SObject> oldlist,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        List<Allocation__c> triggerList = (List<Allocation__c>) newList;
        Boolean parentErrorDetected = false;

        for (integer i=0; i<triggerList.size(); i++) {
            Allocation__c allo = triggerlist[i];

            //throw error if allocating at the payment level but default allocation is not enabled
            if (!settings.Default_Allocations_Enabled__c && allo.Payment__c != null) {
                allo.addError(Label.alloDefaultNotEnabled);
                parentErrorDetected = true;
            }

            //throw error if payment allocations are disabled and Payment__c is not null
            if (!isPaymentAllocationsEnabled() && allo.Payment__c != null) {
                allo.addError(Label.alloPaymentNotEnabled);
                parentErrorDetected = true;
            }

            //if we don't have a parent, or have more than one parent, exception thrown
            if (parentError(allo)) {
                allo.AddError(Label.alloSingleParent);
                parentErrorDetected = true;
            }
            //neither an amount nor a percent is defined
            if (allo.Amount__c == null && allo.Percent__c == null) {
                allo.addError(Label.alloAmountOrPercent);
            }
            //negative amount (Payments excepted)
            if (allo.Amount__c != null && allo.Amount__c < 0 && allo.Payment__c == null) {
                allo.addError(Label.alloNegativeAmount);
            }
            //negative percent
            if (allo.Percent__c != null && allo.Percent__c < 0) {
                allo.addError(Label.alloNegativePercent);
            }
            //manually updated currency
            if (triggerAction == TDTM_Runnable.Action.BeforeUpdate &&
                    UserInfo.isMultiCurrencyOrganization() &&
                    allo.get('CurrencyIsoCode') != oldList[i].get('CurrencyIsoCode')) {
                allo.addError(Label.alloModifyCurrency);
            }

        }

        if (parentErrorDetected) {
            return;
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
            if (wrap.parentAmount==null) {
                continue;
            }

            //Verify that allocation and Payment amount sign match
            if ((allo.Amount__c >= 0 && wrap.parentAmount < 0)
                ||(allo.Amount__c < 0 && wrap.parentAmount >= 0)){
                allo.addError(Label.alloSignMistmatch);
            }

            //verify the total allocations don't exceed the parent amount
            if ((wrap.totalAmount >= 0 && wrap.totalAmount > wrap.parentAmount)
                ||(wrap.totalAmount < 0 && wrap.totalAmount < wrap.parentAmount)) {
                allo.addError(Label.alloTotalExceedsOppAmt);
            }

        }

        //if this org is multicurrency and this is an insert or update, set currency ISO code based on parent ISO code
        if ((triggerAction == TDTM_Runnable.Action.BeforeInsert || triggerAction == TDTM_Runnable.Action.BeforeUpdate)
                && ALLO_Multicurrency_TDTM.isMultiCurrency()) {
            ALLO_Multicurrency_TDTM.updateAllocationCurrency(triggerList);
        }
        //TODO: don't let users change allocation currency manually
    }

    /*******************************************************************************************************
    * @description Allocations after trigger handler on GAU Allocation. When a recurring donation allocation
    * is modified, creates or modifies all allocations for open opportunities under that recurring
    * donations' schedule to match the recurring donation's allocations.
    * @param listNew The list of allocations from trigger new.
    * @param listOld The list of allocations from trigger old.
    * @param triggerAction Which action triggered the current context. (Before or After; Insert, Update,
    * Delete, or Undelete.)
    * @param objResult The field describe object for GAU Allocation.
    * @return dmlWrapper Objects that need to be inserted or updated after the processing of the trigger.
    ********************************************************************************************************/
    private void runAllocationAfterTriggerHandler(List<SObject> newlist, List<SObject> oldlist,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {

        List<Opportunity> listOpps = new List<Opportunity>();
        List<npe01__OppPayment__c> listPmts = new List<npe01__OppPayment__c>();
        Set<Id> setRecDonId = new Set<Id>();
        Set<Id> setOppIds = new Set<Id>();
        Set<Id> setPmtIds = new Set<Id>();

        for (Allocation__c allo : triggerAction == TDTM_Runnable.Action.AfterDelete ? (List<Allocation__c>) oldList : (List<Allocation__c>) newList) {
            //if this allocation is for a recurring donation, save the Id for updating open opportunities under that RD schedule
            if (allo.Recurring_Donation__c != null)
                setRecDonId.add(allo.Recurring_Donation__c);
            //if this is an opportunity allocation and defaults are enabled, adjust/create/delete the default
            if (settings.Default_Allocations_Enabled__c && allo.Opportunity__c!=null)
                setOppIds.add(allo.Opportunity__c);
            //if this is a Payment allocation and defaults are enabled, adjust/create/delete the default
            if (settings.Default_Allocations_Enabled__c && allo.Payment__c!=null)
                setPmtIds.add(allo.Payment__c);
        }

        if (!setRecDonId.isEmpty() || !setOppIds.isEmpty()) {
            String oppQuery = 'SELECT Id, Amount, npe03__Recurring_Donation__c, CampaignId';
            if (UserInfo.isMultiCurrencyOrganization()) {
                oppQuery += ', CurrencyIsoCode';
            }
            oppQuery+=' FROM Opportunity WHERE (Opportunity.isClosed = FALSE AND npe03__Recurring_Donation__c IN :setRecDonId) OR Id IN :setOppIds';
            listOpps = database.query(oppQuery);
        }

        if (!setPmtIds.isEmpty()) {
            String pmtQuery = 'SELECT Id, npe01__Payment_Amount__c, npe01__Paid__c, npe01__Written_Off__c, npe01__Opportunity__c';
            if (UserInfo.isMultiCurrencyOrganization()) {
                pmtQuery += ', CurrencyIsoCode';
            }
            pmtQuery+=' FROM npe01__OppPayment__c WHERE Id IN :setPmtIds';
            listPmts = database.query(pmtQuery);
        }

        if (!listPmts.isEmpty()) {

            fillMapWrapper(listPmts);

            //if we have any Payment allocations and default handling is enabled, adjust the payments' default allocation
            if (!setPmtIds.isEmpty()) {
                for (npe01__OppPayment__c pmt : listPmts) {

                    //we have allocations for this payment
                    if (setPmtIds.contains(pmt.Id)) {
                        //this pmt has allocations, check for default cases
                        if (mapWrapper.containsKey(pmt.Id)) {
                            alloWrapper pmtWrap = mapWrapper.get(pmt.Id);
                            //adjust default allocation, and add to DML wrapper if needed
                            Decimal amountDifferential = pmt.npe01__Payment_Amount__c - pmtWrap.totalAmount;

                            //no remainder: delete default allocation
                            if (amountDifferential == 0 && pmtWrap.defaultAllo != null) {
                                    dmlWrapper.objectsToDelete.add(pmtWrap.defaultAllo);
                            } else if ((pmt.npe01__Payment_Amount__c >= 0 && amountDifferential > 0)
                                    ||(pmt.npe01__Payment_Amount__c < 0 && amountDifferential < 0)) {
                                //create a default allocation if we don't have one
                                if (pmtWrap.defaultAllo == null) {
                                    pmtWrap.defaultAllo = makeDefaultAllocation(pmt);
                                    pmtWrap.defaultAllo.Amount__c = amountDifferential;
                                    dmlWrapper.objectsToInsert.add(pmtWrap.defaultAllo);
                                } else if (pmtWrap.defaultAllo.Amount__c != amountDifferential) {
                                        pmtWrap.defaultAllo.Amount__c = amountDifferential;
                                        dmlWrapper.objectsToUpdate.add(pmtWrap.defaultAllo);
                                }
                            }
                            //delete duplicate default GAU allocations
                            if (!pmtWrap.defaultDupesById.isEmpty()) {
                                dmlWrapper.objectsToDelete.addAll((List<SObject>)pmtWrap.defaultDupesById.values());
                            }
                        //this pmt has no allocations, just create the default
                        } else dmlWrapper.objectsToInsert.add(makeDefaultAllocation(pmt));
                    }
                }
            }
        }

        if (!listOpps.isEmpty()) {

            fillMapWrapper(listOpps);

            //if we have any opportunity allocations and default handling is enabled, adjust the opps' default allocation
            List<Opportunity> listRecDonOpps = new List<Opportunity>();
            if (!setOppIds.isEmpty()) {
                for (Opportunity opp : listOpps) {
                    //we have allocations for this opportunity
                    if (setOppIds.contains(opp.Id)) {
                        //this opp has allocations, check for default cases
                        if (mapWrapper.containsKey(opp.Id)) {
                            alloWrapper oppWrap = mapWrapper.get(opp.Id);
                            //adjust default allocation, and add to DML wrapper if needed
                            Decimal amountDifferential = opp.Amount - oppWrap.totalAmount;

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
                            //delete duplicate default GAU allocations
                            if (!oppWrap.defaultDupesById.isEmpty()) {
                                dmlWrapper.objectsToDelete.addAll((List<SObject>)oppWrap.defaultDupesById.values());
                            }
                        //this opp has no allocations, just create the default
                        } else dmlWrapper.objectsToInsert.add(makeDefaultAllocation(opp));
                    //if this was a recurring donation allocation, add to list for processing
                    } else listRecDonOpps.add(opp);
                }
            //no opportunity default cases, just copy the list over
            } else {
                listRecDonOpps = listOpps;
            }
            //after insert/update/delete of Recurring Donation allocations: delete and recreate all open opportunities' allocations
            if (!listRecDonOpps.isEmpty()) {

                //first, delete all existing opp allocations
                for (Opportunity opp : listRecDonOpps) {
                    if (isPaymentAllocationsEnabled()) { // Record for further processing if Payment Allocations is enabled
                        updatedRecurringDonationOppIds.add(opp.Id);
                    }
                    if (mapWrapper.containsKey(opp.Id)){
                        alloWrapper oppWrap = mapWrapper.get(opp.Id);
                        dmlWrapper.objectsToDelete.addAll((List<SObject>)oppWrap.listAllo);
                        if (settings.Default_Allocations_Enabled__c && oppWrap.defaultAllo != null) {
                            dmlWrapper.objectsToDelete.add(oppWrap.defaultAllo);
                        }
                    }
                }

                //then, recreate them based on the recurring donation
                copyRecurringDonationCampaignAndPaymentAllocations(listRecDonOpps);
            }
        }
    }

    /*******************************************************************************************************
    * @description Determines whether it is necessary to copy allocations from campaign, recurring donation
    * or opportunity and calls method to do so if required.
    * @param listSObjs A list of Opportunities or Payments.
    * @return void
    ********************************************************************************************************/
    private void copyRecurringDonationCampaignAndPaymentAllocations(List<SObject> listSObjs) {

        for (SObject sObj : listSObjs) {
            Boolean isPaymentRecord = sObj instanceof npe01__OppPayment__c;

            if (isPaymentRecord && mapWrapper.containsKey((Id)sObj.get('npe01__Opportunity__c'))) {
                copyRecurringDonationCampaignAndPaymentAllocations(sObj);

            } else if (!isPaymentRecord && sObj.get('npe03__Recurring_Donation__c') != null && mapWrapper.containsKey((Id)sObj.get('npe03__Recurring_Donation__c'))) {
                copyRecurringDonationCampaignAndPaymentAllocations(sObj);

            } else if (!isPaymentRecord && sObj.get('CampaignId') != null && mapWrapper.containsKey((Id)sObj.get('CampaignId'))) {
                copyRecurringDonationCampaignAndPaymentAllocations(sObj);

            } else if (settings.Default_Allocations_Enabled__c) {
                dmlWrapper.objectsToInsert.add(makeDefaultAllocation(sObj));
            }
        }
    }

    /*******************************************************************************************************
    * @description Creates allocations by copying from campaign or recurring donation allocations to Opps,
    * or from Opportunitys to Payments. Adjusts default allocation if enabled.
    * @param sObj Opportunity or Payment.
    * @return void This method modifies class variables and doesn't return anything.
    ********************************************************************************************************/
    private void copyRecurringDonationCampaignAndPaymentAllocations(SObject sObj) {
        alloWrapper wrap;
        Map<Id, Allocation__c> GAUtoAlloMapping = new Map<Id, Allocation__c>();
        Boolean isPaymentAllocation = false;

        //get wrapper for parent Payment.
        if (sObj instanceof npe01__OppPayment__c) {
            wrap = mapWrapper.get((Id)sObj.get('npe01__Opportunity__c'));
            isPaymentAllocation = true;
        }

        //get wrapper for parent object, preferring recurring donation over campaign allocations if they exist
        else if (sObj.get('npe03__Recurring_Donation__c') != null && mapWrapper.containsKey((Id)sObj.get('npe03__Recurring_Donation__c'))) {
            wrap = mapWrapper.get((Id) sObj.get('npe03__Recurring_Donation__c'));
        }

        else {
            wrap = mapWrapper.get((Id) sObj.get('CampaignId'));
        }

        List<Allocation__c> listAlloForInsert = new List<Allocation__c>();

        //add only allocations to active GAUs
        for (Allocation__c allo : wrap.listAllo.deepclone()) {

            // If it's a payment, don't filter out the active allocations.
            if (sObj instanceof npe01__OppPayment__c) {
                listAlloForInsert.add(allo);

            } else {
                if (allo.General_Accounting_Unit__r.Active__c) {
                    listAlloForInsert.add(allo);
                }
            }
        }

        Decimal amount = (Decimal)(sObj instanceof Opportunity ? sObj.get('Amount') : sObj.get('npe01__Payment_Amount__c'));
        Decimal remainder = amount;

        //reparent the cloned allocation to the opportunity
        for (Allocation__c allo : listAlloForInsert) {
            Allocation__c alloInMap;
            Boolean isPercentOnly = allo.Percent__c !=null && allo.Amount__c == null;

            if (isPaymentAllocation == true && GAUtoAlloMapping.containsKey(allo.General_Accounting_Unit__c)) {
                alloInMap = GAUtoAlloMapping.get(allo.General_Accounting_Unit__c);
            }

            allo.Opportunity__c = null;
            allo.Recurring_Donation__c = null;
            allo.Campaign__c = null;
            if (sObj instanceof Opportunity) {
                allo.Opportunity__c = sObj.Id;

            } else {
                allo.Payment__c = sObj.Id;
            }

            if (allo.Percent__c != null) {
                allo.Amount__c = (amount * allo.Percent__c * .01).setScale(2);
            }

            //Calculate proportional amount for non-percentage based Payment allocations
            if (sObj instanceof npe01__OppPayment__c && allo.Percent__c == null) {
                // Determine Percentage
                Decimal alloPercent = allo.Amount__c / wrap.parentAmount * 100;
                allo.Amount__c = (amount * alloPercent * .01).setScale(2);
                
                // Store Percentage as is, so precision is not lost in future calculations
                allo.Percent__c = alloPercent;
            }

            //if this is a multicurrency org, recalculate the amount and set the CurrencyIsoCode
            if (UserInfo.isMultiCurrencyOrganization()) {
                if (allo.Amount__c != null && !isPercentOnly) {
                    allo.Amount__c = UTIL_CurrencyConversion.convertAmountUsingStandardRates(
                            (String)allo.get('CurrencyIsoCode'),
                            (String)sObj.get('CurrencyIsoCode'),
                            allo.Amount__c
                    );
                }
                allo.put('CurrencyIsoCode', sObj.get('CurrencyIsoCode'));
            }

            if (isPaymentAllocation == true && alloInMap != null) {
                alloInMap.Amount__c += allo.Amount__c;
                if (alloInMap.Percent__c != null && allo.Percent__c != null) {
                    // If both Payment Allocations have a percent set (which they should), maintain the total
                    alloInMap.Percent__c += allo.Percent__c;
                }
            }

            remainder -= allo.Amount__c;

            if (isPaymentAllocation == true) {
                if (alloInMap != null) {
                    GAUtoAlloMapping.put(alloInMap.General_Accounting_Unit__c, alloInMap);

                } else {
                    GAUtoAlloMapping.put(allo.General_Accounting_Unit__c, allo);
                }
            }
        }

        // Only update the list to insert to the consolidated list when it's a payment.
        if (isPaymentAllocation == true) {
            // Set the consolidated list as the list to insert
            listAlloForInsert = GAUtoAlloMapping.values();
        }

        //if our remainder is negative, only create percentage based allocations
        if ((amount >= 0 && remainder < 0)||(amount < 0 && remainder > 0)) {
            remainder = amount;

            //TODO: log error: not able to create allocations. chatter post?
            for (Allocation__c allo : listAlloForInsert) {
                if (allo.Percent__c!=null) {
                    dmlWrapper.objectsToInsert.add(allo);
                    remainder-=allo.Amount__c;
                }
            }

            if (settings.Default_Allocations_Enabled__c) {
                Allocation__c defaultAllo = makeDefaultAllocation(sObj);
                defaultAllo.Amount__c = remainder;
                dmlWrapper.objectsToInsert.add(defaultAllo);
            }

        //create default allocation if needed
        } else if (settings.Default_Allocations_Enabled__c && ((amount >= 0 && remainder > 0)||(amount < 0 && remainder < 0))) {
            Allocation__c defaultAllo = makeDefaultAllocation(sObj);
            defaultAllo.Amount__c = remainder;
            dmlWrapper.objectsToInsert.add(defaultAllo);
            dmlWrapper.objectsToInsert.addAll((List<SObject>)listAlloForInsert);
        //add objects to DML wrapper in all other cases (no remainder, or positive remainder without default allocations enabled)
        } else {
            Boolean needsDefaultAllocation = isPaymentAllocation == true && listAlloForInsert.isEmpty() && amount == 0;
            if (needsDefaultAllocation) {
                Allocation__c defaultAllo = makeDefaultAllocation(sObj);
                defaultAllo.Amount__c = 0;
                listAlloForInsert.add(defaultAllo);
            }
            dmlWrapper.objectsToInsert.addAll((List<SObject>)listAlloForInsert);
        }
    }

    //opportunity amount has changed or currency has changed. retrieve this opps allocations, adjust amounts and currencies
    //adjust percentage based allocations, adjust default allocations if enabled,
    //enforce that total allocations don't exceed the opportunity amount
    /*******************************************************************************************************
    * @description Updates an opportunity's allocations when amount or currency changes.
    * @param listOpps A list of opportunities whose amount or currency has changed.
    * @return void This method modifies class variables and doesn't return anything.
    ********************************************************************************************************/
    private void opportunityAmountCurrencyChange(List<Opportunity> listOpps){

        for (Opportunity opp : listOpps) {

            if (mapWrapper.containsKey(opp.Id)) {
                alloWrapper oppWrap = mapWrapper.get(opp.Id);

                //null amount: delete all associated allocations
                if (opp.Amount == null) {
                    dmlWrapper.objectsToDelete.addAll((List<SObject>)oppWrap.listAllo);
                    if (settings.Default_Allocations_Enabled__c && oppWrap.defaultAllo!=null) {
                        dmlWrapper.objectsToDelete.add(oppWrap.defaultAllo);
                        dmlWrapper.objectsToDelete.addAll((List<SObject>)oppWrap.defaultDupesById.values());
                    }
                } else {

                    for (Allocation__c allo : oppWrap.listAllo) {
                        // if the Opportunity is for $0, we can safely update fixed Allocations to be $0
                        // This fixes a bug with Elevate refunds when non-default Allocations have fixed (not percent based) Amounts
                        if (oppWrap.parentAmount == 0 && allo.Percent__c == null) {
                            oppWrap.totalAmount -= allo.Amount__c;
                            allo.Amount__c = 0;

                            if (UserInfo.isMultiCurrencyOrganization()) {
                                allo.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
                            }
                            dmlWrapper.objectsToUpdate.add(allo);
                        //if the percentage changed, recalculate the amount
                        } else if (allo.Percent__c != null && allo.Percent__c > 0 && allo.Amount__c != (oppWrap.parentAmount * allo.Percent__c * .01).setScale(2)) {
                            //remove the previous amount, recalculate the amount, and add it back
                            oppWrap.totalAmount -= allo.Amount__c;
                            allo.Amount__c = (oppWrap.parentAmount * allo.Percent__c * .01).setScale(2);
                            oppWrap.totalAmount += allo.Amount__c;

                            if (UserInfo.isMultiCurrencyOrganization()) {
                                allo.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
                            }
                            dmlWrapper.objectsToUpdate.add(allo);
                        //if just the currency changed, recalculate the currency
                        } else if (UserInfo.isMultiCurrencyOrganization() && allo.get('CurrencyIsoCode') != opp.get('CurrencyIsoCode')) {
                            allo.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
                            dmlWrapper.objectsToUpdate.add(allo);
                        }
                    }
                    //if the Default allocation handling is enabled, create/update/delete the default allocation to cover 100% of the opportunity
                    if (settings.Default_Allocations_Enabled__c) {
                        Decimal remainder = oppWrap.parentAmount - oppWrap.totalAmount;
                        if (remainder==0) {
                            if (oppWrap.defaultAllo!=null)
                                dmlWrapper.objectsToDelete.add(oppWrap.defaultAllo);
                        } else if (remainder > 0) {
                            if (oppWrap.defaultAllo==null) {
                                oppWrap.defaultAllo = makeDefaultAllocation(opp);
                                oppWrap.defaultAllo.Amount__c = remainder;
                                dmlWrapper.objectsToInsert.add(oppWrap.defaultAllo);
                            } else if (oppWrap.defaultAllo.Amount__c != remainder || (UserInfo.isMultiCurrencyOrganization() && oppWrap.defaultAllo.get('CurrencyIsoCode') != opp.get('CurrencyIsoCode'))) {
                                oppWrap.defaultAllo.Amount__c = remainder;
                                if (UserInfo.isMultiCurrencyOrganization()) {
                                    oppWrap.defaultAllo.put('CurrencyIsoCode', opp.get('CurrencyIsoCode'));
                                }
                                dmlWrapper.objectsToUpdate.add(oppWrap.defaultAllo);
                            }
                        }
                        //delete duplicate default GAU allocations
                        if (!oppWrap.defaultDupesById.isEmpty()) {
                            dmlWrapper.objectsToDelete.addAll((List<SObject>)oppWrap.defaultDupesById.values());
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

    //Payment amount has changed or currency has changed. retrieve this payment's allocations, adjust amounts and currencies
    //adjust percentage based allocations, adjust default allocations if enabled,
    //enforce that total allocations don't exceed the payment amount
    /*******************************************************************************************************
    * @description Updates a payment's allocations when amount or currency changes.
    * @param listPmts A list of payments whose amount or currency has changed.
    * @return void This method modifies class variables and doesn't return anything.
    ********************************************************************************************************/
    private void paymentAmountCurrencyChange(List<npe01__OppPayment__c> listPmts){

        for (npe01__OppPayment__c pmt : listPmts) {

            if (mapWrapper.containsKey(pmt.Id)) {
                alloWrapper pmtWrap = mapWrapper.get(pmt.Id);
                Decimal amt = pmt.npe01__Payment_Amount__c;
                // null delete all associated allocations
                if (amt == null) {
                    addAllAssociatedAllocationsToDeleteCollection(pmtWrap);
                } else {
                    for (Allocation__c allo : pmtWrap.listAllo) {
                        //if the percentage changed, recalculate the amount
                        if (allo.Percent__c!=null && allo.Percent__c>0 && allo.Amount__c != (pmtWrap.parentAmount * allo.Percent__c * .01).setScale(2)) {
                            //remove the previous amount, recalculate the amount, and add it back
                            pmtWrap.totalAmount -= allo.Amount__c;
                            allo.Amount__c = (pmtWrap.parentAmount * allo.Percent__c * .01).setScale(2);
                            pmtWrap.totalAmount += allo.Amount__c;

                            if (UserInfo.isMultiCurrencyOrganization()) {
                                allo.put('CurrencyIsoCode', pmt.get('CurrencyIsoCode'));
                            }
                            dmlWrapper.objectsToUpdate.add(allo);

                        //make sure alloc and parent amount sign match (both positive or both negative)
                        } else if (allo.Percent__c == null && (allo.Amount__c >= 0 && pmtWrap.parentAmount < 0 || allo.Amount__c < 0 && pmtWrap.parentAmount >= 0)) {
                            pmtWrap.totalAmount -= allo.Amount__c;
                            allo.Amount__c =  -1 * allo.Amount__c; //Change allocation sign to natch parent
                            pmtWrap.totalAmount += allo.Amount__c;

                            if (UserInfo.isMultiCurrencyOrganization()) {
                                allo.put('CurrencyIsoCode', pmt.get('CurrencyIsoCode'));
                            }
                            dmlWrapper.objectsToUpdate.add(allo);

                        //if just the currency changed, recalculate the currency
                        } else if (UserInfo.isMultiCurrencyOrganization() && allo.get('CurrencyIsoCode') != pmt.get('CurrencyIsoCode')) {
                            allo.put('CurrencyIsoCode', pmt.get('CurrencyIsoCode'));
                            dmlWrapper.objectsToUpdate.add(allo);
                        }
                    }
                    //if the Default allocation handling is enabled, create/update/delete the default allocation to cover 100% of the opportunity
                    if (settings.Default_Allocations_Enabled__c) {
                        Decimal remainder = pmtWrap.parentAmount - pmtWrap.totalAmount;
                        if (remainder==0) {
                            if (pmtWrap.defaultAllo!=null)
                                dmlWrapper.objectsToDelete.add(pmtWrap.defaultAllo);
                        } else if ((pmtWrap.parentAmount >= 0 && remainder > 0)||(pmtWrap.parentAmount < 0 && remainder < 0)) {
                            if (pmtWrap.defaultAllo==null) {
                                pmtWrap.defaultAllo = makeDefaultAllocation(pmt);
                                pmtWrap.defaultAllo.Amount__c = remainder;
                                dmlWrapper.objectsToInsert.add(pmtWrap.defaultAllo);
                            } else if (pmtWrap.defaultAllo.Amount__c != remainder || (UserInfo.isMultiCurrencyOrganization() && pmtWrap.defaultAllo.get('CurrencyIsoCode') != pmt.get('CurrencyIsoCode'))) {
                                pmtWrap.defaultAllo.Amount__c = remainder;
                                if (UserInfo.isMultiCurrencyOrganization()) {
                                    pmtWrap.defaultAllo.put('CurrencyIsoCode', pmt.get('CurrencyIsoCode'));
                                }
                                dmlWrapper.objectsToUpdate.add(pmtWrap.defaultAllo);
                            }
                        }
                        //delete duplicate default GAU allocations
                        if (!pmtWrap.defaultDupesById.isEmpty()) {
                            dmlWrapper.objectsToDelete.addAll((List<SObject>)pmtWrap.defaultDupesById.values());
                        }
                    }

                    //if the payment amount has decreased, we run the risk of allocations exceeding the total payment amount
                    // We only check this when there are allocations other than the default.
                    // If it is the default, it can't exceed the total payment amount.
                    if ((!pmtWrap.listAllo.isEmpty()) && ((pmtWrap.totalAmount >= 0 && pmtWrap.totalAmount > pmtWrap.parentAmount)||(pmtWrap.totalAmount < 0 && pmtWrap.totalAmount < pmtWrap.parentAmount))) {
                        //using addError here because we want to block payment update, display the error inline, and block the DML of updating all the related allocations
                        pmt.npe01__Payment_Amount__c.addError(Label.alloExceedsPmtAmount);
                    }
                }
            //if we have no allocations for this payment, defaults are enabled, and the payment has an amount, make a default allocation
            } else if (settings.Default_Allocations_Enabled__c && pmt.npe01__Payment_Amount__c != null) {
                dmlWrapper.objectsToInsert.add(makeDefaultAllocation(pmt));
            }
        }
    }

    /**
     * @description Add all associated Allocations to the delete collection of the DMLWrapper
     * @param alloWrap Allocation Wrapper to delete associated allocations from
     */
    private void addAllAssociatedAllocationsToDeleteCollection(alloWrapper alloWrap) {
        dmlWrapper.objectsToDelete.addAll((List<SObject>)alloWrap.listAllo);
        if (settings.Default_Allocations_Enabled__c && alloWrap.defaultAllo != null) {
            dmlWrapper.objectsToDelete.add(alloWrap.defaultAllo);
            dmlWrapper.objectsToDelete.addAll((List<SObject>)alloWrap.defaultDupesById.values());
        }
    }

    /*******************************************************************************************************
    * @description Fills the mapWrapper variable based on a list of allocations from the trigger set.
    * Updates current trigger set amounts to match percentages.
    * @param listOpps A list of GAU Allocations.
    * @return void This method modifies class variables and doesn't return anything.
    ********************************************************************************************************/
    public void fillMapWrapper (List<Allocation__c> alloList) {

        Set<Id> setParentId = new Set<Id>();
        Set<Id> setExistingAlloId = new Set<Id>();

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
            if (allo.Id != null)
                setExistingAlloId.add(allo.Id);
            if (settings.Default_Allocations_Enabled__c && allo.General_Accounting_Unit__c == idDefaultGAU) {
                if (allo.Percent__c != null && (allo.Opportunity__c != null || allo.Payment__c != null))
                    allo.addError(Label.alloDefaultNotPercent);
                if (wrap.defaultAllo == null)
                    wrap.defaultAllo = allo;
                else if (wrap.defaultAllo.Id != allo.Id) {
                    wrap.defaultDupesById.put(allo.Id, allo);
                }
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
        for (Allocation__c allo : [SELECT Id, Payment__c, Payment__r.npe01__Payment_Amount__c,  Payment__r.npe01__Paid__c, Payment__r.npe01__Written_Off__c, Opportunity__c, Opportunity__r.Amount, Amount__c, Percent__c, General_Accounting_Unit__c, Recurring_Donation__c, Campaign__c FROM Allocation__c
                WHERE (Payment__c IN :setParentId OR Opportunity__c IN :setParentId OR Recurring_Donation__c IN :setParentId OR Campaign__c IN :setParentId)
                AND Id NOT IN :setExistingAlloId]) {

            alloWrapper wrap = mapWrapper.get(getParentId(allo));

            //add payment amount
            if (allo.Payment__c != null) {
                wrap.parentAmount = allo.Payment__r.npe01__Payment_Amount__c;
            }
            //add opportunity amount
            else if (allo.Opportunity__c != null) {
                wrap.parentAmount = allo.Opportunity__r.Amount;
            }

            //save the default allocation.
            if (settings.Default_Allocations_Enabled__c && allo.General_Accounting_Unit__c == idDefaultGAU) {
                if (wrap.defaultAllo == null || wrap.defaultAllo.Id == allo.Id) {
                wrap.defaultAllo = allo;
                //keep the default allocation from listAllo
                }
                else {
                    wrap.defaultDupesById.put(allo.Id, allo);
                }
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

        Set<Id> setOppIds = new Set<Id>();
        Set<Id> setPmtIds = new Set<Id>();

        //if we arrive here without a parent amount for an opportunity/payment, we need another query for the parent info.
        for (Allocation__c allo : alloList) {
            alloWrapper wrap = mapWrapper.get(getParentId(allo));
            if (wrap.parentAmount == null && allo.Opportunity__c!=null)
                setOppIds.add(allo.Opportunity__c);
            if (wrap.parentAmount == null && allo.Payment__c!=null)
                setPmtIds.add(allo.Payment__c);
        }

        //we have opportunities we need to query for a parent amount
        if (!setOppIds.isEmpty()) {
            for (Opportunity opp : [SELECT Id, Amount FROM Opportunity WHERE Id IN :setOppIds]) {
                mapWrapper.get(opp.Id).parentAmount = opp.Amount;
            }
        }

        //we have payments we need to query for a parent amount
        if (!setPmtIds.isEmpty()) {
            for (npe01__OppPayment__c pmt : [SELECT Id, npe01__Payment_Amount__c, npe01__Paid__c,
                 npe01__Written_Off__c  FROM npe01__OppPayment__c WHERE Id IN :setPmtIds]) {
                mapWrapper.get(pmt.Id).parentAmount = pmt.npe01__Payment_Amount__c;
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
    /*******************************************************************************************************
    * @description Fills the mapWrapper variable based on a list of opportunities.
    * @param listOpps A list of GAU Allocations.
    * @return void This method modifies class variables and doesn't return anything.
    ********************************************************************************************************/
    private void fillMapWrapper (List<SObject> parentList) {
        if (parentList == null || parentList.isEmpty()) {
            return;
        }

        Set<Id> setParentId = new Set<Id>();
        //create set of Campaign IDs, Recurring Donation Ids, and Opp Ids for query
        for (SObject parent : parentList) {
            if (parent instanceof Opportunity && parent.get('CampaignId') != null)
                setParentId.add((Id)parent.get('CampaignId'));
            if (parent instanceof Opportunity && parent.get('npe03__Recurring_Donation__c') != null)
                setParentId.add((Id)parent.get('npe03__Recurring_Donation__c'));
            if (parent instanceof npe01__OppPayment__c && parent.get('npe01__Opportunity__c') != null)
                setParentId.add((Id)parent.get('npe01__Opportunity__c'));
            setParentId.add(parent.id);
        }

        String alloQueryString = 'SELECT Id, Payment__c, Payment__r.npe01__Payment_Amount__c, Payment__r.npe01__Paid__c, ' +
        'Payment__r.npe01__Written_Off__c, Opportunity__c, Opportunity__r.Amount, Campaign__c, Recurring_Donation__c, ' +
            'Amount__c, Percent__c, General_Accounting_Unit__c, General_Accounting_Unit__r.Active__c';

        //query for multicurrency string if multicurrency org
        if (UserInfo.isMultiCurrencyOrganization()) {
            alloQueryString += ', CurrencyIsoCode';
        }
        alloQueryString += ' FROM Allocation__c WHERE (Payment__c IN :setParentId OR Opportunity__c IN :setParentId OR Campaign__c IN :setParentId OR Recurring_Donation__c IN :setParentId)';
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

            //add payment amount and allocation totals
            if (allo.Payment__c != null) {
                wrap.parentAmount = allo.Payment__r.npe01__Payment_Amount__c;
            }

            //save the default allocation.
            if (settings.Default_Allocations_Enabled__c && allo.General_Accounting_Unit__c == idDefaultGAU) {
                if (wrap.defaultAllo == null)
                    wrap.defaultAllo = allo;
                else if (wrap.defaultAllo.Id != allo.Id) {
                    wrap.defaultDupesById.put(allo.Id, allo);
                }
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

    /*******************************************************************************************************
    * @description Returns the id of a given allocation's parent object; Opportunity, Recurring Donation, or
    * Campaign.
    * @param allo A GAU Allocation.
    * @return id The id of this allocation's parent object.
    ********************************************************************************************************/
    public static Id getParentId (Allocation__c allo) {
        if (allo.Payment__c!=null)
            return allo.Payment__c;
        if (allo.Opportunity__c!=null)
            return allo.Opportunity__c;
        if (allo.Recurring_Donation__c!=null)
            return allo.Recurring_Donation__c;
        if (allo.Campaign__c!=null)
            return allo.Campaign__c;
        return null;
    }

    /*******************************************************************************************************
    * @description Returns true if this allocation doesn't have exactly one parent object.
    * @param allo A GAU Allocation.
    * @return boolean Whether this allocation has a parent error.
    ********************************************************************************************************/
    public boolean parentError (Allocation__c allo) {
        integer cParts=0;

        if (allo.Payment__c!=null)
            cParts++;
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

    /*******************************************************************************************************
    * @description Creates a default allocation for the specified Opportunity/Payment.
    * @param parentSObj An Opportunity or Payment.
    * @return Allocation__c A default allocation for the amount of the Opportunity/Payment.
    ********************************************************************************************************/
    public static Allocation__c makeDefaultAllocation(SObject parentSObj) {

        Allocation__c defaultAllo = new Allocation__c(
            General_Accounting_Unit__c = idDefaultGAU
        );

        if (parentSObj instanceof npe01__OppPayment__c) {
            defaultAllo.Payment__c = parentSObj.Id;
            defaultAllo.Amount__c = (Decimal)parentSObj.get('npe01__Payment_Amount__c');
        }

        if (parentSObj instanceof Opportunity) {
            defaultAllo.Opportunity__c = parentSObj.Id;
            defaultAllo.Amount__c = (Decimal)parentSObj.get('Amount');
        }

        if (UserInfo.isMultiCurrencyOrganization()) {
            defaultAllo.put('CurrencyIsoCode', parentSObj.get('CurrencyIsoCode'));
        }

        return defaultAllo;
    }

    /*******************************************************************************************************
    * @description Returns the value or a default value (if null)
    * @param Decimal val The value to check
    * @param Decimal defaultVal The value to return if val is null
    * @return Decimal value to return
    ********************************************************************************************************/
    @testVisible private static Decimal valueOrDefaultIfNull(Decimal val, Decimal defaultVal) {
        return (val != null) ? val : defaultVal;
    }

    /**
     * @description Recreates the Scheduled Payment Allocations for Opportunities whose Allocations were updated as a
     *              result of A Recurring Donations GAU Allocations being updated.
     */
    @testVisible private void recreateScheduledPaymentAllocationsIfNecessary() {
        if (!isPaymentAllocationsEnabled() || updatedRecurringDonationOppIds.isEmpty()) {
            return;
        }

        DmlWrapper paDMLWrapper =  new DMLWrapper();

        // Payment with Payment Allocations Query for Scheduled Payments related to Opportunities
        // whose Allocations were recreated because the Recurring Donations Allocations changed
        String pmtReviewQuery = 'SELECT     Id, ' +
                                ' (SELECT Id FROM Allocations__r) ' +
                                'FROM npe01__OppPayment__c ' +
                                'WHERE npe01__Paid__c <> true AND ' +
                                '      npe01__Written_Off__c <> true AND ' +
                                '      npe01__Opportunity__c in :updatedRecurringDonationOppIds';

        List<SObject> pmtsRequiringAllocationReview = Database.query(pmtReviewQuery);

        List<SObject> pmtAllocations = new List<SObject>();
        for (SObject pmtSObj : pmtsRequiringAllocationReview) {
            npe01__OppPayment__c pmt = (npe01__OppPayment__c) pmtSObj;
            if (pmt.Allocations__r != null && !pmt.Allocations__r.isEmpty()) {
                paDMLWrapper.objectsToDelete.addAll((List<SObject>)pmt.Allocations__r);
            }
        }

        // Delete the existing Payment Allocations
        TDTM_TriggerHandler.processDML(paDMLWrapper);

        // Leverage the Allocations Service class to recreate the Payment Allocations
        // Let it log the errors, if any occur.
        ALLO_AllocationsService allocService = new ALLO_AllocationsService()
                                                .withAllocationTriggersDisabled(true)
                                                .withCommitAndClearRecordsEnabled(true);

        // Process Allocations (Will Replicate Opportunity Allocations to Scheduled Payments without Allocations)
        Set<Id> successfullyProcessedOppIds = allocService.processRecords(updatedRecurringDonationOppIds);
    }

    /**
     * @description Wraps checks to see if Payment Allocations are enabled so it can be changed in one spot
     *              in class later
     * @return Boolean true if enabled
     */
    @testVisible private static Boolean isPaymentAllocationsEnabled() {
        return (settings.Payment_Allocations_Enabled__c == true);
    }

}