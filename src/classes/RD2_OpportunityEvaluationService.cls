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
* @description Installment Opportunity Evaluation and Processing
*
*/
public inherited sharing class RD2_OpportunityEvaluationService {

    /***
     * @description CurrencyIsoCode field name
     */
    private static final String CURRENCY_ISO_CODE_FIELD = UTIL_Currency.CURRENCY_ISO_CODE_FIELD;

    /***
    * @description Determines if multi-currency is enabled for the org
    */
    private Boolean isMultiCurrencyEnabled {
        get {
            if (isMultiCurrencyEnabled == null) {
                isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
            }
            return isMultiCurrencyEnabled;
        }
        set;
    }

    /**
     * @description Indicates if the Opp evaluation service will be skipped.
     * The flag is currently applicable to migration since the Opp evaluation service should not be executed on migration.
     * For example, if an active RD has no Opp, no new Opp should be created during migration.
     * If the RD is closed, close action on Open Opps should not be applied when data migration is executed.
     */
    public static Boolean skipEvaluationService = false;

    /**
    * @description Indicates if the Opportunity evaluation is invoked from a nightly batch job
    */
    private Boolean isBatchContext = false;

    /***
    * @description Recurring Donation custom settings
    */
    private RD2_Settings rdSettings {
        get {
            if (rdSettings == null) {
                rdSettings = new RD2_Settings();
            }
            return rdSettings;
        }
        set;
    }

    /**
     * @description Current date is the cut off date to filter out and evaluate existing Opportunities
     * and to determine if the next Opp should be created for a Recurring Donation.
     * Moreover, it is used to calculate projected installments as of the current date.
     * It can be a past date, today or a future date when testing. When executed from a scheduler,
     * the current date is always today.
    */
    private Date currentDate {
        get {
            if (currentDate == null) {
                currentDate = RD2_ScheduleService.currentDate;
            }
            return currentDate;
        } set;
    }

    /**
     * @description Beggining of the current calendar or fiscal year, whichever is earlier.
    */
    private Date startDate {
        get {
            return yearValueProcessor.getStartDate();
        } set;
    }

    /***
    * @description Recurring Donation Opportunity service
    */
    private RD2_OpportunityService oppService {
        get {
            if (oppService == null) {
                oppService = new RD2_OpportunityService(currentDate, dbService);
            }
            return oppService;
        }
        set;
    }

    /***
    * @description Applies DML operations on records and keeps track of errors
    */
    private DatabaseService dbService {
        get {
            if (dbService == null) {
                dbService = new DatabaseService();
            }
            return dbService;
        }
        set;
    }

    /***
    * @description Recurring Donation Schedule service
    */
    public RD2_ScheduleService scheduleService {
        get {
            if (scheduleService == null) {
                scheduleService = new RD2_ScheduleService();
            }
            return scheduleService;
        } set;
    }

    /***
    * @description Calculates Current and Next Year Values for a Recurring Donation
    */
    private YearValueProcessor yearValueProcessor {
        get {
            if (yearValueProcessor == null) {
                yearValueProcessor = new YearValueProcessor(currentDate, scheduleService);
            }
            return yearValueProcessor;
        }
        set;
    }

    /**
     * @description Recurring Donation Id's to be processed
     */
    public Set<Id> rdIds {
        get {
            if (rdIds == null && rds != null) {
                rdIds = (new Map<Id, npe03__Recurring_Donation__c>(rds)).keySet();
            }
            return rdIds;
        } set;
    }

    /**
     * @description Queried Recurring Donation records with subqueries to be processed.
     */
    @TestVisible
    private List<npe03__Recurring_Donation__c> rds {
        get {
            if (rds == null && rdIds != null) {
                rds = getRecurringDonations(this.rdIds);
            }
            return rds;
        } set;
    }

    /**
    * @description Contains Ids of new Recurring Donations
    */
    @TestVisible
    private Set<Id> newRDIds {
        get {
            if (newRDIds == null) {
                newRDIds = getNewRDIds(this.rdIds);
            }
            return newRDIds;
        } set;
    }

    /**
     * @description Sets batch context
     * @return RD2_OpportunityEvaluationService The service instance
     */
    public RD2_OpportunityEvaluationService withBatchContext() {
        isBatchContext = true;
        return this;
    }

    /**
     * @description Sets current date.
     * It also synchronizes the passed in current date with the RD Schedule service date.
     *
     * @param currentDate Date considered as the current date
     * @return RD2_OpportunityEvaluationService The service instance
     */
    public RD2_OpportunityEvaluationService withCurrentDate(Date currentDate) {
        this.currentDate = currentDate;
        RD2_ScheduleService.currentDate = currentDate;
        return this;
    }

    /**
     * @description Pass the set of Recurring Donation Id's to be processed
     * @param rdIds Recurring Donation Ids
     * @return RD2_OpportunityEvaluationService The service instance
     */
    public RD2_OpportunityEvaluationService withRds(Set<Id> rdIds) {
        this.rdIds = rdIds;
        return this;
    }

    /**
     * @description Returns number of failed Recurring Donation records
     * @return Integer
     */
    public Integer getRecordsFailed() {
        return dbService.getRecordsFailed();
    }

    /**
     * @description Returns true if any of the key fields used to create or manage installment
     * Opportunities has been changed.
     * @param rd Changed Recurring Donation
     * @param oldRd Old Recurring Donation
     * @return Boolean
     */
    public Boolean hasKeyFieldChanged(npe03__Recurring_Donation__c rd, npe03__Recurring_Donation__c oldRd) {
        Boolean isChanged =
            rd.npe03__Contact__c != oldRd.npe03__Contact__c ||
            rd.npe03__Organization__c != oldRd.npe03__Organization__c ||
            rd.npe03__Amount__c != oldRd.npe03__Amount__c ||
            rd.npe03__Installment_Period__c != oldRd.npe03__Installment_Period__c ||
            rd.npe03__Installments__c != oldRd.npe03__Installments__c ||
            rd.InstallmentFrequency__c != oldRd.InstallmentFrequency__c ||
            rd.StartDate__c != oldRd.StartDate__c ||
            rd.Day_of_Month__c != oldRd.Day_of_Month__c ||
            rd.Status__c != oldRd.Status__c ||
            rd.PaymentMethod__c != oldRd.PaymentMethod__c ||
            rd.npe03__Recurring_Donation_Campaign__c != oldRd.npe03__Recurring_Donation_Campaign__c;

        if (!isChanged && isMultiCurrencyEnabled) {
            isChanged = (String) rd.get(CURRENCY_ISO_CODE_FIELD) != (String) oldRd.get(CURRENCY_ISO_CODE_FIELD);
        }

        return isChanged;
    }

    /**
     * @description Primary processor
     * @return RD2_OpportunityEvaluationService This service instance
     */
    public RD2_OpportunityEvaluationService evaluateOpportunities() {
        //do not evaluate Opps when override is set
        if (skipEvaluationService) {
            return this;
        }

        List<npe03__Recurring_Donation__c> newOppRDs = new List<npe03__Recurring_Donation__c>();
        List<npe03__Recurring_Donation__c> updateOppRDs = new List<npe03__Recurring_Donation__c>();
        List<npe03__Recurring_Donation__c> closedRDs = new List<npe03__Recurring_Donation__c>();

        for (npe03__Recurring_Donation__c rd : rds) {
            RecurringDonation rdRecord = new RecurringDonation(rd);

            if (!rdRecord.isEnhancedFormat()) {
                continue;
            }

            rdRecord
                .setIsNew(newRDIds.contains(rd.Id))
                .reviseNextDonationDate(scheduleService);

            if (rdRecord.isClosed()) {
                closedRDs.add(rd);

            } else {
                if (isNewOpportunityCandidate(rdRecord)) {
                    newOppRDs.add(rd);
                }

                if (hasOpenOpportunity(rdRecord)) {
                    updateOppRDs.add(rd);
                }
            }

            // TODO Handle Past Due Installment
        }

        toggleTriggerState(false);

        oppService
            .createOpportunities(newOppRDs)
            .updateOpportunities(updateOppRDs)
            .voidOpenOpportunities(closedRDs);

        handleOutdatedRecurringDonations();

        toggleTriggerState(true);

        dbService.processErrors();

        return this;
    }

    /**
     * @description Update Next Donation Date and Current/Next Year Value
     * on Recurring Donations when they are not in sync with existing Opps and projected installments.
     * @return RD2_OpportunityEvaluationService This service instance
     */
    public RD2_OpportunityEvaluationService handleOutdatedRecurringDonations() {
        //do not evaluate Opps when override is set
        if (skipEvaluationService) {
            return this;
        }

        rds = null;//reset Recurring Donations so just created/updated Opps are retrieved

        List<npe03__Recurring_Donation__c> outdatedRDs = new List<npe03__Recurring_Donation__c>();
        for (npe03__Recurring_Donation__c rd : rds) {
            RecurringDonation rdRecord = new RecurringDonation(rd);

            if (!rdRecord.isEnhancedFormat()) {
                continue;
            }

            if (rdRecord
                .reviseStatusForFixedLength()
                .reviseNextDonationDate(scheduleService)
                .reviseYearValues(yearValueProcessor)
                .isOutdated()
            ) {
                outdatedRDs.add(rdRecord.getUpdate());
            }
        }

        toggleTriggerState(false);
        dbService.updateRecords(outdatedRDs);
        toggleTriggerState(true);

        return this;
    }

    /**
     * @description Activate or deactive RD2 triggers
     * @param isActive Indicates if triggers are active
     * @return void
     */
    private void toggleTriggerState(Boolean isActive) {
        TDTM_ProcessControl.toggleTriggerState('npe03__Recurring_Donation__c', 'RD2_RecurringDonations_TDTM', isActive);
        TDTM_ProcessControl.toggleTriggerState('Opportunity', 'RD2_RecurringDonationsOpp_TDTM', isActive);
    }

    /**
     * @description Indicates if a Recurring Donation requires a new installment Opp to be created.
     * @param rd Recurring Donation SObject
     * @return Boolean
     */
    @TestVisible
    private Boolean isNewOpportunityCandidate(npe03__Recurring_Donation__c rd) {
        return isNewOpportunityCandidate(new RecurringDonation(rd));
    }

    /**
     * @description Indicates if the Recurring Donation require a new installment Opp to be created.
     * Schedules are inserted when the Recurring Donation is created and before Opp evaluation is done.
     * @param rd Recurring Donation record
     * @return Boolean
     */
    private Boolean isNewOpportunityCandidate(RecurringDonation rd) {
        Boolean hasMandatoryConditions = rd.isActive()
            && rd.hasNextDonationDate()
            && rd.hasSchedule();

        if (!hasMandatoryConditions) {
            return false;
        }

        if (isBatchContext) {
            return !rdSettings.isDisableAllInstallments;

        } else if (rd.isNew()) {
            return rdSettings.isFirstInstallmentEnabled;

        } else if (!rd.hasCurrentOpenOpportunity(currentDate)) {
            return rdSettings.isNextInstallmentEnabled;
        }

        return false;
    }

    /**
     * @description Determines if the Recurring Donation open Opportunity should be updated
     * @param rd Recurring Donation record
     * @return Boolean
     */
    private Boolean hasOpenOpportunity(RecurringDonation rd) {
        return !isBatchContext
            && rd.isActive()
            && rd.hasSchedule()
            && rd.hasOpenOpportunity();
    }

    /**
     * @description Populate the collection of Recurring Donation records, querying ALL fields,
     * with the related Installment Opportunities and Active Schedule Records. Due to a core KI (W-2503825)
     * this query needs to exclude CLOB fields. Since there is no pure definition of that for a Describe, the
     * query excludes Large Text Area fields larger than 4KB. These would only be custom fields.
     * @param rdIds Recurring Donation Ids
     * @return List<RecurringDonation> Recurring Donations with related installment Opportunities and active Schedules
     */
    @TestVisible
    private List<npe03__Recurring_Donation__c> getRecurringDonations(Set<Id> rdIds) {
        final String parentAccountField = 'npe03__Contact__r.AccountId';

        Map<String, Schema.DescribeFieldResult> allRdFields =
            UTIL_Describe.getAllFieldsDescribe(npe03__Recurring_Donation__c.SObjectType.getDescribe().name);

        Set<String> queryFields = new Set<String>();
        for (String fld : allRdFields.keySet()) {
            DescribeFieldResult fldResult = allRdFields.get(fld);
            if (fldResult.getType() == DisplayType.BASE64 ||
                    fldResult.getType() == DisplayType.ENCRYPTEDSTRING ||
                    (fldResult.getSoapType() == SoapType.STRING && fldResult.getLength() > 4096)) {
                continue;
            }
            queryFields.add(fld);
        }

        //Return Recurring Donations'
        //open Opps regardless of the Close Date
        //and Opps with Close Date >= current date regardless if closed or open
        //and all Opps with Close Date in this current year
        String oppSubquery =
            '(SELECT Id, Name, AccountId, Primary_Contact__c, ' +
            'npe03__Recurring_Donation__c, ' +
            'Amount, CloseDate, ' +
            'StageName, IsClosed, IsWon, ' +
            'CampaignId, Recurring_Donation_Installment_Number__c ';

        if (isMultiCurrencyEnabled) {
            oppSubquery += ', ' + CURRENCY_ISO_CODE_FIELD + ' ';
        }

        oppSubquery += 'FROM npe03__Donations__r ' +
            'WHERE IsClosed = false ' +
            'OR CloseDate >= :startDate ' +
            'ORDER BY npe03__Recurring_Donation__c, CloseDate ASC)';

        //Return all schedules for the RD Schedule visualization.
        //The RD Schedule will filter them out if not applicable within the time period.
        String scheduleSubquery =
            '(SELECT Id, InstallmentAmount__c, ' +
            'Campaign__c, ' +
            'Campaign__r.Name, ' +
            'InstallmentFrequency__c, ' +
            'InstallmentPeriod__c, ' +
            'DayOfMonth__c, ' +
            'PaymentMethod__c, ' +
            'StartDate__c, ' +
            'EndDate__c ' +
            'FROM RecurringDonationSchedules__r)';

        queryFields.add(parentAccountField);
        queryFields.add(oppSubquery);
        queryFields.add(scheduleSubquery);

        String soql = new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(queryFields)
            .withWhere('Id IN :rdIds')
            .build();

        return Database.query(soql);
    }

    /**
    * @description Determines which Recurring Donations are new
    * @param rdIds All Recurring Donation Ids to be evaluated
    * @return Set<Id> Ids of new Recurring Donations
    */
    private Set<Id> getNewRDIds(Set<Id> rdIds) {
        Set<Id> newRDIds = new Set<Id>();

        for (npe03__Recurring_Donation__c rd : [
            SELECT Id,
                (
                    SELECT Id
                    FROM npe03__Donations__r
                    LIMIT 1
                )
            FROM npe03__Recurring_Donation__c
            WHERE Id IN :rdIds
        ]) {
            if (rd.npe03__Donations__r.isEmpty()) {
                newRDIds.add(rd.Id);
            }
        }

        return newRDIds;
    }

    /**
     * @description Recurring Donation SObject wrapper
     */
    public class RecurringDonation {

        /**
        * @description Recurring Donation record
        */
        npe03__Recurring_Donation__c rd;

        /**
        * @description Indicates if the Recurring Donation is a new record
        */
        private Boolean isNew;

        /**
        * @description A list of the fields that have been changed by one of the revise methods.
        */
        private Set<Schema.SObjectField> changedFields = new Set<Schema.SObjectField>();

        /**
        * @description Constructor
        * @param rd Recurring Donation record
        */
        public RecurringDonation(npe03__Recurring_Donation__c rd) {
            this.rd = rd;
        }

        /**
        * @description Revises and modifies the Recurring Donation Next Donation Date
        * @param scheduleService RD Schedule Service
        * @return RecurringDonation This record instance
        */
        public RecurringDonation reviseNextDonationDate(RD2_ScheduleService scheduleService) {
            if (isClosed()) {
                return this;
            }

            Date nextDonationDate = scheduleService.getNextDonationDate(rd.RecurringDonationSchedules__r);
            if (nextDonationDate != rd.npe03__Next_Payment_Date__c) {
                rd.npe03__Next_Payment_Date__c = nextDonationDate;
                changedFields.add(npe03__Recurring_Donation__c.npe03__Next_Payment_Date__c);
            }

            return this;
        }

        /**
        * @description Revises and modifies the Recurring Donation
        * Current Year Value and Next Year Value fields
        * @param processor Used to calculate current and next year values
        * @return RecurringDonation This record instance
        */
        public RecurringDonation reviseYearValues(YearValueProcessor processor) {
            Decimal value = processor.calcCurrentYearValue(rd.npe03__Donations__r, rd.RecurringDonationSchedules__r);
            if (value != rd.CurrentYearValue__c) {
                rd.CurrentYearValue__c = value;
                changedFields.add(npe03__Recurring_Donation__c.CurrentYearValue__c);
            }

            value = processor.calcNextYearValue(rd.npe03__Donations__r, rd.RecurringDonationSchedules__r);
            if (value != rd.NextYearValue__c) {
                rd.NextYearValue__c = value;
                changedFields.add(npe03__Recurring_Donation__c.NextYearValue__c);
            }

            return this;
        }

        /**
        * @description Revises and modifies the Recurring Donation if it is Fixed Length and is now fully completed
        * based on the Number of Planned Installments as compared to the Number of Paid Installments.
        * @return RecurringDonation This record instance
        */
        public RecurringDonation reviseStatusForFixedLength() {
            if (isActive()
                && isFixedLength()
                && isFixedLengthComplete()
            ) {
                rd.Status__c = RD2_Constants.STATUS_CLOSED;
                rd.ClosedReason__c = RD2_Constants.FIXED_TYPE_CLOSED_REASON;
                rd.npe03__Next_Payment_Date__c = null;
                changedFields.add(npe03__Recurring_Donation__c.Status__c);
                changedFields.add(npe03__Recurring_Donation__c.ClosedReason__c);
                changedFields.add(npe03__Recurring_Donation__c.npe03__Next_Payment_Date__c);
            }
            return this;
        }


        /**
        * @description Indicates if the Recurring Donation is outdated and requiring an update
        * @return Boolean
        */
        public Boolean isOutdated() {
            return !changedFields.isEmpty();
        }

        /**
        * @description Returns Recurring Donation fields that potentially can be modified
        * @return npe03__Recurring_Donation__c
        */
        public npe03__Recurring_Donation__c getUpdate() {
            npe03__Recurring_Donation__c updatedRd = new npe03__Recurring_Donation__c(Id = rd.Id);
            for (SObjectField field : changedFields) {
                updatedRd.put(field, rd.get(field));
            }
            return updatedRd;
        }

        /**
        * @description Indicates if the Recurring Donation is active
        * @return Boolean
        */
        public Boolean isActive() {
            return rd.Status__c == RD2_Constants.STATUS_ACTIVE;
        }

        /**
        * @description Indicates if the Recurring Donation is closed
        * @return Boolean
        */
        public Boolean isClosed() {
            return rd.Status__c == RD2_Constants.STATUS_CLOSED;
        }

        /**
        * @description Indicates if the Recurring Donation is open ended
        * @return Boolean
        */
        public Boolean isOpenEnded() {
            return rd.RecurringType__c == RD2_Constants.RECURRING_TYPE_OPEN;
        }

        /**
        * @description Indicates if the Recurring Donation is fixed length
        * @return Boolean
        */
        public Boolean isFixedLength() {
            return rd.RecurringType__c == RD2_Constants.RECURRING_TYPE_FIXED;
        }

        /**
         * @description Indicates if the number of paid installments is equal to or greater than number of planned installments
         * @return Boolean
         */
        public Boolean isFixedLengthComplete() {
            return rd.npe03__Total_Paid_Installments__c >= rd.npe03__Installments__c;
        }

        /**
        * @description Returns true if the RD record is in enhanced Recurring Donation format
        */
        public Boolean isEnhancedFormat() {
            return String.isNotBlank(rd.Status__c) && rd.InstallmentFrequency__c != null;
        }

        /**
        * @description Indicates if the Recurring Donation Next Donation Date is determined
        * @return Boolean
        */
        public Boolean hasNextDonationDate() {
            return rd.npe03__Next_Payment_Date__c != null;
        }

        /**
        * @description Indicates if the Recurring Donation has a Schedule
        * @return Boolean
        */
        public Boolean hasSchedule() {
            return !rd.RecurringDonationSchedules__r.isEmpty();
        }

        /**
        * @description Sets property indicating the Recurring Donation is a new record
        * @param isNew Indicates if the record is new
        * @return Boolean
        */
        public RecurringDonation setIsNew(Boolean isNew) {
            this.isNew = isNew;
            return this;
        }

        /**
        * @description Indicates if the Recurring Donation is new, ie the RD has no installment Opp
        * @return Boolean
        */
        public Boolean isNew() {
            return isNew == null
                ? rd.npe03__Donations__r.isEmpty()
                : isNew;
        }

        /**
        * @description Indicates if the Recurring Donation has an open Opportunity with Close Date >= current date
        * @param currentDate Current Date to compare the Close Date to
        * @return Boolean
        */
        public Boolean hasCurrentOpenOpportunity(Date currentDate) {
            return new RD2_OpportunityMatcher(currentDate)
                .includeCurrentAndOpen(rd.npe03__Donations__r)
                .size() > 0;
        }

        /**
        * @description Indicates if the Recurring Donation has any open Opportunity
        * @return Boolean
        */
        public Boolean hasOpenOpportunity() {
            for (Opportunity opp : rd.npe03__Donations__r) {
                if (opp.IsClosed == false) {
                    return true;
                }
            }
            return false;
        }
    }

    /**
    * @description Recurring Donation processor calculating Current Year Value and Next Year Value
    * NOTE: values are calculated based on the calendar year currently.
    */
    public class YearValueProcessor {
        /**
        * @description Recurring Donation Schedule Service
        */
        private RD2_ScheduleService scheduleService;

        /**
        * @description Date representing current date.
        * It can be back-dated or future-dated during testing, but it defaults to today
        * in the batch scheduler or if not provided in testing.
        * Date is populated from the Opp eval service.
        */
        private Date currentDate;

        /**
        * @description Date at the beginning of the current calendar or fiscal year.
        * Used to retrieve current year Opportunities regardless if they are open or closed.
        */
        private Date currentYearStartDate {
            get {
                if (currentYearStartDate == null) {
                    currentYearStartDate = Date.newInstance(currentDate.year(), 1, 1);
                }
                return currentYearStartDate;
            }
            set;
        }

        /**
        * @description Date at the end of the current calendar or fiscal year.
        * Used to set end date for projected installments' Close Date.
        */
        private Date currentYearEndDate {
            get {
                if (currentYearEndDate == null) {
                    currentYearEndDate = Date.newInstance(currentDate.year(), 12, 31);
                }
                return currentYearEndDate;
            }
            set;
        }

        /**
        * @description Date at the beginning of the next calendar or fiscal year.
        * Used to retrieve next year Opportunities regardless if they are open or closed.
        */
        private Date nextYearStartDate {
            get {
                if (nextYearStartDate == null) {
                    nextYearStartDate = Date.newInstance(currentDate.addYears(1).year(), 1, 1);
                }
                return nextYearStartDate;
            }
            set;
        }

        /**
        * @description Date at the end of the next calendar or fiscal year.
        * Used to set end date for projected installments' Close Date.
        */
        private Date nextYearEndDate {
            get {
                if (nextYearEndDate == null) {
                    nextYearEndDate = Date.newInstance(currentDate.addYears(1).year(), 12, 31);
                }
                return nextYearEndDate;
            }
            set;
        }

        /**
        * @description Constructor
        * @param currentDate Current Date
        * @param scheduleService RD Schedule Service
        */
        public YearValueProcessor(Date currentDate, RD2_ScheduleService scheduleService) {
            this.currentDate = currentDate;
            this.scheduleService = scheduleService;
        }

        /**
        * @description Returns the earliest date to filter open/closed Opportunities based on their Close Date.
        * If the current year is a calendar year, the current year start date is earlier than the current date.
        * If the current year is a fiscal year, the current year start date is also earlier than the current date.
        * So regardless if we calculate calendar or fiscal year values, we can use the current year start date
        * as the cut off date to get existing Opportunities in the Opp eval service .
        */
        public Date getStartDate() {
            return currentYearStartDate;
        }

        /**
        * @description Calculates Current Year Value
        * NOTE: the value is calculated based on the calendar year currently.
        *
        * @param opps A Recurring Donation Opportunities
        * @param schedules A Recurring Donation Schedules
        * @return Decimal
        */
        public Decimal calcCurrentYearValue(List<Opportunity> opps, List<RecurringDonationSchedule__c> schedules) {
            return calcCalendarYearValue(opps, schedules, currentDate, currentYearEndDate);
        }

        /**
        * @description Calculates Next Year Value
        * NOTE: the value is calculated based on the calendar year currently.
        *
        * @param opps A Recurring Donation Opportunities
        * @param schedules A Recurring Donation Schedules
        * @return Decimal
        */
        public Decimal calcNextYearValue(List<Opportunity> opps, List<RecurringDonationSchedule__c> schedules) {
            return calcCalendarYearValue(opps, schedules, nextYearStartDate, nextYearEndDate);
        }

        /**
        * @description Calculates calendar Current or Next Year Value.
        * @param opps A Recurring Donation Opportunities
        * @param schedules A Recurring Donation Schedules
        * @param startDate Start date is the start cutoff date for existing Opps and projected installments
        * @param endDate End date is the end cutoff date for projected installments
        * @return Decimal
        */
        public Decimal calcCalendarYearValue(
            List<Opportunity> opps, List<RecurringDonationSchedule__c> schedules,
            Date startDate, Date endDate
        ) {
            Decimal value = 0;

            List<RD2_ScheduleService.Installment> installments =
                scheduleService.getVisualizedInstallments(startDate, endDate, schedules);

            RD2_OpportunityMatcher matcher = new RD2_OpportunityMatcher(startDate)
                .includeByYear(opps, startDate.year())
                .match(installments);

            for (RD2_OpportunityMatcher.Record record : matcher.getRecords()) {
                if (!record.isClosedLost()) {
                    value += record.getAmount();
                }
            }

            return value;
        }
    }


    /**
     * @description Database DML service to insert/update/delete records and keep track of failed RD Ids
     */
    public class DatabaseService {
        private SObjectType rdSObjectType = npe03__Recurring_Donation__c.SObjectType;
        private SObjectType oppSObjectType = Opportunity.SObjectType;

        private ERR_Handler.Errors errorResult = new ERR_Handler.Errors();
        private Set<Id> failedRDIds = new Set<Id>();

        /***
        * @description Creates specified records
        * @param records Records to create
        * @return Set<Id> Ids of created records
        */
        public Set<Id> insertRecords(List<SObject> records) {
            if (records == null || records.isEmpty()) {
                return new Set<Id>();
            }

            List<Database.SaveResult> saveResults = Database.insert(records, false);
            handleErrors(saveResults, records);

            return getSuccessIds(saveResults);
        }

        /***
        * @description Updates specified records
        * @param records Records to update
        * @return void
        */
        public void updateRecords(List<SObject> records) {
            if (records == null || records.isEmpty()) {
                return;
            }

            List<Database.SaveResult> saveResults = Database.update(records, false);
            handleErrors(saveResults, records);
        }

        /***
        * @description Extracts Ids of records that were successfully created/update
        * @param saveResults Insert/update DML operation results
        * @return Set<Id> Ids of successfully created/updated records
        */
        private Set<Id> getSuccessIds(Database.SaveResult[] saveResults) {
            Set<Id> successIds = new Set<Id>();

            if (saveResults == null || saveResults.isEmpty()) {
                return successIds;
            }

            for (Database.SaveResult result : saveResults) {
                if (result.isSuccess()) {
                    successIds.add(result.getId());
                }
            }
            return successIds;
        }

        /***
        * @description Deletes specified records
        * @param records Records to delete
        * @return void
        */
        public void deleteRecords(List<SObject> records) {
            if (records == null || records.isEmpty()) {
                return;
            }

            List<Database.DeleteResult> deleteResults = Database.delete(records, false);
            handleErrors(deleteResults, records);
        }

        /***
        * @description Keeps track of errors
        * @param dmlResults Database DML results upon insert/update/delete operation
        * @param records SObject records in DML operation
        * @return void
        */
        private void handleErrors(List<Object> dmlResults, List<SObject> records) {
            if (records == null || records.isEmpty()) {
                return;
            }

            //extract errors
            ERR_Handler.Errors dmlErrors = ERR_Handler.getErrorsOnly(dmlResults, records);
            if (dmlErrors.errorRecords.isEmpty()) {
                return;
            }

            errorResult.errorRecords.addAll(
                dmlErrors.errorRecords
            );

            //track failed Recurring Donation Ids
            SObjectType recordSObjectType = records[0].getSObjectType();
            if (recordSObjectType == oppSObjectType) {
                for (Integer i = 0; i < dmlResults.size(); i++) {
                    Boolean isSuccess = dmlResults[i] instanceof Database.SaveResult
                        ? ((Database.SaveResult)dmlResults[i]).isSuccess()
                        : ((Database.DeleteResult)dmlResults[i]).isSuccess();

                    if (!isSuccess) {
                        failedRDIds.add((Id) records[i].get('npe03__Recurring_Donation__c'));
                    }
                }

            } else if (recordSObjectType == rdSObjectType) {
                for (Error__c error : dmlErrors.errorRecords) {
                    failedRDIds.add(error.Related_Record_ID__c);
                }
            }
        }

        /**
        * @description Creates Error__c record for each errorResult.errorRecords
        * @return void
        */
        public void processErrors() {
            errorResult.errorsExist = !errorResult.errorRecords.isEmpty();

            ERR_Handler.processErrorsOnly(errorResult, ERR_Handler_API.Context.RD.name());
        }

        /***
        * @description Returns number of failed Recurring Donations
        * @return Integer
        */
        public Integer getRecordsFailed() {
            failedRDIds.remove(null);

            return failedRDIds.size();
        }
    }
}