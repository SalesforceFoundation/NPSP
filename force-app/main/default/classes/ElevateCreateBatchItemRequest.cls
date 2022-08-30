/*
 * Copyright (c) 2020, Salesforce.org
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
public with sharing class ElevateCreateBatchItemRequest {
    @AuraEnabled public Integer amount {get; set;}
    @AuraEnabled public String firstName {get; set;}
    @AuraEnabled public String lastName {get; set;}
    @AuraEnabled public String paymentMethodToken {get; set;}
    @AuraEnabled public String currencyCode {get; set;}
    @AuraEnabled public Map<String, Object> recurringSchedule {get; set;}

    public String batchItemType;
    public CommitmentInfo commitmentInfo;
    public PurchaseInfo purchaseInfo;

    public ElevateCreateBatchItemRequest() {
        setBatchItemType();
    }

    public class CommitmentInfo {
        public String currencyCode;
        public String email;
        public String firstName;
        public String lastName;
        public String gatewayId;
        public String merchantId;
        public String paymentMethodToken;
        public String paymentMethodType;
        public Map<String, Object> productMetadata;
        public List<Schedule> schedules;
        public String type;

        public CommitmentInfo() {
            this.productMetadata = getProductMetadata();
            this.type = 'SUSTAINER';
        }

        public CommitmentInfo withCurrencyCode(String currencyCode) {
            this.currencyCode = currencyCode;
            return this;
        }

        public CommitmentInfo withEmail(String commitmentEmail) {
            this.email = commitmentEmail;
            return this;
        }

        public CommitmentInfo withFirstName(String firstName) {
            this.firstName = firstName;
            return this;
        }

        public CommitmentInfo withLastName(String lastName) {
            this.lastName = lastName;
            return this;
        }

        public CommitmentInfo withGatewayId(String gatewayId) {
            this.gatewayId = gatewayId;
            return this;
        }

        public CommitmentInfo withMerchantId(String merchantId) {
            this.merchantId = merchantId;
            return this;
        }

        public CommitmentInfo withPaymentMethodToken(String paymentMethodToken) {
            this.paymentMethodToken = paymentMethodToken;
            return this;
        }

        public CommitmentInfo withPaymentMethodType(String paymentMethodType) {
            this.paymentMethodType = paymentMethodType;
            return this;
        }

        public CommitmentInfo withSchedules(Map<String, Object> schedulesUntyped) {
            List<Schedule> schedules = new List<Schedule>();
            for (String field : schedulesUntyped.keySet()) {
                Schedule newSchedule = new Schedule();

                String amountFieldName = String.valueOf(
                        npe03__Recurring_Donation__c.npe03__Amount__c);
                String installmentPeriodFieldName = String.valueOf(
                    npe03__Recurring_Donation__c.npe03__Installment_Period__c);
                String dayOfMonthFieldName = String.valueOf(
                        npe03__Recurring_Donation__c.Day_of_Month__c);
                String startDateFieldName = String.valueOf(
                        npe03__Recurring_Donation__c.StartDate__c);

                newSchedule.amount = Decimal.valueOf(
                    String.valueOf(schedulesUntyped?.get(
                        amountFieldName))
                );

                newSchedule.frequency = String.valueOf(
                    schedulesUntyped?.get(installmentPeriodFieldName)
                );

                newSchedule.frequencyInterval = Integer.valueOf(
                    schedulesUntyped?.get(dayOfMonthFieldName)
                );

                newSchedule.firstOccurrenceOnTimestamp = Date.valueOf(
                    schedulesUntyped?.get(startDateFieldName)
                );

            }
            return this;
        }

    }
    public class Schedule {
        public Decimal amount;
        public Date firstOccurrenceOnTimestamp;
        public String frequency;
        public Integer frequencyInterval;
    }

    public class PurchaseInfo {
        public String merchantId;
        public String gatewayId;
        public String currencyCode;
        public Integer amount;
        public String firstName;
        public String lastName;
        public AchData achData;
        public String email;
        public String paymentMethodToken;
        public String paymentMethodType;
        public Map<String, Object> productMetadata;
    }

    public class AchData {
        public String achCode;
        public String bankType;
        public String checkNumber;
        public String consent;
        public String type;
    }

    private void setBatchItemType() {
        if (recurringSchedule == null || recurringSchedule.isEmpty()) {
            batchItemType = ElevateBatchItemType.ONE_TIME.name();
        } else {
            batchItemType = ElevateBatchItemType.COMMITMENT.name();
        }
    }

    private static Map<String, Object> getProductMetadata() {
        PS_ProductMetadata productMetadata = new PS_ProductMetadata()
            .withOrigin(PS_Request.OriginType.CRM.name());    

        return productMetadata.toUntypedMap();
    }

//    private void setProductMetadataSchemaUri() {
//        this.productMetadataSchemaUri = PS_Request.PRODUCT_METADATA_SCHEMA_URI;
//    }
}