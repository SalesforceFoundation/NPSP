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
* @description Class with methods to create, modify and visualize RecurringDonationSchedule__c records.
*
*/

public without sharing class RD2_Schedule_SVC {

    public static final String FIFTEENTH = '15';
    public static final String FIRST = '1';
    public static final String FIRST_AND_FIFTEENTH = '1st and 15th';
    public static final String LAST_DAY_OF_MONTH = 'Last Day';
    public static final Integer LAST_DAY_THRESHHOLD = 29;
    public static final String MONTHLY = 'Monthly';


    private List<RecurringDonationSchedule__c> schedulesToUpdate = new List<RecurringDonationSchedule__c>();
    private List<RecurringDonationSchedule__c> schedulesToInsert = new List<RecurringDonationSchedule__c>();

    /***
    * @description Gets new recurring donation schedules
    * @return List<RecurringDonationSchedule__c>
    */
    public List<RecurringDonationSchedule__c> getRDSchedulesToInsert() {
        return schedulesToInsert;
    }

    /***
    * @description Gets updated recurring donation schedules
    * @return List<RecurringDonationSchedule__c>
    */
    public List<RecurringDonationSchedule__c> getRDSchedulesToUpdate() {
        return schedulesToUpdate;
    }

    /***
    * @description Creates new recurring donation schedule(s) for recurring donation
    * @param rd Recurring donation record
    * @return RD2_Schedule_SVC
    */
    public RD2_Schedule_SVC createSchedule(npe03__Recurring_Donation__c rd) {

        RecurringDonationSchedule__c rdsched = new RecurringDonationSchedule__c();

        rdsched.Campaign__c = rd.npe03__Recurring_Donation_Campaign__c;

        /* TODO: For fixed length recurring donations we may need to calculate this
        rdsched.EndDate__c = ??
         */

        rdsched.InstallmentAmount__c = rd.npe03__Installment_Amount__c;
        rdsched.InstallmentFrequency__c = rd.InstallmentFrequency__c;
        rdsched.InstallmentPeriod__c = rd.npe03__Installment_Period__c;
        rdsched.PaymentMethod__c = rd.PaymentMethod__c;
        rdsched.RecurringDonation__c = rd.Id;

        if (rdsched.InstallmentPeriod__c == MONTHLY) {
            rdsched.DayOfMonth__c = getDayOfMonth(rd);
        }
        schedulesToInsert.add(rdsched);

        if (isFirstAndFifteenth(rd)) {
            rdsched = rdsched.clone();
            rdsched.DayOfMonth__c = FIFTEENTH;
            schedulesToInsert.add(rdsched);
        }

        for (RecurringDonationSchedule__c rds : schedulesToInsert) {
            rds.StartDate__c = calculateStartDate(rds, rd);
        }

        return this;
    }

    // TODO: Update schedule to reflect recurringDonation - W-036113 (Placeholder)
    public RD2_Schedule_SVC updateSchedule(npe03__Recurring_Donation__c rd, List<RecurringDonationSchedule__c> rdScheds) {
        return this;
    }

    // TODO: Will return next Donation date - W-036251 (Placeholder)
    public Date getNextDonationDate(RecurringDonationSchedule__c rdSched) {
        return null;
    }

    // TODO: Will return an inner class (Placeholder - RDScheduleDates)
    public List<RDScheduleDates> visualizeSchedule(npe03__Recurring_Donation__c rd, List<RecurringDonationSchedule__c> rdScheds) {
        return new List<RDScheduleDates>();
    }

    // TODO: Placeholder internal class used for visualization)
    public class RDScheduleDates {
        public npe03__Recurring_Donation__c recurringDonation;
        public List<RecurringDonationSchedule__c> rdSchedules;
        public Date donationDate;
    }

    /***
    * @description Calculates start date for a recurring donation schedule
    * @param rdSchedule Recurring Donation schedule
    * @param rd Recurring Donation schedule
    * @return Date
    */
    private Date calculateStartDate(RecurringDonationSchedule__c rdSchedule, npe03__Recurring_Donation__c rd) {
        Date retDate;

        Date minSD = rd.StartDate__c > rd.npe03__Date_Established__c ?
                     rd.StartDate__c :
                     rd.npe03__Date_Established__c;

        retDate = minSD > Date.today() ?
                  minSD :
                  Date.today();

        if (rdSchedule.InstallmentPeriod__c == MONTHLY) {
            Integer lastDay = Date.daysInMonth(retDate.year(), retDate.month());
            retDate = Date.newInstance(retDate.year(), retDate.month(), rdSchedule.DayOfMonth__c == LAST_DAY_OF_MONTH ?
                                                                        lastDay :
                                                                        Integer.valueOf(rdSchedule.DayOfMonth__c));
            retDate = retDate >= Date.today() ?
                      retDate :
                      retDate.addMonths(1);
        }

        return retDate;
    }

    /***
    * @description Determines whether '1st and 15th' is the schedule selected.
    * @param rd Recurring Donation record
    * @return Boolean
    */
    private Boolean isFirstAndFifteenth(npe03__Recurring_Donation__c rd) {
        return rd.Day_of_Month__c == FIRST_AND_FIFTEENTH && rd.npe03__Installment_Period__c == MONTHLY;
    }

    /***
    * @description Gets schedule day of month from recurring donation day of month
    * @param rd Recurring Donation
    * @return String
    */
    private String getDayOfMonth(npe03__Recurring_Donation__c rd) {
        String retval = rd.Day_of_Month__c;

        if (rd.Day_of_Month__c.isNumeric() && Integer.valueOf(rd.Day_of_Month__c) >= LAST_DAY_THRESHHOLD) {
            retval = LAST_DAY_OF_MONTH;
        }
        else if (isFirstAndFifteenth(rd)) {
            retval = FIRST;
        }

        return retval;
    }

}