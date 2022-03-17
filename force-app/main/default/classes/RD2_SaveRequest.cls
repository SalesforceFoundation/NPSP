/*
 *
 *     Copyright (c) 2022, Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 * /
 */
/**
* @author Salesforce.org
* @date 2022
* @description Message class representing a request to save a Recurring Donation
*/
public with sharing class RD2_SaveRequest {
    @AuraEnabled public Id recordId {get; set;}
    @AuraEnabled public String recordName {get; set;}
    @AuraEnabled public String recurringStatus {get; set;}
    @AuraEnabled public String statusReason {get; set;}
    @AuraEnabled public Id contactId {get; set;}
    @AuraEnabled public Id accountId {get; set;}
    @AuraEnabled public Date dateEstablished {get; set;}
    @AuraEnabled public Decimal donationValue {get; set;}
    @AuraEnabled public String currencyIsoCode {get; set;}
    @AuraEnabled public String recurringPeriod {get; set;}
    @AuraEnabled public Integer recurringFrequency {get; set;}
    @AuraEnabled public Date startDate {get; set;}
    @AuraEnabled public String dayOfMonth {get; set;}
    @AuraEnabled public Integer plannedInstallments {get; set;}
    @AuraEnabled public String recurringType {get; set;}
    @AuraEnabled public String campaignId {get; set;}
    @AuraEnabled public String paymentToken {get; set;}
    @AuraEnabled public String commitmentId {get; set;}
    @AuraEnabled public String paymentMethod {get; set;}
    @AuraEnabled public Map<String, Object> customFieldValues {get; set;}

    public npe03__Recurring_Donation__c toRecord() {
        npe03__Recurring_Donation__c rd = new npe03__Recurring_Donation__c();
        rd.Id = recordId;
        rd.Name = recordName;
        if (recurringStatus != null) {
            rd.Status__c = recurringStatus;
        }
        rd.ClosedReason__c = statusReason;
        rd.npe03__Contact__c = contactId;
        rd.npe03__Organization__c = accountId;
        rd.npe03__Date_Established__c = dateEstablished;

        rd.npe03__Amount__c = donationValue;
        if (UserInfo.isMultiCurrencyOrganization()) {
            rd.put('CurrencyIsoCode', currencyIsoCode);
        }

        rd.npe03__Installment_Period__c = recurringPeriod;
        rd.InstallmentFrequency__c = recurringFrequency;
        rd.StartDate__c = startDate;
        rd.Day_of_Month__c = dayOfMonth;
        rd.npe03__Installments__c = plannedInstallments;
        rd.RecurringType__c = recurringType;
        rd.npe03__Recurring_Donation_Campaign__c = campaignId;
        rd.CommitmentId__c = commitmentId;
        rd.PaymentMethod__c = paymentMethod;

        if (customFieldValues != null) {
            for (String fieldApiName : customFieldValues.keySet()) {
                Object fieldValue = customFieldValues.get(fieldApiName);
                rd.put(fieldApiName, fieldValue);
            }
        }

        return rd;
    }

    public Set<String> getCustomFieldNames() {
        return customFieldValues.keySet();
    }
}