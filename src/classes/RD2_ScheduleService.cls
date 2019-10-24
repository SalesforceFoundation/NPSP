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

public without sharing class RD2_ScheduleService {

    private List<RecurringDonationSchedule__c> schedulesToInsert = new List<RecurringDonationSchedule__c>();

    /***
    * @description Gets new recurring donation schedules
    * @return List<RecurringDonationSchedule__c>
    */
    public List<RecurringDonationSchedule__c> getRDSchedulesToInsert() {
        return schedulesToInsert;
    }

    /***
    * @description Creates new recurring donation schedule(s) for recurring donation
    * @param rd Recurring donation record
    * @return RD2_Schedule_SVC
    */
    public RD2_ScheduleService createSchedule(npe03__Recurring_Donation__c rd) {

        RecurringDonationSchedule__c rdsched = new RecurringDonationSchedule__c();

        rdsched.RecurringDonation__c = rd.Id;
        rdsched.Campaign__c = rd.npe03__Recurring_Donation_Campaign__c;

        /* TODO: For fixed length recurring donations we may need to calculate this
        rdsched.EndDate__c = ??
         */

        rdsched.InstallmentAmount__c = rd.npe03__Installment_Amount__c;
        rdsched.InstallmentFrequency__c = rd.InstallmentFrequency__c;
        rdsched.InstallmentPeriod__c = rd.npe03__Installment_Period__c;
        rdsched.PaymentMethod__c = rd.PaymentMethod__c;
        rdsched.StartDate__c = rd.StartDate__c;

        if (!isFirstAndFifteenth(rd)) {
            rdsched.DayOfMonth__c = rd.Day_of_Month__c;

        } else {
            rdsched.DayOfMonth__c = RD2_Constants.DAY_OF_MONTH_FIRST;
            schedulesToInsert.add(rdsched);
            rdsched = rdsched.clone();
            rdsched.DayOfMonth__c = RD2_Constants.DAY_OF_MONTH_FIFTEENTH;
        }

        schedulesToInsert.add(rdsched);

        return this;
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
