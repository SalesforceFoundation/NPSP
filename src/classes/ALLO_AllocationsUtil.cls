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
* @description Utility class to support shared functionality for Allocations
*/
public class ALLO_AllocationsUtil {
    /** @description Allocations settings. */
    public static Allocations_Settings__c ALLOCATION_SETTINGS = UTIL_CustomSettingsFacade.getAllocationsSettings();

    /** @description Used as a way to identify parts of Allocation Sync that may or may not be allowed to execute depending on earlier execution statuses */
    public enum PROCESS_DEF {
        ALL,
        OPP_AMT_UPD,
        OPP_ALLOC_UPD,
        PMT_ALLOC,
        PMT_ALLOC_ZERO_OUT,
        PMT_ALLOC_RECALC,
        PMT_ALLOC_INITIALIZE,
        PMT_ALLOC_SYNC_TO_OPP_ALLOC,
        OPP_ALLOC_SYNC_FINALIZED,
        OPP_ALLOC_SYNC_NONFINALIZED
    }

    /** @description Caches PROCESS_EXCLUSIONS */
    private static Map<PROCESS_DEF, Set<PROCESS_DEF>> PROCESS_EXCLUSIONS;
    private static Set<Id> EXCLUDED_OPPORTUNITY_RECORDTYPES;
    private static Set<String> EXCLUDED_OPPORTUNITY_TYPES;


    /** @description Manages Record Exclusions for downstream processes, so it can process as much as possible while skipping what it has to */
    public class RecordExclusions {
        private Map<Id, Set<PROCESS_DEF>> exclusionsByRecordId = new Map<Id, Set<PROCESS_DEF>>();

        /**
          * @description Adds an exclusion for the specified record.
          * @param Id recordId The Id of the record to add an Exclusion for
          * @param PROCESS_DEF exclusion The exclusion to add
          */
        public void addExclusion(Id recordId, PROCESS_DEF exclusion) {
            if (!this.exclusionsByRecordId.containsKey(recordId)) {
                this.exclusionsByRecordId.put(recordId, new Set<PROCESS_DEF> {exclusion});
            } else {
                this.exclusionsByRecordId.get(recordId).add(exclusion);
            }
        }

        /**
          * @description Adds a set of exclusions for the specified record.
          * @param Id recordId The Id of the record to add an Exclusion for
          * @param Set<PROCESS_DEF> exclusions The exclusions to add
          */
        public void addExclusions(Id recordId, Set<PROCESS_DEF> exclusions) {
            Set<PROCESS_DEF> recordExclusions = (this.exclusionsByRecordId.containsKey(recordId)) ? new Set<PROCESS_DEF>() : this.exclusionsByRecordId.get(recordId);

            for (PROCESS_DEF excl : exclusions) {
                recordExclusions.add(excl);
            }

            if (!this.exclusionsByRecordId.containsKey(recordId)) {
                this.exclusionsByRecordId.put(recordId, recordExclusions);
            }
        }

        /**
          * @description Checks to see if an exclusion is present for a record
          * @param Id recordId The Id of the record
          * @param PROCESS_DEF exclusion The exclusions to check for
          */
        public boolean hasExclusion(Id recordId, PROCESS_DEF exclusion) {
            return (this.exclusionsByRecordId.containsKey(recordId) && this.exclusionsByRecordId.get(recordId).contains(exclusion));
        }
    }

    /** @description Envelope of Changes to Allocations, along with any functional errors by Opportunity or Payment Id */
    public class AllocationResults {
        public List<Allocation__c> allocationsForInsert= new List<Allocation__c>();
        public List<Allocation__c> allocationsForUpdate= new List<Allocation__c>();
        public List<Allocation__c> allocationsForDelete= new List<Allocation__c>();
        public Map<String, List<String>> errorsByRecordId = new Map<String, List<String>>();
    }

    /**
     * @description Records Identified as needing further review and/or updates based on the state of the records, as well as any recent changes.
     *  Opportunity Data with payments, as well as the allocations for the opportunity, payment, recurring donation (if needed), and campaign (if needed)
     *  are returned if flagged for further review/processing
     */
    public class RecordsForReview {
        public List<Opportunity> opps = new List<Opportunity>();
        public Map<Id, Opportunity> oppsById = new Map<Id, Opportunity>();
        public Map<Id, Id> paymentIdsToOppIds = new Map<Id, Id>();
        public Map<Id, List<Allocation__c>> oppsAllocations = new Map<Id, List<Allocation__c>>();
        public Map<Id, List<Allocation__c>> paymentAllocations = new Map<Id, List<Allocation__c>>();
        public Map<Id, List<Allocation__c>> recurringDonationAllocations = new Map<Id, List<Allocation__c>>();
        public Map<Id, List<Allocation__c>> campaignAllocations = new Map<Id, List<Allocation__c>>();
        public ERR_RecordError recErrs;

        /**
          * @description Adds the Allocation to the appropriate map.  It picks the appropriate parent allocation
          * Map based on which lookup is populated.
          * @param alloc Allocation to add to the maps
          */
        public void addAllocationByType(Allocation__c alloc) {
            if (alloc.Opportunity__c != null) { // This is an Opportunity Allocation
                ALLO_AllocationsUtil.add(oppsAllocations, alloc.Opportunity__c, alloc);
            } else if (alloc.Payment__c != null) { // This is a Payment Allocation
                ALLO_AllocationsUtil.add(paymentAllocations, alloc.Payment__c, alloc);
            } else if (alloc.Recurring_Donation__c != null) {
                ALLO_AllocationsUtil.add(recurringDonationAllocations, alloc.Recurring_Donation__c, alloc);
            } else if (alloc.Campaign__c != null) {
                ALLO_AllocationsUtil.add(campaignAllocations, alloc.Campaign__c, alloc);
            }
        }

        /** @description Checks to see if the Opportunity requires review, based on it's payments, allocations, etc.
          * @param Opportunity opp The opportunity to check
          * @param Datetime boundary Represents a Datatime boundary.  Records newer than this boundary will require review
          * @return true if the Opportunity requires review
          */
        public boolean isOpportunityRequiresReview(Opportunity opp, Datetime boundary) {
            // If the Opportunity is excluded for Recordtype or Type it will be skipped.
            if (isExcluded(opp)) {
                return false;
            }
            // Check Opportunity & Opportunity Allocations first
            if (isRequiresReview(opp, this.oppsAllocations.get(opp.Id), boundary)) {
                return true;
            }

            // Check Payments and Payment Allocations Next
            if (opp.npe01__OppPayment__r != null) {
                for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
                    if (isRequiresReview(payment, this.paymentAllocations.get(payment.Id), boundary)) {
                        return true;
                    }
                }
            }

            //TODO: Add checks for circumstances where Campaign Allocations and/or Recurring Donation Allocations differ from Opportunity Allocations, and thus need to update the Opportunity Allocations.
            // These checks will likely be fairly complex, and involve complex comparisons between the campaign or recurring donation allocations and the Opportunity.
            // Believe this to be out of scope for GA, but will confirm.

            return false;
        }

        /** @description Return true if either the Opportunities Recordtype or Type match those
          * configured to be excluded from Allocations processing
          * @param Opportunity opp The opportunity to check
          * @return Boolean true if the Opportunity should be excluded from Allocations processing
          */
        public static Boolean isExcluded(Opportunity opp) {
            if (EXCLUDED_OPPORTUNITY_RECORDTYPES == null || EXCLUDED_OPPORTUNITY_TYPES == null) {
                EXCLUDED_OPPORTUNITY_RECORDTYPES = getExcludedOpportunityRecordtypes();
                EXCLUDED_OPPORTUNITY_TYPES = getExcludedOpportunityTypes();
            }

            return (EXCLUDED_OPPORTUNITY_RECORDTYPES.contains(opp.RecordtypeId) || EXCLUDED_OPPORTUNITY_TYPE.contains(opp.Type));
        }

        /** @description Initialize errors for Process using the records flagged for review.  It will retrieve any
          * existing errors so we can update them if more errors for that record and process.
          * @param String processName The processName/context the record errors are recorded under
          */
        public void initializeErrors(String processName) {
            // Initialize the Record Errors
            this.recErrs = new ERR_RecordError(processName);

            // Build SObjects List to retrieve existing records
            List<SObject> sObjs = new List<SObject>();
            for (Opportunity opp : this.oppsById.values()) {
                sObjs.add(opp);
                for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
                    sObjs.add(payment);
                }
            }

            // Retrieve any errors already in the System
            this.recErrs.retrieveExistingErrorsFor(sObjs);
        }

    }

    /**
     * @description Returns a list of configuration problems, if any.  If the List is empty, there are no configuration problems.
     * @return List<String> List of configuration problems, if any
     */
    public static List<String> validatePaymentAllocationsConfiguration() {
        List<String> problems = new List<String>();
        if (!ALLOCATION_SETTINGS.Payment_Allocations_Enabled__c) {
            problems.add(System.Label.alloPaymentNotEnabled);
        }
        if (!ALLOCATION_SETTINGS.Default_Allocations_Enabled__c) {
            problems.add(System.Label.alloDefaultNotEnabled);
        }

        if (ALLOCATION_SETTINGS.Default__c == null) {
            problems.add(System.Label.alloDefaultGAUMissing);
        } else {
            List<General_Accounting_Unit__c> defaultGAU = [select Id, Active__c, Name from General_Accounting_Unit__c where Id = :ALLOCATION_SETTINGS.Default__c];
            if (defaultGAU.size() < 1) {
                problems.add(System.Label.alloDefaultGAUDoesNotExist);
            } else if (!defaultGAU[0].Active__c) {
                problems.add(System.Label.alloDefaultGAUNotActive.replace('{0}', defaultGAU[0].Name));
            }
        }

        return problems;
    }

    /**
     * description Returns a populated RecordsForReview structure for the set of Opportunity Ids provided, and the boundary Datetime.  The
     * boundary is used to determine whether or not the records were updated based on whether the LastModified is >= boundary date.  If the boundary is
     * null, all records are considered to be updated.
     * @return RecordsForReview the Opportunity records requiring review and additional/processing
     */
    public static RecordsForReview determineRecordsRequiringReview(String processName, Set<Id> oppIds, Datetime boundary) {
        RecordsForReview recsForReview = new RecordsForReview();

        Map<Id, Opportunity> oppsById = retrieveOpportunities(oppIds);

        Set<Id> paymentsIds = new Set<Id>();
        Set<Id> recurringDonationIds = new Set<Id>();
        Set<Id> campaignIds = new Set<Id>();
        Map<Id, Id> rdIdsByOppIds = new Map<Id, Id>();
        Map<Id, Id> paymentIdToOppId = new Map<Id, Id>();
        Map<Id, Set<Id>> campaignIdToOppIds = new Map<Id, Set<Id>>();
        Map<Id, Set<Id>> rdIdToOppIds = new Map<Id, Set<Id>>();

        for (Opportunity opp :oppsById.values()) {
            recsForReview.oppsAllocations.put(opp.Id, new List<Allocation__c>());

            if (opp.npe03__Recurring_Donation__c != null) {
                recurringDonationIds.add(opp.npe03__Recurring_Donation__c);
                rdIdsByOppIds.put(opp.Id, opp.npe03__Recurring_Donation__c);
                add(rdIdToOppIds, opp.npe03__Recurring_Donation__c, opp.Id);
            }

            if (opp.CampaignId != null) {
                campaignIds.add(opp.CampaignId);
                add(campaignIdToOppIds, opp.CampaignId, opp.Id);
            }

            // Will only review Payments and Payment Allocations if Payment Allocations are enabled.
            // Note: This differs from the existing trigger, in that it will check and error if there are
            // Payment Allocations (inserts/updates) in the system and Payment Allocations is not enabled
            if (ALLOCATION_SETTINGS.Payment_Allocations_Enabled__c) {
                if (opp.npe01__OppPayment__r != null) {
                    for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
                        paymentsIds.add(payment.Id);
                        paymentIdToOppId.put(payment.Id, opp.Id);
                        if (!recsForReview.oppsById.containsKey(payment.npe01__Opportunity__c) &&
                            (boundary == null || payment.LastModifiedDate >= boundary)) {
                                recsForReview.oppsById.put (opp.Id, opp);
                        }
                    }
                }
            }
        }

        List<Allocation__c> allocs = retrieveAllocations(oppIds, paymentsIds, recurringDonationIds, campaignIds);
        for (Allocation__c alloc : allocs) {
            recsForReview.addAllocationByType(alloc);
        }

        // Determine which Opportunities require review and add to the oppsById map
        for (Opportunity opp :oppsById.values()) {
            if (recsForReview.isOpportunityRequiresReview(opp, boundary)) { // Add to review map
                recsForReview.oppsById.put(opp.Id, opp);
            }
        }

        // Clear out allocations, etc. not flagged for review
        removeIfNotForReview(recsForReview.recurringDonationAllocations, rdIdToOppIds, recsForReview.oppsById);
        removeIfNotForReview(recsForReview.campaignAllocations, campaignIdToOppIds, recsForReview.oppsById);
        removeIfNotForReview(recsForReview.paymentAllocations, paymentIdToOppId, recsForReview.oppsById);
        removeIfNotForReview(recsForReview.oppsAllocations, recsForReview.oppsById);

        // Build SObjects List to retrieve existing records, as well as the Payment to Opportunity Id map
        List<SObject> sObjs = new List<SObject>();
        for (Opportunity opp : recsForReview.oppsById.values()) {
            sObjs.add(opp);
            for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
                sObjs.add(payment);
                recsForReview.paymentIdsToOppIds.put (payment.Id, opp.Id);
            }
        }

        recsForReview.initializeErrors(processName);

        recsForReview.recErrs.retrieveExistingErrorsFor(sObjs);

        return recsForReview;
    }

    /**
     * @description processes Opportunities and their allocations:
     * 1) Resizes existing percentage based allocations for Amount changes
     * 2) Adds/updates/removes the default allocation if enabled, and as appropriate
     * 3) Creates allocations from parent (if no allocations are present, and record has a parent)
     * 4) If amount goes to null/0, deletes default allocations and converts existing non percentage
     *    allocations to percentage allocations if possible, and zeroes all allocations
     * 5) Records errors if allocations become invalid for the Opportunity
     * 6) Adds record exclusions if cannot proceed with downstream steps, based on record state
     * 7) Validates changes, logs errors if allocations are now invalid
     * NO DML is processed in this method.  It is instead returned to the caller for processing
     * @param Map<Id, Opportunity> opps The opportunities to process
     * @param Map<Id, List<Allocation__c>> oppsAllocations The Allocations associated with the Opportunity
     * @param Map<Id, List<Allocation__c>> campaignAllocations The Allocations associated with (parent Campaigns, if any)
     * @param Map<Id, List<Allocation__c>> recurringDonationAllocations The Allocations associated with (parent Recurring Donations, if any)
     * @param RecordExclusions recExclusions Map of records to any exclusions they might have
     * @return AllocationResults The DML to process, along with any errors identified
     */
    public static AllocationResults processOpportunityAllocations(Map<Id, Opportunity> opps, Map<Id, List<Allocation__c>> oppsAllocations, Map<Id, List<Allocation__c>> campaignAllocations, Map<Id, List<Allocation__c>> recurringDonationAllocations, RecordExclusions recExclusions) {
        AllocationResults allocResults = new AllocationResults();

        for (Opportunity opp : opps.values()) {
            Decimal amount = getAmountFor(opp);
            List<Allocation__c> oppAllocations = oppsAllocations.get(opp.Id);
            // Covers #3, part of #2
            if (amount == null || amount == 0) {
                // Convert all non percent based allocations to %, remove Default Allocation(s), zero out amounts

            } else if (oppAllocations == null || oppAllocations.isEmpty()) {
                List<Allocation__c> sourceAllocations = null;
                // No Allocations, copyFromParent or set default of no parent
                if (opp.CampaignId != null && campaignAllocations.containsKey(opp.CampaignId)) {
                    sourceAllocations = campaignAllocations.get(opp.CampaignId);
                }

                if (opp.npe03__Recurring_Donation__c != null && recurringDonationAllocations.containsKey(opp.npe03__Recurring_Donation__c)) {
                    sourceAllocations = recurringDonationAllocations.get(opp.npe03__Recurring_Donation__c);
                }

                copyAllocationsToTarget(opp, null, sourceAllocations, allocResults, false, false);
            } else { // Resize Allocations

            }
        }

        return allocResults;
    }

    /**
     * @description processes Payments and their allocations:
     * 1) Resizes existing percentage based allocations for Amount changes
     * 2) Adds/updates/removes the default allocation if enabled, and as appropriate
     * 3) Creates allocations from parent
     * 4) Clears allocations if amount goes to null/0
     * 5) Records errors if allocations become invalid for the Payment
     * 6) Adds record exclusions if cannot proceed with downstream steps, based on record state
     * 7) Validates changes, logs errors if allocations are now invalid
     * NO DML is processed in this method.  It is instead returned to the caller for processing
     * @param Map<Id, Opportunity> opps The opportunities to process
     * @param Map<Id, List<Allocation__c>> oppsAllocations The Allocations associated with the Opportunity
     * @param Map<Id, List<Allocation__c>> pmtsAllocations The Payment Allocations for the Payments associated with these Opportunities
     * @param RecordExclusions recExclusions Map of records to any exclusions they might have
     * @return AllocationResults The DML to process, along with any errors identified
     */
    public static AllocationResults processPaymentAllocations(Map<Id, Opportunity> opps, Map<Id, List<Allocation__c>> oppsAllocations, Map<Id, List<Allocation__c>> pmtsAllocations, RecordExclusions recExclusions) {
        AllocationResults allocResults = new AllocationResults();

        if (!ALLOCATION_SETTINGS.Payment_Allocations_Enabled__c) {
            // TODO: Determine whether this should throw an Exception instead...
            return allocResults;
        }

        for (Opportunity opp : opps.values()) {
            for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
                List<Allocation__c> oppAllocations = oppsAllocations.get(opp.Id);
                List<Allocation__c> pmtAllocations = pmtsAllocations.get(payment.Id);
                // Covers #3, part of #2
                Decimal sourceAmount = getAmountFor(opp);
                Decimal amount = getAmountFor(payment);
                if (amount == null || amount == 0) {
                    // Convert all non percent based allocations to %, remove Default Allocation(s), zero out amounts

                } else if (pmtAllocations == null || pmtAllocations.isEmpty()) {
                    copyAllocationsToTarget(payment, sourceAmount, oppAllocations, allocResults, true, true);
                } else { // Resize Allocations...

                }
            }
        }

        return allocResults;
    }

    /**
     * @description Processes the DML for the Allocation Results and updates the RecordsForReview and recExclusions
     * @param AllocationResults allocResults The DML to process, along with any errors identified
     * @param RecordsForReview recs the Opportunity records and associated Allocations requiring review and additional/processing
     * @param RecordExclusions recExclusions Map of records to any exclusions they might have
     */
    public static void processAllocationResults(PROCESS_DEF process, AllocationResults allocResults, RecordsForReview recs, RecordExclusions recExclusions) {

        // These are shells to pass to the ERR_RecordError addDML Errors method, so it can set the Object Type
        SObject oppObjType = new Opportunity();
        SObject paymentObjType = new npe01__OppPayment__c();
        Set<PROCESS_DEF> processExclusions = getProcessExclusionsFor(process);

        // Process Deletes
        processAllocationDeleteResults(allocResults.allocationsForDelete, recs, recExclusions, processExclusions, oppObjType, paymentObjType);

        // Process Inserts
        processAllocationInsertResults(allocResults.allocationsForInsert, recs, recExclusions, processExclusions, oppObjType, paymentObjType);

        // Process Updates
        processAllocationUpdateResults(allocResults.allocationsForUpdate, recs, recExclusions, processExclusions, oppObjType, paymentObjType);

        // Process any functional errors
        processFunctionalErrors(recs, allocResults.errorsByRecordId, oppObjType);
    }

    private static void processAllocationDeleteResults(List<Allocation__c> allocationsForDelete, RecordsForReview recs, RecordExclusions recExclusions, Set<PROCESS_DEF> processExclusions, SObject oppObjType, SObject paymentObjType) {
        List<Database.DeleteResult> deletes = null;

        // Process Deletions
        if (allocationsForDelete != null && allocationsForDelete.size() > 0) {
            deletes = Database.delete(allocationsForDelete, false);
        }

        // Handle Deletes and Update Maps and Errors
        if (deletes != null) {
            for (Integer i=0; i < deletes.size(); i++) {
                Allocation__c deletedAlloc = allocationsForDelete[i];
                Database.DeleteResult delResult = deletes[i];
                if (deletedAlloc.Opportunity__c != null) {
                    if (delResult.isSuccess()) {
                        // Removes the successfully deleted Opportunity Allocation from the Opportunity Allocations List, indexed by Opportunity Id
                        remove(recs.oppsAllocations, deletedAlloc.Opportunity__c, deletedAlloc);
                    } else {
                        recs.recErrs.addError(deletedAlloc.Opportunity__c, delResult, oppObjType);
                        recExclusions.addExclusions(deletedAlloc.Opportunity__c, processExclusions);
                    }

                } else if (deletedAlloc.Payment__c != null) {
                    if (delResult.isSuccess()) {
                        // Removes the successfully deleted Payment Allocation from the Payment Allocations List, indexed by Payment Id
                        remove(recs.paymentAllocations, deletedAlloc.Payment__c, deletedAlloc);
                    } else {
                        recs.recErrs.addError(deletedAlloc.Payment__c, delResult, paymentObjType);
                        recExclusions.addExclusions(recs.paymentIdsToOppIds.get(deletedAlloc.Payment__c), processExclusions);
                    }
                }
            }
        }
    }

    private static void processAllocationInsertResults(List<Allocation__c> allocationsForInsert, RecordsForReview recs, RecordExclusions recExclusions, Set<PROCESS_DEF> processExclusions, SObject oppObjType, SObject paymentObjType) {
        List<Database.SaveResult> inserts = null;

        // Process Inserts
        if (allocationsForInsert != null && allocationsForInsert.size() > 0) {
            inserts = Database.insert(allocationsForInsert, false);
        }

        // Handle Inserts and Update Maps and Errors
        if (inserts != null) {
            for (Integer i=0; i < inserts.size(); i++) {
                Allocation__c insertedAlloc = allocationsForInsert[i];
                Database.SaveResult insResult = inserts[i];
                if (insertedAlloc.Opportunity__c != null) {
                    if (insResult.isSuccess()) {
                        // add the successfully inserted Allocation to the Opportunity Allocations List, indexed by the Opportunity Id
                        add(recs.oppsAllocations, insertedAlloc.Opportunity__c, insertedAlloc);
                    } else {
                        recs.recErrs.addError(insertedAlloc.Opportunity__c, insResult, oppObjType);
                        recExclusions.addExclusions(insertedAlloc.Opportunity__c, processExclusions);
                    }
                } else if (insertedAlloc.Payment__c != null) {
                    if (insResult.isSuccess()) {
                        // add the successfully inserted Allocation to the Payment Allocations List, indexed by the Payment Id
                        add(recs.paymentAllocations, insertedAlloc.Payment__c, insertedAlloc);
                    } else {
                        recs.recErrs.addError(insertedAlloc.Payment__c, insResult, paymentObjType);
                        recExclusions.addExclusions(recs.paymentIdsToOppIds.get(insertedAlloc.Payment__c), processExclusions);
                    }
                }
            }
        }
    }

    private static void processAllocationUpdateResults(List<Allocation__c> allocationsForUpdate, RecordsForReview recs, RecordExclusions recExclusions, Set<PROCESS_DEF> processExclusions, SObject oppObjType, SObject paymentObjType) {
        List<Database.SaveResult> updates = null;

        // Process Updates
        if (allocationsForUpdate != null && allocationsForUpdate.size() > 0) {
            updates = Database.update(allocationsForUpdate, false);
        }

        // Handle Updates and Update Maps and Errors
        if (updates != null) {
            for (Integer i=0; i < updates.size(); i++) {
                Allocation__c updatedAlloc = allocationsForUpdate[i];
                Database.SaveResult updResult = updates[i];
                if (updatedAlloc.Opportunity__c != null) {
                    if (updResult.isSuccess()) {
                        // Replaces the Updated Allocation in the Opportunity Allocations List, indexed by Opportunity Id
                        replace(recs.oppSAllocations, updatedAlloc.Opportunity__c, updatedAlloc);
                    } else {
                        recs.recErrs.addError(updatedAlloc.Opportunity__c, updResult, oppObjType);
                        recExclusions.addExclusions(updatedAlloc.Opportunity__c, processExclusions);
                    }
                } else if (updatedAlloc.Payment__c != null) {
                    if (updResult.isSuccess()) {
                        // Replaces the Updated Allocation in the Payment Allocations List, indexed by Payment Id
                        replace(recs.paymentAllocations, updatedAlloc.Payment__c, updatedAlloc);
                    } else {
                        recs.recErrs.addError(updatedAlloc.Payment__c, updResult, paymentObjType);
                        recExclusions.addExclusions(recs.paymentIdsToOppIds.get(updatedAlloc.Payment__c), processExclusions);
                    }
                }
            }
        }
    }

    private static void processFunctionalErrors(RecordsForReview recs, Map<String, List<String>> errorsByRecordId, SObject oppObjType) {
        // Functional errors
        if (errorsByRecordId != null && !errorsByRecordId.isEmpty()) {
            for(String soId :errorsByRecordId.keySet()) {
                for (String msg :errorsByRecordId.get(soId)) {
                    recs.recErrs.addError(soId, msg, oppObjType);
                }
            }
        }
    }

    /**
     * @description Disables the following Allocation Triggers, on the Allocation, Opportunity,
     * and npe01__OppPayment__c objects: ALLO_Allocations_TDTM, ALLO_PaymentSync_TDTM (in
     * memory only)
     */
    public static void disableAllocationTriggers() {
        updateAllocationTriggersState(false);
    }

    /**
     * @description Enables the following Allocation Triggers, on the Allocation, Opportunity,
     * and npe01__OppPayment__c objects: ALLO_Allocations_TDTM, ALLO_PaymentSync_TDTM (in
     * memory only)
     */
    public static void enableAllocationTriggers() {
        updateAllocationTriggersState(true);
    }



    /**
     * @description Updates the state of the Allocation triggers in the in memory cache, enabling or disabling the
     * trigger.  The following triggers are enabled/disabled by this method: ALLO_Allocations_TDTM, ALLO_PaymentSync_TDTM.
     * @param Boolean state - If true, they are active, if false, they are inactive.
     */
    private static void updateAllocationTriggersState(Boolean state) {
        TDTM_ProcessControl.toggleTriggerState('Allocation__c', 'ALLO_Allocations_TDTM', state);
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'ALLO_Allocations_TDTM', state);
        TDTM_ProcessControl.toggleTriggerState('npe01__OppPayment__c', 'ALLO_Allocations_TDTM', state);
        TDTM_ProcessControl.toggleTriggerState('Allocation__c', 'ALLO_PaymentSync_TDTM', state);
    }

    /**
     * @description Retrieves Opportunity and Payment Data into a Map by Opportunity Id for the Set of Opportunity
     * Ids requested.
     * @param Set<Id> oppIds The set of Opportunity Ids to retrieve Opportunity and Payment information for
     * @return Map<Id, Opportunity> Map of Opportunities by Opportunity Id
     */
    private static Map<Id, Opportunity> retrieveOpportunities(Set<Id> oppIds) {
        Set<String> oppPaymentFields = new Set<String> {
            'Id',
            'Name',
            'npe01__Payment_Amount__c',
            'npe01__Payment_Date__c',
            'npe01__Scheduled_Date__c',
            'npe01__Written_Off__c',
            'npe01__Paid__c',
            'npe01__Opportunity__c',
            'LastModifiedDate',
            'RecordtypeId',
            'Type'
        };
        String paymentSubQueryString = + new UTIL_Query()
            .withSelectFields(oppPaymentFields)
            .withMultiCurrencyField()
            .withFrom('npe01__OppPayment__r')
            .build();

        Set<String> oppFields = new Set<String> {
            'Id',
            'Name',
            'Amount',
            'StageName',
            'CampaignId',
            'npe03__Recurring_Donation__c',
            'IsClosed',
            'LastModifiedDate',
            '(' + paymentSubQueryString + ')'
        };

        String oppQueryString = new UTIL_Query()
            .withSelectFields(oppFields)
            .withMultiCurrencyField()
            .withFrom(Opportunity.getSObjectType())
            .withWhere('Id IN :oppIds')
            .build();

        return new Map<Id, Opportunity>((List<Opportunity>)Database.query(oppQueryString));
    }

    /**
     * @description Retrieves and returns a list of Allocations associated the requested Opportunities, Payments, Campaigns, and
     * Recurring Donation records.  It will return Allocations associated with any of the sets.
     * @param Set<Id> oppIds The set of Opportunity Ids to retrieve Allocations for
     * @param Set<Id> paymentIds The set of Payment Ids to retrieve Allocations for
     * @param Set<Id> campaignIds The set of Campaign Ids to retrieve Allocations for
     * @param Set<Id> recurringDonationIds The set of Recurring Donation Ids to retrieve Allocations for
     * @return List<Allocation__c> All allocations associated with any of the records specified
     */
    private static List<Allocation__c> retrieveAllocations(Set<Id> oppIds, Set<Id> paymentIds, Set<Id>campaignIds, Set<Id> recurringDonationIds) {
        Set<String> allocationFields = new Set<String> {
            'Id',
            'Name',
            'Amount__c',
            'Campaign__c',
            'General_Accounting_Unit__c',
            'General_Accounting_Unit__r.Active__c',
            'General_Accounting_Unit__r.Name',
            'Opportunity__c',
            'Payment__c',
            'Payment__r.npe01__Opportunity__c',
            'Percent__c',
            'Recurring_Donation__c',
            'LastModifiedDate'
        };

        UTIL_Query allocQuery = new UTIL_Query()
            .withSelectFields(allocationFields)
            .withMultiCurrencyField()
            .withFrom(Allocation__c.getSObjectType());

        List<String> whereClauses = new List<String>();

        if (oppIds != null && !oppIds.isEmpty()) {
            whereClauses.add('Opportunity__c in :oppIds');
        }
        if (paymentIds != null && !paymentIds.isEmpty()) {
            whereClauses.add('Payment__c in :paymentIds');
        }
        if (campaignIds != null && !campaignIds.isEmpty()) {
            whereClauses.add('Campaign__c in :campaignIds');
        }
        if (recurringDonationIds != null && !recurringDonationIds.isEmpty()) {
            whereClauses.add('Recurring_Donation__c in :recurringDonationIds');
        }

        if (whereClauses.size() == 0) {
            return new List<Allocation__c>();
        } else {
            String whereClauseExpanded = String.join(whereClauses, ' OR ');

            String allocationQueryString = allocQuery.withWhere(whereClauseExpanded).build();
            return new List<Allocation__c>((List<Allocation__c>) Database.query(allocationQueryString));
        }
    }

    public static Set<Id> getExcludedOpportunityRecordtypes() {
        return (String.isNotBlank(ALLOCATION_SETTINGS.Excluded_Opp_RecTypes__c)) ? new Set<Id>((List<Id>)ALLOCATION_SETTINGS.Excluded_Opp_RecTypes__c.split(';')) : new Set<Id>();
    }

    public static Set<String> getExcludedOpportunityTypes() {
        return (String.isNotBlank(ALLOCATION_SETTINGS.Excluded_Opp_Types__c)) ? new Set<String>(ALLOCATION_SETTINGS.Excluded_Opp_Types__c.split(';')) : new Set<String>();
    }

    /**
     * @description Get a Map that indicates which processes an Opportunity should be excluded from
     * if an error occurs for that Opportunity in that process.  Recommend calling process cache map for further use.
     *@return  Map<PROCESS_DEFINITION, Set<PROCESS_DEFINITION>>
     */
    public static Map<PROCESS_DEF, Set<PROCESS_DEF>> getProcessExclusions() {

        if (PROCESS_EXCLUSIONS == null) {
            PROCESS_EXCLUSIONS = new Map<PROCESS_DEF, SET<PROCESS_DEF>> {
                PROCESS_DEF.OPP_AMT_UPD =>
                    new Set<PROCESS_DEF>    {PROCESS_DEF.OPP_ALLOC_UPD,
                                            PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC,
                                            PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED,
                                            PROCESS_DEF.OPP_ALLOC_SYNC_NONFINALIZED},
                PROCESS_DEF.OPP_ALLOC_UPD =>
                    new Set<PROCESS_DEF>    {PROCESS_DEF.PMT_ALLOC_INITIALIZE,
                                            PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC,
                                            PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED,
                                            PROCESS_DEF.OPP_ALLOC_SYNC_NONFINALIZED},
                PROCESS_DEF.PMT_ALLOC =>
                    new Set<PROCESS_DEF>    {PROCESS_DEF.ALL},
                PROCESS_DEF.PMT_ALLOC_ZERO_OUT =>
                    new Set<PROCESS_DEF>    {PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC,
                                            PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED,
                                            PROCESS_DEF.OPP_ALLOC_SYNC_NONFINALIZED},
                PROCESS_DEF.PMT_ALLOC_RECALC =>
                    new Set<PROCESS_DEF>    {PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC,
                                            PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED},
                PROCESS_DEF.PMT_ALLOC_INITIALIZE =>
                    new Set<PROCESS_DEF>    {PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC,
                                            PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED,
                                            PROCESS_DEF.OPP_ALLOC_SYNC_NONFINALIZED},
                PROCESS_DEF.PMT_ALLOC_SYNC_TO_OPP_ALLOC =>
                    new Set<PROCESS_DEF>    {PROCESS_DEF.OPP_ALLOC_SYNC_FINALIZED,
                                            PROCESS_DEF.OPP_ALLOC_SYNC_NONFINALIZED}
            };
        }

        return PROCESS_EXCLUSIONS;
    }

    private static Set<PROCESS_DEF> getProcessExclusionsFor(PROCESS_DEF process) {
        return getProcessExclusions().get(process);
    }

    /**
     * @description Adds to the childId to a Map of a Set of Child Ids, but Parent Id.  This is used to
     * Keep track of which records are affected by changes to the Parent
     * @param Map<Id, Set<Id>> parentIdToChildIds The map of Set of Child Ids, by Parent Id
     * @param Id parentId The Id of the Parent record
     * @param Id childId The Id of the Child (to the Parent) record
     */
    private static void add(Map<Id, Set<Id>> parentIdToChildIds, Id parentId, Id childId) {
        if (parentIdToChildIds.containsKey(parentId)) {
            parentIdToChildIds.get(parentId).add(childId);
        } else {
            parentIdToChildIds.put(parentId, new Set<Id> { childId });
        }
    }

    /**
     * @description Generically adds an Allocation to a List of Allocations index by Parent Id in a Map.  If the
     * Parent Id is not yet in the Map, it will create a new list with the allocation in it, and add it to the Map.
     * Otherwise, it will add the Allocation to the List of Allocations associated with that Parent record
     * @param Map<Id, List<Allocation__c>> allocsByParentId List of Allocations Indexed By the Id of the Parent
     * @param Id parentId The Id of the Parent record
     * @param Allocation__c alloc The Allocation to add to the List of Allocations associated with the specified Parent
     */
    private static void add(Map<Id, List<Allocation__c>> allocsByParentId, Id parentId, Allocation__c alloc) {
        if (allocsByParentId.containsKey(parentId)) {
            allocsByParentId.get(parentId).add(alloc);
        } else {
            allocsByParentId.put (parentId, new List<Allocation__c> { alloc });
        }
    }

    /**
     * @description Generically removes an Allocation from a List of Allocations indexex by Parent Id in a Map.  If the
     * Parent Id is not  in the Map, it will do nothing.  Otherwise, it will iterate over the List of Allocations, comparing
     * the Id of the allocation in the list to the Id of the allocation to remove.  Any that match will be removed.
     * @param Map<Id, List<Allocation__c>> allocsByParentId List of Allocations Indexed By the Id of the Parent
     * @param Id parentId The Id of the Parent record
     * @param Allocation__c alloc The Allocation to remove from the List of Allocations associated with the specified Parent
     */
    private static void remove(Map<Id, List<Allocation__c>> allocsByParentId, Id parentId, Allocation__c alloc) {
        if (alloc == null || alloc.Id == null)
            return;

        if (allocsByParentId.containsKey(parentId)) {
            List<Allocation__c> allocs = allocsByParentId.get(parentId);

            Integer idx=0;
            while (idx < allocs.size()) {
                Allocation__c allocToCheck = allocs[idx];
                if (allocToCheck.Id == alloc.Id) {
                    // Remove from List
                    allocs.remove(idx);
                } else {
                    idx++;
                }
            }
        }
    }

    /**
     * @description Generically replaces an Allocation from a List of Allocations indexex by Parent Id in a Map.  If the
     * Parent Id is not in the Map, it will do nothing.  Otherwise, it will iterate over the List of Allocations, comparing
     * the Id of the allocation in the list to the Id of the allocation to replace.  The first that matches, will be replaced.
     * If not found, it will add the Allocation to end of the list
     * @param Map<Id, List<Allocation__c>> allocsByParentId List of Allocations Indexed By the Id of the Parent
     * @param Id parentId The Id of the Parent record
     * @param Allocation__c alloc The Allocation to replace in the List of Allocations associated with the specified Parent
     */
    private static void replace(Map<Id, List<Allocation__c>> allocsByParentId, Id parentId, Allocation__c alloc) {
        if (alloc == null || alloc.Id == null)
            return;

        if (allocsByParentId.containsKey(parentId)) {
            List<Allocation__c> allocs = allocsByParentId.get(parentId);

            Integer idx=0;
            while (idx < allocs.size()) {
                Allocation__c allocToCheck = allocs[idx];
                if (allocToCheck.Id == alloc.Id) {
                    // Replace in list
                    allocs.set(idx, alloc);
                    return;
                } else {
                    idx++;
                }
            }
        }
        // Adds if it was not found in the list to replace
        add (allocsByParentId, parentId, alloc);
    }


    /**
     * @description Initially, we added all the Allocations retrieved to the Maps.  After it is determined which Opportunities
     * require further review, some of the Allocations can be removed from the allocation Maps.  This method removes ones where
     * None of the related Opportunities are flagged for update (and so the Campaign/Recurring Donation Allocations are not needed)
     * @param Map<Id, List<Allocation__c>> allocsByParentId List of Allocations Indexed By the Id of the Parent
     * @param Map<Id, Set<Id>> parentIdToOppIds Set of Opportunities, Indexed By the Parent/Related Record's Id
     * @param Map<Id, Opportunity> oppsById Map of Opportunities by Opportunity Id
     */
    private static void removeIfNotForReview(Map<Id, List<Allocation__c>> allocationsByParentId, Map<Id, Set<Id>> parentIdToOppIds, Map<Id, Opportunity> oppsById) {
        // Clear out allocations by parent id, if they are not associated with at least one Opportunity tagged for review
        for (Id parentId :parentIdToOppIds.keySet()) {
            Set<Id> oppIds = parentIdToOppIds.get(parentId);
            Set<Id> oppsForReviewIds = oppsById.keySet();
            if (!set1ContainsAnyInSet2(oppsById.keySet(), oppIds)) {
                allocationsByParentId.remove(parentId);
            }
        }
    }

    /**
     * @description Determines whether set 1 contains any of the Ids in set 2.  If at least 1 Id found in set 2 is
     * also in set 1, this method returns true.  Otherwise, it returns false.
     * @param Set<Id> set1 The first set of Ids (we will see if any members of set2 are in this set)
     * @param Set<Id> set2 The second set of Ids
     */
    private static boolean set1ContainsAnyInSet2(Set<Id> set1, Set<Id> set2) {
        for (Id id :set2) {
            if (set1.contains(id)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Removes List of Allocations from the allocationsByParentId map, if the Opportunity that is a parent of the allocation parent (E.g. The Payment) is not
     * flagged for review.
     * @param Map<Id, List<Allocation__c>> allocsByParentId List of Allocations Indexed By the Id of the Parent
     * @param Map<Id, Id> parentIdToOppId Opportunity, Indexed By the Parent/Related Record's Id
     * @param Map<Id, Opportunity> oppsById Map of Opportunities by Opportunity Id
     */
   private static void removeIfNotForReview(Map<Id, List<Allocation__c>> allocationsByParentId, Map<Id, Id> parentIdToOppId, Map<Id, Opportunity> oppsById) {
        // Clear out allocations by parent id, if they are not associated with at least one Opportunity tagged for review
        for (Id parentId :parentIdToOppId.keySet()) {
            Id oppId = parentIdToOppId.get(parentId);
            if (!oppsById.containsKey(oppId)) {
                allocationsByParentId.remove(parentId);
            }
        }
    }

    /**
     * @description Removes List of Allocations from the allocationsByParentId map, if the Opportunity that is a parent of the allocation is not
     * flagged for review.
     * @param Map<Id, List<Allocation__c>> allocsByParentId List of Allocations Indexed By the Id of the Parent
     * @param Map<Id, Opportunity> oppsById Map of Opportunities by Opportunity Id
     */
   private static void removeIfNotForReview(Map<Id, List<Allocation__c>> allocationsByParentId, Map<Id, Opportunity> oppsById) {
        // Clear out allocations by parent id, if they are not associated with at least one Opportunity tagged for review
        for (Id parentId :new Set<Id>(allocationsByParentId.keySet())) {
            if (!oppsById.containsKey(parentId)) {
                allocationsByParentId.remove(parentId);
            }
        }
    }

    /**
     * @description Determines whether a record requires review (based on it and it's associated allocations, and an associated boundary timestamp)
     * Rule 1 - If boundary is null, it will flag the record for review.  This will be null for records requiring reprocessing because they originally errored
     * Rule 2 - Record was Modified since "Boundary" timestamp. (LastModifiedDate >= Boundary)
     * Rule 3 - Default Allocations are enabled, but no allocations are present
     * Rule 4 - Allocations are present but Amount is null or 0 (Excluding ones associated with Payment)
     * Rule 5 - Any of the individual allocations are Modified since "Boundary" timestamp. (LastModifiedDate >= Boundary)
     * Rule 6 - If MultiCurrencyOrg, and Allocation CurrencyIsoCode and Parent CurrencyIsoCode are different
     * Rule 7 - Payment Allocations Only: Parent Amount is 0/null, and Allocation Amount is Not Equal to 0
     * Rule 8 - Payment Allocations Only: Parent Amount is not 0/null, but Allocation Amount equals 0
     * Rule 9 - Sum of Allocations != Parent Amount
     * Rule 10 - Parent Allocations have changed (Not Implemented)
     * @param SObject parentSObj Parent of the Allocations
     * @param List<Allocation__c> allocations Allocations associated with the parentSObj that need to be checked to see if review is required
     * @param DateTime boundary Records older than this timestamp should not be considered modified since the last execution.  If null, will reprocess
     */
    private static boolean isRequiresReview(SObject parentSObj, List<Allocation__c> allocations, DateTime boundary) {
        // if boundary is null, it is assumed it must be validated.  Likeliest circumstance is from reprocessing an error
        if (boundary == null) {
            return true;
        }

        Decimal amount = null;
        Boolean forPayment = false;

        if (parentSObj instanceOf Opportunity) {
            amount = (Decimal) parentSObj.get('Amount');
        } else if (parentSObj instanceOf npe01__OppPayment__c) {
            amount = (Decimal) parentSObj.get('npe01__Payment_Amount__c');
            forPayment = true;
        } else { // invalid object passed to method
            return false;
        }

        DateTime lastModifiedDate = (DateTime) parentSObj.get('LastModifiedDate');
        String currencyIsoCode = null;
        if (UserInfo.isMultiCurrencyOrganization()) {
            currencyIsoCode = (String) parentSObj.get('CurrencyIsoCode');
        }

        // Data Modified since last execution
        if (lastModifiedDate >= boundary) {
            return true;
        }
        // If Default Allocations are enabled, Check for a non null/zero amount with no allocations.
        if (ALLOCATION_SETTINGS.Default_Allocations_Enabled__c && amount != null && amount != 0 && (allocations == null || allocations.size() == 0)) {
            return true;
        }

        // Check for a null/zero amount with allocations ( not associated with payment)
        if ((amount == null || amount == 0) && (allocations != null && allocations.size() > 0 && !forPayment)) {
            return true;
        }

        Decimal allocAmount = 0;

        // Check individual allocations next
        for (Allocation__c alloc :allocations)  {
            // Modified since last execution
            if (alloc.LastModifiedDate >= boundary) {
                return true;
            }

            allocAmount += alloc.Amount__c;

            if (UserInfo.isMultiCurrencyOrganization()) { // Only check if CurrencyIsoCode is different if Multi Currency Organization
                String alloCurrencyIsoCode = (String) alloc.get('CurrencyIsoCode');
                if (alloCurrencyIsoCode != currencyIsoCode) {
                    return true;
                }
            }

            if (forPayment) { // These checks are only for Payment Allocations
                // Amount on allocation is present that needs to be cleared.
                if ((amount == null || amount == 0) && alloc.Amount__c != 0) {
                    return true;
                }
                // Amount is blank zero, but should not be if Parent is a non null/zero amount
                if (amount != null && amount != 0 && (alloc.Amount__c == null || alloc.Amount__c == 0)) {
                    return true;
                }
            }
        }

        // Total of Allocations and Parent Amount should match
        if (amount != null && allocAmount != amount) {
            return true;
        }

        // Positive checks exhausted.
        return false;
    }

    public static void copyAllocationsToTarget(SObject targetObj, Decimal sourceAmount, List<Allocation__c> sourceAllocations, AllocationResults allocResults, boolean copyInactiveAllocations, Boolean convertToPercentages) {
        Decimal amount = getAmountFor(targetObj);

        List<Allocation__c> proposedAllocations = new List<Allocation__c>();

        if (sourceAllocations != null && sourceAllocations.size() > 0) {
            Id opportunityId = (targetObj instanceOf Opportunity) ? targetObj.Id : null;
            Id paymentId = (targetObj instanceOf npe01__OppPayment__c) ? targetObj.Id : null;

            List<Allocation__c> listAlloForInsert = new List<Allocation__c>();

            for (Allocation__c allocation : sourceAllocations.deepclone()) {
                // Only copy if Default Allocations are not Enabled or it is not for the Default Allocation
                if (!ALLOCATION_SETTINGS.Default_Allocations_Enabled__c || allocation.General_Accounting_Unit__c != ALLOCATION_SETTINGS.Default__c) {
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
                if (UserInfo.isMultiCurrencyOrganization()) {
                    if (allocation.Amount__c!=null) {
                        allocation.Amount__c = UTIL_CurrencyConversion.convertAmountUsingStandardRates(
                            (String)allocation.get('CurrencyIsoCode'),
                            (String)targetObj.get('CurrencyIsoCode'),
                            allocation.Amount__c
                                );
                    }
                    allocation.put('CurrencyIsoCode', targetObj.get('CurrencyIsoCode'));
                }

                if (allocation.Percent__c != null) {
                    allocation.Amount__c = (amount * allocation.Percent__c * .01).setScale(2);
                }

                //Calculate proportional amount for non-percentage based Payment allocations
                // convertToPercentages must be true, the Percentage null, sourceAmount cannot be null and either Default Allocations are not enabled or the allocation is not for the Default Allocation
                if (convertToPercentages && allocation.Percent__c == null & sourceAmount != null) {
                    allocation.Percent__c = allocation.Amount__c / sourceAmount * 100;
                    allocation.Amount__c = (amount * allocation.Percent__c * .01).setScale(2);
                }
                remainder -= allocation.Amount__c;
            }

            //if our remainder is not the same sign as the amount, only create percentage based Allocations
            if ((amount >= 0 && remainder < 0) || (amount < 0 && remainder > 0)) {
                remainder = amount;

                //TODO: log error: not able to create allocations. chatter post?
                for (Allocation__c allocation : listAlloForInsert) {
                    if (allocation.Percent__c != null) {
                        allocResults.allocationsForInsert.add(allocation);
                        remainder -= allocation.Amount__c;
                    }
                }

                if (ALLOCATION_SETTINGS.Default_Allocations_Enabled__c && ((amount >= 0 && remainder > 0) || (amount < 0 && remainder < 0))) {
                    Allocation__c defaultAllo = makeDefaultAllocation(targetObj, remainder);
                    proposedAllocations.add(defaultAllo);
                }

            //Create Default Allocation if needed
            } else if (ALLOCATION_SETTINGS.Default_Allocations_Enabled__c && ((amount >= 0 && remainder > 0)||(amount < 0 && remainder < 0))) {
                proposedAllocations.add(makeDefaultAllocation(targetObj, remainder));
                proposedAllocations.addAll((List<Allocation__c>)listAlloForInsert);
            //add objects to DML wrapper in all other cases (no remainder, or positive remainder without default allocations enabled)
            } else {
                proposedAllocations.addAll((List<Allocation__c>)listAlloForInsert);
            }

        //if we have no source Allocations and defaults are enabled, create them for each payment/opportunity
        } else if (ALLOCATION_SETTINGS.Default_Allocations_Enabled__c) {
                proposedAllocations.add(makeDefaultAllocation(targetObj, amount));
        }

        if (validateAllocations(amount, proposedAllocations, allocResults.errorsByRecordId)) {
            allocResults.allocationsForInsert.addAll (proposedAllocations);
        }

    }

    private static Boolean validateAllocations(Decimal parentAmount, List<Allocation__c> allocations, Map<String, List<String>> errorsByRecordId) {
        return true;
    }

    private static List<String> validateAllocation(Allocation allocation) {
        errors = new List<String>();
        // No parent, or multiple parents
        if (hasParentError(allo)) {
            errors.add(UTIL_Describe.getObjectLabel('Allocation__c') + '[' + allocation.Name__c + ']: ' + Label.alloSingleParent);
        }
        //neither an amount nor a percent is defined
        if (allo.Amount__c == null && allo.Percent__c == null) {
            errors.add(UTIL_Describe.getObjectLabel('Allocation__c') + '[' + allocation.Name__c + ']: ' + Label.alloAmountOrPercent);
        }
        //negative amount (Payments excepted)
        if (allo.Amount__c != null && allo.Amount__c < 0 && allo.Payment__c == null) {
            errors.add(UTIL_Describe.getObjectLabel('Allocation__c') + '[' + allocation.Name__c + ']: ' + Label.alloNegativeAmount);
        }
        //negative percent
        if (allo.Percent__c != null && allo.Percent__c < 0) {
            errors.add(UTIL_Describe.getObjectLabel('Allocation__c') + '[' + allocation.Name__c + ']: ' + Label.alloNegativePercent);
        }

        return errors;
    }

    public static void resizeAllocationsAsNeeded(SObject parentObj, List<Allocation__c> allocations, AllocationResults allocResults) {

        Decimal sumOfAllocations = 0;
        Decimal totalOfPercentages = 0;
        Decimal parentAmount = getAmountFor(parentObj);

        Boolean requiresUpdates = false;

        List<Allocation__c> proposedAllocations = new List<Allocation__c>();
        List<Allocation__c> proposedAllocDeletes = new List<Allocation__c>();
        List<Allocation__c> defaultAllocations = new List<Allocation__c>();
        String parentCurrencyIsoCode = (UserInfo.isMultiCurrencyOrganization()) ? (String) parentObj.get('CurrencyIsoCode') : null;
        Boolean errorsFound = false;

        for (Allocation__c allocation : allocations.deepClone(true, true, true)) {
            if (ALLOCATION_SETTINGS.Default_Allocations_Enabled__c && allocation.General_Accounting_Unit__c == ALLOCATION_SETTINGS.Default__c) {

            }

            String allocCurrencyIsoCode = (UserInfo.isMultiCurrencyOrganization()) ? (String) allocation.get('CurrencyIsoCode') : null;

            if (allocation.Percent__c != null) {
                Decimal curAllocAmount = allocation.Percent__c * 0.01 * parentAmount;

                if (allocation.Amount__c != curAllocAmount || parentCurrencyIsoCode != currencyIsoCode) {
                    allocation.Amount__c = curAllocAmount;
                    if (UserInfo.isMultiCurrencyOrganization()) {
                        allocation.put('CurrencyIsoCode', parentCurrencyIsoCode);
                    }
                    List<String> errs = validateAllocation(allocation);
                    if (errs.isNotEmpty()) {
                        errorsFound = true;
                        if (allocResults.errorsByRecordId.containsKey(parentObj.Id)) {
                            allocResults.errorsByRecordId.get(parentObj.Id).addAll(errs);
                        } else {
                            allocResults.put(parentObj.Id, errs);
                        }
                    } else {
                        proposedAllocations.add(allocations);
                    }
                }
            } else {
                // Amount requires sign update
                if ((allocation.Amount__c > 0 && parentAmount < 0) || (allocation.Amount__c < 0 && parentAmount > 0)) {
                    allocation.Amount__c = -1 * allocation.Amount__c;
                    if (UserInfo.isMultiCurrencyOrganization()) {
                        allocation.put('CurrencyIsoCode', parentCurrencyIsoCode);
                    }
                }

            }



            if (UserInfo.isMultiCurrencyOrganization()) {
                if (parentCurrencyIsoCode != (String) allocation.get('CurrencyIsoCode')) {

                }
            }

            sumOfAllocations += allocation.Amount__c;
            totalOfPercentages += allocation.Percent__c;
        }

        if (!requiresUpdates) {
            if (totalOfPercentages > 100) {

            }

        }

        if (validateAllocations(parentAmount, proposedAllocations, allocResults.errorsByRecordId)) {
            if (!proposedAllocations.isEmpty()) {
                for (Allocation__c allocation : proposedAllocations) {
                    if (allocation.Id != null) {
                        allocResults.allocationsForUpdate.add (allocation);
                    } else {
                        allocResults.allocationsForInsert.add (allocation);
                    }
                }
            }
            if (!proposedAllocDeletes.isEmpty()) {
                allocResults.allocationsForDelete.addAll (proposedAllocDeletes);
            }
        }
    }

    private static Id getOpportunityIdFor(SObject sObj) {
        if (sObj != null) {
            if (sObj instanceOf Opportunity) {
                return (Id) sObj.Id;
            }
            if (sObj instanceOf npe01__OppPayment__c) {
                return (Id) sObj.get('npe01__Opportunity__c');
            }
        }

        return null;
    }

    private static Decimal getAmountFor(SObject sObj) {
        if (sObj != null) {
            if (sObj instanceOf Opportunity) {
                return (Decimal) sObj.get('Amount');
            }
            if (sObj instanceOf npe01__OppPayment__c) {
                return (Decimal) sObj.get('npe01__Payment_Amount__c');
            }
        }

        return null;
    }

    /*******************************************************************************************************
    * @description Returns true if this allocation doesn't have exactly one parent object.
    * @param allo A GAU Allocation.
    * @return boolean Whether this allocation has a parent error.
    ********************************************************************************************************/
    public Boolean hasParentError (Allocation__c allo) {
        Integer parentCnt = 0;

        parentCnt += (allo.Payment__c != null) ? 1 : 0;
        parentCnt += (allo.Opportunity != null) ? 1 : 0;
        parentCnt += (allo.Recurring_Donation__c != null) ? 1 : 0;
        parentCnt += (allo.Campaign__c != null) ? 1 : 0;
        // Anything other than exactly 1 will return an error
        return (parentCnt != 1);
    }

    /*******************************************************************************************************
    * @description Creates a Default Allocation for the specified Opportunity/Payment.
    * @param parentSObj An Opportunity or Payment.
    * @param amount Amount of the Default Allocation
    * @return Allocation__c A Default Allocation for the amount specified
    ********************************************************************************************************/
    public static Allocation__c makeDefaultAllocation(SObject parentSObj, Decimal amount) {

        Id opportunityId = (parentSObj instanceOf Opportunity) ? parentSObj.Id : null;
        Id paymentId = (parentSObj instanceOf npe01__OppPayment__c) ? parentSObj.Id : null;

        Allocation__c defaultAllo = new Allocation__c(
            General_Accounting_Unit__c = ALLOCATION_SETTINGS.Default__c,
            Opportunity__c = opportunityId,
            Payment__c = paymentId,
            Amount__c = amount
        );

        if (UserInfo.isMultiCurrencyOrganization()) {
            defaultAllo.put('CurrencyIsoCode', parentSObj.get('CurrencyIsoCode'));
        }

        return defaultAllo;
    }


}