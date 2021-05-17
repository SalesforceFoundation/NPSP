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
* @description Recurring Donation SObject wrapper
*
*/
public inherited sharing class RD2_RecurringDonation {

    /**
    * @description Recurring Donation record containing
    * related Opportunities and Schedules in subqueries
    */
    npe03__Recurring_Donation__c rd;

    /**
    * @description Indicates if the Recurring Donation is a new record
    * The Recurring Donation is considered as new if it has no related Opp
    */
    private Boolean isNew;

    /**
    * @description Indicates the converted State of the Recurring Donation from Status To State Mapping 
    */
    private String state {
        get { 
            state = RD2_StatusMapper.getInstance().getState(rd.Status__c);
            return state;
        }
        set;
    }

    /**
    * @description Recurring Donation record current and future Opportunities
    */
    List<Opportunity> opportunities = new List<Opportunity>();

    /**
    * @description A list of the fields that have been changed by one of the revise methods.
    */
    private Set<Schema.SObjectField> changedFields = new Set<Schema.SObjectField>();

    /**
    * @description Constructor
    * @param rd Recurring Donation record
    */
    public RD2_RecurringDonation(npe03__Recurring_Donation__c rd) {
        this(rd, rd.npe03__Donations__r);
    }

    /**
    * @description Constructor
    * @param rd Recurring Donation record
    * @param opportunities Recurring Donation current and future Opportunities
    */
    public RD2_RecurringDonation(npe03__Recurring_Donation__c rd, List<Opportunity> opportunities) {
        this.rd = rd;

        this.opportunities = opportunities == null 
            ? new List<Opportunity>()
            : opportunities;
    }

    /**
    * @description Returns current and future Opportunities on the Recurring Donation
    * @param List<Opportunity>
    */
    public List<Opportunity> getOpportunities() {
        return this.opportunities;
    }

    /**
    * @description Revises and sets the Recurring Donation Next Donation Date on the record insert
    * @param scheduleService RD Schedule Service
    * @return RD2_RecurringDonation This record instance
    */
    public RD2_RecurringDonation reviseNextDonationDateBeforeInsert(RD2_ScheduleService scheduleService) {
        return setNextDonationDate(
            scheduleService.getNextDonationDate(rd)
        );
    }

    /**
    * @description Revises and modifies the Recurring Donation Next Donation Date.
    * @param scheduleService RD Schedule Service
    * @return RD2_RecurringDonation This record instance
    */
    public RD2_RecurringDonation reviseNextDonationDate(RD2_ScheduleService scheduleService) {
        return reviseNextDonationDate(scheduleService, rd.RecurringDonationSchedules__r);
    }

    /**
    * @description Revises and modifies the Recurring Donation Next Donation Date.
    * Whenever the Next Donation Date is being revised, review the status and the Next Donation Date
    * for a fixed-length RD in the case it should be closed.
    * If so, the next installment Opp should not be created when the last open Opp on the fixed-length RD is closed.
    * @param scheduleService RD Schedule Service
    * @param rdSchedules Existing Schedules on the Recurring Donation
    * @return RD2_RecurringDonation This record instance
    */
    public RD2_RecurringDonation reviseNextDonationDate(RD2_ScheduleService scheduleService, List<RecurringDonationSchedule__c> rdSchedules) {
        return setNextDonationDate(
            scheduleService.getNextDonationDate(this, rdSchedules)
        );
    }

    /**
    * @description Sets the Next Donation Date on the Recurring Donation if the value has changed
    * @param nextDonationDate Calculated value of the next donation date
    * @return RD2_RecurringDonation This record instance
    */
    private RD2_RecurringDonation setNextDonationDate(Date nextDonationDate) {
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
    * @return RD2_RecurringDonation This record instance
    */
    public RD2_RecurringDonation reviseYearValues(RD2_YearValueProcessor processor) {
        Decimal value = processor.calcCurrentYearValue(opportunities, rd.RecurringDonationSchedules__r);
        if (value != rd.CurrentYearValue__c) {
            rd.CurrentYearValue__c = value;
            changedFields.add(npe03__Recurring_Donation__c.CurrentYearValue__c);
        }

        value = processor.calcNextYearValue(opportunities, rd.RecurringDonationSchedules__r);
        if (value != rd.NextYearValue__c) {
            rd.NextYearValue__c = value;
            changedFields.add(npe03__Recurring_Donation__c.NextYearValue__c);
        }

        return this;
    }

    /**
    * @description Revises and modifies the Recurring Donation status
    * @param currentDate Used to determined current date
    * @param scheduleService RD Schedule Service
    * @return RD2_RecurringDonation This record instance
    */
    public RD2_RecurringDonation reviseStatus(Date currentDate, RD2_ScheduleService scheduleService) {
        if (!isActive()) {
            return this;
        }

        if (isFixedLength()) {
            reviseStatusForFixedLength();

        } else if (isOpenEnded()) {
            reviseStatusForOpenEnded(currentDate);
        }

        reviseStatusForPaused(currentDate, scheduleService);

        return this;
    }

    /**
    * @description Revises and modifies the Recurring Donation if it is Fixed Length and is now fully completed
    * based on the Number of Planned Installments as compared to the Number of Paid Installments.
    * @return RD2_RecurringDonation This record instance
    */
    private RD2_RecurringDonation reviseStatusForFixedLength() {
        if (isFixedLength()
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
    *@description Revises and modifies the Recurring Donation if it is Open Ended and it past the RD End Date
    * @param currentDate Used to determined current date
    * @return RD2_RecurringDonation This record instance
    */
    private RD2_RecurringDonation reviseStatusForOpenEnded(Date currentDate) {
        if (isOpenEnded()
            && rd.EndDate__c != null
            && rd.EndDate__c < currentDate
        ) {
            rd.Status__c = RD2_Constants.STATUS_CLOSED;
            changedFields.add(npe03__Recurring_Donation__c.Status__c);

        }

        return this;
    }

    /**
    * @description Revises and modifies for paused and unpaused Recurring Donation
    * @param currentDate Used to determined current date
    * @param scheduleService RD Schedule Service
    */
    private void reviseStatusForPaused(Date currentDate, RD2_ScheduleService scheduleService) {
        if (isClosed() || !hasSchedule()) {
            return;
        }
    
        if (scheduleService.isCurrentlyPaused(currentDate, rd.RecurringDonationSchedules__r)) {

            if (rd.Status__c != RD2_Constants.STATUS_PAUSED && RD2_ValidationService.isStatusPausedActive()) {
                RecurringDonationSchedule__c nextPauseSchedule = scheduleService.getNextActivePauseSchedule(
                    currentDate,
                    rd.RecurringDonationSchedules__r
                );

                rd.Status__c = RD2_Constants.STATUS_PAUSED;
                rd.ClosedReason__c = nextPauseSchedule.StatusReason__c;
                changedFields.add(npe03__Recurring_Donation__c.Status__c);
                changedFields.add(npe03__Recurring_Donation__c.ClosedReason__c);
            }
        } else {

            if (rd.Status__c == RD2_Constants.STATUS_PAUSED) {
                rd.Status__c = RD2_Constants.STATUS_ACTIVE;
                rd.ClosedReason__c = '';
                changedFields.add(npe03__Recurring_Donation__c.Status__c);
                changedFields.add(npe03__Recurring_Donation__c.ClosedReason__c);
            }
        }
    }

    /**
    * @description Sets the Number of Planned Installments to null when RecurringType is Open
    * and Number of Planned Installments = 1 (default)
    * @return RD2_RecurringDonation This record instance
    */
    public RD2_RecurringDonation revisePlannedInstallments() {

        if (isOpenEnded() && rd.npe03__Installments__c == 1) {
            rd.npe03__Installments__c = null;
            changedFields.add(npe03__Recurring_Donation__c.npe03__Installments__c);
        }

        return this;
    }

    /**
    * @description Revises and modifies the Number of Paid Installments for a fixed-length RD
    * @param paidInstallments Number of Paid Installments
    * @return RD2_RecurringDonation This record instance
    */
    public RD2_RecurringDonation revisePaidInstallments(Integer paidInstallments) {
        //do not check if the Number of Paid Installments is up to date for an open RD,
        //the CRLP can update the number asynchronously
        if (!isFixedLength() || paidInstallments == null) {
            return this;
        }

        if (paidInstallments != rd.npe03__Total_Paid_Installments__c) {
            rd.npe03__Total_Paid_Installments__c = paidInstallments;
            changedFields.add(npe03__Recurring_Donation__c.npe03__Total_Paid_Installments__c);
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
    * @description Return the Recurring Donation record
    * @return npe03__Recurring_Donation__c
    */
    public npe03__Recurring_Donation__c getSObject() {
        return rd;
    }

    /**
    * @description Indicates if the Recurring Donation is active
    * @return Boolean
    */
    public Boolean isActive() {
        return state == RD2_Constants.STATUS_ACTIVE;
    }

    /**
    * @description Indicates if the Recurring Donation is lapsed
    * @return Boolean
    */
    public Boolean isLapsed() {
        return state == RD2_Constants.STATUS_LAPSED;
    }

    /**
    * @description Indicates if the Recurring Donation is closed
    * @return Boolean
    */
    public Boolean isClosed() {
        return state == RD2_Constants.STATUS_CLOSED;
    }

    /**
    * @description Indicates if the Recurring Donation is open ended.  Must evaluate the proxy
    * behavior of isFixedLength() as well since RecurringType__c == 'Open' during dry run.
    * @return Boolean
    */
    public Boolean isOpenEnded() {
        return !isFixedLength() && rd.RecurringType__c == RD2_Constants.RECURRING_TYPE_OPEN ;
    }

    /**
    * @description Indicates if the Recurring Donation is fixed length
    * @return Boolean
    */
    public Boolean isFixedLength() {
        return RD2_EnablementService.isFixedLength(rd);
    }

    /**
     * @description Indicates if the number of paid installments is equal to or greater than number of planned installments
     * @return Boolean
     */
    public Boolean isFixedLengthComplete() {
        return rd.npe03__Total_Paid_Installments__c >= rd.npe03__Installments__c;
    }

    /**
    * @description Return number of planned installments on the Recurring Donation, default to 0 when null
    * @return Integer
    */
    public Integer getPlannedInstallments() {
        return rd.npe03__Installments__c == null
            ? 0
            : rd.npe03__Installments__c.intValue();
    }

    /**
    * @description Return number of paid installments on the Recurring Donation, default to 0 when null
    * @return Integer
    */
    public Integer getPaidInstallments() {
        return rd.npe03__Total_Paid_Installments__c == null
            ? 0
            : rd.npe03__Total_Paid_Installments__c.intValue();
    }

    public String paymentMethod() {
        return rd.PaymentMethod__c;
    }

    /**
    * @description Return the state of the Recurring Donation.
    * @return String 
    */
    public String getState() {
        return state;
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

    /***
     * @description Determines if the Installment Frequency is in the range
     * @return Boolean
     */
    public Boolean isValidInstallmentFrequency() {
        return rd.InstallmentFrequency__c != null
            && rd.InstallmentFrequency__c >= 1
            && rd.InstallmentFrequency__c <= 20;
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
    public RD2_RecurringDonation setIsNew(Boolean isNew) {
        this.isNew = isNew;
        return this;
    }

    /**
    * @description Indicates if the Recurring Donation is new, ie the RD has no installment Opp
    * @return Boolean
    */
    public Boolean isNew() {
        return isNew == null
            ? opportunities.isEmpty()
            : isNew;
    }

    /**
    * @description Indicates if the Recurring Donation has first installment creation disabled.
    * @return Boolean 
    */
    public Boolean isFirstInstallmentDisabled() {
        return rd.DisableFirstInstallment__c == true;
    }

    /**
    * @description Indicates if the Recurring Donation has an open Opportunity with Close Date >= current date
    * @param currentDate The current date
    * @return Boolean
    */
    public Boolean hasCurrentOpenOpportunity(Date currentDate) {
        return new RD2_OpportunityMatcher(currentDate)
            .includeCurrent(opportunities)
            .hasOpenOpportunity();
    }

    /**
    * @description Indicates if the Recurring Donation has any open Opportunity
    * @return Boolean
    */
    public Boolean hasOpenOpportunity() {
        for (Opportunity opp : opportunities) {
            if (opp.IsClosed == false) {
                return true;
            }
        }
        return false;
    }

    /***
    * @description Checks if the Recurring Donation is originated in Elevate
    */
    public Boolean isElevateRecord() {
       return String.isNotBlank(rd.CommitmentId__c);
    }

    public Boolean hasValidRecurringDonationPaymentMethod() {
        if (isElevateRecord()) {
            return isValidElevatePaymentMethod();
        }
        return true;
    }

    private Boolean isValidElevatePaymentMethod() {
        return paymentMethod() == RD2_Constants.PAYMENT_PICKLIST_VALUE_CARD ||
               paymentMethod() == RD2_Constants.PAYMENT_PICKLIST_VALUE_ACH;
    }
}