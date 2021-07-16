/*
    Copyright (c) 2020 Salesforce.org
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
* @description All services specific to Enhanced Recurring Donation Api's
*
*/
public inherited sharing class RD2_ApiService {

    @TestVisible
    private static Integer MAXIMUM_RECORDS_TO_PROCESS = 200;

    /**
     * @description Retrieve a map of RecurringDonationSchedule__c records by Rd.id using an inner wrapper
     * class representation of the RdSchedule object because it's protected and customers will not be able to
     * deserialize it.
     * @param rdIds Recurring Donation Id's to retrieve schedules for
     * @return JSON Serialized version of Map<Id, List<RD2_ApiService.Schedule>> schedulesByRdId
     */
    public String querySchedules(Set<Id> rdIds) {
        Map<Id, List<Schedule>> schedulesByRdId = new Map<Id, List<Schedule>>();

        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            return JSON.serialize(schedulesByRdId);
        }

        String soql = getRecurringDonationQuery();
        for (npe03__Recurring_Donation__c rd : Database.query(soql)) {

            List<Schedule> schedules = new List<Schedule>();
            for (RecurringDonationSchedule__c s : rd.RecurringDonationSchedules__r) {
                schedules.add(new Schedule(s, rd));
            }

            schedulesByRdId.put(rd.Id, schedules);
        }

        return JSON.serialize(schedulesByRdId);
    }

    /**
     * @return SOQL of Recurring Donation records with a subquery on schedule records
     */
    private String getRecurringDonationQuery() {
        Set<String> queryFields = new Set<String>{
            'Id',
            'CommitmentId__c',
            'EndDate__c',
            'Status__c'
        };
        if (UserInfo.isMultiCurrencyOrganization()) {
            queryFields.add('CurrencyIsoCode');
        }

        queryFields.add(getScheduleSubQuery());

        String soql = new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(queryFields)
            .withWhere('Id IN :rdIds')
            .build();

        return soql;
    }

    /**
     * @description Returns query on Recurring Donation Schedule
     * Return all schedules for the RD Schedule visualization.
     * The Schedule Service will filter them out if not applicable within the time period.
     * @return String RD Schedule subquery used in the Recurring Donation SOQL
     */
    private String getScheduleSubQuery() {
        Set<String> fields = new RD2_ScheduleService.ScheduleQueryHandler().getFields();
        fields.add('CreatedDate');
        fields.add('LastModifiedDate');

        return '(SELECT ' + String.join(new List<String>(fields), ', ') +
            ' FROM RecurringDonationSchedules__r' +
            ' ORDER By StartDate__c' +
            ')';
    }

    /***
    * @description Wrapper class for Recurring Donation Schedule data for the querySchedules api
    */
    public class Schedule {

        public String recurringDonationId { get; set; }
        public String scheduleId { get; set; }
        public Boolean isActive { get; set; }
        public Boolean isCurrent { get; set; }
        public Boolean isPause { get; set; }
        public String campaignId { get; set; }
        public String dayOfMonth { get; set; }
        public Date endDate { get; set; }
        public Decimal installmentAmount { get; set; }
        public Integer installmentFrequency { get; set; }
        public String installmentPeriod { get; set; }
        public String paymentMethod { get; set; }
        public Date startDate { get; set; }
        public String statusReason { get; set; }
        public String currencyCode { get; set; }
        public Datetime createdDate { get ;set; }
        public Datetime lastModifiedDate { get ;set; }

        public Schedule(RecurringDonationSchedule__c rdSchedule, npe03__Recurring_Donation__c rd) {
            isActive = rdSchedule.Active__c;
            isCurrent = rdSchedule.StartDate__c <= RD2_ScheduleService.currentDate
                && (rdSchedule.EndDate__c == null || RD2_ScheduleService.currentDate <= rdSchedule.EndDate__c);
            isPause = rdSchedule.IsPause__c;
            campaignId = rdSchedule.Campaign__c;
            dayOfMonth = rdSchedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY ? rdSchedule.DayOfMonth__c : null;
            endDate = (rdSchedule.EndDate__c != null) ? rdSchedule.EndDate__c : rd.EndDate__c;
            installmentAmount = rdSchedule.InstallmentAmount__c;
            installmentFrequency = rdSchedule.InstallmentFrequency__c != null ? Integer.valueOf(rdSchedule.InstallmentFrequency__c) : null;
            installmentPeriod = rdSchedule.InstallmentPeriod__c;
            paymentMethod = rdSchedule.PaymentMethod__c;
            recurringDonationId = rdSchedule.RecurringDonation__c;
            scheduleId = rdSchedule.Id;
            startDate = rdSchedule.StartDate__c;
            statusReason = rdSchedule.StatusReason__c;
            createdDate = rdSchedule.CreatedDate;
            lastModifiedDate = rdSchedule.LastModifiedDate;
            currencyCode = RD2_ApiService.getCurrencyCode(rd);
        }
    }

    /**
     * @description Retrieves the currency from the RD or the org
     * @return currencyCode
     */
    private static String getCurrencyCode(npe03__Recurring_Donation__c rd) {
        String currencyCode;

        try {
            if (UserInfo.isMultiCurrencyOrganization()) {
                currencyCode = (String) rd.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
            } else {
                currencyCode = Userinfo.getDefaultCurrency();
            }
        } catch (Exception ex) {
            // ignore any errors if for some reason we can't retrieve the currency code
            // because usage in the ActiveSchedule inner class is only for api use
        }

        return currencyCode;
    }

    /**
     * @description Retrieve a map of scheduled installments by Rd.id.  Paused installments are omitted.
     * @param startDate Begin date of range for installments. Defaults to current date if null.
     * @param endDate End date of range for installments
     * @param rdIds Recurring Donation Ids for which to retrieve installments
     * @return String JSON Serialized version of Map<Id, List<RD2_ApiService.Installment>> installmentsByRdId
     */
    public String queryInstallments(Date startDate, Date endDate, Set<Id> rdIds) {
        Map<Id, List<Installment>> installmentsByRdId = new Map<Id, List<Installment>>();

        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            return JSON.serialize(installmentsByRdId);
        }

        if (startDate == null) {
            startDate = RD2_ScheduleService.currentDate;
        }

        if (endDate == null) {
            endDate = getDefaultEndDate(startDate);
        }

        RD2_ScheduleService service = new RD2_ScheduleService();
        String soql = getRecurringDonationQuery();
        for (npe03__Recurring_Donation__c rd : Database.query(soql)) {

            List<Installment> installments = new List<Installment>();
            for (RD2_ScheduleService.Installment installment : service.getVisualizedInstallments(
                startDate,
                endDate,
                rd.RecurringDonationSchedules__r)
            ) {
                installments.add(new Installment(installment, rd));
            }

            installmentsByRdId.put(rd.Id, installments);
        }

        return JSON.serialize(installmentsByRdId);
    }

    /**
     * @description Calculates endDate to produce 1 year of installment data. In most cases that means
     * endDate should be set to startDate + 1 year - 1 day. There may be edge cases where that is not
     * true, so the subtraction is limited to cases where the day portion of startDate == the day portion of endDate.
     * The outcome of subtracting one day is to ensure that one year of installments is included. Without the
     * adjustment, an extra installment is reported in most, if not all, scenarios.
     * @param startDate Date
     * @return endDate Date
     */
    private Date getDefaultEndDate(Date startDate) {
        Date endDate = startDate.addYears(1);

        if (startDate.day() == endDate.day()) {
            endDate = endDate.addDays(-1);
        }
        
        return endDate;
    }

    /***
    * @description Wrapper class for Recurring Donation Schedule data for the querySchedules api
    */
    public class Installment {

        public String recurringDonationId { get; set; }
        public String scheduleId { get; set; }
        public String campaignId { get; set; }
        public Date closeDate { get; set; }
        public Decimal installmentAmount { get; set; }
        public String currencyCode { get; set; }
        public String paymentMethod { get; set; }

        public Installment(RD2_ScheduleService.Installment installment, npe03__Recurring_Donation__c rd) {
            recurringDonationId = rd.Id;
            scheduleId = installment.scheduleId;
            campaignId = installment.campaignId;
            closeDate = installment.nextDonationDate;
            installmentAmount = installment.installmentAmount;
            paymentMethod = installment.paymentMethod;
            currencyCode = currencyCode = RD2_ApiService.getCurrencyCode(rd);
        }
    }

    public String pause(Map<Id, PauseObject> pauseData) {
        validateEnvironment(pauseData.size());

        return JSON.serialize(handlePauseRequests(pauseData));
    }

    private void validateEnvironment(Integer recordsCount) {
        String errorMessage;

        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            errorMessage = System.Label.RD2_EnhancedRecurringDonationsNotEnabled;

        } else if (recordsCount > MAXIMUM_RECORDS_TO_PROCESS) {
           errorMessage = String.format(System.Label.CallableApiMaximumRecordsExceeded,
            new List<String> { String.valueOf(MAXIMUM_RECORDS_TO_PROCESS) });
        }

        if (String.isNotBlank(errorMessage)) {
            throwRecurringDonationApiException('rd2.pause', errorMessage);
        }
    }

    private void throwRecurringDonationApiException(String jobType, String errorString) {
        throw new RecurringDonationApiException(String.format( System.Label.CallableApiProcessingError,
                new List<String>{ jobType, errorString} ));
    }

    private class RecurringDonationApiException extends Exception {}

    private Map<Id, PauseObject> handlePauseRequests(Map<Id, PauseObject> pauseData) {
        List<RecurringDonationSchedule__c> schedulesToInsert = new List<RecurringDonationSchedule__c>();
        List<RecurringDonationSchedule__c> schedulesToUpdate = new List<RecurringDonationSchedule__c>();

        Map<Id, npe03__Recurring_Donation__c> recurringDonationsById = new Map<Id, npe03__Recurring_Donation__c>(
            getRecurringDonationsById(pauseData.keySet())
        );

        for (Id rdId : pauseData.keySet()) {
            RD2_RecurringDonation rdRecord = new RD2_RecurringDonation(recurringDonationsById.get(rdId));
            PauseObject pauseInfo = pauseData.get(rdId);

            pauseInfo.populateDefaultValues();

            if (!isValidPauseData(rdId, pauseInfo, rdRecord)) {
                continue;
            }

            RecurringDonationSchedule__c updateSchedule = deactivatePauseSchedule(rdRecord);
            if (updateSchedule != null) {
                schedulesToUpdate.add(updateSchedule);
            }

            if (!pauseInfo.unPause) {
                schedulesToInsert.add(createPauseSchedule(pauseInfo, rdId));
            }
        }

        return commitScheduleUpdates(pauseData, schedulesToInsert, schedulesToUpdate);
    }

    @TestVisible
    private Boolean isValidPauseData(Id rdId, PauseObject pause, RD2_RecurringDonation recurringDonation) {
        PauseValidator validator = new PauseValidator(pause);
        validator.validatePauseData(rdId, recurringDonation);

        return pause.isSuccess;
    }

    private Map<Id, PauseObject> commitScheduleUpdates(Map<Id, PauseObject> pauseData,
        List<RecurringDonationSchedule__c> schedulesToInsert,
        List<RecurringDonationSchedule__c> schedulesToUpdate)
    {
        Set<Id> recurringDonationIds = new Set<Id>();

        Set<Id> insertIds = insertPauseSchedules(pauseData, schedulesToInsert);
        if (insertIds != null) {
            recurringDonationIds.addAll(insertIds);
        }

        Set<Id> updateIds = updatePauseSchedules(pauseData, schedulesToUpdate);
        if (updateIds != null) {
            recurringDonationIds.addAll(updateIds);
        }
        if (!recurringDonationIds.isEmpty()) {
            RD2_QueueableService.enqueueOppEvalService(recurringDonationIds, recurringDonationIds);
        }

        return pauseData;
    }

    private List<npe03__Recurring_Donation__c> getRecurringDonationsById(Set<Id> rdIds) {
        String soql = getRecurringDonationQuery();
        return Database.query(soql);
    }

    private RecurringDonationSchedule__c createPauseSchedule(PauseObject pause, Id rdId) {
        return new RD2_ScheduleService.PauseScheduleHandler().createPauseSchedule(
            pause.statusReason,
            pause.startDate,
            pause.endDate,
            rdId
        );
    }

    private RecurringDonationSchedule__c deactivatePauseSchedule(RD2_RecurringDonation recurringDonation) {
        RecurringDonationSchedule__c schedule = recurringDonation.getPauseSchedule();

        if (schedule == null) {
            return null;
        }

        new RD2_ScheduleService.PauseScheduleHandler().deactivatePauseSchedule(schedule);

        return schedule;
    }

    private Set<Id> insertPauseSchedules(Map<Id, PauseObject> pauseData, List<RecurringDonationSchedule__c> schedules) {
        List<Database.SaveResult> results = Database.insert(schedules, false);

        return handleResultsAndReturnSuccessRD(results, pauseData, schedules);
    }

    private Set<Id> updatePauseSchedules(Map<Id, PauseObject> pauseData, List<RecurringDonationSchedule__c> schedules) {
        List<Database.SaveResult> results = Database.update(schedules, false);

        return handleResultsAndReturnSuccessRD(results, pauseData, schedules);
    }

    private Set<Id> handleResultsAndReturnSuccessRD(List<Database.SaveResult> results, Map<Id, PauseObject> pauseData, List<RecurringDonationSchedule__c> schedules) {
        Set<Id> successfulProcessIds = new Set<Id>();

        for (Integer i = 0; i < results.size(); i++) {
            Id recurringDonationId = schedules[i].RecurringDonation__c;

            if (results[i].isSuccess()) {
                successfulProcessIds.add(recurringDonationId);
            } else {
                PauseObject pauseInfo = pauseData.get(recurringDonationId);
                pauseInfo.addError(results[i].getErrors()[0].getMessage());
            }
        }

        return successfulProcessIds;
    }

    public class PauseObject {

        public Date startDate;
        public Date endDate;
        public String statusReason;
        public Boolean unPause;
        public Boolean isSuccess;
        public String error;

        public PauseObject addError(String errorString) {
            this.isSuccess = false;
            this.error = errorString;

            return this;
        }

        public PauseObject populateDefaultValues() {
            this.isSuccess = true;
            this.unPause = (this.unPause == null)
                ? false
                : this.unPause;

            return this;
        }
    }

    public class PauseValidator {
        PauseObject pause;

        PauseValidator(PauseObject pause) {
            this.pause = pause;
        }

        public void validatePauseData(Id rdId, RD2_RecurringDonation recurringDonation) {
            validateRecurringDonationId(rdId);
            validateStateShouldBeActive(recurringDonation);
            validateRecurringDonationNotLinkedToElevate(recurringDonation);

            if (this.pause.unPause) {
                validateUnPause();
            } else {
                validateDatesArePopulated();
                validateEndDateGreaterThanOrEqualToStartDate();
                validateStartDateGreaterThanOrEqualToToday();
                validateEndDateNoGreaterThanTwelveMonthsFromStartDate();
            }
        }

        private void validateRecurringDonationId(Id recordId) {
            if (UTIL_Describe.isObjectIdThisType(recordId, 'npe03__Recurring_Donation__c') == false) {
                pause.addError(String.format(System.Label.RD2_InvalidRecurringDonationId,
                        new List<String> { recordId }));
            }
        }

        private void validateStateShouldBeActive(RD2_RecurringDonation recurringDonation) {
            if (!pause.isSuccess) {
                return;
            }

            if (!recurringDonation.isActive()) {
                pause.addError(System.Label.RD2_StatusMustBeActiveOrPause);
            }
        }

        private void validateRecurringDonationNotLinkedToElevate(RD2_RecurringDonation recurringDonation) {
            if (!pause.isSuccess) {
                return;
            }

            if (recurringDonation.isElevateRecord()) {
                pause.addError(System.Label.RD2_ElevateRDCannotBePaused);
            }
        }

        private void validateUnPause() {
            if (!pause.isSuccess) {
                return;
            }

            if (pause.startDate != null || pause.endDate != null) {
                pause.addError(System.Label.RD2_UnPauseRequestCannotIncludeDates);
            }
        }

        private void validateEndDateGreaterThanOrEqualToStartDate() {
            if (!pause.isSuccess) {
                return;
            }

            if (pause.startDate > pause.endDate) {
                pause.addError(System.Label.RD2_PauseEndDateMustBeGreaterThanStartDate);
            }
        }

        private void validateDatesArePopulated() {
            if (!pause.isSuccess) {
                return;
            }

            if (pause.startDate == null || pause.endDate == null) {
                pause.addError(System.Label.RD2_PauseRequestMustIncludeBothStartDateAndEndDate);
            }
        }

        private void validateEndDateNoGreaterThanTwelveMonthsFromStartDate() {
            if (!pause.isSuccess) {
                return;
            }

            if (pause.endDate > pause.startDate.addYears(1).addDays(1)) {
                pause.addError(System.Label.RD2_PauseEndDateCannotBeMoreThanTwelveMonths);
            }
        }

        private void validateStartDateGreaterThanOrEqualToToday() {
            if (!pause.isSuccess) {
                return;
            }

            if (pause.startDate < RD2_ScheduleService.currentDate) {
                pause.addError(System.Label.RD2_PauseStartDateMustBeTodayOrLater);
            }
        }
    }
}
