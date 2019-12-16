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
* @description Controller for the Schedule Visualization Component
*
*/
public with sharing class RD2_VisualizeScheduleController {

    @TestVisible
    private static RD2_ScheduleService scheduleService {
        get {
            if (scheduleService == null) {
                scheduleService = new RD2_ScheduleService();
            }
            return scheduleService;
        } set;
    }

    /**
     * @description Retrieves the current schedule of future donations to render in the UI
     * @param recordId
     * @return List<Schedule>
     */
    @AuraEnabled
    public static List<Installment> getSchedule(Id recordId, Integer displayNum) {

        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            throw new AuraHandledException(System.Label.RD2_ScheduleVisualizerErrorInvalidUsage);
        }

        if (recordId == null || recordId.getSobjectType() != npe03__Recurring_Donation__c.SObjectType) {
            throw new AuraHandledException(System.Label.RD2_ScheduleVisualizerErrorEnhancedRDNot);
        }

        npe03__Recurring_Donation__c rd = getRecurringDonation(recordId);

        List<Installment> upcomingDonations = new List<Installment>();
        if (rd.Status__c != RD2_Constants.STATUS_CLOSED) {
            List<RD2_ScheduleService.Installment> installments = scheduleService.getVisualizedInstallments(rd, Date.today(), displayNum, null);
            Integer num = 1;
            for (RD2_ScheduleService.Installment installment : installments) {
                upcomingDonations.add(new Installment(num++, rd, installment));
            }
        }

        if (upcomingDonations.isEmpty()) {
            throw new AuraHandledException(System.Label.RD2_ScheduleVisualizerMessageNoSchedule);
        }

        return upcomingDonations;
    }

    /**
     * @description Retrieves the currency code to use for the display
     * @param recordId
     * @return CurrencyIsoCode
     */
    public static String getCurrencyCode(npe03__Recurring_Donation__c rd) {
        if (UserInfo.isMultiCurrencyOrganization()) {
            return (String)rd.get('CurrencyIsoCode');
        } else {
            return UserInfo.getDefaultCurrency();
        }
    }


    /**
     * @description Inner Class of Future Donations for a given Recurring Donation
     */
    public class Installment {
        @AuraEnabled public Integer installmentNumber;
        @AuraEnabled public Date donationDate;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String campaign;
        @AuraEnabled public String paymentMethod;
        @AuraEnabled public String currencyIsoCode;

        public Installment(Integer num, npe03__Recurring_Donation__c rd, RD2_ScheduleService.Installment installment) {
            this.installmentNumber = num;
            this.paymentMethod = installment.paymentMethod;
            this.campaign = installment.campaignName;
            this.donationDate = installment.nextDonationDate;
            this.amount = installment.installmentAmount;
            this.currencyIsoCode = getCurrencyCode(rd);
        }
    }

    /**
     * @description Retrieve the full RecurringDonation record
     * @param Recurring Donations Id
     * @return Recurring Donation record
     */
    private static npe03__Recurring_Donation__c cachedRd;
    private static npe03__Recurring_Donation__c getRecurringDonation(Id recordId) {
        if (cachedRd == null) {
            Set<String> queryFields = new Set<String>{
                'Id',
                'StartDate__c',
                'InstallmentFrequency__c',
                'npe03__Installment_Period__c',
                'npe03__Amount__c',
                'PaymentMethod__c',
                'npe03__Recurring_Donation_Campaign__r.Name',
                'Day_of_Month__c',
                'Status__c'
            };
            if (UserInfo.isMultiCurrencyOrganization()) {
                queryFields.add('CurrencyIsoCode');
            }
            String soql = new UTIL_Query()
                .withFrom(npe03__Recurring_Donation__c.SObjectType)
                .withSelectFields(queryFields)
                .withWhere('Id = :recordId')
                .build();

            cachedRd = Database.query(soql);
        }
        return cachedRd;
    }
}