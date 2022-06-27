/*
    Copyright (c) 2022, Salesforce.org
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
* @date 2022
* @group Payment
* @description Selector Class for npe01__OppPayment__c Sobject
*/
public with sharing class PaymentSelector {
    private Boolean isMultiCurrencyEnabled {
        get {
            if (isMultiCurrencyEnabled == null) {
                isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
            }
            return isMultiCurrencyEnabled;
        }
        set;
    }
    
    public npe01__OppPayment__c getPaymentRecordForRefund(Id paymentId) {
        return getPaymentRecordsForRefund(new Set<Id>{paymentId})?.get(0);
    }

    public List<npe01__OppPayment__c> getPaymentRecordsForRefund(Set<Id> paymentIds) {
        Set<String> queryFields = getRefundFields();

        if (isMultiCurrencyEnabled) {
            queryFields.add(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
        }

        String soql = new UTIL_Query()
            .withFrom(npe01__OppPayment__c.SObjectType)
            .withSelectFields(queryFields)
            .withWhere('Id IN: paymentIds')
            .build();

        return Database.query(soql);
    }

    public List<npe01__OppPayment__c> getPaymentsWithRefunds(Set<Id> paymentIds) {
        Set<String> queryFields = getRefundFields();
        queryFields.add(getRefundSubQuery());

        if (isMultiCurrencyEnabled) {
            queryFields.add(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
        }
        
    
        String soql = new UTIL_Query()
            .withFrom(npe01__OppPayment__c.SObjectType)
            .withSelectFields(queryFields)
            .withWhere('Id IN: paymentIds')
            .build();

        return Database.query(soql);
    }

    private Set<String> getRefundFields() {
        return new Set<String>{
            'Id',
            String.valueOf(npe01__OppPayment__c.Elevate_Payment_ID__c),
            'npe01__Payment_Amount__c',
            'npe01__Opportunity__c',
            'npe01__Opportunity__r.Amount',
            'npe01__Payment_Date__c',
            String.valueOf(npe01__OppPayment__c.DebitType__c)
        }; 
    }
    private String getRefundSubQuery() {
        Set<String> refundFields = new Set<String>{
            'Id',
            'npe01__Payment_Amount__c'
        };

        if (isMultiCurrencyEnabled) {
            refundFields.add(UTIL_Currency.CURRENCY_ISO_CODE_FIELD);
        }

    
        String refundSubquery = new UTIL_Query()
            .withSelectFields(refundFields)
            .withFrom('Refunds__r')
            .build();

        return '(' + refundSubquery + ')';
    }
}
