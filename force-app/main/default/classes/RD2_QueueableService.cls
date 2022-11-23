/*
    Copyright (c) 2019 Salesforce.org
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
* @group Recurring Donations
* @description Queueable Services for Enhanced Recurring Donations
*
*/
public class RD2_QueueableService {
    /**
    * @desciprtion A set of Recurring Donation Id to keep track of which RD has been queue up to process in a single transaction
    * to prevent race condition.
    */
    @TestVisible
    private static Set<Id> alreadyEnqueuedIds;
    /**
     * @description Queues up Opp eval service to recalculate Next Donation Date,
     * Current/Next Year Value and re-evaluate Opportunities on the Recurring Donation.
     * @param rdId Recurring Donation Id
     * @param isScheduleChanged Boolean indicated if the schedule has changed
     * @return void
     */
    public static void enqueueOppEvalService(Id rdId, Boolean isScheduleChanged) { 
        Set<Id> rdIdsWhereScheduleChanged = new Set<Id>();
        if (isScheduleChanged) {
            rdIdsWhereScheduleChanged.add(rdId);
        }
        enqueueOppEvalService(new Set<Id>{ rdId }, rdIdsWhereScheduleChanged, null);
    }

    /**
     * @description Queues up Opp eval service to recalculate Next Donation Date,
     * Current/Next Year Value and re-evaluate Opportunities on specified Recurring Donations.
     * @param rdIds Recurring Donation Ids
     * @return void
     */
    public static void enqueueOppEvalService(Set<Id> rdIds) { 
        enqueueOppEvalService(rdIds, null, null);
    }

    /**
     * @description Queues up Opp eval service to recalculate Next Donation Date,
     * Current/Next Year Value and re-evaluate Opportunities on specified Recurring Donations.
     * @param rdIds Recurring Donation Ids
     * @param rdIdsWhereScheduleChanged - Ids of Recurring Donation for which a schedule has been changed
     * @return void
     */
    public static void enqueueOppEvalService(Set<Id> rdIds, Set<Id> rdIdsWhereScheduleChanged) {
        enqueueOppEvalService(rdIds, rdIdsWhereScheduleChanged, null);
    }

    /**
     * @description Queues up Opp eval service to recalculate Next Donation Date,
     * Current/Next Year Value and re-evaluate Opportunities on specified Recurring Donations.
     * @param rdIds Recurring Donation Ids
     * @param rdIdsWhereScheduleChanged - Ids of Recurring Donation for which a schedule has been changed
     * @param oldRds - Recurring Donations used as a comparison for creating Change Log records
     * @return void
     */
    public static void enqueueOppEvalService(Set<Id> rdIds, Set<Id> rdIdsWhereScheduleChanged,
            List<npe03__Recurring_Donation__c> oldRds) {
        Set<Id> toProcess = removeAlreadyEnqueuedRecurringDonations(rdIds);

        if (toProcess.size() == 0) {
            return;
        }

        EvaluateInstallmentOpportunities service = new EvaluateInstallmentOpportunities(toProcess, rdIdsWhereScheduleChanged, oldRds);
        RD2_Settings settings = RD2_Settings.getInstance();

        if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs() && !settings.isGiftEntryMode) {
            System.enqueueJob(service);

        } else {
            service.executeOppEvaluationService();
        }
    }

    /**
    * @description Remove already Recurring Donation Ids that are already queue up to be evaluate to prevent being queue
    * up the second time. Skip the removal if the process is synchronize since there will not be a potential race condition.
    * @return Set<Id> Recurring Donation Ids 
    */
    private static Set<Id> removeAlreadyEnqueuedRecurringDonations(Set<Id> rdIds) {
        if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
            return rdIds;
        }

        if (alreadyEnqueuedIds == null) {
            alreadyEnqueuedIds = new Set<Id>();
        }

        Set<Id> rdIdsToProcess = new Set<Id>();

        for(Id rdId : rdIds) {
            if(!alreadyEnqueuedIds.contains(rdId)) {
                rdIdsToProcess.add(rdId);
                alreadyEnqueuedIds.add(rdId);
            }
        }

        return rdIdsToProcess;
    }

    /**
     * @description Queueable service to process Installment Opportunities for a Recurring Donation
     * that was inserted or modified.
     */
    public class EvaluateInstallmentOpportunities implements Queueable {
        Set<Id> rdIds;
        List<npe03__Recurring_Donation__c> oldRds;

        /**
        * @description Contains Recurring Donation Ids for which schedule has been changed
        */
        @TestVisible
        private Set<Id> rdIdsWhereScheduleChanged {
            get {
                if (rdIdsWhereScheduleChanged == null) {
                    rdIdsWhereScheduleChanged = new Set<Id>();
                }
                return rdIdsWhereScheduleChanged;
            } set;
        }

        /***
         * @description Constructor
         * @param rdIds - the RD Ids to process in this Queueable action
         */
        public EvaluateInstallmentOpportunities(Set<Id> rdIds) {
            this.rdIds = rdIds;
        }

        /***
         * @description Constructor
         * @param rdIds - the RD Ids to process in this Queueable action
         * @param rdIdsWhereScheduleChanged - Ids of Recurring Donations that have a changed schedule
         */
        public EvaluateInstallmentOpportunities(Set<Id> rdIds, Set<Id> rdIdsWhereScheduleChanged) {
            this.rdIds = rdIds;
            this.rdIdsWhereScheduleChanged = rdIdsWhereScheduleChanged;
        }

        /***
         * @description Constructor
         * @param rdIds - the RD Ids to process in this Queueable action
         * @param rdIdsWhereScheduleChanged - Ids of Recurring Donations that have a changed schedule
         * @param oldRds - Recurring Donations used as a comparison for creating Change Log records
         */
        public EvaluateInstallmentOpportunities(Set<Id> rdIds, Set<Id> rdIdsWhereScheduleChanged,
                List<npe03__Recurring_Donation__c> oldRds) {
            this.rdIds = rdIds;
            this.rdIdsWhereScheduleChanged = rdIdsWhereScheduleChanged;
            this.oldRds = oldRds;
        }

        /**
         * @description Execute method called when the Queueable runs. Delegates to the
         * evaluation service
         * @param context queuableContext
         */
        public void execute(QueueableContext context) {
            if (rdIds == null || rdIds.isEmpty()) {
                return;
            }

            executeOppEvaluationService();
        }

        /**
         * @description Delegate processing of the Recurring Donations to the Evaluation Service
         */
        public void executeOppEvaluationService() {
            new RD2_OpportunityEvaluationService()
                .withRds(rdIds)
                .withOldRds(oldRds)
                .withScheduleChanged(rdIdsWhereScheduleChanged)
                .evaluateOpportunities();
        }
    }

    /**
     * @description Queueable service to process inserted Recurring Donations that have a value
     * in the Elevate CommitmentId__c field.
     */
    public class ElevateOpportunityMatcher implements Queueable {
        Map<String, Id> rdIdByCommitmentId;

        /***
         * @description Constructor
         * @param rdIdByCommitmentId - Map of CommitmentId's to RecurringDonation.Id
         */
        public ElevateOpportunityMatcher(Map<String, Id> rdIdByCommitmentId) {
            this.rdIdByCommitmentId = rdIdByCommitmentId;
        }

        /**
         * @description Execute method called when the Queueable runs. Delegates to the
         * evaluation service
         * @param context queuableContext
         */
        public void execute(QueueableContext context) {
            if (rdIdByCommitmentId == null || rdIdByCommitmentId.isEmpty()) {
                return;
            }

            match();
        }

        /**
         * @description Delegate processing of the Recurring Donations to the Evaluation Service
         */
        public void match() {
            new RD2_ElevateIntegrationService()
                .matchRecurringDonationsToOpps(rdIdByCommitmentId);
        }
    }

    /**
     * @description Queueable service to make callouts to Elevate payment services and cancel commitments
     */
    public class CancelCommitmentService implements Queueable, Database.AllowsCallouts {
        List<RD2_CancelCommitmentService.RecordWrapper> commitmentRDs;

        /**
        * @description Constructor
        * @param closedRDs Closed Recurring Donations containing Commitment Id
        */
        public CancelCommitmentService(List<RD2_CancelCommitmentService.RecordWrapper> closedRDs) {
            this.commitmentRDs = closedRDs;
        }

        /**
         * @description Cancel Commitments in Elevate payment services
         * @param context queueableContext
         */
        public void execute(QueueableContext context) {
            executeCancelCommitments();
        }

        /**
         * @description Cancel Commitments in Elevate payment services
         */
        public void executeCancelCommitments() {
            if (commitmentRDs == null || commitmentRDs.isEmpty()) {
                return;
            }

            new RD2_CancelCommitmentService()
                .cancelCommitments(commitmentRDs);
        }
    }

    /**
     * @description Queues up Opp name update service to recalculate Opportunity name.
     * @param updatedOpps Updated opportunities
     */
    public static void enqueueOppNamingService(List<Opportunity> updatedOpps) {
        OpportunityNamingService service = new OpportunityNamingService(updatedOpps);

        if (canQueueNamingService()) {
            System.enqueueJob(service);

        } else {
            service.refreshOppNames();
        }
    }

    private static Boolean canQueueNamingService() {
        RD2_Settings settings = RD2_Settings.getInstance();

        return Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()
            && !Test.isRunningTest() && !settings.isGiftEntryMode;
    }

    /**
     * @description Queueable service to recalculate Opportunity names
     */
    public class OpportunityNamingService implements Queueable {
        List<Opportunity> updatedOpps;

        /**
        * @description Constructor
        * @param updatedOpps Updated opportunities
        */
        public OpportunityNamingService(List<Opportunity> updatedOpps) {
            this.updatedOpps = updatedOpps;
        }

        /**
         * @description Update opportunity names
         * @param context queueableContext
         */
        public void execute(QueueableContext context) {
            refreshOppNames();
        }

        /**
         * @description Update opportunity names
         */
        public void refreshOppNames() {
            if (updatedOpps == null || updatedOpps.isEmpty()) {
                return;
            }

            Map<Id, String> oppNameById = new Map<Id, String>();
            for (Opportunity opp: updatedOpps) {
                oppNameById.put(opp.Id, opp.Name);
            }

            OPP_OpportunityNaming.refreshOppNames(updatedOpps);

            List<Opportunity> renamedOpps = new List<Opportunity>();
            for (Opportunity opp: updatedOpps) {
                if (!opp.Name.equalsIgnoreCase(oppNameById.get(opp.Id))) {
                    renamedOpps.add(opp);
                }
            }

            TDTM_ProcessControl.toggleTriggerState('Opportunity', 'RD2_RecurringDonationsOpp_TDTM', false);
            update renamedOpps;
        }
    }
}