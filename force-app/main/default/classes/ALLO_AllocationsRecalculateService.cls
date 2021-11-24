/*
    Copyright (c) 2020, Salesforce.org
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
* @date 2020
* @group Allocations
* @description Utility class to create the lists of inserts, deletes, and updates for
*              Opportunities and Payments requiring it
*/
public inherited sharing class ALLO_AllocationsRecalculateService {

    /**
     * @description Determines if multi-currency is enabled for the org
     */
    private Boolean isMultiCurrencyEnabled {
        get {
            if (isMultiCurrencyEnabled == null) {
                isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
            }
            return isMultiCurrencyEnabled;
        }
        set;
    }

    /** @description Allocations Wrapper Allocations Work */
    private ALLO_AllocationsWrapper allocationsWrapper;

    /**
     * @description Provides an allocations wrapper to the class for processing
     * @param allocationsWrapper Allocation Wrapper with DML to be processed
     * @return Class Instance
     */
    public ALLO_AllocationsRecalculateService withAllocationsWrapper(ALLO_AllocationsWrapper allocationsWrapper) {
        this.allocationsWrapper = allocationsWrapper;
        return this;
    }

    /**
     * @description Processes Opportunities and their Allocations:
     *              1) Resizes existing percentage based Allocations for amount changes
     *              2) Adds/updates/removes the default Allocation if enabled, and as appropriate
     *              3) Creates Allocations from the parent (if no Allocations are present, and the
     *                 record has a parent)
     *              4) If amount goes to null/0, deletes the default Allocations (if present/enabled) and
     *                 converts existing non percentage Allocations to percentage Allocations if possible,
     *                 and zeroes all allocations
     *              Records errors if allocations become invalid for the Opportunity
     *              Validates changes, logs errors if allocations are now invalid
     *              NO DML is processed in this method.  It is instead returned to the caller for
     *              processing
     */
    public void processOpportunityAllocations() {
         for (Opportunity opp : allocationsWrapper.oppsById.values()) {
            if (allocationsWrapper.hasExclusion(opp.Id, ALLO_AllocationsService.processDefinitionType.OPP_ALLOC_UPD)) {
                continue;
            }

            List<Allocation__c> oppAllocations = allocationsWrapper.oppsAllocations.get(opp.Id);

            if (oppAllocations == null || oppAllocations.isEmpty()) {
                // New Allocations to be copied from parent, or defaulted (part of #2, #3)

                List<Allocation__c> sourceAllocations = null;
                // No Allocations, copyFromParent or set default of no parent
                if (opp.CampaignId != null && allocationsWrapper.campaignAllocations.containsKey(opp.CampaignId)) {
                    sourceAllocations = allocationsWrapper.campaignAllocations.get(opp.CampaignId);
                }

                if (opp.npe03__Recurring_Donation__c != null && allocationsWrapper.recurringDonationAllocations.containsKey(opp.npe03__Recurring_Donation__c)) {
                    sourceAllocations = allocationsWrapper.recurringDonationAllocations.get(opp.npe03__Recurring_Donation__c);
                }

                copyAllocationsToTarget(opp, null, sourceAllocations, false, false);
            } else {
                // Existing Allocations and are to be resized, or cleared as necessary (#1, part of #2, #4)
                resizeAllocationsAsNeeded(opp, oppAllocations);
            }
        }
    }

    /**
     * @description Processes Payments and their Allocations:
     *              1) Resizes existing percentage based Allocations for amount changes
     *              2) Adds/updates/removes the default Allocation if enabled, and as appropriate
     *              3) Creates Allocations from the parent
     *              4) If amount goes to null/0, deletes the default Allocations (if present/enabled) and
     *                 converts existing non percentage Allocations to percentage Allocations if possible,
     *                 and zeroes all Allocations
     *              Records errors if Allocations become invalid for the Payment
     *              Validates changes, logs errors if Allocations are now invalid
     *              NO DML is processed in this method.  It is instead returned to the caller for
     *              processing
     */
    public void processPaymentAllocations() {
        if (!ALLO_AllocationsSettings.getSettings().isPaymentAllocationsEnabled()) {
            // TODO: Determine whether this should throw an Exception instead...
            return;
        }

        for (Opportunity opp : allocationsWrapper.oppsById.values()) {
            for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
                // All processing for this payment should be skipped
                if (allocationsWrapper.hasExclusion(opp.Id, ALLO_AllocationsService.processDefinitionType.PMT_ALLOC)) {
                    continue;
                }
                // Retrieve existing Payment Allocations, if present
                List<Allocation__c> pmtAllocations = allocationsWrapper.paymentAllocations.get(payment.Id);

                if (pmtAllocations == null || pmtAllocations.isEmpty()) {
                    // New Allocations to be copied from parent, or defaulted (part of #2, #3)
                    if (!allocationsWrapper.hasExclusion(opp.Id, ALLO_AllocationsService.processDefinitionType.PMT_ALLOC_INITIALIZE)) {
                        copyAllocationsToTarget(payment, ALLO_AllocationsUtil.getAmountFor(opp), allocationsWrapper.oppsAllocations.get(opp.Id), true, true);
                    }
                } else {
                    // Existing Allocations and are to be resized, or cleared as necessary (#1, part of #2, #4)
                    if (!allocationsWrapper.hasExclusion(opp.Id, ALLO_AllocationsService.processDefinitionType.PMT_ALLOC_RECALC)) {
                        resizeAllocationsAsNeeded(payment, pmtAllocations);
                    }
                }
            }
        }
    }

    /**
     * @description Copies Allocations from the source to the target.  It should only do this if there are
     *              no allocations present on the target.
     *              Note: This will not actually modify any records.
     *              Refactored from
     *              ALLO_ALLOCATIONS_TDTM.copyRecurringDonationCampaignAndPaymentAllocations
     * @param SObject targetObj The record the Allocations will be copied to
     * @param List<Allocation__c> sourceAllocations The Allocations associated with the source that will
     *        be copied to the target
     * @param Boolean copyInactiveAllocations If true, it will attempt to copy Allocations associated with
     *        an Inactive General Accounting Unit to the target
     * @param Boolean convertToPercentages Indicates whether amount based allocations (other than
     *        Allocations for the default) should be converted to percentages
     */
    public void copyAllocationsToTarget(SObject targetObj, Decimal sourceAmount, List<Allocation__c> sourceAllocations, Boolean copyInactiveAllocations, Boolean convertToPercentages) {
        Decimal amount = ALLO_AllocationsUtil.getAmountFor(targetObj);

        // Allocations should not be copied to the target if the target object's amount is null
        if (amount == null) {
            return;
        }

        // Convert Amount to 0.  Will only get here with null amount if Parent is a Payment
        amount = (amount != null) ? amount : 0;
        List<Allocation__c> proposedAllocations = new List<Allocation__c>();

        if (sourceAllocations != null && sourceAllocations.size() > 0) {
            Id opportunityId = (targetObj instanceOf Opportunity) ? targetObj.Id : null;
            Id paymentId = (targetObj instanceOf npe01__OppPayment__c) ? targetObj.Id : null;

            List<Allocation__c> listAlloForInsert = new List<Allocation__c>();

            for (Allocation__c allocation : sourceAllocations.deepclone()) {
                // Only copy if Default Allocations are not Enabled or it is not for the Default Allocation
                if (!ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled() ||
                     allocation.General_Accounting_Unit__c != ALLO_AllocationsSettings.getSettings().getDefaultAllocationsId()) {
                    // Set the Allocation Lookup Fields
                    allocation.Opportunity__c = opportunityId;
                    allocation.Payment__c = paymentId;
                    allocation.Recurring_Donation__c = null;
                    allocation.Campaign__c = null;

                    // Copy all Allocations if copyInActiveAllocations is true
                    if (copyInactiveAllocations) {
                        listAlloForInsert.add(allocation);
                    } else {
                        if (allocation.General_Accounting_Unit__r.Active__c) {
                            listAlloForInsert.add(allocation);
                        }
                    }
                }
            }

            Decimal remainder = amount;

            // Update the Allocations amounts and percentages, and if required, non-percentage based Allocations to percentage Allocations
            for (Allocation__c allocation : listAlloForInsert) {
                //if this is a multicurrency org, recalculate the amount and set the CurrencyIsoCode to the same one as the parent
                if (isMultiCurrencyEnabled) {
                    if (allocation.Amount__c != null) {
                        allocation.Amount__c = UTIL_CurrencyConversion.convertAmountUsingStandardRates(
                            (String)allocation.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD),
                            (String)targetObj.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD),
                            allocation.Amount__c
                        );
                    }
                    allocation.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, targetObj.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD));
                }

                if (allocation.Percent__c != null) {
                    allocation.Amount__c = (amount * allocation.Percent__c * .01).setScale(2);
                }

                //Calculate proportional amount for non-percentage based Payment allocations
                // convertToPercentages must be true, the Percentage null, sourceAmount cannot be null and either Default Allocations are not enabled or the allocation is not for the Default Allocation
                if (convertToPercentages && allocation.Percent__c == null & sourceAmount != null) {
                    // Determine Percentage
                    Decimal allocationPercent = ((allocation.Amount__c != null) ? allocation.Amount__c : 0) / sourceAmount * 100;

                    allocation.Amount__c = (amount * allocationPercent * .01).setScale(2);

                    // Store Percentage as is, so precision is not lost in future calculations
                    allocation.Percent__c = allocationPercent;
                }
                remainder -= (allocation.Amount__c != null) ? allocation.Amount__c : 0;
            }
            Boolean isRemainderAndAmountOppositeSign = (amount >= 0 && remainder < 0) || (amount < 0 && remainder > 0);
            Boolean isRemainderAndAmountSameSign = (amount >= 0 && remainder > 0) || (amount < 0 && remainder < 0);
            Boolean isRemainderAndAmountZero = amount == 0 && remainder == 0;

            //if our remainder is not the same sign as the amount, only create percentage based Allocations
            if (isRemainderAndAmountOppositeSign) {
                remainder = amount;

                //TODO: log error: not able to create allocations. chatter post?
                for (Allocation__c allocation : listAlloForInsert) {
                    if (allocation.Percent__c != null) {
                        allocationsWrapper.allocationsForInsert.add(allocation);
                        remainder -= (allocation.Amount__c != null) ? allocation.Amount__c : 0;
                    }
                }

                if (ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled() && isRemainderAndAmountSameSign) {
                    Allocation__c defaultAllo = makeDefaultAllocation(targetObj, remainder);
                    proposedAllocations.add(defaultAllo);
                }

            //Create Default Allocation if needed
            } else if (ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled() && isRemainderAndAmountSameSign) {
                proposedAllocations.add(makeDefaultAllocation(targetObj, remainder));
                proposedAllocations.addAll((List<Allocation__c>)listAlloForInsert);
            //add objects to DML wrapper in all other cases (no remainder, or positive remainder without default allocations enabled)
            } else if (ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled() && isRemainderAndAmountZero && listAlloForInsert.isEmpty()) {
                // Adding Default Allocation for $0
                proposedAllocations.add(makeDefaultAllocation(targetObj, 0));
            } else {
                proposedAllocations.addAll((List<Allocation__c>)listAlloForInsert);
            }

        //if we have no source Allocations and defaults are enabled, create them for each payment/opportunity
        } else if (ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled()) {
                proposedAllocations.add(makeDefaultAllocation(targetObj, amount));
        }

        allocationsWrapper.allocationsForInsert.addAll (proposedAllocations);
    }

    /**
     * @description In the event a parent's Amount has increased or Decreased, or it has changed sign, or
     *              new Allocations have been added, or Allocations have been removed, the parentObj's
     *              Allocations must be recalculated/resized.  If the parent object's amount becomes null,
     *              clear allocations should instead be called.
     *              Refactored from ALLO_Allocations_TDTM.opportunityAmountCurrencyChange
     * @param SObject parentObj An Opportunity or Payment.
     * @param List<Allocation__c> List of any Allocations associated with the parentObj
     */
    public void resizeAllocationsAsNeeded(SObject parentObj, List<Allocation__c> allocations) {
        Decimal sumOfAllocations = 0;
        Decimal totalOfPercentages = 0;
        Decimal parentAmount = ALLO_AllocationsUtil.getAmountFor(parentObj);

        // Resizing of Allocations for null Amounts is not done in this method, as null resizing is a special case.
        if (parentAmount == null || parentAmount == 0) {
            clearAllocations(parentObj, allocations);
            return;
        }

        Boolean requiresUpdates = false;
        Boolean nonDefaultAllocationsPresent = false;
        List<Allocation__c> proposedAllocations = new List<Allocation__c>();
        List<Allocation__c> defaultAllocations = new List<Allocation__c>();
        String parentCurrencyIsoCode = (isMultiCurrencyEnabled) ? (String) parentObj.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD) : null;
        Boolean errorsFound = false;

        for (Allocation__c allocation : allocations.deepClone(true, true, true)) {
            if (ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled() &&
                allocation.General_Accounting_Unit__c == ALLO_AllocationsSettings.getSettings().getDefaultAllocationsId()) {
                defaultAllocations.add(allocation);
            } else {
                String allocCurrencyIsoCode = (isMultiCurrencyEnabled) ? (String) allocation.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD) : null;
                Decimal curAllocAmount = (allocation.Percent__c != null) ? allocation.Percent__c * 0.01 * parentAmount : allocation.Amount__c;
                Boolean updatesToAllocation = false;

                nonDefaultAllocationsPresent = true;

                // Change due to Parent Amount update or Parent CurrencyIsoCode change
                if (allocation.Amount__c != curAllocAmount || parentCurrencyIsoCode != allocCurrencyIsoCode) {
                    updatesToAllocation = true;
                }

                Boolean isAllocAndParentSignDifferent = curAllocAmount != null && ((curAllocAmount > 0 && parentAmount < 0) || (curAllocAmount < 0 && parentAmount > 0));
                // Amount requires sign update.  Only allowed for Payments...
                if (allocation.Payment__c != null && isAllocAndParentSignDifferent) {
                    curAllocAmount = -1 * curAllocAmount;
                    updatesToAllocation = true;
                }

                List<String> errs = validateAllocation(parentObj, allocation);
                if (!errs.isEmpty()) {
                    errorsFound = true;
                    allocationsWrapper.addAllErrors(ALLO_AllocationsUtil.getOpportunityIdFor(parentObj), errs);
                } else {
                    if (updatesToAllocation) {
                        allocation.Amount__c = curAllocAmount;
                        if (isMultiCurrencyEnabled) {
                            allocation.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, parentCurrencyIsoCode);
                        }
                        proposedAllocations.add(allocation);
                    }
                }
                sumOfAllocations += (curAllocAmount != null) ? curAllocAmount : 0;
                totalOfPercentages += (allocation.Percent__c != null) ? allocation.Percent__c : 0;
            }
        }

        if (totalOfPercentages > 100) {
            allocationsWrapper.addRecordError(parentObj, Label.alloPercentExceed100);
            errorsFound = true;
        }

        Boolean isParentAmountExceeded = (sumOfAllocations > parentAmount && parentAmount > 0) || (sumofAllocations < parentAmount && parentAmount < 0);
        if (isParentAmountExceeded) {
            allocationsWrapper.addRecordError(parentObj, Label.alloOverallocatedError);
            errorsFound = true;
        }

        if (!errorsFound) {
            if (!proposedAllocations.isEmpty()) {
                for (Allocation__c allocation : proposedAllocations) {
                    if (allocation.Id != null) {
                        allocationsWrapper.allocationsForUpdate.add (allocation);
                    } else {
                        allocationsWrapper.allocationsForInsert.add (allocation);
                    }
                }
            }

            // Process Default Allocations
            processDefaultAllocations(parentObj, parentAmount, parentCurrencyIsoCode, sumOfAllocations, nonDefaultAllocationsPresent, defaultAllocations);
        }
    }

    /**
     * @description In the event a parent object's amount becomes Null, the Allocations associated with it
     *              should be converted to percentages, excluding the Default Allocation (which should be
     *              deleted if present).  All Allocation amount values should be set to 0.  In the event
     *              that an Allocation cannot successfully be converted to percentages, a functional error
     *              is added to the result and all Allocations for the object are deleted.
     * @param SObject parentObj An Opportunity or Payment.
     * @param List<Allocation__c> List of any Allocations associated with the parentObj
     */
    @testVisible private void clearAllocations(SObject parentObj, List<Allocation__c> allocations) {
        Decimal totalOfPercentages = 0;
        Decimal parentAmount = ALLO_AllocationsUtil.getAmountFor(parentObj);

        Boolean isParentPaymentObj = parentObj instanceOf npe01__OppPayment__c;

        // Will only clear Allocations if Amount is null
        if (parentAmount != null && parentAmount != 0) {
            return;
        }

        Boolean requiresUpdates = false;

        String parentCurrencyIsoCode = (isMultiCurrencyEnabled) ? (String) parentObj.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD) : null;

        List<Allocation__c> proposedAllocations = new List<Allocation__c>();
        List<Allocation__c> proposedAllocDeletes = new List<Allocation__c>();
        List<Allocation__c> defaultAllocations = new List<Allocation__c>();

        if (parentAmount == null) { // Delete all Allocations if parentAmount is Null
            allocationsWrapper.allocationsForDelete.addAll(allocations.deepClone(true, true, true));
            return;
        }

        Boolean errorsFound = false;

        // Sum Allocations
        for (Allocation__c allocation : allocations) {
            Boolean isDefaultAllocation = ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled() &&
                                          allocation.General_Accounting_Unit__c == ALLO_AllocationsSettings.getSettings().getDefaultAllocationsId();
            // Fixed Allocation, Non Default, with non null, non zero amount
            if (allocation.Percent__c == null &&
                allocation.Amount__c != null &&
                allocation.Amount__c != 0 &&
                !isDefaultAllocation) {
                String errorLabel = (isParentPaymentObj) ? Label.alloExceedsPmtAmount : Label.alloExceedsOppAmount;
                allocationsWrapper.addRecordError(parentObj, errorLabel);
                // If any non zero, non percent based allocations other than the default are encountered, generate an error and return
                return;
            }
        }
        Boolean nonDefaultAllocationsPresent = false;

        for (Allocation__c allocation : allocations.deepClone(true, true, true)) {
            Boolean isDefaultAllocation = ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled() &&
                                          allocation.General_Accounting_Unit__c == ALLO_AllocationsSettings.getSettings().getDefaultAllocationsId();
            if (isDefaultAllocation) { // Default Allocations will be handled elsewhere
                defaultAllocations.add(allocation);
            } else {
                nonDefaultAllocationsPresent = true;
                String allocCurrencyIsoCode = (isMultiCurrencyEnabled) ? (String) allocation.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD) : null;
                if (allocation.Percent__c != null && allocation.Percent__c < 0) {
                    allocationsWrapper.addError(ALLO_AllocationsUtil.getOpportunityIdFor(parentObj), assembleAllocationError(parentObj, allocation, Label.alloNegativePercent));
                    errorsFound = true;
                }
                totalOfPercentages += (allocation.Percent__c != null) ? allocation.Percent__c : 0;
                if (allocation.Amount__c != 0) {
                    allocation.Amount__c = 0;
                    proposedAllocations.add (allocation);
                }
            }
        }

        if (totalOfPercentages > 100) {
            errorsFound = true;
            allocationsWrapper.addRecordError(parentObj, Label.alloPercentExceed100);
        }

        if (!errorsFound) {
            if (!proposedAllocations.isEmpty()) {
                for (Allocation__c allocation : proposedAllocations) {
                    if (allocation.Id != null) {
                        allocationsWrapper.allocationsForUpdate.add (allocation);
                    } else {
                        allocationsWrapper.allocationsForInsert.add (allocation);
                    }
                }
            }
            if (!proposedAllocDeletes.isEmpty()) {
                allocationsWrapper.allocationsForDelete.addAll (proposedAllocDeletes);
            }
            // Process Default Allocations
            processDefaultAllocations(parentObj, parentAmount, parentCurrencyIsoCode, 0, nonDefaultAllocationsPresent, defaultAllocations);
        }
    }

    /**
     * @description Recalculates the Default Allocation for the specified Opportunity/Payment, adding,
     *              updating, or removing it as necessary.
     * @param SObject parentSObj An Opportunity or Payment.
     * @param Decimal parentAmount Amount of the Parent Object
     * @param String parentCurrencyIsoCode The parent objects CurrencyIsoCode, if Multicurrency is enabled
     *        or null if not
     * @param Decimal allocationTotalAmount Total amount of all Allocations for the parentObject other
     *        than the default
     * @param nonDefaultAllocationsPresent If true, means there should not be a default allocation if
     *        parent Amount is 0
     * @param List<Allocation__c> List of any Allocations on the current object for the Default GAU
     *        It will include the allocations to create/update/delete, as well as any functional errors to be
     *        added
     */
    @testVisible private void processDefaultAllocations(SObject parentObj, Decimal parentAmount, String parentCurrencyIsoCode, Decimal allocationTotalAmount, Boolean nonDefaultAllocationsPresent, List<Allocation__c> defaultAllocations) {
        // Skip all processing of Default Allocations if they are not enabled
        if (!ALLO_AllocationsSettings.getSettings().isDefaultAllocationsEnabled()) {
            return;
        }

        Decimal defaultAllocationAmount = parentAmount - allocationTotalAmount;

        if (nonDefaultAllocationsPresent && (defaultAllocationAmount == 0 || parentAmount == 0)) {
            // No default allocations should be present.  Parent is fully allocated.  Any existing defaults should be deleted.
            allocationsWrapper.allocationsForDelete.addAll(defaultAllocations);
        } else if ((parentAmount >= 0 && defaultAllocationAmount >= 0) || (parentAmount < 0 && defaultAllocationAmount < 0)) {
            if (!defaultAllocations.isEmpty()) {
                String allocCurrencyIsoCode = (isMultiCurrencyEnabled) ? (String) defaultAllocations[0].get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD) : null;
                if (defaultAllocationAmount != defaultAllocations[0].Amount__c || parentCurrencyIsoCode != allocCurrencyIsoCode || defaultAllocations[0].Percent__c != null) {
                    defaultAllocations[0].Amount__c = defaultAllocationAmount;
                    defaultAllocations[0].Percent__c = null;
                    if (isMultiCurrencyEnabled) {
                        defaultAllocations[0].put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, parentCurrencyIsoCode);
                    }
                    allocationsWrapper.allocationsForUpdate.add(defaultAllocations[0]);
                }
                // Add all remaining allocations to the list of allocations to delete
                for (Integer i=1; i< defaultAllocations.size(); i++) {
                    allocationsWrapper.allocationsForDelete.add(defaultAllocations[i]);
                }
            } else { // Add a default Allocation
                allocationsWrapper.allocationsForInsert.add(makeDefaultAllocation(parentObj, defaultAllocationAmount));
            }
        }
        // Other conditions could not occur because trapped for inside of resizeAllocations method...
    }

    /**
     * @description Validates an individual Allocation record
     * @param SObject parentObj The Allocation's parent
     * @param Allocation__c allocation The Allocation to validate
     * @return List<String> A list of errors.  If the list is empty, there were no errors associated with
     *         this Allocation
     */
    public List<String> validateAllocation(SObject parentObj, Allocation__c allocation) {
        List<String> errors = new List<String>();
        // No parent, or multiple parents
        if (validateAllocationHasParentError(allocation)) {
            errors.add(assembleAllocationError(parentObj, allocation, Label.alloSingleParent));
        }
        //neither an amount nor a percent is defined
        if (allocation.Amount__c == null && allocation.Percent__c == null) {
            errors.add(assembleAllocationError(parentObj, allocation, Label.alloAmountOrPercent));
        }
        //negative amount (Payments excepted)
        if (allocation.Amount__c != null && allocation.Amount__c < 0 && allocation.Payment__c == null) {
            errors.add(assembleAllocationError(parentObj, allocation, Label.alloNegativeAmount));
        }
        //negative percent
        if (allocation.Percent__c != null && allocation.Percent__c < 0) {
            errors.add(assembleAllocationError(parentObj, allocation, Label.alloNegativePercent));
        }

        return errors;
    }

    /**
     * @description Returns true if this allocation doesn't have exactly one parent object.
     * @param allo A GAU Allocation.
     * @return boolean Whether this allocation has a parent error.
     */
    private Boolean validateAllocationHasParentError (Allocation__c allo) {
        Integer parentCnt = 0;

        parentCnt += (allo.Payment__c != null) ? 1 : 0;
        parentCnt += (allo.Opportunity__c != null) ? 1 : 0;
        parentCnt += (allo.Recurring_Donation__c != null) ? 1 : 0;
        parentCnt += (allo.Campaign__c != null) ? 1 : 0;
        // Anything other than exactly 1 will return an error
        return (parentCnt != 1);
    }

    // TODO: Add additional validation method(s) to cover trigger validations not needed by the batch.
    // This will need to be done as the triggers are refactored to share code.

    /**
     * @description Creates a Default Allocation for the specified Opportunity/Payment.
     * @param parentSObj An Opportunity or Payment.
     * @param amount Amount of the Default Allocation
     * @return Allocation__c A Default Allocation for the amount specified
     */
    public Allocation__c makeDefaultAllocation(SObject parentSObj, Decimal amount) {
        Id opportunityId = (parentSObj instanceOf Opportunity) ? parentSObj.Id : null;
        Id paymentId = (parentSObj instanceOf npe01__OppPayment__c) ? parentSObj.Id : null;

        Allocation__c defaultAllo = new Allocation__c(
            General_Accounting_Unit__c = ALLO_AllocationsSettings.getSettings().getDefaultAllocationsId(),
            Opportunity__c = opportunityId,
            Payment__c = paymentId,
            Amount__c = amount
        );

        if (isMultiCurrencyEnabled) {
            defaultAllo.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, parentSObj.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD));
        }

        return defaultAllo;
    }

    /**
     * @description Assembles an error associated with a specific Allocation
     * @param SObject parentObj The Allocation's parent
     * @param Allocation__c alloc The Allocation associated with the error
     * @param String message The error or warning message to add
     * @return String the complete message for this Allocation
     */
    @testVisible private String assembleAllocationError(SObject parentObj, Allocation__c alloc, String message) {
        return String.format(Label.alloPaymentAllocationBatchAllocationError,
                             new List<String> {
                                 ALLO_AllocationsUtil.getLabelFor(parentObj),
                                 (String) parentObj.Id,
                                 String.IsNotBlank(alloc.Name) ? alloc.Name : '(null)',
                                 message
                                }
                            );
    }
}