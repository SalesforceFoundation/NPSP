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
* @description Recurring Donations Builder
*
*/
@isTest
public without sharing class TEST_RecurringDonationBuilder {
    public static final Date DEFAULT_ESTABLISHED_DATE = Date.newInstance(1970,6,12);

    private Map<String, Object> valuesByFieldName;

    /***
    * @description Constructor 
    */
    public TEST_RecurringDonationBuilder() {
        valuesByFieldName = new Map<String, Object>();
        
        this.withName('RD' + UTIL_UnitTestData_TEST.getUniqueString());
    }

    /***
    * @description Sets default values
    */
    public TEST_RecurringDonationBuilder withDefaults() {
        return this
            .withAmount(2)
            .withInstallments(2)
            .withInstallmentPeriodYearly()
            .withDateEstablished(DEFAULT_ESTABLISHED_DATE)
            .withScheduleTypeMultiplyValue();
    }

    /***
    * @description Sets the Id
    */
    public TEST_RecurringDonationBuilder withId(Id rdId) {
        valuesByFieldName.put('Id', rdId);
        return this;
    }

    /***
    * @description Sets the mock Id
    */
    public TEST_RecurringDonationBuilder withMockId() {
        valuesByFieldName.put('Id', UTIL_UnitTestData_TEST.mockId(npe03__Recurring_Donation__c.SObjectType));
        return this;
    }    

    /***
    * @description Sets the Owner to the current user Id
    */
    public TEST_RecurringDonationBuilder withOwnerId() {
        valuesByFieldName.put('OwnerId', System.UserInfo.getUserId());
        return this;
    }


    /***
    * @description Sets Name
    */
    public TEST_RecurringDonationBuilder withName(String name) {
        valuesByFieldName.put('Name', name);
        return this;
    }

    /***
    * @description Sets Account
    */
    public TEST_RecurringDonationBuilder withAccount(Id accountId) {
        valuesByFieldName.put('npe03__Organization__c', accountId);
        return this;
    }

    /***
    * @description Sets Contact
    */
    public TEST_RecurringDonationBuilder withContact(Id contactId) {
        valuesByFieldName.put('npe03__Contact__c', contactId);
        return this;
    }

    /***
    * @description Sets Amount
    */
    public TEST_RecurringDonationBuilder withAmount(Decimal amount) {
        valuesByFieldName.put('npe03__Amount__c', amount);
        return this;
    }

    /***
    * @description Sets CurrencyIsoCode
    */
    public TEST_RecurringDonationBuilder withCurrencyIsoCode(String ccyIsoCode) {
        if (UserInfo.isMultiCurrencyOrganization()) {
            valuesByFieldName.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, ccyIsoCode);
        }
        
        return this;
    }

    /***
    * @description Sets Date Established
    */
    public TEST_RecurringDonationBuilder withDateEstablished(Date dt) {
        valuesByFieldName.put('npe03__Date_Established__c', dt);
        return this;
    }

    /***
    * @description Sets Next Payment Date
    */
    public TEST_RecurringDonationBuilder withNextPaymentDate(Date dt) {
        valuesByFieldName.put('npe03__Next_Payment_Date__c', dt);
        return this;
    }    

    /***
    * @description Sets if the last day of month should be used
    */
    public TEST_RecurringDonationBuilder withAlwaysUseLastDayOfMonth(Boolean shouldUse) {
        valuesByFieldName.put('Always_Use_Last_Day_Of_Month__c', shouldUse);
        return this;
    }    

    /***
    * @description Sets Day of Month
    */
    public TEST_RecurringDonationBuilder withDayOfMonth(String dayOfMonth) {
        valuesByFieldName.put('Day_Of_Month__c', dayOfMonth);
        return this;
    }    

    /***
    * @description Sets number of Installments
    */
    public TEST_RecurringDonationBuilder withInstallments(Integer size) {
        valuesByFieldName.put('npe03__Installments__c', size);
        return this;
    }

    /***
    * @description Sets Installment Period to Yearly
    */
    public TEST_RecurringDonationBuilder withInstallmentPeriodYearly() {
        return withInstallmentPeriod(System.Label.npe03.RecurringDonationInstallmentPeriodYearly);
    }

    /***
    * @description Sets Installment Period to Quarterly
    */
    public TEST_RecurringDonationBuilder withInstallmentPeriodQuarterly() {
        return withInstallmentPeriod(System.Label.npe03.RecurringDonationInstallmentPeriodQuarterly);
    }

    /***
    * @description Sets Installment Period to Monthly
    */
    public TEST_RecurringDonationBuilder withInstallmentPeriodMonthly() {
        return withInstallmentPeriod(System.Label.npe03.RecurringDonationInstallmentPeriodMonthly);
    }

    /***
    * @description Sets Installment Period to Weekly
    */
    public TEST_RecurringDonationBuilder withInstallmentPeriodWeekly() {
        return withInstallmentPeriod(System.Label.npe03.RecurringDonationInstallmentPeriodWeekly);
    }

    /***
    * @description Sets Installment Period
    */
    public TEST_RecurringDonationBuilder withInstallmentPeriod(String installmentPeriod) {
        valuesByFieldName.put('npe03__Installment_Period__c', installmentPeriod);
        return this;
    }

    /***
    * @description Sets Schedule Type
    */
    public TEST_RecurringDonationBuilder withScheduleTypeMultiplyValue() {
        valuesByFieldName.put('npe03__Schedule_Type__c', System.Label.npe03.RecurringDonationMultiplyValue);
        return this;
    }

    /***
    * @description Sets Open Ended Status to Open Status
    */
    public TEST_RecurringDonationBuilder withOpenEndedStatusOpen() {
        return withOpenEndedStatus(System.Label.npe03.RecurringDonationOpenStatus);
    }

    /***
    * @description Sets Open Ended Status to Closed Status
    */
    public TEST_RecurringDonationBuilder withOpenEndedStatusClosed() {
        return withOpenEndedStatus(System.Label.npe03.RecurringDonationClosedStatus);
    }

    /***
    * @description Sets Open Ended Status to None
    */
    public TEST_RecurringDonationBuilder withOpenEndedStatusNone() {
        return withOpenEndedStatus('None');
    }

    /***
    * @description Sets Open Ended Status
    */
    public TEST_RecurringDonationBuilder withOpenEndedStatus(String status) {
        valuesByFieldName.put('npe03__Open_Ended_Status__c', status);
        return this;
    }

    /***
    * @description Sets Recurring Donation Campaign
    */
    public TEST_RecurringDonationBuilder withCampaign(Id campaignId) {
        valuesByFieldName.put('npe03__Recurring_Donation_Campaign__c', campaignId);
        return this;
    }
    

    /***
    * @description Builds Recurring Donation sObject based on the provided values
    */
    public npe03__Recurring_Donation__c build() {
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();

        for (String fieldName : valuesByFieldName.keySet()) {
            rd.put(fieldName, valuesByFieldName.get(fieldName));
        }

        return rd;
    }

    /***
    * @description Builds "size" number of Recurring Donation records based on already provided values
    */
    public List<npe03__Recurring_Donation__c> build(Integer size) {
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();

        for (Integer i = 0; i < size; i++) {
            rds.add(this
                .withName(UTIL_UnitTestData_TEST.getUniqueString())
                .build()
            );
        }

        return rds;
    }

    /***
    * @description Builds Recurring Donation records for each provided Contact
    */
    public List<npe03__Recurring_Donation__c> build(List<Contact> contacts) {
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();

        for (Contact c : contacts) {
            rds.add(this
                .withName(UTIL_UnitTestData_TEST.getUniqueString())
                .withContact(c.Id)
                .build()
            );
        }

        return rds;
    }

    /***
    * @description Builds Recurring Donation records for each provided Account
    */
    public List<npe03__Recurring_Donation__c> build(List<Account> accounts) {
        List<npe03__Recurring_Donation__c> rds = new List<npe03__Recurring_Donation__c>();

        for (Account acc : accounts) {
            rds.add(this
                .withName(UTIL_UnitTestData_TEST.getUniqueString())
                .withAccount(acc.Id)
                .build()
            );
        }

        return rds;
    }

}