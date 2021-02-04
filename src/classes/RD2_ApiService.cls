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
        Map<Id, List<Schedule>> schedulesByRdId = new Map<Id, List<Schedule>>();

        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            return JSON.serialize(schedulesByRdId);
        }

        String soql = getRecurringDonationQuery();
        for (npe03__Recurring_Donation__c rd : Database.query(soql)) {

            List<Schedule> schedules = new List<Schedule>();
            for (RecurringDonationSchedule__c s : rd.RecurringDonationSchedules__r) {
                schedules.add(new Schedule(s, rd));
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
    private String getScheduleSubQuery() {
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
            currencyCode = RD2_ApiService.getCurrencyCode(rd);
        }
    }

    /**
     * @description Retrieves the currency from the RD or the org
     * @return currencyCode
     */
    private static String getCurrencyCode(npe03__Recurring_Donation__c rd) {
        String currencyCode;

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

        return currencyCode;
    }

    /**
     * @description Retrieve a map of scheduled installments by Rd.id.  Paused installments are omitted.
     * @param startDate Begin date of range for installments. Defaults to current date if null.
     * @param endDate End date of range for installments
     * @param rdIds Recurring Donation Ids for which to retrieve installments
     * @return String JSON Serialized version of Map<Id, List<RD2_ApiService.Installment>> installmentsByRdId
     */
    public String queryInstallments(Date startDate, Date endDate, Set<Id> rdIds) {
        Map<Id, List<Installment>> installmentsByRdId = new Map<Id, List<Installment>>();

        if (!RD2_EnablementService.isRecurringDonations2Enabled) {
            return JSON.serialize(installmentsByRdId);
        }

        if (startDate == null) {
            startDate = RD2_ScheduleService.currentDate;
        }

        if (endDate == null) {
            endDate = getDefaultEndDate(startDate);
        }

        RD2_ScheduleService service = new RD2_ScheduleService();
        String soql = getRecurringDonationQuery();
        for (npe03__Recurring_Donation__c rd : Database.query(soql)) {

            List<Installment> installments = new List<Installment>();
            for (RD2_ScheduleService.Installment installment : service.getVisualizedInstallments(
                startDate,
                endDate,
                rd.RecurringDonationSchedules__r)
            ) {
                installments.add(new Installment(installment, rd));
            }

            installmentsByRdId.put(rd.Id, installments);
        }

        return JSON.serialize(installmentsByRdId);
    }

    /**
     * @description Calculates endDate to produce 1 year of installment data. In most cases that means
     * endDate should be set to startDate + 1 year - 1 day. There may be edge cases where that is not
     * true, so the subtraction is limited to cases where the day portion of startDate == the day portion of endDate.
     * The outcome of subtracting one day is to ensure that one year of installments is included. Without the
     * adjustment, an extra installment is reported in most, if not all, scenarios.
     * @param startDate Date
     * @return endDate Date
     */
    private Date getDefaultEndDate(Date startDate) {
        Date endDate = startDate.addYears(1);

        if (startDate.day() == endDate.day()) {
            endDate = endDate.addDays(-1);
        }
        
        return endDate;
    }

    /***
    * @description Wrapper class for Recurring Donation Schedule data for the querySchedules api
    */
    public class Installment {

        public String recurringDonationId { get; set; }
        public String scheduleId { get; set; }
        public String campaignId { get; set; }
        public Date closeDate { get; set; }
        public Decimal installmentAmount { get; set; }
        public String currencyCode { get; set; }
        public String paymentMethod { get; set; }

        public Installment(RD2_ScheduleService.Installment installment, npe03__Recurring_Donation__c rd) {
            recurringDonationId = rd.Id;
            scheduleId = installment.scheduleId;
            campaignId = installment.campaignId;
            closeDate = installment.nextDonationDate;
            installmentAmount = installment.installmentAmount;
            paymentMethod = installment.paymentMethod;
            currencyCode = currencyCode = RD2_ApiService.getCurrencyCode(rd);
        }
    }
}