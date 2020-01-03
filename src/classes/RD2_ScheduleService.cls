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
    private final Integer DEFAULT_VISUALIZATION_SCHEDULE_COUNT = 12;

    /**
    * @description Date to treat as current date in calculation of schedules
    */
    @TestVisible
    private Date currentDate {
        get {
            if (currentDate == null) {
                currentDate = Date.today();
            }
            return currentDate;
        } set;
    }

    /***
    * @description Builds new recurring donation schedule(s) for recurring donation
    * @param rd Recurring donation record
    * @return List<RecurringDonationSchedule__c>
    */
    public List<RecurringDonationSchedule__c> getNewSchedules(npe03__Recurring_Donation__c rd) {

        List<RecurringDonationSchedule__c> newSchedules = new List<RecurringDonationSchedule__c>();

        if (rd.Status__c == RD2_Constants.STATUS_CLOSED) {
            return newSchedules;
        }

        RecurringDonationSchedule__c schedule = new RecurringDonationSchedule__c();

        schedule.RecurringDonation__c = rd.Id;
        schedule.Campaign__c = rd.npe03__Recurring_Donation_Campaign__c;

        /* TODO: For fixed length recurring donations we may need to calculate this
        schedule.EndDate__c = ??
         */

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
    * @param rd Recurring Donation record
    * @param schedules Recurring Donation Schedule record
    * @return TDTM_Runnable.DMLWrapper
    */
    public TDTM_Runnable.DMLWrapper getUpdatedSchedules(npe03__Recurring_Donation__c rd, List<RecurringDonationSchedule__c> schedules) {

        Date newStartDate = rd.StartDate__c;
        TDTM_Runnable.DMLWrapper scheduleChanges = new TDTM_Runnable.DMLWrapper();

        if (schedules != null) {
            for (RecurringDonationSchedule__c schedule : schedules) {

                if (rd.Status__c != RD2_Constants.STATUS_CLOSED && schedule.StartDate__c <= currentDate) {
                    schedule.EndDate__c = newStartDate.addDays(-1);

                } else if (rd.Status__c != RD2_Constants.STATUS_CLOSED && schedule.StartDate__c > currentDate) {
                    schedule.EndDate__c = schedule.StartDate__c.addDays(-1);

                } else if (rd.Status__c == RD2_Constants.STATUS_CLOSED) {
                    schedule.EndDate__c = currentDate.addDays(-1);
                }

                scheduleChanges.objectsToUpdate.add(schedule);
            }
        }

        List<RecurringDonationSchedule__c> newSchedules = getNewSchedules(rd);
        for (RecurringDonationSchedule__c newSchedule : newSchedules) {
            newSchedule.StartDate__c = newStartDate;
        }

        scheduleChanges.objectsToInsert.addAll(newSchedules);

        return scheduleChanges;
    }

    /***
    * @description Determines whether changes to recurring donation should trigger creation of new schedule(s)
    * @param rd Trigger.new record
    * @param oldRd Trigger.old record
    * @return Boolean
    */
    @TestVisible
    private Boolean isScheduleUpdateNeeded(npe03__Recurring_Donation__c newRd, npe03__Recurring_Donation__c oldRd) {

        Boolean isNeeded = false;

        // newRD should never be null.  This is a fail safe measure only.
        if (newRd == null) {
            isNeeded = false;

        // Since this method should never be called on inserts, oldRd should never be null.  Defensive again.
        } else if (oldRd == null) {
            isNeeded = true;

        // These two special conditions should never result in a schedule update.
        } else if
                ((newRd.Status__c == RD2_Constants.STATUS_LAPSED && oldRd.Status__c == RD2_Constants.STATUS_ACTIVE) ||
                (newRd.Status__c == RD2_Constants.STATUS_ACTIVE && oldRd.Status__c == RD2_Constants.STATUS_LAPSED))
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
            newRd.Status__c != oldRd.Status__c ||
            newRd.npe03__Recurring_Donation_Campaign__c != oldRd.npe03__Recurring_Donation_Campaign__c)
        {
            isNeeded = true;
        }

        return isNeeded;
    }


    /***
    * @description Calculates the dates of the next n donations for a single RD
    * @param rd Recurring Donation record
    * @param startDate Date (if null, current date will be used)
    * @param numInstallments Integer (if null, DEFAULT_VISUALIZATION_SCHEDULE_COUNT will be used)
    * @param schedules RecurringDonationSchedule__c (if null, getVisualizedInstallments will query for all active schedules)
    * @return List<Installment>
    */
    public List<Installment> getVisualizedInstallments(npe03__Recurring_Donation__c rd, Date startDate, Integer numInstallments, List<RecurringDonationSchedule__c> schedules) {
        if (rd == null) {
            return new List<Installment>();
        }

        Map<Id, List<RecurringDonationSchedule__c>> schedulesByRd;
        if (schedules != null) {
            schedulesByRd = new Map<Id, List<RecurringDonationSchedule__c>>();
            schedulesByRd.put(rd.Id, schedules);
        }

        return getVisualizedInstallments(new List<npe03__Recurring_Donation__c> {rd}, startDate, numInstallments, schedulesByRd).get(rd.Id);
    }

    /***
    * @description Calculates the dates of the next n donations for a list of Recurring Donations
    * @param rds List of Recurring Donation records
    * @param startDate Date (if null, current date will be used)
    * @param numInstallments Integer (if null, DEFAULT_VISUALIZATION_SCHEDULE_COUNT will be used)
    * @param schedulesByRd Map Id, RecurringDonationSchedule__c (if null, getVisualizedInstallments will query for all active schedules)
    * @return Map<Id, List<Installment>> Recurring Donation Ids to List of upcoming installments
    */
    public Map<Id, List<Installment>> getVisualizedInstallments(
            List<npe03__Recurring_Donation__c> rds, Date startDate, Integer numInstallments, Map<Id, List<RecurringDonationSchedule__c>> schedulesByRd) {

        if (numInstallments == null) {
            numInstallments = DEFAULT_VISUALIZATION_SCHEDULE_COUNT;
        }

        if (startDate == null) {
            startDate = currentDate;
        }

        Map<Id, List<Installment>> installmentsByRd = new Map<Id, List<Installment>>();
        if (schedulesByRd == null) {
            schedulesByRd = getExistingSchedules(rds);
        }

        for (npe03__Recurring_Donation__c rd : rds) {

            if (rd == null || rd.Id == null) {
                continue;
            }

            installmentsByRd.put(rd.Id, doVisualization(startDate, numInstallments, schedulesByRd.get(rd.Id)));
        }

        currentDate = Date.today();

        return installmentsByRd;
    }

    /***
    * @description Calculates the dates of the next n donations for a single Recurring Donation
    * @param startDate Date
    * @param numInstallments Integer
    * @param schedules List of active RecurringDonationSchedule__c records
    * @return List<Installment>
    */
    private List<Installment> doVisualization(Date startDate, Integer numInstallments, List<RecurringDonationSchedule__c> schedules) {

        List<Installment> installments = new List<Installment>();
        if (schedules == null) {
            return installments;
        }

        currentDate = startDate;
        List <RecurringDonationSchedule__c> filteredSchedules;

        while (installments.size() < numInstallments) {

            // We are changing currentDate with each loop, so the active schedules potentially change with each loop
            filteredSchedules = new List<RecurringDonationSchedule__c>();

            for (RecurringDonationSchedule__c schedule : schedules) {
                if (schedule.EndDate__c == null || schedule.EndDate__c >= currentDate) {
                    filteredSchedules.add(schedule);
                }
            }

            Installment ins = getNextInstallment(filteredSchedules);
            if (ins == null) {
                break;
            }

            installments.add(ins);
            currentDate = ins.nextDonationDate.addDays(1);
        }

        return installments;
    }

    /***
    * @description Wrapper class for Recurring Donation Installment data
    */
    public class Installment {

        public Id       campaignId {get; set;}
        public String   campaignName {get; set;}
        public Date     endDate {get; set;}
        public Decimal  installmentAmount {get; set;}
        public Date     nextDonationDate {get; set;}
        public String   paymentMethod {get; set;}
        public Id       scheduleId {get; set;}
        public Date     startDate {get; set;}

        Installment(RecurringDonationSchedule__c rdSchedule) {
            campaignId =            rdSchedule.Campaign__c;
            campaignName =          rdSchedule.Campaign__r.Name;
            endDate =               rdSchedule.EndDate__c;
            installmentAmount =     rdSchedule.InstallmentAmount__c;
            paymentMethod =         rdSchedule.PaymentMethod__c;
            scheduleId =            rdSchedule.Id;
            startDate =             rdSchedule.StartDate__c;
        }
    }

    /***
    * @description Calculate the Next Installment using the provided Schedule with the CurrentDate as the starting point
    * @param rdSchedules Recurring Donation Schedule records
    * @return Installment
    */
    private Installment getNextInstallment(List<RecurringDonationSchedule__c> rdSchedules) {

        Date nextDonationDate;
        Installment nextInstallment;
        Installment previousInstallment;

        if (rdSchedules == null) {
            return nextInstallment;
        }

        for (RecurringDonationSchedule__c schedule : rdSchedules) {

            nextDonationDate = getNextDonationDateGreaterThanToday(schedule);

            if (nextDonationDate == null) {
                continue;
            }

            if ((schedule.EndDate__c == null || nextDonationDate <= schedule.EndDate__c) &&
                (previousInstallment == null || previousInstallment.nextDonationDate > nextDonationDate)) {
                    nextInstallment = new Installment(schedule);
                    nextInstallment.nextDonationDate = nextDonationDate;
            }

            previousInstallment = nextInstallment;
        }

        return nextInstallment;
    }

    /***
    * @description Calculates the date of the next donation
    * @param rd Recurring Donation record
    * @return Date
    */
    public Date getNextDonationDate(npe03__Recurring_Donation__c rd) {
        if (rd.Status__c == RD2_Constants.STATUS_CLOSED) {
            return null;
        }

        return getNextDonationDate(getNewSchedules(rd));
    }

    /***
    * @description Calculates the date of the next donation
    * @param rdSchedules Recurring Donation Schedule records
    * @return Date
    */
    public Date getNextDonationDate(List<RecurringDonationSchedule__c> rdSchedules) {

        Date nextDate;
        Date previousDate;

        if (rdSchedules == null) {
            return nextDate;
        }

        for (RecurringDonationSchedule__c schedule : rdSchedules) {
            nextDate = getNextDonationDateGreaterThanToday(schedule);

            if (previousDate < nextDate) {
                nextDate = previousDate;
            }

            previousDate = nextDate;
        }

        return nextDate;
    }

    /***
    * @description Calculates the next donation date >= currentDate
    * @param schedule Recurring Donation Schedule record
    * @return Date
    */
    private Date getNextDonationDateGreaterThanToday(RecurringDonationSchedule__c schedule) {

        Date firstValid = getFirstPossibleDonationDateFromStart(schedule);

        if (firstValid >= currentDate) {
            return firstValid;
        }

        Integer adjustedFrequency =
            (schedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_WEEKLY ? DAYS_IN_WEEK : 1) * Integer.valueOf(schedule.InstallmentFrequency__c);

        Integer unitsBetween = getDateUnitsBetweenFirstValidAndCurrentDate(firstValid, schedule.InstallmentPeriod__c);

        Date adjusted = addDateUnits(firstValid, (unitsBetween / adjustedFrequency) * adjustedFrequency, schedule.InstallmentPeriod__c);

        if (adjusted < currentDate) {
            adjusted = addDateUnits(adjusted, adjustedFrequency, schedule.InstallmentPeriod__c);
        }

        if (schedule.DayOfMonth__c == RD2_Constants.DAY_OF_MONTH_LAST_DAY && schedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY) {
            adjusted = Date.newInstance(adjusted.year(), adjusted.month(), Date.daysInMonth(adjusted.year(),adjusted.month()));
        }

        return adjusted;
    }

    /***
    * @description Returns the date units between an input date and current date based on installment period
    * @param firstValid Date
    * @param period String
    * @return Integer
    */
    private Integer getDateUnitsBetweenFirstValidAndCurrentDate(Date firstValid, String period) {
        Integer unitsBetween = 0;

        if (period == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY || period == RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH) {
            unitsBetween = firstValid.monthsBetween(currentDate);

        } else if (period == RD2_Constants.INSTALLMENT_PERIOD_WEEKLY || period == RD2_Constants.INSTALLMENT_PERIOD_DAILY) {
            unitsBetween = firstValid.daysBetween(currentDate);

        } else if (period == RD2_Constants.INSTALLMENT_PERIOD_YEARLY) {
            unitsBetween = Math.abs(firstValid.year() - currentDate.year());
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
            nextDate = Date.newInstance(
                nextDate.year(),
                nextDate.month(),
                schedule.DayOfMonth__c == RD2_Constants.DAY_OF_MONTH_LAST_DAY ?
                    Date.daysInMonth(nextDate.year(), nextDate.month()) :
                    Integer.valueOf(schedule.DayOfMonth__c)
            );
            nextDate = nextDate >= schedule.StartDate__c ? nextDate : nextDate.addMonths(1);
        }

        return nextDate;
    }

    /***
    * @description Performs a full analysis and rebuild of the Schedule records for a Recurring Donation,
    * but does not commit the schedule records to the database.  Uses the active schedules for the RD
    * to calculate the Next Donation Date and store onto the RD record (in a Before Update context,
    * thus avoiding the extra DML against the object).
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    */
    public Map<Id, List<RecurringDonationSchedule__c>> getAllRecurringDonationSchedules(List<npe03__Recurring_Donation__c> rds, List<npe03__Recurring_Donation__c> oldRds) {

        Map<Id, List<RecurringDonationSchedule__c>> schedulesByRdId = getExistingSchedules(rds);

        Map<Id, npe03__Recurring_Donation__c> filteredRecurringDonations = getRecurringDonationsNeedingScheduleUpdates(rds, oldRds, TDTM_Runnable.Action.BeforeUpdate);

        TDTM_Runnable.DmlWrapper revisedSchedules;
        Map<Id, List<RecurringDonationSchedule__c>> newSchedulesByRdId = new Map<Id, List<RecurringDonationSchedule__c>>();

        for (npe03__Recurring_Donation__c rd : filteredRecurringDonations.values()) {

            revisedSchedules = getUpdatedSchedules(rd, schedulesByRdId.get(rd.Id));

            for (SObject sobj : revisedSchedules.objectsToUpdate) {
                addUpdatedSchedules((RecurringDonationSchedule__c)sobj, newSchedulesByRdId);
            }

            for (SObject sobj : revisedSchedules.objectsToInsert) {
                addUpdatedSchedules((RecurringDonationSchedule__c)sobj, newSchedulesByRdId);
            }
        }

        // Merge the schedules from RDs NOT needing schedule updates with the updated schedules
        for (Id rdId : newSchedulesByRdId.keySet()) {
            schedulesByRdId.put(rdId, newSchedulesByRdId.get(rdId));
        }

        return schedulesByRdId;
    }

    /***
    * @description Retrieves recurring donation schedules associated with recurring donation list
    * @param rds List<npe03__Recurring_Donation__c>
    */
    public Map<Id, List<RecurringDonationSchedule__c>> getExistingSchedules(List<npe03__Recurring_Donation__c> rds) {

        Map<Id, List<RecurringDonationSchedule__c>> oldSchedules = new Map<Id, List<RecurringDonationSchedule__c>>();

        for (RecurringDonationSchedule__c oldSchedule : [
                SELECT
                    Campaign__c,
                    Campaign__r.Name,
                    DayOfMonth__c,
                    EndDate__c,
                    InstallmentAmount__c,
                    InstallmentFrequency__c,
                    InstallmentPeriod__c,
                    PaymentMethod__c,
                    RecurringDonation__c,
                    StartDate__c
                FROM RecurringDonationSchedule__c
                WHERE RecurringDonation__c IN :rds
                AND Active__c = true
        ]) {
            if (!oldSchedules.containsKey(oldSchedule.RecurringDonation__c)) {
                oldSchedules.put(oldSchedule.RecurringDonation__c, new List<RecurringDonationSchedule__c>());
            }
            oldSchedules.get(oldSchedule.RecurringDonation__c).add(oldSchedule);
        }

        return oldSchedules;
    }

    /***
    * @description Filters recurring donations to determine which need schedule updates
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    */
    public Map<Id, npe03__Recurring_Donation__c> getRecurringDonationsNeedingScheduleUpdates(
            List<npe03__Recurring_Donation__c> rds,
            List<npe03__Recurring_Donation__c> oldRds,
            TDTM_Runnable.Action triggerAction)
    {

        Map<Id, npe03__Recurring_Donation__c> oldRdsById = new Map<Id, npe03__Recurring_Donation__c>();
        oldRdsById.putAll(oldRds);

        Map<Id, npe03__Recurring_Donation__c> filteredRecurringDonations = new Map<Id, npe03__Recurring_Donation__c>();
        for (npe03__Recurring_Donation__c rd : rds) {
            npe03__Recurring_Donation__c oldRd = oldRdsById.get(rd.Id);

            if (isScheduleUpdateNeeded(rd, oldRd)) {

                if (triggerAction == TDTM_Runnable.Action.BeforeUpdate &&
                    rd.StartDate__c == oldRd.StartDate__c &&
                    rd.Status__c != RD2_Constants.STATUS_CLOSED) {
                    rd.StartDate__c = Date.today();
                }

                filteredRecurringDonations.put(rd.Id, rd);
            }
        }

        return filteredRecurringDonations;
    }

    /***
    * @description Adds recurring donation schedules to map by recurring donation Id
    * @param rd SObject
    * @param newSchedulesByRdId Map<Id, List<RecurringDonationSchedule__c>>
    */
    private void addUpdatedSchedules(RecurringDonationSchedule__c rd, Map<Id, List<RecurringDonationSchedule__c>> newSchedulesByRdId) {

        if (rd.EndDate__c == null || (rd.EndDate__c >= Date.today() && rd.StartDate__c < rd.EndDate__c)) {

            if (!newSchedulesByRdId.containsKey(rd.RecurringDonation__c)) {
                newSchedulesByRdId.put(rd.RecurringDonation__c, new List<RecurringDonationSchedule__c>());
            }
            newSchedulesByRdId.get(rd.RecurringDonation__c).add(rd);
        }
    }
}
