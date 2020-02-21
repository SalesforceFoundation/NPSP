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

        // Invalid Installment Frequency should never result in a schedule update. This is a fail safe measure only
        } else if (newRd.InstallmentFrequency__c == null || newRd.InstallmentFrequency__c < 1 || newRd.InstallmentFrequency__c > 20) {
            isNeeded = false;

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
    * @description Calculates the dates of the next N Installment Opportunities for specified Recurring Donations
    * @param rds Recurring Donation records
    * @param startDate Lower boundary date used to filter installments with Close Date >= startDate (if null, current date will be used)
    * @param numInstallments Number of installment Opportunities to return (if null, default number will be used)
    * @param schedulesByRd RD Schedules by RD Id (if null, active schedules will be queried)
    * @return Map<Id, List<Installment>> Upcoming installments mapped by the Recurring Donation Id
    */
    public Map<Id, List<Installment>> getVisualizedInstallments(
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
    * @description Calculates the dates of the next N Installment Opportunities for a single Recurring Donation
    * @param startDate Lower boundary date used to filter installments with Close Date >= startDate
    * @param numInstallments Number of installment Opportunities
    * @param schedules RD Schedules
    * @return List<Installment>
    */
    public List<Installment> getVisualizedInstallments(Date startDate, Integer numInstallments, List<RecurringDonationSchedule__c> schedules) {
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

            installments.add(inst);
            referenceDate = inst.nextDonationDate.addDays(1);
        }

        return installments;
    }

    /***
    * @description Calculates the dates of the next N donations for a single Recurring Donation
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

            installments.add(inst);
            referenceDate = inst.nextDonationDate.addDays(1);
        }

        return installments;
    }

    /***
    * @description Indicates if the schedule is active starting from the reference date
    * @param schedule Recurring Donation schedule
    * @param referenceDate Reference Date
    * @return Boolean
    */
    public Boolean isActive(RecurringDonationSchedule__c schedule, Date referenceDate) {
        //ensure the passed in schedules are active within the time period
        Boolean isActive = schedule.EndDate__c == null 
            || (schedule.EndDate__c >= referenceDate && (schedule.StartDate__c <= schedule.EndDate__c));

        Boolean isInstallmentFrequencyValid = schedule.InstallmentFrequency__c != null
            && schedule.InstallmentFrequency__c >= 1
            && schedule.InstallmentFrequency__c <= 20;

        return isActive && isInstallmentFrequencyValid;
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

        List <RecurringDonationSchedule__c> filteredSchedules = new List<RecurringDonationSchedule__c>();
        for (RecurringDonationSchedule__c schedule : schedules) {
            if (isActive(schedule, referenceDate)) {
                filteredSchedules.add(schedule);
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
        if (rdSchedules == null) {
            return null;
        }

        Date nextDate;
        Date previousDate;
        for (RecurringDonationSchedule__c schedule : rdSchedules) {
            if (!isActive(schedule, currentDate)) {
                continue;
            }

            nextDate = getNextDonationDateGreaterThan(schedule, currentDate);

            if (previousDate < nextDate) {
                nextDate = previousDate;
            }
            previousDate = nextDate;
        }

        return nextDate;
    }

    /***
    * @description Calculates the next donation date >= referenced date
    * @param schedule Recurring Donation Schedule record
    * @param referenceDate Reference date used to calculate next donation date. It can be today or a future projected date.
    * @return Date The Next Donation Date
    */
    private Date getNextDonationDateGreaterThan(RecurringDonationSchedule__c schedule, Date referenceDate) {
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

        if (schedule.DayOfMonth__c == RD2_Constants.DAY_OF_MONTH_LAST_DAY && schedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY) {
            adjusted = Date.newInstance(adjusted.year(), adjusted.month(), Date.daysInMonth(adjusted.year(),adjusted.month()));
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
    * @description Retrieves detailed information about schedules suitable for viewing through UI
    * @param rd Recurring Donation record
    * @return List<ActiveSchedule>
    */
    public List<ActiveSchedule> getVisualizedSchedules(npe03__Recurring_Donation__c rd) {
        List<ActiveSchedule> activeSchedules = new List<ActiveSchedule>();
        List<RecurringDonationSchedule__c> schedules = getExistingSchedules(rd);

        Boolean first1stAnd15thFound = false;
        for (RecurringDonationSchedule__c schedule : schedules) {

            // This block collapses 1st and 15th schedules into a single row and nulls out day of month
            if (schedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH) {
                if (first1stAnd15thFound) {
                    first1stAnd15thFound = false;
                    continue;
                }
                first1stAnd15thFound = true;
            }
            activeSchedules.add(new ActiveSchedule(schedule));
        }

        return activeSchedules;
    }

    /***
    * @description Wrapper class for Recurring Donation Schedule data
    */
    public class ActiveSchedule {

        public Boolean  isCurrent {get;set;}
        public Id       campaignId {get; set;}
        public String   campaignName {get; set;}
        public String   dayOfMonth {get; set;}
        public Date     endDate {get; set;}
        public Decimal  installmentAmount {get; set;}
        public Integer  installmentFrequency {get; set;}
        public String   installmentPeriod {get; set;}
        public String   paymentMethod {get; set;}
        public String   recurringDonationId {get; set;}
        public Id       scheduleId {get; set;}
        public Date     startDate {get; set;}

        ActiveSchedule(RecurringDonationSchedule__c rdSchedule) {
            isCurrent =             rdSchedule.StartDate__c <= RD2_ScheduleService.currentDate ? true : false;
            campaignId =            rdSchedule.Campaign__c;
            campaignName =          rdSchedule.Campaign__r.Name;
            dayOfMonth =            rdSchedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY ? rdSchedule.DayOfMonth__c : null;
            endDate =               rdSchedule.EndDate__c;
            installmentAmount =     rdSchedule.InstallmentAmount__c;
            installmentFrequency =  rdSchedule.InstallmentFrequency__c != null ? Integer.valueOf(rdSchedule.InstallmentFrequency__c) : null;
            installmentPeriod =     rdSchedule.InstallmentPeriod__c;
            paymentMethod =         rdSchedule.PaymentMethod__c;
            recurringDonationId =   rdSchedule.RecurringDonation__c;
            scheduleId =            rdSchedule.Id;
            startDate =             rdSchedule.StartDate__c;
        }
    }

    /***
    * @description Performs a full analysis and rebuild of the Schedule records for a Recurring Donation,
    * but does not commit the schedule records to the database.  Uses the active schedules for the RD
    * to calculate the Next Donation Date and store onto the RD record (in a Before Update context,
    * thus avoiding the extra DML against the object).
    * @param rds Trigger.new records
    * @param oldRds Trigger.old records
    * @return Map<Id, List<RecurringDonationSchedule__c>>
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
    * @description Retrieves recurring donation schedules associated with recurring donation list
    * @param rds List<npe03__Recurring_Donation__c>
    * @return Map<Id, List<RecurringDonationSchedule__c>>
    */
    public Map<Id, List<RecurringDonationSchedule__c>> getExistingSchedules(List<npe03__Recurring_Donation__c> rds) {
        Map<Id, List<RecurringDonationSchedule__c>> schedulesById = new Map<Id, List<RecurringDonationSchedule__c>>();

        for (RecurringDonationSchedule__c schedule : Database.query(getExistingScheduleQueryString())) {
            if (!isActive(schedule, currentDate)) {
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
    * @description Build dynamic soql query string with support for date injection
    * @return String
    */
    private String getExistingScheduleQueryString() {

        Set<String> selectFields = new Set<String> {
            'Campaign__c',
            'Campaign__r.Name',
            'DayOfMonth__c',
            'EndDate__c',
            'InstallmentAmount__c',
            'InstallmentFrequency__c',
            'InstallmentPeriod__c',
            'PaymentMethod__c',
            'RecurringDonation__c',
            'StartDate__c'
        };
        String orderString = 'StartDate__c';

        Util_Query theQuery = new UTIL_Query()
            .withSelectFields(selectFields)
            .withFrom(RecurringDonationSchedule__c.SObjectType)
            .withWhere('RecurringDonation__c IN :rds')
            .withWhere('(EndDate__c = null OR EndDate__c >= :currentDate)')
            .withOrderBy(orderString);

        return theQuery.build();
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
                        rd.Status__c != RD2_Constants.STATUS_CLOSED
                        ) {
                    rd.StartDate__c = currentDate;
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
    * @return void
    */
    private void addUpdatedSchedules(RecurringDonationSchedule__c rd, Map<Id, List<RecurringDonationSchedule__c>> newSchedulesByRdId) {

        if (rd.EndDate__c == null || (rd.EndDate__c >= currentDate && rd.StartDate__c < rd.EndDate__c)) {

            if (!newSchedulesByRdId.containsKey(rd.RecurringDonation__c)) {
                newSchedulesByRdId.put(rd.RecurringDonation__c, new List<RecurringDonationSchedule__c>());
            }
            newSchedulesByRdId.get(rd.RecurringDonation__c).add(rd);
        }
    }
}
