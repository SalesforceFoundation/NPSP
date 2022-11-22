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
* @description All services specific to the Recurring Donation Schedule object
*
*/

public without sharing class RD2_ScheduleService {

    /**
    * @description Date unit conversion factor for Recurring Donation weekly period
    */
    private final Integer DAYS_IN_WEEK = 7;

    /**
    * @description Default number of visualization records to calculate
    */
    private final Integer DEFAULT_INSTALLMENT_NUMBER = 12;

    /**
    * @description Date to treat as current date in calculation of schedules.
    * The date should not be overwritten in this class, only from other test classes in order to
    * verify Recurring Donation and its schedule fields based on various "current" dates.
    * This date is used as the starting date to
    * - calculate RD next donation date upon RD creation
    * - set RD Start Date when relevant fields (such as Amount) are changed
    * - calculate projected installment Opportunities' Close Date.
    */
    public static Date currentDate {
        get {
            if (currentDate == null) {
                currentDate = Date.today();
            }
            return currentDate;
        } set;
    }

    /**
    * @description Handles Pause Schedules
    */
    public PauseScheduleHandler pauseHandler {
        get {
            if (pauseHandler == null) {
                pauseHandler = new PauseScheduleHandler();
            }
            return pauseHandler;
        }
        set;
    }

    /***
    * @description Builds new recurring donation schedule(s) for recurring donation
    * @param rd Recurring donation record
    * @return List<RecurringDonationSchedule__c>
    */
    public List<RecurringDonationSchedule__c> buildNewSchedules(npe03__Recurring_Donation__c rd) {
        List<RecurringDonationSchedule__c> newSchedules = new List<RecurringDonationSchedule__c>();

        if (new RD2_RecurringDonation(rd).isClosed()) {
            return newSchedules;
        }

        RecurringDonationSchedule__c schedule = new RecurringDonationSchedule__c();
        schedule.RecurringDonation__c = rd.Id;
        schedule.Campaign__c = rd.npe03__Recurring_Donation_Campaign__c;

        schedule.InstallmentAmount__c = rd.npe03__Amount__c;
        schedule.InstallmentFrequency__c = rd.InstallmentFrequency__c;
        schedule.InstallmentPeriod__c = rd.npe03__Installment_Period__c;
        schedule.PaymentMethod__c = rd.PaymentMethod__c;
        schedule.StartDate__c = (rd.StartDate__c != null ? rd.StartDate__c : rd.npe03__Date_Established__c);

        if (isFirstAndFifteenth(rd)) {
            schedule.DayOfMonth__c = RD2_Constants.DAY_OF_MONTH_FIRST;
            newSchedules.add(schedule);

            schedule = schedule.clone();
            schedule.DayOfMonth__c = RD2_Constants.DAY_OF_MONTH_FIFTEENTH;

        } else {
            schedule.DayOfMonth__c = rd.Day_of_Month__c;
        }

        newSchedules.add(schedule);

        return newSchedules;
    }

    /***
    * @description Determines whether '1st and 15th' is the schedule selected.
    * @param rd Recurring Donation record
    * @return Boolean
    */
    private Boolean isFirstAndFifteenth(npe03__Recurring_Donation__c rd) {
        return rd.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH;
    }


    /***
    * @description Synchronizes the schedule records to match an updated recurring donation
    * and returns only schedules that require to be updated or created.
    * @param rd Recurring Donation record
    * @param schedules Recurring Donation Schedule record
    * @return TDTM_Runnable.DMLWrapper
    */
    public TDTM_Runnable.DMLWrapper getUpdatedSchedules(npe03__Recurring_Donation__c rd, List<RecurringDonationSchedule__c> schedules) {
        Boolean isUpdate = true;
        return rebuildSchedules(rd, schedules, isUpdate);
    }

    /***
    * @description Synchronizes the schedule records to match an updated recurring donation
    * @param rd Recurring Donation record
    * @param schedules Recurring Donation Schedule record
    * @param isUpdate Indicates if returned schedules should be only changed and new schedules
    * @return TDTM_Runnable.DMLWrapper
    */
    private TDTM_Runnable.DMLWrapper rebuildSchedules(npe03__Recurring_Donation__c rd, List<RecurringDonationSchedule__c> schedules, Boolean isUpdate) {
        Date newStartDate = rd.StartDate__c;
        Boolean isClosed = new RD2_RecurringDonation(rd).isClosed();
        TDTM_Runnable.DMLWrapper scheduleChanges = new TDTM_Runnable.DMLWrapper();

        //Add updated schedules
        if (schedules != null) {
            for (RecurringDonationSchedule__c schedule : schedules) {
                //The pause schedule should stay the same if the RD schedule data is updated
                //unless the RD is closed, when all schedules should be closed.
                if (pauseHandler.isPause(schedule)) {
                    Boolean isCurrentPause = schedule.EndDate__c == null || currentDate < schedule.EndDate__c;
                    if (isClosed && isCurrentPause) {
                        schedule.EndDate__c = currentDate.addDays(-1);

                    } else if (!isUpdate && isCurrentPause) {
                        scheduleChanges.objectsToUpdate.add(schedule);
                        continue;

                    } else {
                        continue;
                    }
                }

                if (!isClosed && schedule.StartDate__c <= currentDate) {
                    schedule.EndDate__c = newStartDate.addDays(-1);

                } else if (!isClosed && schedule.StartDate__c > currentDate) {
                    schedule.EndDate__c = schedule.StartDate__c.addDays(-1);

                } else if (isClosed) {
                    schedule.EndDate__c = currentDate.addDays(-1);
                }

                scheduleChanges.objectsToUpdate.add(schedule);
            }
        }

        //Add new schedules
        List<RecurringDonationSchedule__c> newSchedules = buildNewSchedules(rd);
        for (RecurringDonationSchedule__c newSchedule : newSchedules) {
            newSchedule.StartDate__c = newStartDate;
        }

        scheduleChanges.objectsToInsert.addAll(newSchedules);

        return scheduleChanges;
    }

    /***
    * @description Determines whether changes to recurring donation should trigger creation of new schedule(s)
    * @param newRd Trigger.new record
    * @param oldRd Trigger.old record
    * @return Boolean
    */
    @TestVisible
    private Boolean isScheduleUpdateNeeded(npe03__Recurring_Donation__c newRd, npe03__Recurring_Donation__c oldRd) {
        Boolean isNeeded = false;

        RD2_RecurringDonation newRDWrapper = new RD2_RecurringDonation(newRD);
        RD2_RecurringDonation oldRDWrapper = new RD2_RecurringDonation(oldRD);

        // newRD should never be null.  This is a fail safe measure only.
        if (newRd == null) {
            isNeeded = false;

        // Since this method should never be called on inserts, oldRd should never be null.  Defensive again.
        } else if (oldRd == null) {
            isNeeded = true;

        // Invalid Installment Frequency should never result in a schedule update. This is a fail safe measure only
        } else if (!newRDWrapper.isValidInstallmentFrequency()) {
            isNeeded = false;

        // These two special conditions should never result in a schedule update.
        } else if
                ((newRDWrapper.isLapsed() && oldRDWrapper.isActive()) ||
                (newRDWrapper.isActive() && oldRDWrapper.isLapsed()))
        {
            isNeeded = false;

        // Schedules should only be updated if relevant data is updated.
        } else if (
            newRd.StartDate__c != oldRd.StartDate__c ||
            newRd.npe03__Amount__c != oldRd.npe03__Amount__c ||
            newRd.npe03__Installment_Period__c != oldRd.npe03__Installment_Period__c ||
            newRd.Day_of_Month__c != oldRd.Day_of_Month__c ||
            newRd.InstallmentFrequency__c != oldRd.InstallmentFrequency__c ||
            newRd.PaymentMethod__c != oldRd.PaymentMethod__c ||
            newRDWrapper.getState() != oldRDWrapper.getState() ||
            newRd.npe03__Recurring_Donation_Campaign__c != oldRd.npe03__Recurring_Donation_Campaign__c)
        {
            isNeeded = true;
        }

        return isNeeded;
    }



    /***
    * @description Returns active projected installments for provided Recurring Donations.
    * @param rds Recurring Donation records
    * @param startDate Lower boundary date used to filter installments with Close Date >= startDate (if null, current date will be used)
    * @param numInstallments Number of installment Opportunities to return (if null, default number will be used)
    * @param schedulesByRd RD Schedules by RD Id (if null, active schedules will be queried)
    * @return Map<Id, List<Installment>> Upcoming installments mapped by the Recurring Donation Id
    */
    @TestVisible
    private Map<Id, List<Installment>> getVisualizedInstallments(
        List<npe03__Recurring_Donation__c> rds,
        Date startDate,
        Integer numInstallments,
        Map<Id, List<RecurringDonationSchedule__c>> schedulesByRd
    ) {
        if (schedulesByRd == null) {
            schedulesByRd = getExistingSchedules(rds);
        }

        Map<Id, List<Installment>> installmentsByRd = new Map<Id, List<Installment>>();
        for (npe03__Recurring_Donation__c rd : rds) {
            if (rd == null || rd.Id == null) {
                continue;
            }

            installmentsByRd.put(rd.Id, getVisualizedInstallments(startDate, numInstallments, schedulesByRd.get(rd.Id)));
        }

        return installmentsByRd;
    }

    /***
    * @description Returns active projected installments for the Recurring Donation.
    * Installments within the Pause Schedule are excluded and not returned.
    * @param startDate Lower boundary date used to filter installments with Close Date >= startDate
    * @param numInstallments Number of installment Opportunities to return
    * @param schedules RD Schedules
    * @return List<Installment>
    */
    public List<Installment> getVisualizedInstallments(Date startDate, Integer numInstallments, List<RecurringDonationSchedule__c> schedules) {
        Boolean isIncludeSkipped = false;
        return getVisualizedInstallments(startDate, numInstallments, schedules, isIncludeSkipped);
    }

    /***
    * @description Returns all active and skipped projected installments for the Recurring Donation.
    * @param startDate Lower boundary date used to filter installments with Close Date >= startDate
    * @param numInstallments Number of installment Opportunities to return
    * @param schedules RD Schedules
    * @return List<Installment>
    */
    public List<Installment> getAllVisualizedInstallments(Date startDate, Integer numInstallments, List<RecurringDonationSchedule__c> schedules) {
        Boolean isIncludeSkipped = true;
        return getVisualizedInstallments(startDate, numInstallments, schedules, isIncludeSkipped);
    }

    /***
    * @description Returns projected installments for the Recurring Donation.
    * @param startDate Lower boundary date used to filter installments with Close Date >= startDate
    * @param numInstallments Number of installment Opportunities to return
    * @param schedules RD Schedules
    * @param isIncludeSkipped Indicates if skipped Installments within a Pause Schedule date range should be returned
    * @return List<Installment>
    */
    private List<Installment> getVisualizedInstallments(Date startDate, Integer numInstallments, List<RecurringDonationSchedule__c> schedules, Boolean isIncludeSkipped) {
        List<Installment> installments = new List<Installment>();
        if (schedules == null) {
            return installments;
        }

        numInstallments = numInstallments == null
            ? DEFAULT_INSTALLMENT_NUMBER
            : numInstallments;

        Date referenceDate = startDate == null ? currentDate : startDate;
        while (installments.size() < numInstallments) {
            Installment inst = getNextInstallment(referenceDate, schedules);

            if (inst == null) {
                break;
            }

            if (isIncludeSkipped || !inst.isSkipped) {
                installments.add(inst);
            }
            referenceDate = inst.nextDonationDate.addDays(1);
        }

        return installments;
    }

    /***
    * @description Returns projected installments for the Recurring Donation.
    * Installments are used to calculate Current and Next Year Value fields on the RD.
    * @param startDate Lower boundary date used to filter installments with Close Date >= startDate
    * @param endDate Upper boundary date used to filter installments with Close Date <= endDate
    * @param schedules RD Schedules
    * @return List<Installment>
    */
    public List<Installment> getVisualizedInstallments(Date startDate, Date endDate, List<RecurringDonationSchedule__c> schedules) {
        List<Installment> installments = new List<Installment>();
        startDate = startDate == null ? currentDate : startDate;

        if (schedules == null || startDate > endDate) {
            return installments;
        }

        Date referenceDate = startDate;
        while (referenceDate <= endDate) {
            Installment inst = getNextInstallment(referenceDate, schedules);

            if (inst == null || inst.nextDonationDate > endDate) {
                break;
            }

            if (!inst.isSkipped) {
                installments.add(inst);
            }
            referenceDate = inst.nextDonationDate.addDays(1);
        }

        return installments;
    }

    /***
    * @description Indicates if the schedule is active starting from the reference date.
    * It excludes Pause Schedule handling.
    * @param schedule Recurring Donation schedule
    * @param referenceDate Reference Date
    * @return Boolean
    */
    public Boolean isActive(RecurringDonationSchedule__c schedule, Date referenceDate) {
        return
            !pauseHandler.isPause(schedule)
            && isScheduled(schedule, referenceDate)
            && isValidInstallmentFrequency(schedule);
    }

    /***
    * @description Indicates if the schedule is active starting from the reference date
    * @param schedule Recurring Donation schedule
    * @param referenceDate Reference Date
    * @return Boolean
    */
    private Boolean isScheduled(RecurringDonationSchedule__c schedule, Date referenceDate) {
        return schedule.EndDate__c == null
            || (referenceDate <= schedule.EndDate__c && schedule.StartDate__c <= schedule.EndDate__c);
    }

    /***
    * @description Determines if the Installment Frequency is in the range
    * @param schedule Recurring Donation schedule
    * @return Boolean
    */
    private Boolean isValidInstallmentFrequency(RecurringDonationSchedule__c schedule) {
        return schedule.InstallmentFrequency__c != null
            && schedule.InstallmentFrequency__c >= 1
            && schedule.InstallmentFrequency__c <= 20;
    }

    /***
    * @description Calculate the Next Installment using the provided Schedule with the reference date as the starting point
    * @param referenceDate Reference date used to calculate next donation date.
    * @param schedules Recurring Donation Schedule records
    * @return Installment
    */
    private Installment getNextInstallment(Date referenceDate, List<RecurringDonationSchedule__c> schedules) {
        if (schedules == null) {
            return null;
        }

        Installment nextInstallment;
        Installment previousInstallment;

        List<RecurringDonationSchedule__c> filteredSchedules = new List<RecurringDonationSchedule__c>();
        List<RecurringDonationSchedule__c> pauseSchedules = new List<RecurringDonationSchedule__c>();
        for (RecurringDonationSchedule__c schedule : schedules) {
            if (isActive(schedule, referenceDate)) {
                filteredSchedules.add(schedule);

            } else if (pauseHandler.isActivePause(schedule, referenceDate)) {
                pauseSchedules.add(schedule);
            }
        }

        for (RecurringDonationSchedule__c schedule : filteredSchedules) {
            Date nextDonationDate = getNextDonationDateGreaterThan(schedule, referenceDate);

            if (nextDonationDate == null) {
                continue;
            }

            if ((schedule.EndDate__c == null || nextDonationDate <= schedule.EndDate__c) &&
                (previousInstallment == null || previousInstallment.nextDonationDate > nextDonationDate)) {
                    nextInstallment = new Installment(schedule);
                    nextInstallment.nextDonationDate = nextDonationDate;
                    nextInstallment.isSkipped = pauseHandler.isSkipped(nextInstallment, pauseSchedules);
            }

            previousInstallment = nextInstallment;
        }

        return nextInstallment;
    }

    /***
    * @description Calculates the date of the next donation for a new Recurring Donation before the record insert
    * @param rd Recurring Donation record
    * @return Date
    */
    public Date getNextDonationDate(npe03__Recurring_Donation__c rd) {
        return getNextDonationDate(new RD2_RecurringDonation(rd), buildNewSchedules(rd));
    }

    /***
    * @description Calculates the date of the next donation for an existing Recurring Donation
    * @param rdRecord Recurring Donation record
    * @param rdSchedules Schedules on the Recurring Donation record
    * @return Date
    */
    public Date getNextDonationDate(RD2_RecurringDonation rdRecord, List<RecurringDonationSchedule__c> rdSchedules) {
        RD2_OpportunityMatcher.Record record = getNextDonationDateRecord(currentDate, rdRecord, rdSchedules);

        return record != null && record.getInstallment() != null
            ? record.getInstallment().nextDonationDate
            : null;
    }

    /***
    * @description Calculates the date of the next donation and returns the Opportunity matcher record
    * that contains the next donation installment and might contain the matching open Opportunity.
    * @param referenceDate The date the calculation will be based on
    * @param rdRecord Recurring Donation record
    * @param rdSchedules Schedules on the Recurring Donation record
    * @return RD2_OpportunityMatcher.Record
    */
    public RD2_OpportunityMatcher.Record getNextDonationDateRecord(Date referenceDate, RD2_RecurringDonation rdRecord, List<RecurringDonationSchedule__c> rdSchedules) {

        if (rdSchedules == null || rdSchedules.isEmpty()
            || rdRecord.isClosed()
            || rdRecord.isFixedLengthComplete()
        ) {
            return null;
        }

        evaluateScheduleEndDate(rdRecord, rdSchedules);

        RD2_OpportunityMatcher matcher = new RD2_OpportunityMatcher(referenceDate)
            .includeCurrent(rdRecord.getOpportunities());

        Integer numberOfInstallments = matcher.getNumberOfOpportunities() + 1;
        matcher.match(getVisualizedInstallments(
            referenceDate, numberOfInstallments, rdSchedules
        ));

        return getNextDonationDateRecord(matcher);
    }

    /**
    * @description Returns the first installment record not matching an Opportunity
    * or the first installment record matching an open Opportunity, whichever is earlier
    * @param matcher Opportunity and installment matcher
    * @return RD2_OpportunityMatcher.Record
    */
    private RD2_OpportunityMatcher.Record getNextDonationDateRecord(RD2_OpportunityMatcher matcher) {
        //records are ordered by the date
        for (RD2_OpportunityMatcher.Record record : matcher.getRecords()) {

            if (record.hasInstallment()
                && !record.getInstallment().isSkipped
                && (record.isNew() || record.isOpen())
            ) {
                return record;
            }
        }
        return null;
    }

    /***
    * @description Calculates the next donation date >= referenced date
    * @param schedule Recurring Donation Schedule record
    * @param referenceDate Reference date used to calculate next donation date. It can be today or a future projected date.
    * @return Date The Next Donation Date
    */
    public Date getNextDonationDateGreaterThan(RecurringDonationSchedule__c schedule, Date referenceDate) {
        Date firstValid = getFirstPossibleDonationDateFromStart(schedule);

        if (firstValid >= referenceDate) {
            return firstValid;
        }

        Integer adjustedFrequency =
            (schedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_WEEKLY ? DAYS_IN_WEEK : 1) * Integer.valueOf(schedule.InstallmentFrequency__c);

        Integer unitsBetween = getDateUnitsBetweenDates(firstValid, schedule.InstallmentPeriod__c, referenceDate);

        Date adjusted = addDateUnits(firstValid, (unitsBetween / adjustedFrequency) * adjustedFrequency, schedule.InstallmentPeriod__c);

        if (adjusted < referenceDate) {
            adjusted = addDateUnits(adjusted, adjustedFrequency, schedule.InstallmentPeriod__c);
        }

        if (schedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY) {
            if (schedule.DayOfMonth__c == null) {
                return adjusted;
            }
            Integer nextDayOfMonth;
            if (schedule.DayOfMonth__c == RD2_Constants.DAY_OF_MONTH_LAST_DAY ||
                Integer.valueOf(schedule.DayOfMonth__c) > Date.daysInMonth(adjusted.year(), adjusted.month()))
            {
                nextDayOfMonth = Date.daysInMonth(adjusted.year(),adjusted.month());
            }
            else {
                nextDayOfMonth = Integer.valueOf(schedule.DayOfMonth__c);
            }
            adjusted = Date.newInstance(adjusted.year(), adjusted.month(), nextDayOfMonth);
        }

        if (
            schedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_YEARLY &&
            schedule.StartDate__c.day() != adjusted.day() &&
            schedule.StartDate__c.day() == Date.daysInMonth(adjusted.year(), adjusted.month())
        ) {
            adjusted = Date.newInstance(adjusted.year(), adjusted.month(), Date.daysInMonth(adjusted.year(), adjusted.month()));
        }

        return adjusted;
    }

    /***
    * @description Returns the date units between an input date and current date based on installment period
    * @param firstValid Date
    * @param period String
    * @param referenceDate Reference date used to calculate next donation date. It can be today or a future projected date.
    * @return Integer
    */
    private Integer getDateUnitsBetweenDates(Date firstValid, String period, Date referenceDate) {
        Integer unitsBetween = 0;

        if (period == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY || period == RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH) {
            unitsBetween = firstValid.monthsBetween(referenceDate);

        } else if (period == RD2_Constants.INSTALLMENT_PERIOD_WEEKLY || period == RD2_Constants.INSTALLMENT_PERIOD_DAILY) {
            unitsBetween = firstValid.daysBetween(referenceDate);

        } else if (period == RD2_Constants.INSTALLMENT_PERIOD_YEARLY) {
            unitsBetween = Math.abs(firstValid.year() - referenceDate.year());
        }

        return unitsBetween;
    }

    /***
    * @description Adds date units to an input date based on installment period
    * @param dateIn Date
    * @param addUnits Integer
    * @param period String
    * @return Date
    */
    private Date addDateUnits(Date dateIn, Integer addUnits, String period) {
        Date adjustedDate = dateIn;

        if (period == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY || period == RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH) {
            adjustedDate = dateIn.addMonths(addUnits);

        } else if (period == RD2_Constants.INSTALLMENT_PERIOD_WEEKLY || period == RD2_Constants.INSTALLMENT_PERIOD_DAILY) {
            adjustedDate = dateIn.addDays(addUnits);

        } else if (period == RD2_Constants.INSTALLMENT_PERIOD_YEARLY) {
            adjustedDate = dateIn.addYears(addUnits);
        }

        return adjustedDate;
    }

    /***
    * @description Calculates the earliest valid donation date based on start date.
    * @param schedule Recurring Donation Schedule record
    * @return Date
    */
    private Date getFirstPossibleDonationDateFromStart(RecurringDonationSchedule__c schedule) {

        Date nextDate = schedule.StartDate__c;

        if (schedule.DayOfMonth__c != null && (
            schedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY ||
            schedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH))
        {
            Boolean adjustLastDay = (
                schedule.DayOfMonth__c == RD2_Constants.DAY_OF_MONTH_LAST_DAY ||
                Integer.valueOf(schedule.DayOfMonth__c) > Date.daysInMonth(nextDate.year(), nextDate.month())
            );
            nextDate = Date.newInstance(
                nextDate.year(),
                nextDate.month(),
                adjustLastDay ? Date.daysInMonth(nextDate.year(), nextDate.month()) :
                                Integer.valueOf(schedule.DayOfMonth__c)
            );
            nextDate = nextDate >= schedule.StartDate__c ? nextDate : nextDate.addMonths(1);
        }

        return nextDate;
    }

    /***
    * @description Retrieves detailed information about schedules suitable for viewing through UI.
    * Pause Schedules are excluded from the list.
    * @param rd Recurring Donation record
    * @return List<ActiveSchedule>
    */
    public List<ActiveSchedule> getVisualizedSchedules(npe03__Recurring_Donation__c rd) {
        List<ActiveSchedule> activeSchedules = new List<ActiveSchedule>();
        List<RecurringDonationSchedule__c> schedules = getExistingSchedules(rd);

        Boolean first1stAnd15thFound = false;
        for (RecurringDonationSchedule__c schedule : schedules) {
            if (pauseHandler.isPause(schedule)) {
                continue;
            }

            // This block collapses 1st and 15th schedules into a single row and nulls out day of month
            if (schedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH) {
                if (first1stAnd15thFound) {
                    first1stAnd15thFound = false;
                    continue;
                }
                first1stAnd15thFound = true;
            }
            activeSchedules.add(new ActiveSchedule(schedule, rd));
        }

        return activeSchedules;
    }

    /***
    * @description Returns all active schedules on the Recurring Donation including the current/future pause schedules.
    * Performs a full analysis and rebuild of the Schedule records for a Recurring Donation,
    * but does not commit the schedule records to the database.  Uses the active schedules for the RD
    * to calculate the Next Donation Date and store onto the RD record (in a Before Update context,
    * thus avoiding the extra DML against the object).
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @return Map<Id, List<RecurringDonationSchedule__c>>
    */
    public Map<Id, List<RecurringDonationSchedule__c>> getAllSchedules(List<npe03__Recurring_Donation__c> rds, List<npe03__Recurring_Donation__c> oldRds) {
        Map<Id, List<RecurringDonationSchedule__c>> newSchedulesByRdId = new Map<Id, List<RecurringDonationSchedule__c>>();

        Map<Id, List<RecurringDonationSchedule__c>> schedulesByRdId = getExistingSchedules(rds);

        Map<Id, npe03__Recurring_Donation__c> filteredRDs = getRecurringDonationsNeedingScheduleUpdates(rds, oldRds, TDTM_Runnable.Action.BeforeUpdate);

        for (npe03__Recurring_Donation__c rd : filteredRDs.values()) {
            Boolean isUpdate = false;
            TDTM_Runnable.DmlWrapper revisedSchedules = rebuildSchedules(rd, schedulesByRdId.get(rd.Id), isUpdate);

            for (SObject sobj : revisedSchedules.objectsToUpdate) {
                addScheduleIfActive((RecurringDonationSchedule__c)sobj, newSchedulesByRdId);
            }

            for (SObject sobj : revisedSchedules.objectsToInsert) {
                addScheduleIfActive((RecurringDonationSchedule__c)sobj, newSchedulesByRdId);
            }
        }

        // Merge the schedules from RDs NOT needing schedule updates with the updated schedules
        for (Id rdId : newSchedulesByRdId.keySet()) {
            schedulesByRdId.put(rdId, newSchedulesByRdId.get(rdId));
        }

        return schedulesByRdId;
    }

    /***
    * @description Retrieves recurring donation schedules associated with a single recurring donation
    * @param rd npe03__Recurring_Donation__c
    * @return List<RecurringDonationSchedule__c>
    */
    public List<RecurringDonationSchedule__c> getExistingSchedules(npe03__Recurring_Donation__c rd) {
        if (rd == null) {
            return new List<RecurringDonationSchedule__c>();
        }

        Map<Id, List<RecurringDonationSchedule__c>> schedulesByRDId = getExistingSchedules(new List<npe03__Recurring_Donation__c>{ rd });

        return schedulesByRDId.containsKey(rd.Id)
            ? schedulesByRDId.get(rd.Id)
            : new List<RecurringDonationSchedule__c>();
    }

    /***
    * @description Retrieves active recurring donation schedules associated with recurring donation list.
    * The output includes pause schedules as well.
    * @param rds List<npe03__Recurring_Donation__c>
    * @return Map<Id, List<RecurringDonationSchedule__c>>
    */
    public Map<Id, List<RecurringDonationSchedule__c>> getExistingSchedules(List<npe03__Recurring_Donation__c> rds) {
        Map<Id, List<RecurringDonationSchedule__c>> schedulesById = new Map<Id, List<RecurringDonationSchedule__c>>();

        for (RecurringDonationSchedule__c schedule : Database.query(new ScheduleQueryHandler().buildQuery())) {
            Boolean isActive = isActive(schedule, currentDate) || pauseHandler.isActivePause(schedule, currentDate);
            if (!isActive) {
                continue;
            }

            if (!schedulesById.containsKey(schedule.RecurringDonation__c)) {
                schedulesById.put(schedule.RecurringDonation__c, new List<RecurringDonationSchedule__c>());
            }
            schedulesById.get(schedule.RecurringDonation__c).add(schedule);
        }

        return schedulesById;
    }

    /***
    * @description Filters recurring donations to determine which need schedule updates
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @param triggerAction Trigger action (insert, updated,...)
    * @return Map<Id, npe03__Recurring_Donation__c>
    */
    public Map<Id, npe03__Recurring_Donation__c> getRecurringDonationsNeedingScheduleUpdates(
            List<npe03__Recurring_Donation__c> rds,
            List<npe03__Recurring_Donation__c> oldRds,
            TDTM_Runnable.Action triggerAction)
    {
        Map<Id, npe03__Recurring_Donation__c> oldRdById = new Map<Id, npe03__Recurring_Donation__c>(oldRds);
        Map<Id, npe03__Recurring_Donation__c> filteredRecurringDonations = new Map<Id, npe03__Recurring_Donation__c>();

        for (npe03__Recurring_Donation__c rd : rds) {
            npe03__Recurring_Donation__c oldRd = oldRdById.get(rd.Id);

            if (isScheduleUpdateNeeded(rd, oldRd)) {
                if (triggerAction == TDTM_Runnable.Action.BeforeUpdate &&
                    rd.StartDate__c == null &&
                    !(new RD2_RecurringDonation(rd)).isClosed()
                ) {
                    rd.StartDate__c = currentDate;
                }
                filteredRecurringDonations.put(rd.Id, rd);
            }
        }

        return filteredRecurringDonations;
    }

    /***
    * @description Adds RD Schedule to the RD schedules list if the schedule is active
    * @param schedule Recurring Donation Schedule
    * @param newSchedulesByRdId Schedules mapped by the RD Id
    * @return void
    */
    private void addScheduleIfActive(RecurringDonationSchedule__c schedule, Map<Id, List<RecurringDonationSchedule__c>> newSchedulesByRdId) {

        if (isScheduled(schedule, currentDate)) {

            if (!newSchedulesByRdId.containsKey(schedule.RecurringDonation__c)) {
                newSchedulesByRdId.put(schedule.RecurringDonation__c, new List<RecurringDonationSchedule__c>());
            }
            newSchedulesByRdId.get(schedule.RecurringDonation__c).add(schedule);
        }
    }

    /**
    * @description Evaluate Recurring Donation and set End Date on the RD scheulde
    * when the Next Donation Date record is calculated, or when the Visualizer displays upcoming installments.
    * @param rdRecord Recurring Donation record
    * @param rdSchedules Schedules on the Recurring Donation record
    * @return void
    */
    public void evaluateScheduleEndDate(RD2_RecurringDonation rdRecord, List<RecurringDonationSchedule__c> rdSchedules) {
        if (rdSchedules == null
            || rdSchedules.isEmpty()
            || rdRecord.isClosed()
        ) {
            return;
        }

        if (rdRecord.isFixedLength()) {
            evaluateScheduleEndDateForFixedLength(rdRecord, rdSchedules);

        } else if (rdRecord.isOpenEnded()) {
            evaluateScheduleEndDateForOpenEnded(rdRecord, rdSchedules);
        }
    }

    /**
    * @description Sets End Date on the Recurring Donation schedule for a open ended RD.
    * Schedules are dynamically evaluated for the End Date
    * when the Next Donation Date record is calculated, or when the Visualizer displays upcoming installments.
    * @param rdRecord Recurring Donation record
    * @param rdSchedules Schedules on the Recurring Donation record
    * @return void
    */
    public void evaluateScheduleEndDateForOpenEnded(RD2_RecurringDonation rdRecord, List<RecurringDonationSchedule__c> rdSchedules) {
        for (RecurringDonationSchedule__c schedule : rdSchedules) {
            if (schedule.EndDate__c == null) {
                schedule.EndDate__c = rdRecord.getSObject().EndDate__c;
            }
        }
    }

    /**
    * @description Sets End Date on the Recurring Donation schedule for a fixed-length RD.
    * Schedules are dynamically evaluated for the End Date
    * when the Next Donation Date record is calculated, or when the Visualizer displays upcoming installments.
    * @param rdRecord Recurring Donation record
    * @param rdSchedules Schedules on the Recurring Donation record
    * @return void
    */
    public void evaluateScheduleEndDateForFixedLength(RD2_RecurringDonation rdRecord, List<RecurringDonationSchedule__c> rdSchedules) {
        Integer plannedInstallments = rdRecord.getPlannedInstallments();
        Integer paidInstallments = rdRecord.getPaidInstallments();
        Integer estimatedOpenSlots = plannedInstallments - paidInstallments + rdRecord.getOpportunities().size();

        List<RD2_OpportunityMatcher.Record> records = new RD2_OpportunityMatcher(currentDate)
            .include(rdRecord.getOpportunities())
            .match(
                getVisualizedInstallments(currentDate, estimatedOpenSlots, rdSchedules)
            )
            .getRecords();

        Date scheduleEndDate = getScheduleEndDateForFixedLength(records, plannedInstallments, paidInstallments);

        for (RecurringDonationSchedule__c schedule : rdSchedules) {
            if (schedule.EndDate__c == null) {
                schedule.EndDate__c = scheduleEndDate;
            }
        }
    }

    /**
    * @description Dynamically calculates the schedule end date
    * based on existing Opportunities and projected installments
    * @param records Opportunity matcher records
    * @param plannedInstallments Number of planned installments
    * @param paidInstallments Number of paid installments
    * @return Date The fixed-length RD schedule end date
    */
    private Date getScheduleEndDateForFixedLength(List<RD2_OpportunityMatcher.Record> records, Integer plannedInstallments, Integer paidInstallments) {
        //Remove all closed Opportunities
        RD2_OpportunityMatcher.Record lastClosedWonRecord;
        RD2_OpportunityMatcher.Record scheduleEndRecord;

        for (Integer i = records.size() - 1; i >= 0 ; i--) {
            RD2_OpportunityMatcher.Record record = records[i];
            Opportunity opp = record.getOpportunity();

            if (opp.Id != null && opp.IsClosed) {
                records.remove(i);

                if (opp.IsWon && lastClosedWonRecord == null) {
                    lastClosedWonRecord = record;
                }
            }
        }

        Integer lastIndex = plannedInstallments - paidInstallments - 1;
        if (lastIndex < 0 || records.isEmpty()) {
            scheduleEndRecord = lastClosedWonRecord;

        } else if (lastIndex >= 0 && lastIndex < records.size()) {
            scheduleEndRecord = records[lastIndex];
        }

        Date endDate;
        if (scheduleEndRecord == null) {
            endDate = currentDate.addDays(-1);

        } else if (scheduleEndRecord.hasInstallment()) {
            endDate = scheduleEndRecord.getInstallment().nextDonationDate;

        } else {
            endDate = scheduleEndRecord.getOpportunity().CloseDate;
        }

        return endDate;
    }

    /**
    * @description Indicate if on the reference date, the schedule is currently in paused
    * @param referenceDate Reference Date
    * @param schedules Recurring Donation Schedules
    * @return Boolean
    */
    public Boolean isCurrentlyPaused(Date referenceDate, List<RecurringDonationSchedule__c> schedules) {
        RecurringDonationSchedule__c nextPauseSchedule = getNextActivePauseSchedule(referenceDate, schedules);
        
        if (nextPauseSchedule == null) {
            return false;
        }

        List<RD2_ScheduleService.Installment> installments = getVisualizedInstallments(
            referenceDate,
            nextPauseSchedule.StartDate__c.addDays(-1),
            schedules
        );

        return installments.isEmpty();
    }

    /**
    * @description Get the next active paused schedule
    * @param referenceDate Reference Date
    * @param rdSchedules Recurring Donation Schedules
    * @return RecurringDonationSchedule__c
    */
    public RecurringDonationSchedule__c getNextActivePauseSchedule(Date referenceDate, List<RecurringDonationSchedule__c> rdSchedules) {
        RecurringDonationSchedule__c nextActive;

        for (RecurringDonationSchedule__c schedule : rdSchedules) {
            if (pauseHandler.isActivePause(schedule, referenceDate)
                && ( nextActive == null || schedule.StartDate__c <= nextActive.StartDate__c)
            ) {
                nextActive = schedule;
            }
        }

        return nextActive;
    }

    /***
    * @description Wrapper class for Recurring Donation Installment data
    */
    public class Installment {
        public Id       campaignId {get; set;}
        public String   campaignName {get; set;}
        public Date     startDate {get; set;}
        public Date     endDate {get; set;}
        public Date     nextDonationDate {get; set;}
        public String   installmentPeriod {get; set;}
        public Decimal  installmentAmount {get; set;}
        public String   paymentMethod {get; set;}
        public Id       scheduleId {get; set;}
        public Boolean  isSkipped {get; set;}

        Installment(RecurringDonationSchedule__c rdSchedule) {
            campaignId =            rdSchedule.Campaign__c;
            campaignName =          rdSchedule.Campaign__r.Name;
            startDate =             rdSchedule.StartDate__c;
            endDate =               rdSchedule.EndDate__c;
            installmentPeriod =     rdSchedule.InstallmentPeriod__c;
            installmentAmount =     rdSchedule.InstallmentAmount__c;
            paymentMethod =         rdSchedule.PaymentMethod__c;
            scheduleId =            rdSchedule.Id;
            isSkipped =             false;
        }
    }

    /***
    * @description Wrapper class for Recurring Donation Schedule data
    */
    public class ActiveSchedule {

        public Boolean isCurrent { get; set; }
        public Id campaignId { get; set; }
        public String campaignName { get; set; }
        public String dayOfMonth { get; set; }
        public Date endDate { get; set; }
        public Decimal installmentAmount { get; set; }
        public Integer installmentFrequency { get; set; }
        public String installmentPeriod { get; set; }
        public String paymentMethod { get; set; }
        public String recurringDonationId { get; set; }
        public Id scheduleId { get; set; }
        public Date startDate { get; set; }

        public ActiveSchedule(RecurringDonationSchedule__c rdSchedule, npe03__Recurring_Donation__c rd) {
            isCurrent = rdSchedule.StartDate__c <= RD2_ScheduleService.currentDate ? true : false;
            campaignId = rdSchedule.Campaign__c;
            campaignName = rdSchedule.Campaign__r.Name;
            dayOfMonth = rdSchedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY ? rdSchedule.DayOfMonth__c : null;
            endDate = (rdSchedule.EndDate__c != null) ? rdSchedule.EndDate__c : rd.EndDate__c;
            installmentAmount = rdSchedule.InstallmentAmount__c;
            installmentFrequency = rdSchedule.InstallmentFrequency__c != null ? Integer.valueOf(rdSchedule.InstallmentFrequency__c) : null;
            installmentPeriod = rdSchedule.InstallmentPeriod__c;
            paymentMethod = rdSchedule.PaymentMethod__c;
            recurringDonationId = rdSchedule.RecurringDonation__c;
            scheduleId = rdSchedule.Id;
            startDate = rdSchedule.StartDate__c;
        }
    }

    /**
     * Inner class to build Elevate specific pause schedules
     *
     */
    public class ElevatePauseSchedule {
        public Datetime startDate;
        public Datetime endDate;
        public String statusReason;
        public Boolean shouldEditPause;
        public ElevatePauseSchedule(List<RecurringDonationSchedule__c> donationSchedules,
                RD2_PauseForm_CTRL.PauseData pause) {
            this.startDate = pause.startDate;
            this.endDate = calculateElevatePauseEndDate(pause.resumeAfterDate, donationSchedules);
            this.statusReason = pause.pausedReason?.value;
            this.shouldEditPause = shouldEditPause(donationSchedules);
        }
        private Datetime calculateElevatePauseEndDate (Date endDate,
                List<RecurringDonationSchedule__c> donationSchedules) {
            RD2_ScheduleService rd2ScheduleService = new RD2_ScheduleService();
            Date nextDonationDate = rd2ScheduleService.getNextInstallment(
                    endDate, donationSchedules
            ).nextDonationDate;

            return Datetime.newInstance(
                    nextDonationDate.year(), nextDonationDate.month(), nextDonationDate.day()).addSeconds(-1);

        }

        private Boolean shouldEditPause (List<RecurringDonationSchedule__c> donationSchedules) {
            Boolean shouldEdit = false;
            for (RecurringDonationSchedule__c schedule : donationSchedules) {
                if (schedule.IsPause__c && schedule.EndDate__c >= System.today()) {
                    shouldEdit = true;
                    break;
                }
            }
            return shouldEdit;
        }
    }

    /***
    * @description Handles Pause Recurring Donation functionality
    */
    public class PauseScheduleHandler {

        public RecurringDonationSchedule__c createPauseSchedule(String statusReason, Date startDate, Date endDate, Id rdId) {
            return new RecurringDonationSchedule__c(
                RecurringDonation__c = rdId,
                IsPause__c = true,
                StatusReason__c = statusReason,
                StartDate__c = startDate,
                EndDate__c = endDate
            );
        }

        public ElevatePauseSchedule createElevatePauseSchedule (RD2_PauseForm_CTRL.PauseData pause, RD2_RecurringDonation rd) {
            return new ElevatePauseSchedule(rd.getSObject().RecurringDonationSchedules__r, pause);
        }


        /***
        * @description Indicates if the Recurring Donation has an active pause schedule
        * at some point in the future (not necessarily in a current pause state).
        * @param schedules Recurring Donation Schedules
        * @param referenceDate As of today to compare the Schedule Start and End Dates against
        * @return Boolean
        */
        public Boolean hasActivePause(List<RecurringDonationSchedule__c> schedules, Date referenceDate) {
            for (RecurringDonationSchedule__c schedule : schedules) {
                if (isActivePause(schedule, referenceDate)) {
                    return true;
                }
            }

            return false;
        }

        /***
        * @description Simple check on the schedule to check if the "Is Pause" field is checked
        * @param schedule Recurring Donation Schedule
        * @return Boolean
        */
        public Boolean isPause(RecurringDonationSchedule__c schedule) {
            return schedule.IsPause__c;
        }

        /***
        * @description Indicates if the schedule is an active pause schedule
        * @param schedule Recurring Donation Schedule
        * @param referenceDate As of today to compare the Schedule Start and End Dates against
        * @return Boolean
        */
        public Boolean isActivePause(RecurringDonationSchedule__c schedule, Date referenceDate) {
            if (!schedule.IsPause__c) {
                return false;
            }

            return isScheduled(schedule, referenceDate);
        }

        /***
        * @description Indicates if the schedule record is either currently active or will be active in the future
        * @param schedule Recurring Donation schedule
        * @param referenceDate Reference Date
        * @return Boolean
        */
        private Boolean isScheduled(RecurringDonationSchedule__c schedule, Date referenceDate) {
            return schedule.EndDate__c == null ||
                (referenceDate <= schedule.EndDate__c && schedule.StartDate__c <= schedule.EndDate__c);
        }

        /***
        * @description Indicates if the schedule will be active on the date specified.
        * @param schedule Recurring Donation schedule
        * @param referenceDate Reference Date
        * @return Boolean
        */
        private Boolean isCurrentlyActive(RecurringDonationSchedule__c schedule, Date referenceDate) {
            return schedule.StartDate__c <= referenceDate &&
                (schedule.EndDate__c == null || referenceDate <= schedule.EndDate__c);
        }

        /***
        * @description Deactivates an active Pause Schedule (if any) and
        * saves the specified Pause Schedule.
        * @param rdId Recurring Donation Id
        * @param pauseSchedule The Pause Schedule on the Recurring Donation
        * @return void
        */
        public void savePauseSchedule(Id rdId, RecurringDonationSchedule__c pauseSchedule) {
            Savepoint sp = Database.setSavepoint();
            try {
                cancelPauseSchedule(rdId);

                if (isNewPause(pauseSchedule)) {
                    insert pauseSchedule;
                }

            } catch (Exception e) {
                Database.rollback(sp);
                throw new ScheduleException(e.getMessage());
            }
        }


        private Boolean isNewPause(RecurringDonationSchedule__c pauseSchedule) {
            return pauseSchedule.StartDate__c != null && pauseSchedule.EndDate__c != null;
        }

        /***
        * @description Cancels the Pause Schedule.
        * The End Date is set to yesterday. This is valid when the schedule Start Date
        * is in future or has passed but the End Date has not been reached yet.
        * @param rdId Recurring Donation Id
        * @return void
        */
        public void cancelPauseSchedule(Id rdId) {
            RecurringDonationSchedule__c schedule = getPauseSchedule(rdId);

            if (schedule == null) {
                return;
            }

            deactivatePauseSchedule(schedule);
            update schedule;
        }

        public RecurringDonationSchedule__c deactivatePauseSchedule(RecurringDonationSchedule__c schedule) {
            schedule.EndDate__c = currentDate.addDays(-1);
            return schedule;
        }

        /***
        * @description Retrieves a Pause Schedule on the Recurring Donation (if any).
        * Currently at most one Pause Schedule can exist on a Recurring Donation.
        * @param rdId Recurring Donation Id
        * @return RecurringDonationSchedule__c
        */
        public RecurringDonationSchedule__c getPauseSchedule(Id rdId) {
            String soql = new UTIL_Query()
                .withSelectFields(new ScheduleQueryHandler().getFields())
                .withFrom(RecurringDonationSchedule__c.SObjectType)
                .withWhere('RecurringDonation__c = :rdId')
                .withWhere('IsPause__c = true')
                .withWhere('EndDate__c >= :currentDate')
                .withOrderBy('StartDate__c')
                .build();

            for (RecurringDonationSchedule__c schedule : Database.query(soql)) {
                if (isActivePause(schedule, currentDate)) {
                    return schedule;
                }
            }

            return null;
        }

        /***
        * @description Indicates if the projected future installment is within the Pause Schedules
        * @param installment Future installment
        * @param pauseSchedules List of *active* Pause Schedules
        * @return Boolean
        */
        public Boolean isSkipped(Installment installment, List<RecurringDonationSchedule__c> pauseSchedules) {
            if (pauseSchedules.isEmpty()) {
                return false;
            }

            for (RecurringDonationSchedule__c schedule : pauseSchedules) {
                if (schedule.StartDate__c <= installment.nextDonationDate && installment.nextDonationDate <= schedule.EndDate__c) {
                    return true;
                }
            }
            return false;
        }
    }


    /***
    * @description Handles SOQL on Recurring Donation Schedule
    */
    public class ScheduleQueryHandler {

        /***
        * @description Builds dynamic soql query string with support for date injection
        * @return String
        */
        public String buildQuery() {
            return new UTIL_Query()
                .withSelectFields(getFields())
                .withFrom(RecurringDonationSchedule__c.SObjectType)
                .withWhere('RecurringDonation__c IN :rds')
                .withWhere('(EndDate__c = null OR EndDate__c >= :currentDate)')
                .withOrderBy('StartDate__c')
                .build();
        }

        /***
        * @description Fields to select on the RD Schedule SObject
        * @param Set<String> Set of fields
        * @return
        */
        public Set<String> getFields() {
            return new Set<String> {
                'Active__c',
                'Campaign__c',
                'Campaign__r.Name',
                'StartDate__c',
                'EndDate__c',
                'DayOfMonth__c',
                'InstallmentAmount__c',
                'InstallmentFrequency__c',
                'InstallmentPeriod__c',
                'PaymentMethod__c',
                'RecurringDonation__c',
                'IsPause__c',
                'StatusReason__c'
            };
        }
    }

    /**
     * @description Exception thrown during Recurring Donation Schedule processing
     */
    public class ScheduleException extends Exception { }
}