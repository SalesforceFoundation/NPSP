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
* @description Contains Elevate payment services API methods to send a commitment HttpRequest
*/
public with sharing class PS_ElevateCommitmentAPI {

    public enum CommitmentType { 
        SUSTAINER
    }
    public enum PaymentMethod { 
        CARD
    }

    /***
     * @description Translates the currency amt into the lowest denominator; e.g. dollars into cents
     */ 
    private static Map<String, Integer> currencyMultiplierByCode = new Map<String, Integer>{
        'USD' => 100
    };

    /***
     * @description Translates the Installment Period into Elevate API frequency value
     */ 
    private static Map<String, String> frequencyByInstallmentPeriod = new Map<String, String>{
        RD2_Constants.INSTALLMENT_PERIOD_YEARLY => 'YEAR',
        RD2_Constants.INSTALLMENT_PERIOD_MONTHLY => 'MONTH',
        RD2_Constants.INSTALLMENT_PERIOD_WEEKLY => 'WEEK',
        RD2_Constants.INSTALLMENT_PERIOD_DAILY => 'DAY',
        RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH => 'MONTH'
    };

    @TestVisible
    private PS_ElevateAPI.ConfigurationService config {
        get {
            if (config == null) {
                config = new PS_ElevateAPI.ConfigurationService();
            }
            return config;
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
            .withMerchantId(config.getMerchantIds())
            .withGatewayId(config.getGatewayIds())
            .withPaymentMethodToken(token);

        npe03__Recurring_Donation__c rd = getRecurringDonation(recordId);

        String currencyCode = UserInfo.isMultiCurrencyOrganization()
            ? (String) rd.get('CurrencyIsoCode')
            : UserInfo.getDefaultCurrency();
        
        reqBody.withCurrency(currencyCode);

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
    private void setDonorInfo(RequestBody reqBody, npe03__Recurring_Donation__c rd) {
        Boolean isContactDonor = rd.npe03__Contact__c != null;

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
    private void setSchedules(RequestBody reqBody, List<RecurringDonationSchedule__c> rdSchedules, String currencyCode) {
        Integer currencyMultiplier = currencyMultiplierByCode.get(currencyCode);

        List<Schedule> schedules = new List<Schedule>();
        for (RecurringDonationSchedule__c rdSchedule : rdSchedules) {
            schedules.add(new Schedule(rdSchedule, currencyMultiplier));
        }

        reqBody.withSchedules(schedules);
    }

    /**
    * @param recordId RecurringDonation.RecordId
    * @return Recurring Donation object
    */
    private npe03__Recurring_Donation__c getRecurringDonation(Id recordId) {
        Set<String> fields = new Set<String>{
            'Id',
            'RecurringType__c',
            'npe03__Organization__c',
            'npe03__Organization__r.Name',
            'npe03__Contact__c',
            'npe03__Contact__r.FirstName',
            'npe03__Contact__r.LastName',
            'npe03__Contact__r.MailingStreet',
            'npe03__Contact__r.MailingCity',
            'npe03__Contact__r.MailingState',
            'npe03__Contact__r.MailingPostalCode',
            'npe03__Contact__r.MailingCountry'
        };

        if (ADDR_Addresses_TDTM.isStateCountryPicklistsEnabled) {
            fields.add('npe03__Contact__r.MailingStateCode');
            fields.add('npe03__Contact__r.MailingCountryCode');
        }  
        
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
    public with sharing class RequestBody {
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
        public String salutation;
        public String suffix; 
        public String email;
        public String phone;
        public String addressLine1;
        public String addressLine2;
        public String city;
        public String state;
        public String postalCode;        
        public String country;

        public RequestBody() {
            //set defaults
            currencyCode = UserInfo.getDefaultCurrency();
            type = CommitmentType.SUSTAINER.name();
            paymentMethodType = PaymentMethod.CARD.name();
        }

        public RequestBody withMerchantId(String merchantId) {
            this.merchantId = merchantId;
            return this;
        }

        public RequestBody withGatewayId(String gatewayId) {
            this.gatewayId = gatewayId;
            return this;
        }

        public RequestBody withCurrency(String currencyCode) {
            this.currencyCode = currencyCode;
            return this;
        }

        public RequestBody withPaymentMethodToken(String token) {
            this.paymentMethodToken = token;
            return this;
        }

        public RequestBody withDonor(Contact contact) {
            if (contact == null) {
                return this;
            }

            this.firstName = contact.FirstName;
            this.lastName = contact.LastName;

            this.addressLine1 = contact.MailingStreet;
            this.city = contact.MailingCity;
            this.state = contact.MailingState;
            this.postalCode = contact.MailingPostalCode;

            // The ISO 3166-1 alpha-2 country code. E.g. US
            if (ADDR_Validator_UTIL.isUSCountry(contact.MailingCountry)) {
                this.country = 'US';
            }
            
            return this;
        }

        public RequestBody withDonor(Account organization) {
            if (organization == null) {
                return this;
            }

            this.firstName = organization.Name;
            this.lastName = organization.Name;

            return this;
        }

        public RequestBody withSchedules(List<Schedule> schedules) {
            this.schedules = schedules;
            return this;
        }

        public RequestBody applyAll(Map<String, Object> requestBodyParameters) {
            Map<String, Object> selfAsUntyped = (Map<String, Object>) JSON.deserializeUntyped(getAsJson());

            for (String key : requestBodyParameters.keySet()) {
                selfAsUntyped.put(key, requestBodyParameters.get(key));
            }

            return (RequestBody) JSON.deserialize(JSON.serialize(selfAsUntyped), RequestBody.class);
        }

        public String getAsJson() {
            return JSON.serialize(this);
        }
    }

    /***
    * @description Contains Recurring Donation Schedule info to be relayed to the Elevate API
    */
    public with sharing class Schedule {
        public Integer recurringPaymentAmount;
        public String frequency;
        public Integer frequencyInterval;
        public String firstOccurenceOn;

        public Schedule(RecurringDonationSchedule__c rdSchedule, Integer currencyMultiplier) {
            this.recurringPaymentAmount = Integer.valueOf(rdSchedule.InstallmentAmount__c * currencyMultiplier);

            this.frequency = frequencyByInstallmentPeriod.get(rdSchedule.InstallmentPeriod__c);
            this.frequencyInterval = Integer.valueOf(rdSchedule.InstallmentFrequency__c);

            this.firstOccurenceOn = getNextDonationDate(rdSchedule);
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
            return donationDatetime.format('YYYY-MM-DD');
        }
    }

    /***
    * @description Assists in constructing the metadata property.
    */
    public with sharing class Metadata {
        public String originType;
        public String originDisplayName;
        public String campaignCode;
    }
}
