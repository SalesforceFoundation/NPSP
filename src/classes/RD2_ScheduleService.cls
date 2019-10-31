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
    * @param schedule Recurring Donation Schedule record
    * @return Date
    */
    public Date getNextDonationDate(List<RecurringDonationSchedule__c> rdSchedules) {

        Date nextDate;
        Date previousDate;

        for (RecurringDonationSchedule__c schedule : rdSchedules) {

            nextDate = schedule.StartDate__c;

            if (schedule.DayOfMonth__c != null && (
                    schedule.InstallmentPeriod__c == RD2_Constants.FREQUENCY_MONTHLY ||
                    schedule.InstallmentPeriod__c == RD2_Constants.FREQUENCY_FIRST_AND_FIFTEENTH))
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

            if (previousDate < nextDate) {
                nextDate = previousDate;
            }

            previousDate = nextDate;
        }

        return nextDate;
    }

    /***
    * @description Determines whether '1st and 15th' is the schedule selected.
    * @param rd Recurring Donation record
    * @return Boolean
    */
    private Boolean isFirstAndFifteenth(npe03__Recurring_Donation__c rd) {
        return rd.npe03__Installment_Period__c == RD2_Constants.FREQUENCY_FIRST_AND_FIFTEENTH;
    }

}
