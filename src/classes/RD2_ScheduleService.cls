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

public with sharing class RD2_ScheduleService {

    private npe03__Recurring_Donation__c parentRecurringDonation;
    @TestVisible
    private List<RecurringDonationSchedule__c> recurringDonationSchedules = new List<RecurringDonationSchedule__c>();

    private void init(npe03__Recurring_Donation__c rd, List<RecurringDonationSchedule__c> rdSchedules) {
        parentRecurringDonation = rd;
        if (rdSchedules != null) {
            recurringDonationSchedules = rdSchedules;
        }
    }

    public RD2_ScheduleService(npe03__Recurring_Donation__c rd) {
        init(rd, null);
    }

    public RD2_ScheduleService(npe03__Recurring_Donation__c rd, List<RecurringDonationSchedule__c> rdSchedules) {
        init(rd, rdSchedules);
    }

    /*******************************************************************************************************
    * @description Initializes RecurringDonationSchedule__c record(s) associated with a parent
    * npe03__Recurring_Donation__c record (parentRecurringDonation)
    * @return List<RecurringDonationSchedule__c>
    */
    public List<RecurringDonationSchedule__c> initializeSchedule() {
        if (parentRecurringDonation != null && parentRecurringDonation.Id != null && parentRecurringDonation.Status__c != 'Closed') {
            recurringDonationSchedules.add(new RecurringDonationSchedule__c());
            if (parentRecurringDonation.Day_of_Month__c == '1st and 15th' && parentRecurringDonation.npe03__Installment_Period__c == 'Monthly') {
                recurringDonationSchedules.add(new RecurringDonationSchedule__c());
            }
        }
        generateRecurringDonationScheduleDetails();
        return recurringDonationSchedules;
    }

    // TODO: Update schedule to reflect parentRecurringDonation - W-036113
    public List<RecurringDonationSchedule__c> updateSchedule() {
        return null;
    }

    // TODO: Will return next Donation date - W-036251
    public Date getNextDonationDate() {
        return null;
    }

    // TODO: Will return an inner class (TBD)
    public List<Date> visualizeSchedule() {
        return null;
    }

    private void generateRecurringDonationScheduleDetails() {
        Integer recordCount = 1;
        for (RecurringDonationSchedule__c rds : recurringDonationSchedules) {
            rds.InstallmentAmount__c = parentRecurringDonation.npe03__Installment_Amount__c;
            rds.InstallmentFrequency__c = parentRecurringDonation.InstallmentFrequency__c;
            rds.InstallmentPeriod__c = parentRecurringDonation.npe03__Installment_Period__c;
            rds.PaymentMethod__c = parentRecurringDonation.PaymentMethod__c;
            rds.RecurringDonation__c = parentRecurringDonation.Id;
            rds.Campaign__c = parentRecurringDonation.npe03__Recurring_Donation_Campaign__c;
            Date refDate =
                parentRecurringDonation.StartDate__c > parentRecurringDonation.npe03__Date_Established__c ?
                parentRecurringDonation.StartDate__c :
                parentRecurringDonation.npe03__Date_Established__c;
            if (parentRecurringDonation.npe03__Installment_Period__c == 'Monthly') {
                if (parentRecurringDonation.Day_of_Month__c != '1st and 15th') {
                    rds.DayOfMonth__c = parentRecurringDonation.Day_of_Month__c;
                } else if (recordCount == 1) {
                    rds.DayOfMonth__c = '1';
                } else {
                    rds.DayOfMonth__c = '15';
                }
                rds.StartDate__c= Date.newInstance(refDate.year(), refDate.month(), Integer.valueOf(rds.DayOfMonth__c));
            }
            else {
                rds.StartDate__c = refDate;
            }
            recordCount++;
        }
    }

}