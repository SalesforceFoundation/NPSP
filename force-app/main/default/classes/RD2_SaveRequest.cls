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
    @AuraEnabled public String achLastFour {get; set;}
    @AuraEnabled public String cardLastFour {get; set;}
    @AuraEnabled public String cardExpirationMonth {get; set;}
    @AuraEnabled public String cardExpirationYear {get; set;}
    @AuraEnabled public String changeType {get; set;}

    @AuraEnabled public Map<String, Object> customFieldValues {
        get {
            if (customFieldValues == null) {
                customFieldValues = new Map<String, Object>();
            }
            return customFieldValues;
        }
        set;
    }

    @TestVisible
    private UTIL_Permissions permissions {
        get {
            if (permissions == null) {
                permissions = UTIL_Permissions.getInstance();
            }
            return permissions;
        }
        set;
    }

    @TestVisible
    private UTIL_Describe describeUtil {
        get {
            if (describeUtil == null) {
                describeUtil = UTIL_Describe.getInstance();
            }
            return describeUtil;
        }
        set;
    }

    @TestVisible
    private RD2_SaveRequestHelper requestHelper {
        get {
            if (requestHelper == null) {
                requestHelper = new RD2_SaveRequestHelper();
            }
            return requestHelper;
        }
        set;
    }

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
        rd.CardExpirationMonth__c = cardExpirationMonth;
        rd.CardExpirationYear__c = cardExpirationYear;
        rd.CardLast4__c = cardLastFour;
        rd.ACH_Last_4__c = achLastFour;
        rd.ChangeType__c = changeType;

        if (customFieldValues != null && !customFieldValues.isEmpty()) {
            setCustomFieldValues(rd);
        }

        return rd;
    }

    public Set<String> getCustomFieldNamesForPermissionCheck() {
        return customFieldValues == null ? new Set<String>{} : customFieldValues.keySet();
    }

    public RD2_SaveRequest removeNonCreateableCustomFields() {
        DescribeSObjectResult rdSObjectDescribe = describeUtil.getObjectDescribeInstance(
                npe03__Recurring_Donation__c.SObjectType);

        for (String fieldApiName : customFieldValues.keySet()) {
            if (!permissions.canCreateInstanced(
                    rdSObjectDescribe.getName(),
                    fieldApiName,
                    false)) {

                customFieldValues.remove(fieldApiName);
            }
        }
        return this;
    }

    @TestVisible
    private void setCustomFieldValues(npe03__Recurring_Donation__c rd) {

        DescribeSObjectResult recurringDonationDescribeResult = describeUtil.getObjectDescribeInstance(
            npe03__Recurring_Donation__c.SObjectType
        );

        for (String fieldApiName : customFieldValues.keySet()) {
            String fieldValue = String.valueOf(customFieldValues.get(fieldApiName));

            switch on describeUtil.getFieldTypeInstance(
                    recurringDonationDescribeResult.getName(),
                    fieldApiName) {

                when 'BOOLEAN' {
                    Boolean booleanFieldValue = String.isBlank(fieldValue) ? null : Boolean.valueOf(fieldValue);
                    requestHelper.setRecurringDonationField(rd, fieldApiName, booleanFieldValue);
                }
                when 'DATE' {
                    Date dateFieldValue = String.isBlank(fieldValue) ? null : Date.valueOf(fieldValue);
                    requestHelper.setRecurringDonationField(rd, fieldApiName, dateFieldValue);
                }
                when 'DATETIME' {
                    Datetime dateFieldValue = String.isBlank(fieldValue) ? null : Datetime.valueOf(
                        fieldValue.replace('T', ' '));

                    requestHelper.setRecurringDonationField(rd, fieldApiName, dateFieldValue);
                }
                when 'TIME' {
                    Time timeFieldValue = String.isBlank(fieldValue) ? null : convertToTime(fieldValue);
                    requestHelper.setRecurringDonationField(rd, fieldApiName, timeFieldValue);
                }
                when 'CURRENCY', 'PERCENT', 'DOUBLE' {
                    Double doubleFieldValue = String.isBlank(fieldValue) ? null : Double.valueOf(fieldValue);
                    requestHelper.setRecurringDonationField(rd, fieldApiName, doubleFieldValue);
                }
                when 'INTEGER' {
                    Integer integerFieldValue = String.isBlank(fieldValue) ? null : Integer.valueOf(fieldValue);
                    requestHelper.setRecurringDonationField(rd, fieldApiName, integerFieldValue);
                }
                when else {
                    requestHelper.setRecurringDonationField(rd, fieldApiName, fieldValue);
                }
            }
        }
    }

    private Time convertToTime(String fieldValue) {
        List<String> timeSplitByDelimiter = fieldValue.split(':');
        Time timeValue = Time.newInstance(
                Integer.valueOf(timeSplitByDelimiter[0]),
                Integer.valueOf(timeSplitByDelimiter[1]),
                0,
                0);
        return timeValue;
    }
}