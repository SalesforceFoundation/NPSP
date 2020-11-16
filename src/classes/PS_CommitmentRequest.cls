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

    /***
     * @description Commitment type
     */
    public enum CommitmentType {
        SUSTAINER
    }

    /***
     * @description Commitment payment method. Currently only credit card is supported.
     */
    public enum PaymentMethod {
        CARD
    }

    /***
     * @description Commitment Status
     * Commitments start in the NEW state, then transition to ACTIVE after the first payment.
     * The Status cannot be an enum since NEW is a reserved keyword.
     */
    public static String STATUS_NEW = 'NEW';
    public static String STATUS_ACTIVE = 'ACTIVE';
    public static String STATUS_INACTIVE = 'INACTIVE';
    public static String STATUS_FAILING = 'FAILING';

    /***
     * @description Commitment Status Reason
     */
    public enum CommitmentStatusReason {
        COMMITMENT_CREATED,
        PAID_AS_AGREED,
        PARTIALLY_PAID,
        PAYMENT_ERROR,
        PAYMENT_DECLINE,
        DONOR_CANCELED,
        MULTIPLE_FAILURES,
        NEVER_PAID
    }

    /***
     * @description Commitment schedule frequency
     */
    public enum Frequency {
        DAY, WEEK, MONTH, YEAR
    }

    /***
     * @description Translates the Installment Period into the Elevate API frequency value
     */
    private static Map<String, String> frequencyByInstallmentPeriod = new Map<String, String>{
        RD2_Constants.INSTALLMENT_PERIOD_YEARLY => Frequency.YEAR.name(),
        RD2_Constants.INSTALLMENT_PERIOD_MONTHLY => Frequency.MONTH.name(),
        RD2_Constants.INSTALLMENT_PERIOD_WEEKLY => Frequency.WEEK.name(),
        RD2_Constants.INSTALLMENT_PERIOD_DAILY => Frequency.DAY.name(),
        RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH => Frequency.MONTH.name()
    };

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
     * @description Contains max length for a first/last name passed to the Elevate commitment request
     */
    private static Integer MAX_NAME_LENGTH = 60;

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
    * @description Creates an HttpRequest for a new commitment creation
    * @param jsonRequestBody JSON containing parameters for the purchase call request body
    * @return HttpRequest
    */
    public HttpRequest buildCreateRequest(String jsonRequestBody) {
        return new PS_Request.Builder()
            .withMethod(UTIL_Http.Method.POST)
            .withEndpoint(PS_Request.ElevateEndpoint.COMMITMENT)
            .withRecommendedTimeout()
            .withBody(jsonRequestBody)
            .build();
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

    /**
     * @description Parses the response and returns the commitment data contained in the response body
     * @param response Create commitment request response
     * @return ResponseBody
     */
    public ResponseBody getCommitment(UTIL_Http.Response response) {
        ResponseBody commitment = new ResponseBody();

        if (response != null
            && response.statusCode == UTIL_Http.STATUS_CODE_CREATED
            && String.isNotBlank(response.body)
        ) {
            commitment = (ResponseBody) JSON.deserialize(response.body, ResponseBody.class);
        }

        return commitment;
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
         * Optional properties
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

            this.firstName = trimNameField(contact.FirstName);
            this.lastName = trimNameField(contact.LastName);

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

            this.firstName = trimNameField(organization.Name);
            this.lastName = trimNameField(organization.Name);

            return this;
        }

        /**
         * @description Return max number of character allowed for the first/last name in Elevate
         * @param name First or Last Name
         * @return String
         */
        private String trimNameField(String name) {
            return String.isBlank(name) ? name : name.abbreviate(MAX_NAME_LENGTH);
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

    /**
     * @description Contains Elevate recurring commitment data in the response body
     */
    public class ResponseBody {
        public String id;
        public String status;
        public String statusReason;
        public CardData cardData;

        /**
         * @description Returns true if the commitment data has the id specified
         * @return Boolean
         */
        public Boolean hasId() {
            return String.isNotBlank(id);
        }

        /**
         * @description Returns true if the commitment has new or active status
         * @return Boolean
         */
        public Boolean isActive() {
            return status == STATUS_NEW || status == STATUS_ACTIVE;
        }

        /**
         * @description Returns true if the commitment has just been created
         * @return Boolean
         */
        public Boolean isCreated() {
            return isActive()
                && statusReason == CommitmentStatusReason.COMMITMENT_CREATED.name();
        }

        /**
         * @description Returns true if the commitment credit card data has been returned
         * @return Boolean
         */
        public Boolean hasCardData() {
            return cardData != null;
        }

        /**
         * @description Returns credit card last 4 digits
         * @return String
         */
        public String getCardLast4() {
            return hasCardData() ? cardData.last4 : null;
        }

        /**
         * @description Returns credit card expiration month
         * @return String
         */
        public String getCardExpirationMonth() {
            return hasCardData() ? cardData.expirationMonth : null;
        }

        /**
         * @description Returns credit card expiration year
         * @return String
         */
        public String getCardExpirationYear() {
            return hasCardData() ? cardData.expirationYear : null;
        }
    }

    /**
     * @description Contains credit card data on the commitment
     */
    public class CardData {
        public String last4;
        public String expirationMonth;
        public String expirationYear;
    }

    /***
     * @description Metadata property on the commitment request
     */
    public class Metadata {
        public String originType;

        /**
         * @description Metadata constructor
         */
        public Metadata() {
            //set defaults
            this.originType = PS_Request.OriginType.CRM.name();
        }
    }
}
