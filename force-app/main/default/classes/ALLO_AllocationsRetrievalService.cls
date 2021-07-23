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
* @description Retrieves and builds the required maps of Allocation Data and related information, including Opportunity and Payment Information
*/
public inherited sharing class ALLO_AllocationsRetrievalService {
    /** @description The Set of Opportunities to retrieve */
    private Set<Id> oppIds;

    /** @description Allocations Wrapper */
    public ALLO_AllocationsWrapper allocationsWrapper {
        public get {
            if (allocationsWrapper == null) {
                allocationsWrapper = new ALLO_AllocationsWrapper();
            }
            return allocationsWrapper;
        }
        private set;
    }

    /** @description Caches excluded Opportunity Recordtype Ids */
    public static Set<Id> excludedOpportunityRecordtypes {
        public get {
            if (excludedOpportunityRecordtypes == null) {
                excludedOpportunityRecordtypes = (String.isNotBlank(UTIL_CustomSettingsFacade.getAllocationsSettings().Excluded_Opp_RecTypes__c)) ? new Set<Id>((List<Id>)UTIL_CustomSettingsFacade.getAllocationsSettings().Excluded_Opp_RecTypes__c.split(';')) : new Set<Id>();
            }
            return excludedOpportunityRecordtypes;
        }
        private set;
    }

    /** @description Caches excluded Opportunity Type values */
    public static Set<String> excludedOpportunityTypes {
        public get {
            if (excludedOpportunityTypes == null) {
                excludedOpportunityTypes = (String.isNotBlank(UTIL_CustomSettingsFacade.getAllocationsSettings().Excluded_Opp_Types__c)) ? new Set<String>(UTIL_CustomSettingsFacade.getAllocationsSettings().Excluded_Opp_Types__c.split(';')) : new Set<String>();
            }
            return excludedOpportunityTypes;
        }
        private set;
    }

    /**
     * @description The set of Opportunities to be evaluated
     * @param oppIds A set of Opportunity Ids
     * @return Class Instance
    */
    public ALLO_AllocationsRetrievalService withOpportunities(Set<Id> oppIds) {
        this.oppIds = oppIds;
        return this;
    }

    /**
     * @description Retrieves All Allocations and Related Data necessary to review and if necessary update the
     *              Opportunity and Payment Allocations associated a particular set of Opportunities.  Various
     *              Maps are built from the data retrieve to make it easier to evaluate, validate, and process
     *              the Opportunity and Payment Allocations (if enabled)
     * @return Class Instance
     */
    public ALLO_AllocationsRetrievalService retrieveData() {

        Map<Id, Opportunity> oppsByIdFromQuery = new OpportunitiesQuery().withOpportunities(this.oppIds).query();

        // Additional Id Sets used to retrieve Allocation Data only
        Set<Id> paymentsIds = new Set<Id>();
        Set<Id> recurringDonationIds = new Set<Id>();
        Set<Id> campaignIds = new Set<Id>();

        for (Opportunity opp :oppsByIdFromQuery.values()) {

            if (isExcluded(opp)) { // Drop any that are excluded for Recordtype or Type
                continue;
            }

            this.allocationsWrapper.oppsById.put(opp.Id, opp);
            this.allocationsWrapper.oppsAllocations.put(opp.Id, new List<Allocation__c>());

            if (opp.npe03__Recurring_Donation__c != null) { // Update Recurring Donation Sets and Maps
                recurringDonationIds.add(opp.npe03__Recurring_Donation__c);
                this.allocationsWrapper.oppIdToRdId.put(opp.Id, opp.npe03__Recurring_Donation__c);
                add(this.allocationsWrapper.rdIdToOppIds, opp.npe03__Recurring_Donation__c, opp.Id);
            }

            if (opp.CampaignId != null) { // Update Campaign Sets and Maps
                campaignIds.add(opp.CampaignId);
                add(this.allocationsWrapper.campaignIdToOppIds, opp.CampaignId, opp.Id);
            }

            if (UTIL_CustomSettingsFacade.getAllocationsSettings().Payment_Allocations_Enabled__c) {
                if (opp.npe01__OppPayment__r != null) {
                    for (npe01__OppPayment__c payment : opp.npe01__OppPayment__r) { // Update Payment Sets and Maps
                        paymentsIds.add(payment.Id);
                        this.allocationsWrapper.paymentIdsToOppIds.put(payment.Id, opp.Id);
                    }
                }
            }
        }

        List<Allocation__c> allocs = new AllocationsQuery()
                                        .withOpportunities(this.oppIds)
                                        .withPayments(paymentsIds)
                                        .withCampaigns(campaignIds)
                                        .withRecurringDonations(recurringDonationIds)
                                        .query();

        for (Allocation__c alloc : allocs) {
            this.allocationsWrapper.addAllocationByType(alloc);
        }

        return this;
    }

    /**
     * @description Return true if either the Opportunities Recordtype or Type match those
     *              configured to be excluded from Allocations processing
     * @param Opportunity opp The opportunity to check
     * @return Boolean true if the Opportunity should be excluded from Allocations processing
     */
    private Boolean isExcluded(Opportunity opp) {
        return (excludedOpportunityRecordtypes.contains(opp.RecordtypeId) || excludedOpportunityTypes.contains(opp.Type));
    }


    /**
     * @description Adds to the childId to a Map of a Set of Child Ids, but Parent Id.  This is used to
     *              Keep track of which records are affected by changes to the Parent
     * @param Map<Id, Set<Id>> parentIdToChildIds The map of Set of Child Ids, by Parent Id
     * @param Id parentId The Id of the Parent record
     * @param Id childId The Id of the Child (to the Parent) record
     */
    @testVisible private void add(Map<Id, Set<Id>> parentIdToChildIds, Id parentId, Id childId) {
        if (parentIdToChildIds.containsKey(parentId)) {
            parentIdToChildIds.get(parentId).add(childId);
        } else {
            parentIdToChildIds.put(parentId, new Set<Id> { childId });
        }
    }

    /**
     * @description Inner class to facilitate querying Opportunity and related payment information (if Payment Allocations is
     *              enabled)
     */
    public class OpportunitiesQuery {
        @testVisible private Set<Id> opportunityIds;
        @testVisible private Boolean retrievePaymentInfo = UTIL_CustomSettingsFacade.getAllocationsSettings().Payment_Allocations_Enabled__c == TRUE;

        /**
         * @description The set of Opportunity Ids to retrieve Opportunity Data for
         * @param  opportunityIds The Set of Opportunity Ids to retrieve Opportunity Data for
         * @return Class Instance
         */
        public OpportunitiesQuery withOpportunities(Set<Id> opportunityIds) {
            this.opportunityIds = opportunityIds;
            return this;
        }

        /**
         * @description Retrieves Opportunity and Payment Data into a Map by Opportunity Id
         * @return Map<Id, Opportunity> Map of Opportunities by Opportunity Id
         */
        public Map<Id, Opportunity> query() {
            Set<String> oppPaymentFields = new Set<String> {
                'Id',
                'Name',
                'npe01__Payment_Amount__c',
                'npe01__Payment_Date__c',
                'npe01__Scheduled_Date__c',
                'npe01__Written_Off__c',
                'npe01__Paid__c',
                'npe01__Opportunity__c',
                'LastModifiedDate'
            };

            String paymentSubQueryString = null;
            if (this.retrievePaymentInfo == true) {
                paymentSubQueryString = '(' + new UTIL_Query()
                                                .withSelectFields(oppPaymentFields)
                                                .withMultiCurrencyField()
                                                .withFrom('npe01__OppPayment__r')
                                                .build() +
                                        ')';
            }

            Set<String> oppFields = new Set<String> {
                'Id',
                'Name',
                'Amount',
                'StageName',
                'CampaignId',
                'npe03__Recurring_Donation__c',
                'IsClosed',
                'LastModifiedDate',
                'RecordtypeId',
                'Type'
            };

            if (this.retrievePaymentInfo == true) {
                oppFields.add (paymentSubQueryString);
            }

            Set<Id> qryOppIds = this.opportunityIds;

            String oppQueryString = new UTIL_Query()
                .withSelectFields(oppFields)
                .withMultiCurrencyField()
                .withFrom(Opportunity.getSObjectType())
                .withWhere('Id IN :qryOppIds')
                .build();

            return new Map<Id, Opportunity>((List<Opportunity>)Database.query(oppQueryString));
        }
    }

    /**
     * @description Inner class to make retrieving Allocations easier
     */
    public class AllocationsQuery {
        @testVisible private Set<Id> opportunityIds;
        @testVisible private Set<Id> paymentIds;
        @testVisible private Set<Id> campaignIds;
        @testVisible private Set<Id> recurringDonationIds;

        /**
         * @description Opportunities to retrieve Allocations for
         * @param opportunityIds Set of Opportunity Ids to retrieve Allocations for
         * @return Class Instance
        */
        public AllocationsQuery withOpportunities(Set<Id> opportunityIds) {
            this.opportunityIds = opportunityIds;
            return this;
        }

        /**
         * @description Payments to retrieve Allocations for
         * @param paymentIds Set of Payment Ids to retrieve Allocations for
         * @return Class Instance
        */
        public AllocationsQuery withPayments(Set<Id> paymentIds) {
            this.paymentIds = paymentIds;
            return this;
        }

        /**
         * @description Campaigns to retrieve Allocations for
         * @param paymentIds Set of Campaign Ids to retrieve Allocations for
         * @return Class Instance
        */
        public AllocationsQuery withCampaigns(Set<Id> campaignIds) {
            this.campaignIds = campaignIds;
            return this;
        }

        /**
         * @description Recurring Donatiosn to retrieve Allocations for
         * @param paymentIds Set of Recurring Donation Ids to retrieve Allocations for
         * @return Class Instance
        */
        public AllocationsQuery withRecurringDonations(Set<Id> recurringDonationIds) {
            this.recurringDonationIds = recurringDonationIds;
            return this;
        }

        /**
         * @description Retrieves Allocations related to the configured criteria
         * @return List<Allocation> List of Allocations retrieved
        */
        public List<Allocation__c> query() {
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
            Set<Id> qryOppIds = this.opportunityIds;

            if (qryOppIds != null && !qryOppIds.isEmpty()) {
                whereClauses.add('Opportunity__c in :qryOppIds');
            }

            Set<Id> qryPmtIds = this.paymentIds;
            if (qryPmtIds != null && !qryPmtIds.isEmpty()) {
                whereClauses.add('Payment__c in :qryPmtIds');
            }

            Set<Id> qryCampaignIds = this.campaignIds;
            if (qryCampaignIds != null && !qryCampaignIds.isEmpty()) {
                whereClauses.add('Campaign__c in :qryCampaignIds');
            }

            Set<Id> qryRDIds = this.recurringDonationIds;
            if (qryRDIds != null && !qryRDIds.isEmpty()) {
                whereClauses.add('Recurring_Donation__c in :qryRDIds');
            }

            if (whereClauses.size() == 0) {
                return new List<Allocation__c>();
            } else {
                String whereClauseExpanded = String.join(whereClauses, ' OR ');

                String allocationQueryString = allocQuery.withWhere(whereClauseExpanded).build();
                // TODO: Determine if it is necessary to pass into a new list and return, or can directly return
                return (List<Allocation__c>) Database.query(allocationQueryString);
            }
        }
    }
}