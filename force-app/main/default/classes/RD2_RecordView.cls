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
* @description View class representing Recurring Donation record data for the Recurring Donations App
*/
public class RD2_RecordView {
    @AuraEnabled public Id recordId;
    @AuraEnabled public String recordName;
    @AuraEnabled public String recurringStatus;
    @AuraEnabled public String statusReason;
    @AuraEnabled public Id contactId;
    @AuraEnabled public Id accountId;
    @AuraEnabled public String donorType;
    @AuraEnabled public Date dateEstablished;
    @AuraEnabled public Decimal donationValue;
    @AuraEnabled public String currencyIsoCode;
    @AuraEnabled public Decimal paidAmount;
    @AuraEnabled public String recurringPeriod;
    @AuraEnabled public Integer recurringFrequency;
    @AuraEnabled public Date startDate;
    @AuraEnabled public String dayOfMonth;
    @AuraEnabled public Integer plannedInstallments;
    @AuraEnabled public Integer paidInstallments;
    @AuraEnabled public Id campaignId;
    @AuraEnabled public String recurringType;
    @AuraEnabled public Date nextDonationDate;
    @AuraEnabled public String paymentToken;
    @AuraEnabled public String commitmentId;
    @AuraEnabled public String achLastFour;
    @AuraEnabled public String cardLastFour;
    @AuraEnabled public String cardExpirationMonth;
    @AuraEnabled public String cardExpirationYear;
    @AuraEnabled public String paymentMethod;
    @AuraEnabled public Map<String, Object> customFieldValues;

    public RD2_RecordView() {
        Date today = Date.today();
        this.donorType = RD2_Constants.DONOR_TYPE_CONTACT;
        this.dateEstablished = today;
        this.startDate = today;
    }

    public RD2_RecordView(npe03__Recurring_Donation__c record) {
        this.withRecord(record);
    }

    private RD2_RecordView withRecord(npe03__Recurring_Donation__c record) {
        this.recordId = record.Id;
        this.contactId = record.npe03__Contact__c;
        this.accountId = record.npe03__Organization__c;
        this.recurringStatus = record.Status__c;
        this.statusReason = record.ClosedReason__c;
        this.recordName = record.Name;
        this.dateEstablished = record.npe03__Date_Established__c;
        this.donationValue = record.npe03__Amount__c;
        this.paidAmount = record.npe03__Paid_Amount__c;
        this.recurringPeriod = record.npe03__Installment_Period__c;
        this.recurringFrequency = record.InstallmentFrequency__c?.intValue();
        this.startDate = record.StartDate__c;
        this.dayOfMonth = record.Day_of_Month__c;
        this.plannedInstallments = record.npe03__Installments__c?.intValue();
        this.paidInstallments = record.npe03__Total_Paid_Installments__c?.intValue();
        this.paymentMethod = record.PaymentMethod__c;
        this.nextDonationDate = record.npe03__Next_Payment_Date__c;
        this.recurringType = record.RecurringType__c;
        this.campaignId = record.npe03__Recurring_Donation_Campaign__c;
        this.commitmentId = record.CommitmentId__c;
        this.achLastFour = record.ACH_Last_4__c;
        this.cardLastFour = record.CardLast4__c;
        this.cardExpirationMonth = record.CardExpirationMonth__c;
        this.cardExpirationYear = record.CardExpirationYear__c;
        return this;
    }
}