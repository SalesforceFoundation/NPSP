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
* @description Tests for ALLO_AllocationsUTIL class
*/
@IsTest
public class ALLO_AllocationsUtil_TEST {

    /*******************************************************************************************************
     * RecordExclusions Inner Class Tests
     ********************************************************************************************************/

    //TODO: Test 1 - Add Exclusion (Add and Confirm Individal Exlusion [ALLO_AllocationsUtil.RecordExclusions.addExclusion]
    //TODO: Test 2 - Add Set of Exclusions) (Add Set of Exclusions and Confirm) [ALLO_AllocationsUtil.RecordExclusions.addExclusions]
    //TODO: Test 3 - Verify Exclusion via "Has Exclusion" [ALLO_AllocationsUtil.RecordExclusions.hasExclusion]
    //TODO: Test 4 - Verify Has No Exclusions call [ALLO_AllocationsUtil.RecordExclusions.hasNoExclusions]

    /*******************************************************************************************************
     * AllocationResults Inner Class Tests
     ********************************************************************************************************/
    //TODO: Test 1 - Test Add an Error [ALLO_AllocationsUtil.AllocationResults.addError]
    //TODO: Test 2 - Test Add Errors [ALLO_AllocationsUtil.AllocationResults.addAllErrors]

    /*******************************************************************************************************
     * RecordsForReview Inner Class Tests
     ********************************************************************************************************/
    //TODO: Test 1 - Test adding different types of Allocations [ALLO_AllocationsUtil.RecordsForReview.addAllocationByType]
    //TODO: Test 2 - Test method to identify Opportunities require Review [ALLO_AllocationsUtil.RecordsForReview.isOpportunityRequiresReview]
    //TODO: Test 3 - Test initialize Errors [ALLO_AllocationsUtil.RecordsForReview.initializeErrors]
        // Should test both passing in an existing ERR_RecordErrors instance, and initializing from the Opportunities
        // in the RecordsForReview variable oppsById

    /*******************************************************************************************************
     * Main Class Tests [Critical Path is covering as many as possible in this section]
     ********************************************************************************************************/
    //TODO: Method: determineRecordsRequiringReview, isRequiresReview, isExcluded, getExcludedOpportunityRecordtypes, getExcludedOpportunityTypes
    // Confirm that Opportunities that are excluded for either RecordType or Type are not processed/included
    // Confirm that Opportunities Modified Since Boundary Date are flagged for review
    // Confirm that Opportunities are flagged for review if Boundary Date is null
    // Confirm that Opportunities with non null/zero Amount and no allocations are flagged for review [Only if Default Allocations Are Enabled]
    // Confirm that Opportunities Associated with Campaign or Recurring Donation with non null/zero Amount and no allocations are flagged for review (Present to cover circumstance when Default Allocations Are Not Enabled)
    // Confirm that Opportunities with Amount that does not match sum of Allocations are flagged for review [Only if Default Allocations Are Enabled]
    // Confirm that Opportunities with Allocations Modified Since Boundary are flagged for review
    // Confirm that Opportunities with non null/zero Amount and Allocations with null/0 amount are flagged for review
    // Confirm that Opportunities with null/0 Amount and Allocations with non null/0 amount are flagged for review
    // Confirm that Opportunities with Payments that match any of the following conditions are flagged for review [If Payment Allocations Enabled]
            // Any Payments with non null/zero Amount and no allocations [Only if Default Allocations Are Enabled]
            // Any Payments with Amount that does not match sum of Allocations [Only if Default Allocations Are Enabled]
            // Any Payments with Allocations Modified Since Boundary
            // Any Payments with non null/zero Amount and Allocations with null/0 amount
            // Any Payments with null/0 Amount and Allocations with non null/0 amount

    //TODO: Method: processOpportunityAllocations
    // Identify Opportunities with no allocations, and allocate from the Default (No Parent)
    // Identify Opportunities with no allocations, and allocate from Recurring Donations Allocations (Recurring Donation Parent)
    // Identify Opportunities with no allocations, and allocate from Campaign Allocations (Campaign Allocation Parent)
    // Identify Opportunites with existing allocations, resize if Opportunity Amount Changed (confirm Default Allocation recalculated)
    // Identify Opportunities with existing allocations, calculate/recalculate Amounts for Percentage Allocations with no invalid Amounts (confirm Default Allocation recalculated)

    // TODO: Method: processPaymentAllocations
    // Identify Payments with no allocations, and allocate from the Parent (confirm Default Allocation recalculated)
    // Identify Payments with existing allocations, and resize if Payment Amount Changed (Confirm Default Allocation recalculated)
    // Identify Payments with existing allocations, calculate/recalculate Amounts for Percentage Allocations with no invalid Amounts (confirm Default Allocations recalculated)

    // TODO: Method: processAllocationResults (also will cover processAllocationDeleteResults, processAllocationInsertResults, processAllocationUpdateResults, processFunctionalErrors)
    // Pass Allocation Records, To be Inserted, Updated, and Deletes, as well as functional errors to be added
    // Must have a populated RecordsForReview object with the records that will be updated
    // Should confirm that the Allocation Maps are updated afterward for the Inserts, Updates, and Deletes
    // Should confirm functional errors are added, and exclusions should be added
    // Confirm at least update errors are handled (by attempting to update an Allocation without an Id)

    // TODO: Method: determineSuccessfullyProcessedRecords
    // Confirm any records without exclusions are returned as Successful

    // TODO: Method: copyAllocationsToTarget
    // Do not copy Allocations to target, or calculate the Default Allocation if the Parent Amount is null/zero
    // Confirm copies from Parent (Use Opportunity and Payment)
        // Confirm percent based Allocations are scaled to amount
        // Confirm amount based Allocations are converted to percent if convertToPercentages is true
        // Confirm amount based Allocations are not converted to percentage if convertToPercentages is false
        // Confirm amount based Allocations are dropped if total with amount based Allocations exceeds target Amount (convertToPercentages is false)
        // Confirm amount based allocations are converted to percent
        // Confirm works with positive and negative payment amounts
        // Confirm default is only created when there is room for default
        // Confirm Inactive Allocations are only copied if copyInactiveAllocation is true
            // Create Opportunity with Allocations.  Make one of the Allocations GAU's inactive.  Do tests to confirm both not copied, and copied to Payment depending on this value.

    //TODO: Method: resizeAllocationsAsNeeded
    // Should attempt to convert all allocations (except the default allocation) to percentages and set the Allocation Amount to null/0 if target amount is null/0
    // Should recalculate percentage based allocations and validate allocations if amount is non null/zero
        // Should confirm success case where fixed amount and percent amount are resized successfully and default is recalculated, as well as error case where total exceeds new amount because of fixed allocation amount
        // Should also do a test where percentages total above 100%

    // TODO: Method: clearAllocations
    // Confirm converts Amount Allocations to Percent, Nulls All Amounts, and Deletes the Default Allocation
    // Confirm if errors are present, deletes all allocations.  Insert fixed Allocation with Amount of 100, and other Percent Allocations with percentage of 10 and amount of 0.  This will error.
    // Confirm errors if Allocations present with amount 0 and no percentage (Add only allocations with Amount 0, and one or more percentages not filled out

    // TODO: Method: processDefaultAllocations
    // Confirm adds default if parent amount is positive and parent amount is > Allocation amount > 0 and Default Allocation is not present in defaultAllocations list
    // Confirm adds default if parent amount is negative and parent amount is < Allocation amount < 0 and Default Allocation is not present in defaultAllocations list
    // Confirm if multiple Allocations for default are present in defaultAllocations list, and a Default Allocation is still needed, it deletes all but the first, and resizes that Allocation
    // Confirm if Default Allocation is present, and is no longer needed (Parent amount = Allocation amount)

    // TODO: Method: makeDefaultAllocation
    // Confirm creates an Allocation associated with the Default for the specified Amount

    /*******************************************************************************************************
     * Helper Methods - Record Retrieval Tests
     ********************************************************************************************************/
    // TODO: Method: retrieveOpportunities
    // Confirm retrieves Opportunity and Payment Data for the the Opportunity Ids specified

    // TODO: Method: retrieveAllocations
    // Confirm retrieves Allocation Data for the Opportunities, Payments, Recurring Donations, and Campaigns specified (via Ids)

    /*******************************************************************************************************
     * Helper Methods - Allocation Triggers
     ********************************************************************************************************/

    // TODO: Method: disableAllocationTriggers, updateAllocationTriggersState
    // Confirm the state of the following triggers is False
        // ALLO_Allocations_TDTM (Allocation__c, Opportunity, npe01__OppPayment__c Objects)
        // ALLO_PaymentSync_TDTM (Allocation__c)

    // TODO: Method: enableAllocationTriggers, updateAllocationTriggersState
    // Confirm the state of the following triggers is False
        // ALLO_Allocations_TDTM (Allocation__c, Opportunity, npe01__OppPayment__c Objects)
        // ALLO_PaymentSync_TDTM (Allocation__c)

    /*****************************************
     * Helper Methods - Process Exclusions Tests
     *****************************************/

    // TODO: Method: getProcessExclusions
    // Confirm it allocates and returns a Map of Set of PROCESS_DEF records, keyed by PROCESS_DEF.  It should only allocate it once, no matter how many times it is called

    // TODO: Method: getProcessExclusionsFor
    // Confirm it returns the Set of Process Exclusions for a specific Process

    /*****************************************
     * Helper Methods - Allocation Maps
     *****************************************/

    // TODO: Method: add (Id to parentId to Children(Ids))
    // Confirm it adds a child Id to a parent, creating a new Set if necessary, and adding to the Set if not

    // TODO: Method: add (Allocation to a Map of a List of Allocations by parent's Id)
    // Confirm it adds an allocation to a list of allocations in a map, keyed by the parents id, creating a new list if necessary, and adding to the list if not

    // TODO: Method: remove (Allocation from a Map of a List of Allocations by parent's Id)
    // Confirm it will remove an allocation from a List of Allocations by parent, if present

    // TODO: Method: replace (Allocation in a Map of a List of Allocations by parent's Id)
    // Confirm it will find an Allocation in a List of Allocations, keyed by Parent Id, and replace it with the latest version.  It is added to the end if the Allocation is not already in the list

    /*****************************************
     * Helper Methods - Record Review Methods
     *****************************************/

    // TODO: Method: removeIfNotForReview (Parent to Set of Opportunities)
    // Confirm records in allocationByParentId are removed if none of the Opportunities the Parent references are not in the oppsById keyset

    // TODO: Method: set1ContainsAnyInSet2
    // Confirm returns true if one or more members of set2 are present in set1, and false otherwise

    // TODO: Method: removeIfNotForReview (Parent to Opp)
    // Confirms records in allocationsByParentId are removed if the Opportunity that Parent references is not in the oppsById keyset

    // TODO: Method: removeIfNotForReview (Opp)
    // Confirms records in allocationsByParentId are removed if the Allocation Parent Id is not in the oppsById keyset

    /*****************************************
     * Helper Methods - Allocation Validation Tests
     *****************************************/

    // TODO: Method: validatePaymentAllocationsConfiguration
    // Validate that if the configuration is correct, no errors are returned
    // Validate that it checks correctly for Payment Allocations Not Enabled, Default Allocations Not Enabled, Default Allocation not configured, Default Allocation not exist, Default Allocation Not Active

    // TODO: Method: validateAllocation, validateAllocationHasParentError
    // Validate that Allocation with no or multiple parents returns error
    // Validate that Allocation with neither amount nor percent returns error
    // Validate that Only Allocations Associated with a Payment can be negative
    // Validate that Allocation cannot have a negative percent

    /***************************
     * Helper Methods - Error Tests
     ***************************/

    // TODO: Method: assembleAllocationError
    // Confirm it builds a properly formatted error message (associated with a parent and allocation)

    // TODO: Method: assembleRecordError
    // Confirm it builds a properly formatted error message (associated with a parent)

    /***************************
     * Helper Methods - General Tests
     ***************************/

    // TODO: Method: getOpportunityIdFor
    // Confirm it returns the Record Id if it is passed an Opportunity Id or the value in the field npe01__Opportunity__c if passed a payment

    // TODO: Method: getAmountFor
    // Confirm it returns the value in the Amount field if passed an Opportunity, and the value in npe01__Payment_Amount__c if passed a Payment

    // TODO: Method: getLabelFor, getOpportunityLabel, getPaymentLabel
    // Confirm it returns the Opportunity Label if passed an Opportunity Record, and the Payment Label if Passed a Payment object
    // Note: Describe call is only done once

    // TODO: Method: getAllocationLabel
    // Confirm it returns the Allocation Object Label
    // Note: Describe call is only done once

    }