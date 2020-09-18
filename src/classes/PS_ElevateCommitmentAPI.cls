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

    private static Map<String, String> frequencyByInstallmentPeriod = new Map<String, String>{
        RD2_Constants.INSTALLMENT_PERIOD_YEARLY => 'YEAR',
        RD2_Constants.INSTALLMENT_PERIOD_MONTHLY => 'MONTH',
        RD2_Constants.INSTALLMENT_PERIOD_WEEKLY => 'WEEK',
        RD2_Constants.INSTALLMENT_PERIOD_DAILY => 'DAY'
    };


    
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
        public String country;// The ISO 3166-1 alpha-2 country code. E.g. US

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

        public RequestBody withSchedules(List<Schedule> schedules) {
            this.schedules = this.schedules;
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
        public Double recurringPaymentAmount;
        public String frequency;
        public Integer frequencyInterval;
        public String firstOccurenceOn;

        public Schedule(RecurringDonationSchedule__c rdSchedule) {
            this.recurringPaymentAmount = rdSchedule.InstallmentAmount__c;

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
