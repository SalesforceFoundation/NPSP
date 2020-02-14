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
* @description Trigger on Recurring Donations when enhanced Recurring Donations are enabled
*
*/
public class RD2_RecurringDonations_TDTM extends TDTM_Runnable {

    /***
    * @description dml actions gathered during trigger execution
    */
    private DmlWrapper dmlActions = new DmlWrapper();

    /***
    * @description Recurring Donation schedule service instance
    */
    @TestVisible
    private RD2_ScheduleService scheduleService {
        get {
            if (scheduleService == null) {
                scheduleService = new RD2_ScheduleService();
            }
            return scheduleService;
        }
        set;
    }

    /***
    * @description Recurring Donation naming service instance
    */
    @TestVisible
    private RD2_NamingService namingService {
        get {
            if (namingService == null) {
                namingService = new RD2_NamingService();
            }
            return namingService;
        }
        set;
    }

    /***
    * @description Trigger handler on Recurring Donations when enhancement is enabled
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    * @param objResult Recurring Donation SObject describe
    * @return dmlWrapper
    */
    public override DmlWrapper run(
        List<SObject> rds, List<SObject> oldRds,
        TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult
    ) {

        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            return null;
        }
        if (TDTM_ProcessControl.isRecursive(TDTM_ProcessControl.flag.RD)) {
            return null;
        }
        if (triggerAction != TDTM_Runnable.Action.BeforeInsert && triggerAction != TDTM_Runnable.Action.BeforeUpdate) {
            TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, true);
        }

        autogenerateNames(rds, oldRds, triggerAction);
        validate(rds, oldRds, triggerAction);
        handleRDSchedules(rds, oldRds, triggerAction);

        // Insert/Update any pending RecurringDonationSchedule records before the
        // evaluation service is called so that the full schedule is available to the
        // service to determine what Opportunities to insert or modify
        TDTM_TriggerHandler.processDML(dmlActions);
        dmlActions = null;

        evaluateOpportunities(rds, oldRds, triggerAction);

        dispatchToIntegrationGateway(rds, oldRds, triggerAction);

        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, false);
        return dmlActions;
    }

    /***
    * @description Autogenerates recurring donation names
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    */
    public void autogenerateNames(List<SObject> rds, List<SObject> oldRds, TDTM_Runnable.Action triggerAction) {

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            namingService.autogenerateNames(rds);

        } else if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            namingService.autogenerateNamesOnChange(rds, oldRds);
        }
    }

    /***
    * @description Validates Recurring Donations data
    * @param rds Trigger.new records
    * @param triggerAction BeforeInsert, BeforeUpdate, etc.
    */
    public void validate(List<SObject> rds, List<SObject> oldRds, TDTM_Runnable.Action triggerAction) {
        RD2_ValidationService validationService = new RD2_ValidationService(rds);

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            validationService.validate();

        } else if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            validationService
                .withOldRecurringDonations(oldRds)
                .validateOnChange();
        }
    }

    /***
    * @description Determine if Installment Opportunities need to be created or updated.
    * Opportunities are evaluated *asynchronously* unless the async job limit has been reached.
    * Thus, static flags set in the evaluation service are reset when the service executes in the async mode.
    * However, the trigger can check for those flags and verify if the service should be called at all.
    *
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    * @return void
    */
    public void evaluateOpportunities(List<npe03__Recurring_Donation__c> rds, List<npe03__Recurring_Donation__c> oldRds, TDTM_Runnable.Action triggerAction) {
        if (RD2_OpportunityEvaluationService.skipEvaluationService) {
            return;
        }

        Set<Id> rdIds = new Set<Id>();
        if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            rdIds = new Map<Id, npe03__Recurring_Donation__c>(rds).keySet();

        } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            RD2_OpportunityEvaluationService evalService = new RD2_OpportunityEvaluationService();
            Map<Id, npe03__Recurring_Donation__c> oldRdsById = new Map<Id, npe03__Recurring_Donation__c>(oldRds);

            for (npe03__Recurring_Donation__c rd : rds) {
                if (evalService.hasKeyFieldChanged(rd, oldRdsById.get(rd.Id))) {
                    rdIds.add(rd.Id);
                }
            }
        }

        if (!rdIds.isEmpty()) {
            RD2_QueueableService.EvaluateInstallmentOpportunities service =
                new RD2_QueueableService.EvaluateInstallmentOpportunities(rdIds);

            if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
                System.enqueueJob(service);

            } else {
                service.executeOppEvaluationService();
            }
        }
    }

    /***
    * @description Dispatches trigger records to integration gateway
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    */
    private void dispatchToIntegrationGateway(List<SObject> rds, List<SObject> oldRds, TDTM_Runnable.Action triggerAction) {
        if (triggerAction == TDTM_Runnable.Action.BeforeDelete) {
            integrationGateway.handleBeforeDelete(oldRds);
        }
    }

    /***
    * @description Creates/modifies schedule record(s) after insert/update of recurring donation
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction BeforeInsert, AfterInsert, etc.
    */
    private void handleRDSchedules(List<SObject> rds, List<SObject> oldRds, TDTM_Runnable.Action triggerAction) {

        if (triggerAction == TDTM_Runnable.Action.BeforeInsert) {
            calculateNextDonationDates(rds);

        } else if (triggerAction == TDTM_Runnable.Action.AfterInsert) {
            buildNewSchedules(rds);

        } else if (triggerAction == TDTM_Runnable.Action.BeforeUpdate) {
            calculateNextDonationDateBeforeUpdate(rds, oldRds);

        } else if (triggerAction == TDTM_Runnable.Action.AfterUpdate) {
            synchronizeSchedulesAfterRDUpdate(rds, oldRds);
        }
    }

    /***
    * @description Handles next donation calculation before insert of recurring donation
    * @param rds Trigger.new records
    */
    private void calculateNextDonationDates(List<npe03__Recurring_Donation__c> rds) {

        for (npe03__Recurring_Donation__c rd : rds) {
            rd.npe03__Next_Payment_Date__c = scheduleService.getNextDonationDate(rd);
        }
    }

    /***
    * @description Handles schedule creation after insert of recurring donation
    * @param rds Trigger.new records
    */
    private void buildNewSchedules(List<npe03__Recurring_Donation__c> rds) {

        for (npe03__Recurring_Donation__c rd : rds) {
            dmlActions.objectsToInsert.addAll(scheduleService.getNewSchedules(rd));
        }
    }

    /***
    * @description Handles calculation of next donation date before update of recurring donation
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    */
    private void calculateNextDonationDateBeforeUpdate(List<SObject> rds, List<SObject> oldRds) {
        Map<Id, List<RecurringDonationSchedule__c>> schedulesByRdId = scheduleService.getAllRecurringDonationSchedules(rds, oldRds);
        for (npe03__Recurring_Donation__c rd : (List<npe03__Recurring_Donation__c>)rds) {
            rd.npe03__Next_Payment_Date__c = scheduleService.getNextDonationDate(schedulesByRdId.get(rd.Id));
        }
    }

    /***
    * @description Handles schedule modification/creation after modification of recurring donation
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    */
    private void synchronizeSchedulesAfterRDUpdate(List<npe03__Recurring_Donation__c> rds, List<npe03__Recurring_Donation__c> oldRds) {

        Map<Id, npe03__Recurring_Donation__c> filteredRecurringDonations = scheduleService.getRecurringDonationsNeedingScheduleUpdates(rds, oldRds, TDTM_Runnable.Action.AfterUpdate);

        // We only need schedules for RDs that qualify for schedule updates in order to sync schedules
        Map<Id, List<RecurringDonationSchedule__c>> oldSchedules = scheduleService.getExistingSchedules(filteredRecurringDonations.values());

        DmlWrapper revisedSchedules;
        for (npe03__Recurring_Donation__c rd : filteredRecurringDonations.values()) {
            revisedSchedules = scheduleService.getUpdatedSchedules(rd, oldSchedules.get(rd.Id));
            dmlActions.objectsToInsert.addAll(revisedSchedules.objectsToInsert);
            dmlActions.objectsToUpdate.addAll(revisedSchedules.objectsToUpdate);
        }
    }
}