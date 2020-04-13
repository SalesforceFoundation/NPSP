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
* @description Main Service class for Allocations Batch Support (including Payment Allocations)
*              Step 1 - Retrieve Data (ALLO_AllocationsRetrievalService returns populated ALLO_AllocationsWrapper)
*              Step 2 - Review Data to determine which Opportunities require further processing
*                       (ALLO_AllocationReviewService evaluates ALLO_AllocationsWrapper)
*              Step 3 - Filter ALLO_AllocationsWrapper to only ones requiring processing using results from Review
*                       Data Step (ALLO_AllocationsWrapper)
*              Step 4 - Recalculate Opportunity Allocations (ALLO_RecalculateService using ALLO_AllocationsWrapper)
*                       a) Determines changes, and errors, and adds them to the ALLO_AllocationsWrapper class as
*                       inserts, updates, deletes, and error messages
*              Step 5 - Process DML from Step 4 (ALLO_AllocationsDMLService, using ALLO_AllocationsWrapper)
*                       a) Processes the DML.  Any errors will cause a rollback, and add those additional errors
*                          to be logged.  The DML will be retried without the errored records.
*                       b) After DML, it will update the existing Maps of Allocations Data in the
*                          ALLO_AllocationsWrapper with the changes
*                       c) Functional and DML errors are added to the ERR_RecordErrors instance to be logged at the end,
*                          and exclusions are added.
*              Step 6 - Recalculate Payment Allocations, if enabled (ALLO_RecalculateService using ALLO_AllocationsWrapper)
*                       a) Determines changes, and errors, and adds them to the ALLO_AllocationsWrapper class as
*                       inserts, updates, deletes, and error messages
*              Step 7 - Process DML from Step 6, if enabled (ALLO_AllocationsDMLService, using ALLO_AllocationsWrapper)
*                       a) Processes the DML.  Any errors will cause a rollback, and add those additional errors
*                          to be logged.  The DML will be retried without the errored records.
*                       b) After DML, it will update the existing Maps of Allocations Data in the
*                          ALLO_AllocationsWrapper with the changes
*                       c) Functional and DML errors are added to the ERR_RecordErrors instance to be logged at the end,
*                          and exclusions are added.
*              Step 8 - Clear errors for all records that were processed successfully, or did not require further
*                       processing.
*              Step 9 - Commit record errors, if indicated to do so
*/
public inherited sharing class ALLO_AllocationsService {

    /**
     * @description The steps taken in the Allocations processing.  These are used when excluding
     *              specific Opportunities from further processing for failures in earlier steps
     */
    public enum processDefinitionType {
        ALL,
        OPP_AMT_UPD,
        OPP_ALLOC_UPD,
        PMT_ALLOC,
        PMT_ALLOC_RECALC,
        PMT_ALLOC_INITIALIZE
    }

    /**
     * @description The context Error and Informational Messages should be logged under.
     *               Defaults to Context.ALLO, but can be overridden.
     */
    @testVisible private String contextType = ERR_Handler_API.Context.ALLO.name();

    /**
     * @description Record Errors Instance will use to log errors with
     */
    @testVisible private ERR_RecordError recErrs;

    /**
     * @description Indicates whether or not Allocation triggers should be disabled during processing.
     *               Default is true
     */
    @testVisible private Boolean disableAllocationTriggers = true;

    /**
     * @description Indicates whether or not Record Errors should be committed, or left to the calling process to commit.
     *               Default is true (commit and clear)
     */
    @testVisible private Boolean commitAndClearRecordErrors = true;

    /** @description Caches PROCESS_EXCLUSIONS */
    @testVisible private static Map<processDefinitionType, Set<processDefinitionType>> processExclusions {
        get {
            if (processExclusions == null) {
                processExclusions = new Map<processDefinitionType, SET<processDefinitionType>> {
                    processDefinitionType.OPP_AMT_UPD =>
                        new Set<processDefinitionType>     {processDefinitionType.OPP_ALLOC_UPD},
                    processDefinitionType.OPP_ALLOC_UPD =>
                        new Set<processDefinitionType>     {processDefinitionType.PMT_ALLOC_INITIALIZE},
                    processDefinitionType.PMT_ALLOC =>
                        new Set<processDefinitionType>     {processDefinitionType.ALL},
                    processDefinitionType.PMT_ALLOC_RECALC =>
                        new Set<processDefinitionType>     {processDefinitionType.ALL},
                    processDefinitionType.PMT_ALLOC_INITIALIZE =>
                        new Set<processDefinitionType>     {processDefinitionType.ALL}
                };
            }

            return processExclusions;
        }

        private set;
    }


    /**
     * @description provides a non default context type to log info and errors under with the AllocationService
     * @param altContextType Alternate context type to log errors and information under
     * @return Class Instance
     */
    public ALLO_AllocationsService withAlternateContextType(String altContextType) {
        this.contextType = String.isNotBlank(altContextType) ? altContextType : this.contextType;
        return this;
    }

    /**
     * @description provides a non default record errors instance to use when logging errors
     * @param altRecErrs Already initialized instance of the ERR_RecordError class
     * @return Class Instance
     */
    public ALLO_AllocationsService withAlternateRecordErrorsLogger(ERR_RecordError altRecErrs) {
        this.recErrs = (altRecErrs != null) ? altRecErrs : this.recErrs;
        return this;
    }

    /**
     * @description If this method is invoked Allocation Triggers will be enabled/disabled during processing
     *               depending on the value of disableAllocationTriggers
     * @param disableAllocationTriggers If true, Allocation triggers will be disabled during processing
     * @return Class Instance
     */
    public ALLO_AllocationsService withAllocationTriggersDisabled(Boolean disableAllocationTriggers) {
        this.disableAllocationTriggers = disableAllocationTriggers;
        return this;
    }

    /**
     * @description Controls whether Errors/Informational Messages are committed before returning to the caller
     *               or if it is assumed the caller will do this.  The caller should only set this to false if they
     *               will separately commit any pending record errors.
     *  @return Class Instance
     */
    public ALLO_AllocationsService withCommitAndClearRecordsEnabled(Boolean commitAndClearRecordsEnabled) {
        this.commitAndClearRecordErrors = commitAndClearRecordsEnabled;
        return this;
    }

    /**
     * @description Processes Opportunities and Payments, making sure the allocations are default from the parent and
     *               defaults, if appropriate, and resizes and validates allocations based on the current values of the
     *               allocations parent (Payment or Opportunity)
     * @return Class Instance
     */
    public Set<Id> processRecords(Set<Id> opportunityIds) {
        start();

        // Retrieve all Allocation and Relevant Related Data for these Opportunities
        ALLO_AllocationsWrapper allocationsWrapper = new ALLO_AllocationsRetrievalService()
                                                            .withOpportunities(opportunityIds)
                                                            .retrieveData()
                                                            .allocationsWrapper;

        // Get existing error records for this process
        this.recErrs.retrieveExistingErrorsFor(allocationsWrapper.getOpportunityAndPaymentsAsSObjects());

        // Initialize Related Services
        ALLO_AllocationsReviewService allocationsReviewService = new ALLO_AllocationsReviewService();
        ALLO_AllocationsRecalculateService allocationsRecalculateService = new ALLO_AllocationsRecalculateService();
        ALLO_AllocationsDMLService allocationsDMLService = new ALLO_AllocationsDMLService()
                                                                .withAlternateRecordErrorsLogger(recErrs);

        // Determine Opportunities that require review
        Set<Id> opportunityIdsForReview = allocationsReviewService
                                            .withAllocationsWrapper(allocationsWrapper)
                                            .evaluateAllocations();

        // Filter Allocations Wrapper to only opportunities requiring further review/processing
        allocationsWrapper.filterTo(opportunityIdsForReview);

        // Recalculate Opportunity Allocations
        allocationsRecalculateService
            .withAllocationsWrapper(allocationsWrapper)
            .processOpportunityAllocations();

        // Process Opportunity Allocations DML
        allocationsDMLService
            .withProcessExclusions(getProcessExclusionsFor(processDefinitionType.OPP_ALLOC_UPD))
            .withAllocationsWrapper(allocationsWrapper)
            .processAllocationResults();

        // Clear Pending DML
        allocationsWrapper.clearPendingDML();

        // Process Payment Allocations
        allocationsRecalculateService
            .processPaymentAllocations();

        // Process Payment Allocations DML
        allocationsDMLService
            .withProcessExclusions(getProcessExclusionsFor(processDefinitionType.PMT_ALLOC))
            .processAllocationResults();

        // Clear Pending DML
        allocationsWrapper.clearPendingDML();

        // Determine successfully processed errors
        Set<Id> successfullyProcessedOpportunityIds = determineSucessfullyProcessedRecords(
                                                        opportunityIds,
                                                        allocationsWrapper.getOpportunityIdsWithErrors());

        // Clear Retry Pending and add Retry Successful for Records that were successful
        // that have existing errors flagged for Retry
        recErrs.clearErrors(successfullyProcessedOpportunityIds, Label.alloSuccessfulRecordRetry);

        finish();

        // Return Set of Opportunity Ids that were successful to caller
        return successfullyProcessedOpportunityIds;
    }

    /**
     * @description Handles any initialization not related directly to processing, including
     *               disabling the allocation triggers, if configured to do so.
     */
    private void start() {
        if (this.disableAllocationTriggers) { // Disable Triggers Before processing
            ALLO_AllocationsUtil.disableAllocationTriggers();
        }

        if (this.recErrs == null) { // Initialize the Record Errors for this process, if not already initialized
            this.recErrs = new ERR_RecordError(this.contextType);
        }
    }

    /**
     * @description Handles any finalization not related directly to processing, including
     *               enabling the allocation triggers, and committing the errors, if configured to do so.
     */
    private void finish() {
        if (this.disableAllocationTriggers) { // Enable Triggers After processing
            ALLO_AllocationsUtil.enableAllocationTriggers();
        }

        if (this.commitAndClearRecordErrors) { // Commit all pending errors
            recErrs.processErrors();
        }
    }

    /**
     * @description Returns a set of process exclusions for a specific Process.
     * @param processDefinitionType process The process to retrieve process exclusions for
     * @return Set<processDefinitionType> Any processes that should be exluded if there are errors in the specified
     *         process
     */
    public Set<processDefinitionType> getProcessExclusionsFor(processDefinitionType process) {
        return processExclusions.get(process);
    }

    /**
     * @description Returns A set of Opportunity Ids after removing any that errored.
     * @param opportunityIds All opportunity Ids submitted for processing
     * @param opportunityIdsWithErrors opportunity Ids that errored during processing
     * @return Set<Id> opportunity Ids that did not erroring during processing
     */
    private Set<Id> determineSucessfullyProcessedRecords(Set<Id> opportunityIds, Set<Id> opportunityIdsWithErrors) {
        Set<Id> successfullyProcessedOpportunityIds = new Set<Id>(opportunityIds);

        for (Id opportunityIdWithError : opportunityIdsWithErrors) {
            successfullyProcessedOpportunityIds.remove(opportunityIdWithError);
        }
        return successfullyProcessedOpportunityIds;
    }
}