/*
    Copyright (c) 2020, Salesforce.org
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
* @group Elevate Payment Services
* @description Contains Elevate payment services methods specific to building a commitment request
*/
public inherited sharing class PS_CommitmentRequest {

    public enum CommitmentType {
        SUSTAINER
    }

    public enum PaymentMethod {
        CARD
    }

    /***
     * @description Translates the currency amount into the lowest denominator; e.g. dollars into cents
     */
    private static Map<String, Integer> currencyMultiplierByIsoCode = new Map<String, Integer>{
        'USD' => 100
    };

    /***
     * @description Default currency multiplier
     */
    private static Integer DEFAULT_CURRENCY_MULTIPLIER = 100;

    /***
     * @description Translates the Installment Period into the Elevate API frequency value
     */
    private static Map<String, String> frequencyByInstallmentPeriod = new Map<String, String>{
        RD2_Constants.INSTALLMENT_PERIOD_YEARLY => 'YEAR',
        RD2_Constants.INSTALLMENT_PERIOD_MONTHLY => 'MONTH',
        RD2_Constants.INSTALLMENT_PERIOD_WEEKLY => 'WEEK',
        RD2_Constants.INSTALLMENT_PERIOD_DAILY => 'DAY',
        RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH => 'MONTH'
    };

    /***
     * @description Payment Services configuration
     */
    @TestVisible
    private PS_IntegrationServiceConfig.Service configService {
        get {
            if (configService == null) {
                configService = new PS_IntegrationServiceConfig.Service();
            }
            return configService;
        }
        set;
    }

    /***
    * @description Constructs the Commitment request body for the specified Recurring Donation
    * @param recordId Recurring Donation Id
    * @param token Payment Method Token
    * @return RequestBody
    */
    public RequestBody getRequestBody(Id recordId, String token) {
        RequestBody reqBody = new RequestBody()
            .withMerchantId(configService.getMerchantIds())
            .withGatewayId(configService.getGatewayIds())
            .withPaymentMethodToken(token);

        npe03__Recurring_Donation__c rd = getRecurringDonation(recordId);

        String currencyCode = UserInfo.isMultiCurrencyOrganization()
            ? (String) rd.get('CurrencyIsoCode')
            : UserInfo.getDefaultCurrency();

        reqBody.withCurrency(currencyCode);
        reqBody.withMetadata(new Metadata());

        setDonorInfo(reqBody, rd);
        setSchedules(reqBody, rd.RecurringDonationSchedules__r, currencyCode);

        return reqBody;
    }

    /**
    * @description Sets donor info on the commitment request body
    * @param reqBody RequestBody
    * @param rd Recurring Donation record
    * @return void
    */
    @TestVisible
    private void setDonorInfo(RequestBody reqBody, npe03__Recurring_Donation__c rd) {
        Boolean isContactDonor = rd.npe03__Contact__c != null
            && (
                rd.npe03__Organization__c == null 
                || rd.npe03__Organization__c == rd.npe03__Contact__r.AccountId
            );

        if (isContactDonor) {
            reqBody.withDonor(rd.npe03__Contact__r);
        } else {
            reqBody.withDonor(rd.npe03__Organization__r);
        }
    }

    /**
    * @description Sets schedules on the commitment request body
    * @param reqBody RequestBody
    * @param rdSchedules Recurring Donation Schedules
    * @param currencyCode Currency ISO Code
    * @return void
    */
    @TestVisible
    private void setSchedules(RequestBody reqBody, List<RecurringDonationSchedule__c> rdSchedules, String currencyCode) {
        Integer currencyMultiplier = getCurrencyMultiplier(currencyCode);

        List<Schedule> schedules = new List<Schedule>();
        for (RecurringDonationSchedule__c rdSchedule : rdSchedules) {
            schedules.add(new Schedule(rdSchedule, currencyMultiplier));
        }

        reqBody.withSchedules(schedules);
    }

    /**
    * @description Determines the currency multiplier
    * @param currencyCode Currency ISO Code
    * @return Integer
    */
    private Integer getCurrencyMultiplier(String currencyCode) {
        Integer currencyMultiplier = currencyMultiplierByIsoCode.get(currencyCode);

        return currencyMultiplier == null
            ? DEFAULT_CURRENCY_MULTIPLIER
            : currencyMultiplier;
    }

    /**
    * @description Queries Recurring Donation fields and related schedules
    * @param recordId RecurringDonation.RecordId
    * @return Recurring Donation object
    */
    @TestVisible
    private npe03__Recurring_Donation__c getRecurringDonation(Id recordId) {
        Set<String> fields = new Set<String>{
            'Id',
            'RecurringType__c',
            'npe03__Organization__c',
            'npe03__Organization__r.Name',
            'npe03__Contact__c',
            'npe03__Contact__r.AccountId',
            'npe03__Contact__r.FirstName',
            'npe03__Contact__r.LastName'
        };

        if (UserInfo.isMultiCurrencyOrganization()) {
            fields.add('CurrencyIsoCode');
        }

        fields.add(getScheduleSubQuery());

        String soql = new UTIL_Query()
            .withFrom(npe03__Recurring_Donation__c.SObjectType)
            .withSelectFields(fields)
            .withWhere('Id = :recordId')
            .withLimit(1)
            .build();

        return Database.query(soql);
    }

    /**
     * @description Returns query on Recurring Donation Schedule
     * @return String RD Schedule subquery used in the Recurring Donation SOQL
     */
    private String getScheduleSubQuery() {
        Set<String> fields = new RD2_ScheduleService.ScheduleQueryHandler().getFields();

        return '(SELECT ' + String.join(new List<String>(fields), ', ') + ' FROM RecurringDonationSchedules__r)';
    }


    /***
    * @description Assists in constructing the Commitment HttpRequest body.
    */
    public class RequestBody {
        /***
         * Required properties
         */
        public String firstName;
        public String lastName;
        public String merchantId;
        public String gatewayId;
        public String type;
        public String paymentMethodType;
        public String paymentMethodToken;
        public String currencyCode;
        public List<Schedule> schedules;

        /***
         * @description Metadata containing origin type and other properties
         */
        public Metadata metadata;

        /***
         * @description Constructor
         */
        public RequestBody() {
            //set defaults
            currencyCode = UserInfo.getDefaultCurrency();
            type = CommitmentType.SUSTAINER.name();
            paymentMethodType = PaymentMethod.CARD.name();
        }

        /**
         * @description Sets merchant Id
         * @param merchantId Payments merchant Id
         * @return RequestBody This request body instance
         */
        public RequestBody withMerchantId(String merchantId) {
            this.merchantId = merchantId;
            return this;
        }

        /**
         * @description Sets gateway Id
         * @param gatewayId Payments gateway Id
         * @return RequestBody This request body instance
         */
        public RequestBody withGatewayId(String gatewayId) {
            this.gatewayId = gatewayId;
            return this;
        }

        /**
         * @description Sets currency code value
         * @param currencyCode Currency ISO Code
         * @return RequestBody This request body instance
         */
        public RequestBody withCurrency(String currencyCode) {
            this.currencyCode = currencyCode;
            return this;
        }

        /**
         * @description Sets payment token, for example credit card token
         * @param token Token
         * @return RequestBody This request body instance
         */
        public RequestBody withPaymentMethodToken(String token) {
            this.paymentMethodToken = token;
            return this;
        }

        /**
         * @description Sets donor related info such as first and last name required fields
         * @param contact Donor
         * @return RequestBody This request body instance
         */
        public RequestBody withDonor(Contact contact) {
            if (contact == null) {
                return this;
            }

            this.firstName = contact.FirstName;
            this.lastName = contact.LastName;

            return this;
        }

        /**
         * @description Sets donor related info
         * @param organization Donor
         * @return RequestBody This request body instance
         */
        public RequestBody withDonor(Account organization) {
            if (organization == null) {
                return this;
            }

            this.firstName = organization.Name;
            this.lastName = organization.Name;

            return this;
        }

        /**
         * @description Sets schedules data
         * @param schedules Payments API schedules
         * @return RequestBody This request body instance
         */
        public RequestBody withSchedules(List<Schedule> schedules) {
            this.schedules = schedules;
            return this;
        }

        /**
         * @description Sets metadata
         * @param metadata Payments API metadata
         * @return RequestBody This request body instance
         */
        public RequestBody withMetadata(Metadata metadata) {
            this.metadata = metadata;
            return this;
        }

        /**
         * @description Returns this request body as a JSON string
         * @return String
         */
        public String getAsJson() {
            return JSON.serialize(this);
        }
    }

    /***
     * @description Contains Recurring Donation Schedule info to be relayed to the Elevate API
     */
    public class Schedule {
        public Integer recurringPaymentAmount;
        public String frequency;
        public Integer frequencyInterval;
        public String firstOccurrenceOn;

        /**
         * @description Schedule constructor
         * @param rdSchedule Recurring Donation Schedule
         * @param currencyMultiplier Currency multiplier
         */
        public Schedule(RecurringDonationSchedule__c rdSchedule, Integer currencyMultiplier) {
            Double amount = rdSchedule.InstallmentAmount__c * currencyMultiplier;
            this.recurringPaymentAmount = amount == null ? null : Integer.valueOf(amount);

            this.frequency = frequencyByInstallmentPeriod.get(rdSchedule.InstallmentPeriod__c);
            this.frequencyInterval = rdSchedule.InstallmentFrequency__c == null
                ? null
                : Integer.valueOf(rdSchedule.InstallmentFrequency__c);

            this.firstOccurrenceOn = getNextDonationDate(rdSchedule);
        }

        /***
         * @description Determins the first payment date based on the provided schedule
         * @param rdSchedule Recurring Donation Schedule
         * @return String ISO8601 date-time string
         */
        private String getNextDonationDate(RecurringDonationSchedule__c rdSchedule) {
            Date donationDate = new RD2_ScheduleService()
                .getNextDonationDateGreaterThan(rdSchedule, RD2_ScheduleService.currentDate);

            DateTime donationDatetime = Datetime.newInstance(donationDate.year(), donationDate.month(), donationDate.day());
            return donationDatetime.format('yyyy-MM-dd');
        }
    }

    /***
     * @description Assists in constructing the metadata property.
     */
    public class Metadata {
        public String originType;
        public String originDisplayName;
        public String campaignCode;

        /**
         * @description Metadata constructor
         */
        public Metadata() {
            //set defaults
            this.originType = PS_Request.OriginType.CRM.name();
        }
    }
}
