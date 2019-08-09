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
    //TODO: Test 1 - Test adding different types of allocations [ALLO_AllocationsUtil.RecordsForReview.addAllocationByType]
    //TODO: Test 2 - Test method to identify Opportunities require Review [ALLO_AllocationsUtil.RecordsForReview.isOpportunityRequiresReview]
    //TODO: Test 3 - Test initialize Errors [ALLO_AllocationsUtil.RecordsForReview.initializeErrors]
        // Should test both passing in an existing ERR_RecordErrors instance, and initializing from the Opportunities
        // in the RecordsForReview variable oppsById

    /*******************************************************************************************************
     * Main Class Tests
     ********************************************************************************************************/
    //TODO: Method: DetermineRecordsRequiringReview
    // TEST Requirements (Might be multiple tests)
    // Overall Requirements:
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





    }