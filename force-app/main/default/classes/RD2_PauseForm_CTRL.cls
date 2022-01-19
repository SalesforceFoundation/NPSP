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
* @group Recurring Donations
* @description Saves and retrieves pause details on a Recurring Donation record
*/
public with sharing class RD2_PauseForm_CTRL {

    /***
    * @description Recurring Donation Pause Schedule Handler
    */
    @TestVisible
    private static RD2_ScheduleService.PauseScheduleHandler pauseHandler {
        get {
            if (pauseHandler == null) {
                pauseHandler = new RD2_ScheduleService.PauseScheduleHandler();
            }
            return pauseHandler;
        } set;
    }

    /**
     * @description Returns PauseData to the LWC so the page can be initialized and rendered.
     * Determines if the user has the access to create/update the pause
     * as well as determines if the Recurring Donation is closed.
     * The Paused Reason field label and options are returned regardless
     * if the pause exists. However, the schedule Id and the Paused Reason value
     * are specified if the pause exists for the RD.
     * @param rdId Recurring Donation Id
     * @return String JSON string representing PauseData
     */
    @AuraEnabled(cacheable=false)
    public static String getPauseData(Id rdId) {
        String jsonData;
        try {
            RD2_RecurringDonation rd = getRecurringDonation(rdId);

            PauseData pause = new PauseData();
            pause.rdId = rdId;
            pause.hasAccess = hasAccess();
            pause.isElevateRecord = pause.hasAccess
                ? RD2_ElevateIntegrationService.isIntegrationEnabled() && rd.isElevateRecord()
                : null; 
            pause.isRDClosed = pause.hasAccess ? rd.isClosed() : null;

            if (pause.isRDClosed == false && pause.isElevateRecord == false) {
                pause.pausedReason = buildPausedReason();
                populateScheduleData(pause, rdId);
               
            }

            jsonData = JSON.serialize(pause);

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }

        return jsonData;
    }

    /**
     * @description Checks if the user has access to create or update a Recurring Donation
     * @return Boolean
     */
    private static Boolean hasAccess() {
        String rdObjectName = Schema.SObjectType.npe03__Recurring_Donation__c.getName();

        return UTIL_Permissions.canRead(rdObjectName, false) &&
            UTIL_Permissions.canCreate(rdObjectName, false) &&
            UTIL_Permissions.canUpdate(rdObjectName, false);
    }

    /**
    * @description Query and Construct Recurring Donation Record
    * @param rdId Recurring Donation Id
    * @return RD2_RecurringDonation
    */
    private static RD2_RecurringDonation getRecurringDonation(Id rdId) {
        return new RD2_RecurringDonation([
            SELECT Status__c,
                CommitmentId__c
            FROM npe03__Recurring_Donation__c
            WHERE Id = :rdId
            LIMIT 1
        ]);
    }

    /**
     * @description Returns the Paused Reason field label and select options
     * @return PausedReason
     */
    private static PausedReason buildPausedReason() {
        PausedReason reason = new PausedReason();
        reason.label = System.Label.RD2_PausedReasonLabel;
        reason.options = getPausedReasonOptions();
        reason.placeholder = System.Label.commonSelectOptionPlaceholder;

        return reason;
    }

    /**
     * @description Populates PausedReason.value and PauseData.scheduleId
     * if the pause exists on the Recurring Donation
     * @return void
     */
    private static void populateScheduleData(PauseData pause, Id rdId) {
        RecurringDonationSchedule__c schedule = pauseHandler.getPauseSchedule(rdId);

        if (schedule == null) {
            return;
        }

        pause.pausedReason.value = schedule.StatusReason__c;
        pause.scheduleId = schedule.Id;
    }

    /**
     * @description Returns the Paused Reason field select options
     * @return List<PicklistOptionView>
     */
    @TestVisible
    private static List<PicklistOptionView> getPausedReasonOptions() {
        List<PicklistOptionView> options = new List<PicklistOptionView>();
        List<Schema.PicklistEntry> entries = npe03__Recurring_Donation__c.ClosedReason__c.getDescribe().getPicklistValues();

        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {                
                options.add(
                    new PicklistOptionView()
                        .withValue(entry.getValue())
                        .withLabel(entry.getLabel())
                );
            }
        }
        return options;
    }
    
    /**
     * @description Returns future projected installments for the Recurring Donation
     * @param recordId Record Id
     * @param numberOfInstallments Number of installments to return
     * @return Map<String, Object> Installments datatable value by 'dataTable' key
     */
    @AuraEnabled
    public static Map<String, Object> getInstallments(Id recordId, Integer numberOfInstallments) {
        return RD2_VisualizeScheduleController.getInstallments(recordId, numberOfInstallments);
    }

    /**
     * @description Deactivates existing pause (if any). 
     * Creates new pause based on provided data if the both start and end dates are provided.
     * Otherwise, if dates are not provided, save is actual deactivation of the current pause on the RD.
     * @param jsonPauseData JSON representation of the PauseData 
     * @return void
     */
    @AuraEnabled
    public static void savePause(String jsonPauseData) {
        try {
            PauseData pause = (PauseData) JSON.deserialize(jsonPauseData, PauseData.class);
            
            RD2_RecurringDonation rd = getRecurringDonation(pause.rdId);
            if (RD2_ElevateIntegrationService.isIntegrationEnabled() && rd.isElevateRecord()) {
                throw new PauseException(System.Label.RD2_ElevateNotSupported);
            }
    
            Boolean isNewPause = pause.startDate != null && pause.resumeAfterDate != null;
            if (isNewPause) {
                //deactivate the current pause (if any) and create a new one
                pauseHandler.savePauseSchedule(pause.rdId, buildPauseSchedule(pause));

            } else {//deactivate the current pause (if any)
                pauseHandler.cancelPauseSchedule(pause.rdId);
            }

            Boolean isScheduleChanged = true;
            RD2_QueueableService.enqueueOppEvalService(pause.rdId, isScheduleChanged);

        } catch (Exception e) {
            throwAuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Constructs schedule to be inserted for the new pause
     * @param pause PauseData
     * @return RecurringDonationSchedule__c
     */
    private static RecurringDonationSchedule__c buildPauseSchedule(PauseData pause) {
        return pauseHandler.createPauseSchedule(
                pause.pausedReason?.value,
                pause.startDate,
                pause.resumeAfterDate,
                pause.rdId
        );
    }

    /***
    * @description Sets the error message and throws the AuraHandledException.
    * This is required to avoid generic "script-thrown exception" error.
    * @param errMessage Error message
    * @return void
    */
    private static void throwAuraHandledException(String errMessage) {
        AuraHandledException e = new AuraHandledException(errMessage);
        e.setMessage(errMessage);
        throw e;
    }

    /**
    * @description Custom exception for Pause Recurring Donation feature
    */
    public class PauseException extends Exception {}

    /***
    * @description Contains pause data
    */
    public class PauseData {
        public Id rdId;
        public Boolean hasAccess;
        public Boolean isRDClosed;
        public Boolean isElevateRecord;
        public Date startDate;
        public Date resumeAfterDate;
        public PausedReason pausedReason;
        public Id scheduleId;
        
    }

    /***
    * @description Contains Paused Reason field details
    */
    public class PausedReason {
        public String value;
        public String label;
        public List<PicklistOptionView> options;
        public String placeholder;
    }
}
