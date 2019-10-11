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
* @description Class with methods for creation and modification of RecurringDonationSchedule__c records.
*
*/public with sharing class RD2_ScheduleService {

    /*******************************************************************************************************
    * @description Creates and optionally recalculates RecurringDonationSchedule__c records associated
    * with a list of existing npe03__Recurring_Donation__c records
    * @param rds The list of npe03__Recurring_Donation__c records for which to  create associated
    * RecurringDonationSchedule__c records
    * @param recalculate Boolean flag to force recalculation of StartDate__c
    * @return void
    */
    public static List<RecurringDonationSchedule__c> createRecurringDonationSchedule(List<npe03__Recurring_Donation__c> rds, Boolean recalculate) {

        List<RecurringDonationSchedule__c> schedules = new List<RecurringDonationSchedule__c>();
        for (npe03__Recurring_Donation__c rd: rds) {
            if (rd.Id != null) {
                schedules.add(new RecurringDonationSchedule__c(
                        InstallmentAmount__c = rd.npe03__Installment_Amount__c,
                        DayOfMonth__c = rd.Day_of_Month__c,
                        InstallmentFrequency__c = rd.InstallmentFrequency__c,
                        InstallmentPeriod__c = rd.npe03__Installment_Period__c,
                        PaymentMethod__c = rd.PaymentMethod__c,
                        RecurringDonation__c = rd.Id,
                        Campaign__c = rd.npe03__Recurring_Donation_Campaign__c,
                        StartDate__c = rd.StartDate__c
                ));
                if (recalculate) {
                    // TODO: Recalculate call to be inserted here (or earlier perhaps, depending upon the specifics of the method)
                }
            }
        }
        return schedules;
    }

}