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
public with sharing class RD2_TestRecurringDonationBuilder {

    private Map<String, Object> valuesByFieldName;

    /***
    * @description Constructor sets default values
    */
    public RD2_TestRecurringDonationBuilder() {
        valuesByFieldName = new Map<String, Object>();
        
        //defaults
        valuesByFieldName.put('Name', 'TestRecurringDonation');
    }

    /***
    * @description Sets Opportunity Id
    */
    public RD2_TestRecurringDonationBuilder withId(Id rdId) {
        valuesByFieldName.put('Id', rdId);
        return this;
    }

    /***
    * @description Sets Name
    */
    public RD2_TestRecurringDonationBuilder withName(String name) {
        valuesByFieldName.put('Name', name);
        return this;
    }

    /***
    * @description Sets Account
    */
    public RD2_TestRecurringDonationBuilder withAccount(Id accountId) {
        valuesByFieldName.put('npe03__Organization__c', accountId);
        return this;
    }

    /***
    * @description Sets Contact
    */
    public RD2_TestRecurringDonationBuilder withContact(Id contactId) {
        valuesByFieldName.put('npe03__Contact__c', contactId);
        return this;
    }

    /***
    * @description Sets Amount
    */
    public RD2_TestRecurringDonationBuilder withAmount(Decimal amount) {
        valuesByFieldName.put('npe03__Amount__c', amount);
        return this;
    }

    /***
    * @description Sets CurrencyIsoCode
    */
    public RD2_TestRecurringDonationBuilder withCurrencyIsoCode(String ccyIsoCode) {
        valuesByFieldName.put(UTIL_Currency.CURRENCY_ISO_CODE_FIELD, ccyIsoCode);
        return this;
    }

    /***
    * @description Builds npe03__Recurring_Donation__c sObject based on the provided values
    */
    public npe03__Recurring_Donation__c build() {
        String jsonString = JSON.serialize(valuesByFieldName);
            
        return (npe03__Recurring_Donation__c) JSON.deserialize(jsonString, npe03__Recurring_Donation__c.class);
    }

}