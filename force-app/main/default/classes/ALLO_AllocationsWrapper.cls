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
* @description Maps of Allocation and related for the specified Opportunities and Payments, including Parent
*              Allocation Data.  This will be used by the process to review, validate, and update Allocations
*/
public inherited sharing class ALLO_AllocationsWrapper {

    /** @description Opportunities By Opportunity Id */
    public Map<Id, Opportunity> oppsById {
        public get {
             if (oppsById == null) {
                 oppsById = new Map<Id, Opportunity>();
             }
             return oppsById;
        }
        private set;
    }

    /** @description Payment Id to Opportunity Id Map */
    public Map<Id, Id> paymentIdsToOppIds {
        public get {
            if (paymentIdsToOppIds == null) {
                paymentIdsToOppIds = new Map<Id, Id>();
            }
            return paymentIdsToOppIds;
        }
        private set;
    }

    /** @description Maps the Campaign Id to any Opportunity Ids in this set of Opportunities
     *               that are to be retrieved/prcoessed
     */
    public Map<Id, Set<Id>> campaignIdToOppIds {
        public get {
            if (campaignIdToOppIds == null) {
                campaignIdToOppIds = new Map<Id, Set<Id>>();
            }
            return campaignIdToOppIds;
        }
        private set;
    }

    /** @description Maps the Recurring Donation Id to any Opportunity Ids in this set of Opportunities
     *               that are to be retrieved/prcoessed
     */
    public Map<Id, Set<Id>> rdIdToOppIds {
        public get {
            if (rdIdToOppIds == null) {
                rdIdToOppIds = new Map<Id, Set<Id>>();
            }
            return rdIdToOppIds;
        }
        private set;
    }

    /** @description Maps the Opportunity Id to its related Recurring Donation Id, if any
     */
    public Map<Id, Id> oppIdToRdId {
        public get {
            if (oppIdToRdId == null) {
                oppIdToRdId = new Map<Id, Id>();
            }
            return oppIdToRdId;
        }
        private set;
    }

    /** @description Opportunity Allocations By Opportunity Id */
    public Map<Id, List<Allocation__c>> oppsAllocations {
        public get {
            if (oppsAllocations == null) {
                oppsAllocations = new Map<Id, List<Allocation__c>>();
            }
            return oppsAllocations;
        }
        public set {
            oppsAllocations = value;
        }
    }

    /** @description Payment Allocations By Payment Id */
    public Map<Id, List<Allocation__c>> paymentAllocations {
        public get {
            if (paymentAllocations == null) {
                paymentAllocations = new Map<Id, List<Allocation__c>>();
            }
            return paymentAllocations;
        }
        public set {
            paymentAllocations = value;
        }
    }

    /** @description Recurring Donation Allocations By Recurring Donation Id */
    public Map<Id, List<Allocation__c>> recurringDonationAllocations {
        public get {
            if (recurringDonationAllocations == null) {
                recurringDonationAllocations = new Map<Id, List<Allocation__c>>();
            }
            return recurringDonationAllocations;
        }
        private set;
    }

    /** @description Campaign Allocations By Campaign Id */
    public Map<Id, List<Allocation__c>> campaignAllocations {
        public get {
            if (campaignAllocations == null) {
                campaignAllocations = new Map<Id, List<Allocation__c>>();
            }
            return campaignAllocations;
        }
        private set;
    }

    /** @description Process Definition Exclusions by Opportunity Id */
    private Map<Id, Set<ALLO_AllocationsService.processDefinitionType>> exclusionsByOpportunityId {
        private get {
            if (exclusionsByOpportunityId == null) {
                exclusionsByOpportunityId = new Map<Id, Set<ALLO_AllocationsService.processDefinitionType>>();
            }
            return exclusionsByOpportunityId;
        }
        private set;
    }

    /** @description Allocations to be inserted */
    public List<Allocation__c> allocationsForInsert {
        public get {
            if (allocationsForInsert == null) {
                allocationsForInsert = new List<Allocation__c>();
            }
            return allocationsForInsert;
        }
        private set;
    }

    /** @description Allocations to be updated */
    public List<Allocation__c> allocationsForUpdate {
        public get {
            if (allocationsForUpdate == null) {
                allocationsForUpdate = new List<Allocation__c>();
            }
            return allocationsForUpdate;
        }
        private set;
    }

    /** @description Allocations to be deleted */
    public List<Allocation__c> allocationsForDelete {
        public get {
            if (allocationsForDelete == null) {
                allocationsForDelete = new List<Allocation__c>();
            }
            return allocationsForDelete;
        }
        private set;
    }

    /** @description Map of errors added by Record Id */
    public Map<Id, List<String>> errorsByRecordId {
        public get {
            if (errorsByRecordId == null) {
                errorsByRecordId = new Map<Id, List<String>>();
            }
            return errorsByRecordId;
        }
        private set;
    }

    /**
     * @description Adds the Allocation to the appropriate map.  It picks the appropriate parent allocation
     *              Map based on which lookup is populated.
     * @param alloc Allocation to add to the maps
     */
    public void addAllocationByType(Allocation__c alloc) {
        if (alloc.Opportunity__c != null) { // This is an Opportunity Allocation
            add(this.oppsAllocations, alloc.Opportunity__c, alloc);
        } else if (alloc.Payment__c != null) { // This is a Payment Allocation
            add(this.paymentAllocations, alloc.Payment__c, alloc);
        } else if (alloc.Recurring_Donation__c != null) { // Recurring Donation Allocation
            add(this.recurringDonationAllocations, alloc.Recurring_Donation__c, alloc);
        } else if (alloc.Campaign__c != null) { // Campaign Allocation
            add(this.campaignAllocations, alloc.Campaign__c, alloc);
        }
    }

    /**
     * @description Gets the Allocations for an Opportunity, if there are Opportunity Allocations present, otherwise it returns an empty allocations list
     * @param opp The Opportunity to check/retrieve Opportunity Allocations for
     * @return A list of Allocations for an Opportunity, if present, or an empty list if not
     */
    public List<Allocation__c> getOpportunityAllocationsFor(Opportunity opp) {
        return (this.oppsAllocations.containsKey(opp.Id)) ? this.oppsAllocations.get(opp.Id) : new List<Allocation__c>();
    }

    /**
     * @description Gets the Campaign Allocations for an Opportunity, if the Opportunities Campaign Lookup is populated and there are Allocations associated
     *              with that campaign, otherwise it returns an empty allocations list
     * @param opp The Opportunity to check/retrieve Parent Campaign Allocations for
     * @return A list of Allocations for an Opportunities Parent Campaign, if present, or an empty list if not
     */
    public List<Allocation__c> getCampaignAllocationsFor(Opportunity opp) {
        return (opp.CampaignId != null && this.campaignAllocations.containsKey(opp.CampaignId)) ? this.campaignAllocations.get(opp.CampaignId) : new List<Allocation__c>();
    }

    /**
     * @description Gets the Parent Recurring Donation Allocations for an Opportunity, if the Opportunities Recurring Donation Lookup is populated and there are Allocations
     *              associated with that Recurring Donation, otherwise it returns an empty allocations list
     * @param opp The Opportunity to check/retrieve Parent Recurring Donation Allocations for
     * @return A list of Allocations for an Opportunities Parent Recurring Donation, if present, or an empty list if not
     */
    public List<Allocation__c> getRecurringDonationAllocationsFor(Opportunity opp) {
        return (opp.npe03__Recurring_Donation__c != null && this.recurringDonationAllocations.containsKey(opp.npe03__Recurring_Donation__c)) ? this.recurringDonationAllocations.get(opp.npe03__Recurring_Donation__c) : new List<Allocation__c>();
    }

    /**
     * @description Gets the Payment Allocations for a Payment, if there are Payment Allocations present, otherwise it returns an empty allocations list
     * @param payment The Payment to check/retrieve Payment Allocations for
     * @return A list of Allocations for a Payment, if present, or an empty list if not
     */
    public List<Allocation__c> getPaymentAllocationsFor(npe01__OppPayment__c payment) {
        return (this.paymentAllocations.containsKey(payment.Id)) ? this.paymentAllocations.get(payment.Id) : new List<Allocation__c>();
    }

    /**
     * @description Builds list of Opportunity and Payments as a single SObjects list.  This
     *              is needed to retrieve any existing errors.
     * @return List of Opportunity and Payment records as SObjects
     */
    public List<SObject> getOpportunityAndPaymentsAsSObjects() {
        List<SObject> sObjs = new List<SObject>();
        for (Opportunity opp : this.oppsById.values()) {
            sObjs.add(opp);
            for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) {
                sObjs.add(payment);
            }
        }
        return sObjs;
    }

    /**
     * @description Removes Opportunities and Related Data not in the oppIds Set from the Wrapper's member variable maps.
     *              Typically, this is because they are no longer needed because they were determined to not require review.
     * @param Set<Id> oppIds The Opportunities for which any related data should be kept in the Maps
     */
    public void filterTo(Set<Id> oppIds) {
        filterParentAllocations(oppIds, this.recurringDonationAllocations, this.rdIdToOppIds);
        filterParentAllocations(oppIds, this.campaignAllocations, this.campaignIdToOppIds);
        filterPaymentAllocations(oppIds);
        filterOpportunityAllocations(oppIds);
    }

    /**
     * @description Removes Parent Allocations Lists for any Parents which are no longer required.
     *              Also removes from the parentId to OppIds map.
     * @param Set<Id> oppIds The Opportunities for which any related data should be kept in the Maps
     * @param allocationsByParentId The Allocations Lists By Parent, which should be filtered to only data needed for
     *        the remaining Opportunities
     * @param parentIdToOppIds Maps the Parent Ids to Any Opportunities it is related to
     */
    private void filterParentAllocations(Set<Id> oppIds, Map<Id, List<Allocation__c>> allocationsByParentId, Map<Id, Set<Id>> parentIdToOppIds) {
        Set<Id> removedParentIds = new Set<Id>();
        // Clear out allocations by parent id, if they are not associated with at least one Opportunity tagged for review
        for (Id parentId :parentIdToOppIds.keySet()) {
            Set<Id> oppIdsForParent = parentIdToOppIds.get(parentId);

            if (!set1ContainsAnyInSet2(oppIds, oppIdsForParent)) {
                allocationsByParentId.remove(parentId);
                removedParentIds.add(parentId);
            }
        }
        // Cleanup parentIdToOppIds Map
        for (Id removedParentId : removedParentIds) {
            parentIdToOppIds.remove(removedParentId);
        }
    }

    /**
     * @description Removes Payment Allocations Lists for any Payments which are no longer required.
     *              Also removes from the paymentIdsToOppIds map.
     * @param Set<Id> oppIds The Opportunities for which any related data should be kept in the Maps
     */
    private void filterPaymentAllocations(Set<Id> oppIds) {
        Set<Id> removedPaymentIds = new Set<Id>();

        // Clear out allocations by payment id, if they are not associated with at least one Opportunity tagged for review
        for (Id paymentId :this.paymentIdsToOppIds.keySet()) {
            Id oppId = this.paymentIdsToOppIds.get(paymentId);
            // If the Opportunity associated with the payment is not present, remove its allocations and add to cleanup set
            if (!oppIds.contains(oppId)) {
                this.paymentallocations.remove(paymentId);
                removedPaymentIds.add(paymentId);
            }
        }
        // Cleanup paymentIdsToOppIds Map
        for (Id removedPaymentId : removedPaymentIds) {
            this.paymentIdsToOppIds.remove(removedPaymentId);
        }
    }

    /**
     * @description Removes Opportunity Allocations Lists for any Opportunities which are no longer required.
     *              Also removes from the OppsById map.
     * @param Set<Id> oppIds The Opportunities for which any related data should be kept in the Maps
     */
    private void filterOpportunityAllocations(Set<Id> oppIds) {
        Set<Id> removedOppIds = new Set<Id>();
        for (Id oppId : this.oppsById.keySet()) {
            if (!oppIds.contains(oppId)) {
                this.oppsAllocations.remove(oppId);
                removedOppIds.add(oppId);
            }
        }
        for (Id removedOppId : removedOppIds) {
            this.oppsById.remove(removedOppId);
        }
    }

    /**
     * @description Determines whether set 1 contains any of the Ids in set 2.  If at least 1 Id found in
     *              set 2 is also in set 1, this method returns true.  Otherwise, it returns false.
     * @param Set<Id> set1 The first set of Ids (we will see if any members of set2 are in this set)
     * @param Set<Id> set2 The second set of Ids
     */
    @testVisible private Boolean set1ContainsAnyInSet2(Set<Id> set1, Set<Id> set2) {
        for (Id id :set2) {
            if (set1.contains(id)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Generically adds an Allocation to a List of Allocations index by Parent Id in a Map.
     *              If the Parent Id is not yet in the Map, it will create a new list with the allocation
     *              in it, and add it to the Map.  Otherwise, it will add the Allocation to the List of
     *              Allocations associated with that Parent record
     * @param Map<Id, List<Allocation__c>> allocsByParentId List of Allocations Indexed By the Id of the
     *        Parent
     * @param Id parentId The Id of the Parent record
     * @param Allocation__c alloc The Allocation to add to the List of Allocations associated with the
     *        specified Parent
     */
    @testVisible private void add(Map<Id, List<Allocation__c>> allocsByParentId, Id parentId, Allocation__c alloc) {
        if (allocsByParentId.containsKey(parentId)) {
            allocsByParentId.get(parentId).add(alloc);
        } else {
            allocsByParentId.put (parentId, new List<Allocation__c> { alloc });
        }
    }

    /**
     * @description Adds an Allocation to either the Opportunity or Payment List of Allocations,
     *              depending on which it is associated with.  This will be called after a DML
     *              Insertion to add Allocations that should be in the Maps now
     * @param alloc The allocation to remove from either the Opportunity or Payment Allocations Map
     */
    public void addAllocation(Allocation__c alloc) {
        // Determine Parent Id, and which Map to use
        Id parentId = (alloc.Opportunity__c != null) ? alloc.Opportunity__c : alloc.Payment__c;
        Map<Id, List<Allocation__c>> allocsByParentId = (alloc.Opportunity__c != null) ? oppsAllocations : paymentAllocations;

        if (allocsByParentId.containsKey(parentId)) {
            allocsByParentId.get(parentId).add(alloc);
        } else {
            allocsByParentId.put (parentId, new List<Allocation__c> { alloc });
        }
    }

    /**
     * @description Removes Allocation from either Opportunity or Payment List of Allocations, depending on which it is
     *              associated with.  This will be called after a DML Deletion to remove Allocations
     *              that should no longer be in the wrapper because they were deleted
     * @param alloc The allocation to remove from either the Opportunity or Payment Allocations Map
     */
    public void removeAllocation(Allocation__c alloc) {
        // Determine Parent Id, and which Map to use
        Id parentId = (alloc.Opportunity__c != null) ? alloc.Opportunity__c : alloc.Payment__c;
        Map<Id, List<Allocation__c>> allocsByParentId = (alloc.Opportunity__c != null) ? oppsAllocations : paymentAllocations;

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
     * @description Replaces an Allocation from eiter Opportunity or Payment Allocations, depending on which it
     *              is associated with.  It will iterate over the List of Allocations, comparing the Id of the
     *              allocation in the list to the Id of the allocation to replace.  The first that matches,
     *              will be replaced.  If not found, it will add the Allocation to end of the list
     * @param Allocation__c alloc The Allocation to replace in the List of Allocations associated with the
     *        specified Parent
     */
    public void replaceAllocation(Allocation__c alloc) {
        if (alloc == null || alloc.Id == null)
            return;

        // Determine Parent Id, and which Map to use
        Id parentId = (alloc.Opportunity__c != null) ? alloc.Opportunity__c : alloc.Payment__c;
        Map<Id, List<Allocation__c>> allocsByParentId = (alloc.Opportunity__c != null) ? oppsAllocations : paymentAllocations;

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
     * @description Adds a set of exclusions for the specified record.
     * @param opportunityId The Id of the Opportunity to add an Exclusion for
     * @param exclusions The exclusions to add
     */
    public void addExclusions(Id opportunityId, Set<ALLO_AllocationsService.processDefinitionType> exclusions) {
        Set<ALLO_AllocationsService.processDefinitionType> recordExclusions = (this.exclusionsByOpportunityId.containsKey(opportunityId)) ? this.exclusionsByOpportunityId.get(opportunityId) : new Set<ALLO_AllocationsService.processDefinitionType>();

        for (ALLO_AllocationsService.processDefinitionType excl : exclusions) {
            recordExclusions.add(excl);
        }

        if (!this.exclusionsByOpportunityId.containsKey(opportunityId)) {
            this.exclusionsByOpportunityId.put(opportunityId, recordExclusions);
        }
    }

    /**
     * @description Checks to see if an exclusion is present for a record, or if record is excluded from
     *              all processing
     * @param opportunityId The Id of the record
     * @param ALLO_AllocationsService.processDefinitionType exclusion The exclusions to check for
     * @return Boolean True if the exclusion if present for that recordId
     */
    public Boolean hasExclusion(Id opportunityId, ALLO_AllocationsService.processDefinitionType exclusion) {
        Set<ALLO_AllocationsService.processDefinitionType> recordExclusions = (this.exclusionsByOpportunityId.containsKey(opportunityId)) ? this.exclusionsByOpportunityId.get(opportunityId) : null;
        return (recordExclusions != null && (recordExclusions.contains(exclusion) || recordExclusions.contains(ALLO_AllocationsService.processDefinitionType.ALL)));
    }

    /**
     * @description Checks to see if no exclusions are present for a record
     * @param Id opportunityId The Id of the record
     * @return Boolean True if there are no exclusions present for that opportunityId
     */
    public Boolean hasNoExclusions(id opportunityId) {
        Set<ALLO_AllocationsService.processDefinitionType> recordExclusions = (this.exclusionsByOpportunityId.containsKey(opportunityId)) ? this.exclusionsByOpportunityId.get(opportunityId) : null;
        return (recordExclusions == null || recordExclusions.isEmpty());
    }

    /**
     * @description Adds a record Error associated with this SObject
     * @param sObj The sObj to add the error for
     * @param message The message to add for this record
     */
    public void addRecordError(SObject sObj, String message) {
        addError (ALLO_AllocationsUtil.getOpportunityIdFor(sObj), String.format(Label.alloPaymentAllocationBatchRecordError,
                             new List<String> { ALLO_AllocationsUtil.getLabelFor(sObj), (String) sObj.Id, message}));
    }

    /**
     * @description Adds an error to the list of errors for a specific record Id.  If no errors are
     *              present for that record Id, a new error list is created
     * @param Id recordId The Id of the record
     * @param String error to add
     */
    public void addError(Id recordId, String error) {
        if (this.errorsByRecordId.containsKey(recordId)) {
            this.errorsByRecordId.get(recordId).add(error);
        } else {
            this.errorsByRecordId.put(recordId, new List<String> { error });
        }
    }

    /**
     * @description Adds a list of errors to the existing list of errors for a specific record Id.  If no
     *              errors are present for that record Id, the list is inserted as is.
     * @param Id recordId The Id of the record
     * @param List<String> errors to add
     */
    public void addAllErrors(String recordId, List<String> errors) {
        if (this.errorsByRecordId.containsKey(recordId)) {
            this.errorsByRecordId.get(recordId).addAll(errors);
        } else {
            this.errorsByRecordId.put(recordId, errors);
        }
    }

    /**
     * @description Clears the ErrorsByRecordId Map
     */
    public void clearErrors() {
        this.errorsByRecordId = new Map<Id, List<String>>();
    }

    /**
     * @description Clears the Allocations DML Lists
     */
    public void clearPendingDML() {
        this.allocationsForDelete = new List<Allocation__c>();
        this.allocationsForInsert = new List<Allocation__c>();
        this.allocationsForUpdate = new List<Allocation__c>();
    }

    /**
     * @description Returns a Set of Opportunities that failed to be processed properly,
     *              or were identified as having an Allocation issue.
     * @return Set<Id> Opportunity Ids of Records Associated with Errors/Issues
     */
    public Set<Id> getOpportunityIdsWithErrors() {
        return new Set<Id>(exclusionsByOpportunityId.keySet());
    }
}