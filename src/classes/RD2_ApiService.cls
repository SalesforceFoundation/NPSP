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
* @description All services specific to Enhanced Recurring Donation Api's
*
*/
public inherited sharing class RD2_ApiService {

    /**
     * @description Retrieve a map of RecurringDonationSchedule__c records by Rd.id using an inner wrapper
     * class representation of the RdSchedule object because it's protected and customers will not be able to
     * deserialize it.
     * @param rdIds Recurring Donation Id's to retrieve schedules for
     * @return JSON Serialized version of Map<Id, List<RD2_ApiService.Schedule>> schedulesByRdId
     */
    public String querySchedules(Set<Id> rdIds) {
        Map<Id, List<RD2_ApiService.Schedule>> schedulesByRdId = new Map<Id, List<RD2_ApiService.Schedule>>();

        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            return JSON.serialize(schedulesByRdId);
        }

        String soql = getRecurringDonationQuery();
        for (npe03__Recurring_Donation__c rd : Database.query(soql)) {

            List<RD2_ApiService.Schedule> schedules = new List<RD2_ApiService.Schedule>();
            for (RecurringDonationSchedule__c s : rd.RecurringDonationSchedules__r) {
                schedules.add(new RD2_ApiService.Schedule(s, rd));
            }

            schedulesByRdId.put(rd.Id, schedules);
        }

        return JSON.serialize(schedulesByRdId);
    }

    /**
     * @return SOQL of Recurring Donation records with a subquery on schedule records
     */
    private String getRecurringDonationQuery() {
        Set<String> queryFields = new Set<String>{
            'Id',
            'EndDate__c'
        };
        if (UserInfo.isMultiCurrencyOrganization()) {
            queryFields.add('CurrencyIsoCode');
        }

        queryFields.add(getScheduleSubQuery());

        String soql = new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(queryFields)
            .withWhere('Id IN :rdIds')
            .build();

        return soql;
    }

    /**
     * @description Returns query on Recurring Donation Schedule
     * Return all schedules for the RD Schedule visualization.
     * The Schedule Service will filter them out if not applicable within the time period.
     * @return String RD Schedule subquery used in the Recurring Donation SOQL
     */
    public String getScheduleSubQuery() {
        Set<String> fields = new RD2_ScheduleService.ScheduleQueryHandler().getFields();
        fields.add('CreatedDate');
        fields.add('LastModifiedDate');

        return '(SELECT ' + String.join(new List<String>(fields), ', ') +
            ' FROM RecurringDonationSchedules__r' +
            ' ORDER By StartDate__c' +
            ')';
    }

    /***
    * @description Wrapper class for Recurring Donation Schedule data for the querySchedules api
    */
    public class Schedule {

        public String recurringDonationId { get; set; }
        public String scheduleId { get; set; }
        public Boolean isActive { get; set; }
        public Boolean isCurrent { get; set; }
        public Boolean isPause { get; set; }
        public String campaignId { get; set; }
        public String dayOfMonth { get; set; }
        public Date endDate { get; set; }
        public Decimal installmentAmount { get; set; }
        public Integer installmentFrequency { get; set; }
        public String installmentPeriod { get; set; }
        public String paymentMethod { get; set; }
        public Date startDate { get; set; }
        public String statusReason { get; set; }
        public String currencyCode { get; set; }
        public Datetime createdDate { get ;set; }
        public Datetime lastModifiedDate { get ;set; }

        public Schedule(RecurringDonationSchedule__c rdSchedule, npe03__Recurring_Donation__c rd) {
            isActive = rdSchedule.Active__c;
            isCurrent = rdSchedule.StartDate__c <= RD2_ScheduleService.currentDate
                && (rdSchedule.EndDate__c == null || RD2_ScheduleService.currentDate <= rdSchedule.EndDate__c);
            isPause = rdSchedule.IsPause__c;
            campaignId = rdSchedule.Campaign__c;
            dayOfMonth = rdSchedule.InstallmentPeriod__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY ? rdSchedule.DayOfMonth__c : null;
            endDate = (rdSchedule.EndDate__c != null) ? rdSchedule.EndDate__c : rd.EndDate__c;
            installmentAmount = rdSchedule.InstallmentAmount__c;
            installmentFrequency = rdSchedule.InstallmentFrequency__c != null ? Integer.valueOf(rdSchedule.InstallmentFrequency__c) : null;
            installmentPeriod = rdSchedule.InstallmentPeriod__c;
            paymentMethod = rdSchedule.PaymentMethod__c;
            recurringDonationId = rdSchedule.RecurringDonation__c;
            scheduleId = rdSchedule.Id;
            startDate = rdSchedule.StartDate__c;
            statusReason = rdSchedule.StatusReason__c;
            createdDate = rdSchedule.CreatedDate;
            lastModifiedDate = rdSchedule.LastModifiedDate;

            try {
                if (UserInfo.isMultiCurrencyOrganization()) {
                    currencyCode = (String) rd.get(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
                } else {
                    currencyCode = Userinfo.getDefaultCurrency();
                }
            } catch (Exception ex) {
                // ignore any errors if for some reason we can't retrieve the currency code
                // because usage in the ActiveSchedule inner class is only for api use
            }
        }
    }

}