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
* @description Utility class to handle DML for Allocations
*/
public inherited sharing class ALLO_AllocationsDMLService {
    /** @description The number of times it will retry the set of Database operations, after first removing any with errors. */
    @testVisible private static Integer numberOfDatabaseRetries = 1;

    /** @description Set of Opportunity or Payment Ids with Allocations DML errors during processing */
    @testVisible private Set<Id> recordIdsWithErrors {
        private get {
            if (recordIdsWithErrors == null) {
                recordIdsWithErrors = new Set<Id>();
            }
            return recordIdsWithErrors;
        }
        private set;
    }

    /** @description Set of All Opportunity or Payment Ids with Allocations DML */
    @testVisible private Set<Id> allRecordIdsWithDML {
        private get {
            if (allRecordIdsWithDML == null) {
                allRecordIdsWithDML = new Set<Id>();
            }
            return allRecordIdsWithDML;
        }
        private set;
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

    /** @description Opportunity SObject used just for error logging */
    private SObject opportunitySObjectType {
        private get {
            if (opportunitySObjectType == null) {
                opportunitySObjectType = new Opportunity();
            }
            return opportunitySObjectType;
        }
        private set;
    }

    /** @description Payment SObject used just for error logging */
    private SObject paymentSObjectType {
        private get {
            if (paymentSObjectType == null) {
                paymentSObjectType = new npe01__OppPayment__c();
            }
            return paymentSObjectType;
        }
        private set;
    }

    /** @description Allocations Wrapper Allocations Work */
    @testVisible private ALLO_AllocationsWrapper allocationsWrapper;

    /** @description Exclusions that should be added if there are errors */
    @testVisible private Set<ALLO_AllocationsService.processDefinitionType> processExclusions {
        private get {
            if (processExclusions == null) {
                processExclusions = new Set<ALLO_AllocationsService.processDefinitionType>();
            }
            return processExclusions;
        }
        private set;
    }

    /** @description Makes sure recErrs is initialized, if one was not passed using the default Allocation
     *               Context Type */
    private ERR_RecordError getErrorLogger() {
        if (this.recErrs == null) {
            this.recErrs = new ERR_RecordError(this.contextType);
        }

        return this.recErrs;
    }

    /**
     * @description provides a non default record errors instance to use when logging errors
     * @param altRecErrs Already initialized instance of the ERR_RecordError class
     * @return Class Instance
     */
    public ALLO_AllocationsDMLService withAlternateRecordErrorsLogger(ERR_RecordError altRecErrs) {
        this.recErrs = (altRecErrs != null) ? altRecErrs : this.recErrs;
        return this;
    }

    /**
     * @description Provides an allocations wrapper to the class for processing
     * @param allocationsWrapper Allocation Wrapper with DML to be processed
     * @return Class Instance
     */
    public ALLO_AllocationsDMLService withAllocationsWrapper(ALLO_AllocationsWrapper allocationsWrapper) {
        this.allocationsWrapper = allocationsWrapper;
        return this;
    }

    /**
     * @description Passes a Set of Processes that should be excluded if errors occur
     * @param processExclusions the Set of processDefinitionTypes to be added as record exclusions if there are
     *        DML Errors
     * @return Class Instance
     */
    public ALLO_AllocationsDMLService withProcessExclusions(Set<ALLO_AllocationsService.processDefinitionType> processExclusions) {
        this.processExclusions = processExclusions;
        return this;
    }

    /**
     * @description Processes the DML for the Allocation Results and updates the Allocations Wrapper with the results,
     *              adding exclusions and errors as needed
     **/
    public void processAllocationResults() {
        Boolean dmlErrors = false;
        Integer dmlIteration = 0;

        // Clone existing allocation lists in case they need to be restored when rolling back
        Map<Id, List<Allocation__c>> backupOppsAllocations;
        Map<Id, List<Allocation__c>> backupPaymentAllocations;

        Savepoint sp = Database.setSavepoint();

        do {
            // Clone existing allocation lists in case they need to be restored when rolling back
            backupOppsAllocations = allocationsWrapper.oppsAllocations.clone();
            backupPaymentAllocations = allocationsWrapper.paymentAllocations.clone();

            dmlIteration++;
            dmlErrors = false;

            // Process Deletes
            dmlErrors = (dmlErrors || processAllocationDeleteResults());

            // Process Inserts
            dmlErrors = (dmlErrors || processAllocationInsertResults());

            // Process Updates
            dmlErrors = (dmlErrors || processAllocationUpdateResults());

            if (dmLErrors) { // Need to remove errored DML, revert changes and get ready to retry
                handleDMLErrors(sp, backupOppsAllocations, backupPaymentAllocations);
            }
        } while (dmlIteration <= numberOfDatabaseRetries && dmlErrors);

        if (dmlErrors) { // Need to log errors for all Opportunities that don't already have errors since retries exhausted
            addErrorsWhenRetriesExceeded();
        }

        // Convert any errors that were not explicitly DML errors here to RecordErrors
        processFunctionalErrors();
    }

    /**
     * @description Rolls back to a SavePoint restores Allocations to original lists prior to DML execution,
     *              removes allocations associated with a parent whose allocations error, and removes the ID
     *              and timestamps form the DML Insert List.  This is required to be able to retry without the
     *              records that errored in a consistent state.
     * @param sp Savepoint to roll back to
     * @param backupOppsAllocations clone of the Opportunity Allocations Map from the ALLO_AllocationsWrapper to
     *        restore oppsAllocations to
     * @param backupPmtAllocations clone of the Payment Allocations Map from the ALLO_AllocationsWrapper to
     *        restore paymentAllocations to
     **/
    private void handleDMLErrors(Savepoint sp, Map<Id, List<Allocation__c>> backupOppsAllocations, Map<Id, List<Allocation__c>> backupPaymentAllocations) {
        // Rollback to a consistent state && clean the allocationResults for the next try of the loop
        // Removing Allocations associated with Errored records via parentRecordId in errors Set
        // Errors will remain to be logged
        Database.rollback(sp);

        // Revert Maps of existing Allocations to versions prior to DML Operation
        allocationsWrapper.oppsAllocations = backupOppsAllocations;
        allocationsWrapper.paymentAllocations = backupPaymentAllocations;

        // Removes and Allocations associated with Parents with one or more DML Errors
        removeAllDMLAssociatedWithErroredRecords();

        // Insert DML Lists need special handling to clear id and read only timestamp fields from prior execution
        removeIdAndTimestampsFromDMLList(allocationsWrapper.allocationsForInsert);
    }

    /**
     * @description Clears any private member variables of data that needs to be reset between processing
     */
    public void reset() {
        recordIdsWithErrors = new Set<Id>();
        allRecordIdsWithDML = new Set<Id>();
        allocationsWrapper = null;
        processExclusions = null;
    }

    /**
     * @description Processes Allocation deletions, recording DML errors as Record Errors and adding
     * Record Exclusions for ones that errored.  The ALLO_AllocationsWrapper Allocations Maps are updated removing
     * Allocations from the Maps for successful DML.
     * @return Boolean, true if there were any DML errors
     */
    @testVisible private Boolean processAllocationDeleteResults() {
        List<Database.DeleteResult> deletes = null;
        boolean dmlErrorsPresent = false;

        // Nothing to do, return
        if (allocationsWrapper.allocationsForDelete == null || allocationsWrapper.allocationsForDelete.isEmpty()) {
            return dmlErrorsPresent;
        }

        // Process Deletions
        deletes = Database.delete(allocationsWrapper.allocationsForDelete, false);

        // Handle Deletes and Update Maps and Errors
        for (Integer i=0; i < deletes.size(); i++) {
            Allocation__c deletedAlloc = allocationsWrapper.allocationsForDelete[i];
            Database.DeleteResult delResult = deletes[i];
            Id parentRecordId = (deletedAlloc.Opportunity__c != null) ? deletedAlloc.Opportunity__c : deletedAlloc.Payment__c;
            allRecordIdsWithDML.add(parentRecordId);

            if (delResult.isSuccess()) {
                // Removes the successfully deleted Allocation from the appropriate Allocations List
                allocationsWrapper.removeAllocation(deletedAlloc);
            } else {
                dmlErrorsPresent = true;
                handleError(parentRecordId, deletedAlloc, delResult);
            }
        }

        return dmlErrorsPresent;
    }

    /**
     * @description Processes Allocation inserts, recording DML errors as Record Errors and adding
     * Record Exclusions for ones that errored.  The ALLO_AllocationsWrapper Allocations Maps are updated adding all
     * successful DML.
     * @return Boolean true, if there were any dml errors
     */
    @testVisible private Boolean processAllocationInsertResults() {
        List<Database.SaveResult> inserts = null;
        Boolean dmlErrorsPresent = false;

        // Nothing to do, return
        if (allocationsWrapper.allocationsForInsert == null || allocationsWrapper.allocationsForInsert.isEmpty()) {
            return dmlErrorsPresent;
        }

        // Process Inserts
        inserts = Database.insert(allocationsWrapper.allocationsForInsert, false);

        // Handle Inserts and Update Maps and Errors
        for (Integer i=0; i < inserts.size(); i++) {
            Allocation__c insertedAlloc = allocationsWrapper.allocationsForInsert[i];
            Database.SaveResult insResult = inserts[i];
            Id parentRecordId = (insertedAlloc.Opportunity__c != null) ? insertedAlloc.Opportunity__c : insertedAlloc.Payment__c;
            allRecordIdsWithDML.add(parentRecordId);
            if (insResult.isSuccess()) {
                // add the successfully inserted Allocation to the Opportunity Allocations List, indexed by the Opportunity Id
                allocationsWrapper.addAllocation(insertedAlloc);
            } else {
                    dmlErrorsPresent = true;
                    handleError(parentRecordId, insertedAlloc, insResult);
            }
        }

        return dmlErrorsPresent;
    }

    /**
     * @description Processes Allocation updates, recording DML errors as Record Errors and adding
     * Record Exclusions for ones that errored.  The ALLO_AllocationsWrapper Allocations Maps are updated for all
     * successful DML.
     * @return Boolean true, if there were any dml errors
     */
    @testVisible private Boolean processAllocationUpdateResults() {
        List<Database.SaveResult> updates = null;
        Boolean dmlErrorsPresent = false;

        // Nothing to do, return
        if (allocationsWrapper.allocationsForUpdate == null || allocationsWrapper.allocationsForUpdate.isEmpty()) {
            return dmlErrorsPresent;
        }

        // Process Updates
        updates = Database.update(allocationsWrapper.allocationsForUpdate, false);

        // Handle Updates and Update Maps and Errors
        for (Integer i=0; i < updates.size(); i++) {
            Allocation__c updatedAlloc = allocationsWrapper.allocationsForUpdate[i];
            Database.SaveResult updResult = updates[i];
            Id parentRecordId = (updatedAlloc.Opportunity__c != null) ? updatedAlloc.Opportunity__c : updatedAlloc.Payment__c;
            allRecordIdsWithDML.add(parentRecordId);

            if (updResult.isSuccess()) {
                // Replaces the Updated Allocation in the Opportunity Allocations List, indexed by Opportunity Id
                allocationsWrapper.replaceAllocation(updatedAlloc);
            } else {
                dmlErrorsPresent = true;
                handleError(parentRecordId, updatedAlloc, updResult);
            }
        }

        return dmlErrorsPresent;
    }

    /**
     * @description Handles DML Errors, add appropriate exclusions, an Error via the ERR_RecordError functionality,
     *              and recording the recordId in the set of Record Ids with Errors to be able to filter out
     *              Allocations with by Parent Id's with Allocation's that errored
     * @param parentRecordId Id of the Parent Record of the Allocation
     * @param the Allocation associated with the error
     * @param dmlResult associated with the Allocation that errored
     */
    private void handleError(Id parentRecordId, Allocation__c alloc, Object dmlResult) {
        Id opportunityId = (alloc.Opportunity__c != null) ? alloc.Opportunity__c : allocationsWrapper.paymentIdsToOppIds.get(alloc.Payment__c);
        SObject parentSObjectType = (alloc.Opportunity__c != null) ? opportunitySObjectType : paymentSObjectType;

        getErrorLogger().addError(parentRecordId, dmlResult, parentSObjectType);
        allocationsWrapper.addExclusions(opportunityId, processExclusions);
        recordIdsWithErrors.add(parentRecordId);
    }

    /**
     * @description Processes functional errors and adds record exclusions, for the errors that occurred.
     */
    private void processFunctionalErrors() {
        // Functional errors
        if (allocationsWrapper.errorsByRecordId != null && !allocationsWrapper.errorsByRecordId.isEmpty()) {
            for(Id soId :allocationsWrapper.errorsByRecordId.keySet()) {
                for (String msg :allocationsWrapper.errorsByRecordId.get(soId)) {
                    Boolean isOpportunityId = allocationsWrapper.oppsById.containsKey(soId);
                    SObject parentSObjectType = (isOpportunityId) ? opportunitySObjectType : paymentSObjectType;
                    getErrorLogger().addError(soId, msg, parentSObjectType);
                    Id exclusionId = isOpportunityId ? soId : allocationsWrapper.paymentIdsToOppIds.get(soId);
                    allocationsWrapper.addExclusions(exclusionId, processExclusions);
                }
            }
            allocationsWrapper.clearErrors();
        }
    }

    /**
     * @description Removes DML associated with Parent Records whose related allocations DML failed so the
     *              DML can be retried without these records
     */
    private void removeAllDMLAssociatedWithErroredRecords() {
        removeAllocationsAssociatedWithErroredRecordsFromDMLList(allocationsWrapper.allocationsForDelete);
        removeAllocationsAssociatedWithErroredRecordsFromDMLList(allocationsWrapper.allocationsForInsert);
        removeAllocationsAssociatedWithErroredRecordsFromDMLList(allocationsWrapper.allocationsForUpdate);
    }

    /**
     * @description Removes DML associated with Parent Records whose related allocations DML failed so the
     *              DML can be retried without these records
     * @param List of Allocations to filter/remove Allocations associated with Errors from
     */
    private void removeAllocationsAssociatedWithErroredRecordsFromDMLList(List<Allocation__c> allocs) {
        Integer idx = 0;
        while (idx < allocs.size()) {
            Allocation__c alloc = allocs[idx];
            Id allocParentRecordId = (alloc.Opportunity__c != null) ? alloc.Opportunity__c : alloc.Payment__c;

            if (allocParentRecordId != null && this.recordIdsWithErrors.contains(allocParentRecordId)) {
                // If it is in the errors set, remove it
                allocs.remove(idx);
            } else { // Move to next element
                idx++;
            }
        }
    }

    /**
     * @description Removes The ID and Readonly timestamp fields form the Allocations List
     * @param List of Allocations to process/update
     */
    private void removeIdAndTimestampsFromDMLList(List<Allocation__c> allocs) {
        Integer idx = 0;
        while (idx < allocs.size()) {
            Allocation__c alloc = allocs[idx].clone(false, true, false, false);
            allocs.set(idx, alloc);
            idx++;
        }
    }

    /**
     * @description If retries are exceeded, errors are added for all Opportunities pending DML insert/update
     */
    private void addErrorsWhenRetriesExceeded() {
        for (Id oppId :allocationsWrapper.oppsById.keySet()) {
            if (!allocationsWrapper.errorsByRecordId.containsKey(oppId)) {
                //add general retries exceeded error
                allocationsWrapper.addRecordError(new Opportunity(Id = oppId), Label.alloPaymentAllocationBatchRetriesExceeded);
            }
        }
    }
}