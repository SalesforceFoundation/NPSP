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
    * @description Recurring Donation Schedule service
    */
    @TestVisible
    private static RD2_ScheduleService scheduleService {
        get {
            if (scheduleService == null) {
                scheduleService = new RD2_ScheduleService();
            }
            return scheduleService;
        } set;
    }

    /**
     * @description 
     * @return 
     */
    @AuraEnabled(cacheable=false)
    public static String getPauseData(Id rdId) {
        PauseData pause = new PauseData();
        pause.isRDClosed = isClosed(rdId);

        if (!pause.isRDClosed) {
            pause.pausedReason = getPausedReason(rdId);
        }

        return JSON.serialize(pause);
    }

    /**
     * @description 
     * @return 
     */
    public static Boolean isClosed(Id rdId) {
        npe03__Recurring_Donation__c rd = [
            SELECT Status__c
            FROM npe03__Recurring_Donation__c
            WHERE Id = :rdId
            LIMIT 1
        ];

        return (new RD2_RecurringDonation(rd)).isClosed();
    }

    /**
     * @description Returns the Paused Reason value and label select options
     * @return PausedReason
     */
    public static PausedReason getPausedReason(Id rdId) {
        PausedReason reason = new PausedReason();
        reason.label = System.Label.RD2_PausedReasonLabel;
        reason.options = getPausedReasonOptions();
        reason.placeholder = System.Label.lblSelectOptionPlaceholder;

        RecurringDonationSchedule__c schedule = scheduleService.getPauseSchedule(rdId);
        reason.value = schedule == null ? null : schedule.StatusReason__c;

        return reason;
    }

    /**
     * @description Returns the Paused Reason value and label select options
     * @return List<Option>
     */
    private static List<Option> getPausedReasonOptions() {
        List<Option> options = new List<Option>();
        List<Schema.PicklistEntry> entries = npe03__Recurring_Donation__c.ClosedReason__c.getDescribe().getPicklistValues();

        for (Schema.PicklistEntry entry : entries) {
            if (entry.isActive()) {                
                options.add(
                    new Option()
                        .withValue(entry.getValue())
                        .withLabel(entry.getLabel())
                );
            }
        }
        return options;
    }
    
    /**
     * @description Builds future projected installments for the Recurring Donation
     * @param recordId Record Id
     * @param maxRowDisplay Number of installments to display
     * @return Map<String, Object>
     */
    @AuraEnabled
    public static Map<String, Object> getInstallments(Id recordId, Integer maxRowDisplay) {
        Map<String, Object> dataByKey = new Map<String, Object>();
        try {
            dataByKey = RD2_VisualizeScheduleController.getInstallments(recordId, maxRowDisplay);

        } catch(Exception e) {
            if (e.getMessage().contains(System.Label.RD2_ScheduleVisualizerMessageNoSchedule)) {
                throw e;
            }
        }

        return dataByKey;
    }

    /**
     * @description 
     * @param 
     * @return void
     */
    @AuraEnabled
    public static void savePause(String jsonPauseData) {
        try {
            PauseData pause = (PauseData) JSON.deserialize(jsonPauseData, PauseData.class);

            //deactivate current schedule(s)
            delete [
                SELECT Id FROM RecurringDonationSchedule__c 
                WHERE RecurringDonation__c = :pause.rdId
                AND IsPause__c = true
            ];//TODO it should deactivate not delete

            //create new pause schedule
            RecurringDonationSchedule__c schedule = buildPauseSchedule(pause);
            if (schedule.StartDate__c != null && schedule.EndDate__c != null) {
                insert schedule;
            }

        } catch(Exception e) {
            throwAuraHandledException(e.getMessage());
        }
    }

    /**
     * @description 
     * @param 
     * @return void
     */
    private static RecurringDonationSchedule__c buildPauseSchedule(PauseData pause) {
        RecurringDonationSchedule__c schedule = new RecurringDonationSchedule__c(
            RecurringDonation__c = pause.rdId,
            IsPause__c = true,
            StatusReason__c = pause.pausedReason.value,
            StartDate__c = pause.startDate,
            EndDate__c = pause.resumeAfterDate
        );

        return schedule;
    }

    /***
    * @description Throws AuraHandledException
    * @param errMessage
    * @return void
    */
    private static void throwAuraHandledException(String errMessage) {
        AuraHandledException e = new AuraHandledException(errMessage);
        e.setMessage(errMessage);
        throw e;
    }

    /***
    * @description 
    */
    public class PauseData {
        public Id rdId;
        public Boolean isRDClosed;
        public Date startDate;
        public Date resumeAfterDate;
        public PausedReason pausedReason;
    }

    /***
    * @description 
    */
    public class PausedReason {
        public String value;
        public String label;
        public List<Option> options;
        public String placeholder;
    }

    /**
     * @description Contains custom select option
     */
    public class Option {
        @AuraEnabled public String value;
        @AuraEnabled public String label;

        /**
         * @description Sets the option value
         * @param value The option value
         * @return Option This option instance
         */
        public Option withValue(String value) {
            this.value = value;
            return this;
        }

        /**
         * @description Sets the option label
         * @param label The option label
         * @return Option This option instance
         */
        public Option withLabel(String label) {
            this.label = label;
            return this;
        }
    }


}
