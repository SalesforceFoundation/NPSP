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
public class ElevateBatchItemCreateResponse {
    private List<Errors> errors;
    public ElevateBatchItemType batchItemType;
    public CommitmentResponse commitmentResponse;
    public PurchaseResponse purchaseResponse;

    public class Schedules {
        public Integer amount;
        public String canceledAt;
        public String createdAt;
        public String currencyCode;
        public String firstOccurrenceOnTimestamp;
        public String frequency;
        public Integer frequencyInterval;
        public String id;
        public String merchantId;
        public String modifiedAt;
        public Integer nextPaymentAmount;
        public Date nextPaymentDate;
        public String nextPaymentTimestamp;
        public String previousId;
        public String recentTransactionId;
        public String status;
    }

    public class CommitmentResponse {
        public String accountName;
        public AchData achData;
        public String addressLine1;
        public String addressLine2;
        public Integer amountPaidToDate;
        public String batchId;
        public String canceledAt;
        public CardData cardData;
        public String city;
        public String commitmentType;
        public String country;
        public Datetime createdAt;
        public String currencyCode;
        public String email;
        public String firstName;
        public String gatewayId;
        public String id;
        public String importRefId;
        public String lastName;
        public String merchantId;
        public String merchantName;
        public Metadata metadata;
        public String paymentMethodType;
        public String phone;
        public String postalCode;
        public Metadata productMetadata;
        public String productMetadataSchemaUri;
        public String salutation;
        public List<Schedules> schedules;
        public String state;
        public String status;
        public String statusReason;
        public String statusReasonComment;
        public String suffix;
        public Integer version;
    }


    public class Metadata {
    }

    public class PurchaseResponse {
        public String accountName;
        public AchData achData;
        public String addressLine1;
        public String addressLine2;
        public Integer amount;
        public Integer amountRefunded;
        public Datetime authExpiresAt;
        public Datetime authorizedAt;
        public String batchId;
        public String capturedAt;
        public CardData cardData;
        public String city;
        public String commitmentId;
        public String country;
        public Datetime createdAt;
        public String currencyCode;
        public String declineReason;
        public String email;
        public String firstName;
        public Integer gatewayFee;
        public String gatewayId;
        public String gatewayTransactionId;
        public String id;
        public String lastName;
        public String merchantId;
        public String merchantName;
        public Metadata metadata;
        public String mostRecentReceiptId;
        public String originalTransactionId;
        public String paymentType;
        public String phone;
        public Integer platformFee;
        public String postalCode;
        public String processedAt;
        public Metadata productMetadata;
        public String productMetadataSchemaUri;
        public String receiptTimezone;
        public Integer remainingBalance;
        public String salutation;
        public String state;
        public String status;
        public String submittedAt;
        public String suffix;
        public Integer totalFee;
        public String type;
        public Integer version;
    }

    public class AchData {
        public String accountHolderBankType;
        public String accountHolderType;
        public String achCode;
        public String bankName;
        public String checkNumber;
        public String last4;
    }

    public class CardData {
        public String brand;
        public String expirationMonth;
        public String expirationYear;
        public String fingerprint;
        public String firstName;
        public String last4;
        public String lastName;
    }

    public static ElevateBatchItemCreateResponse parse(String json) {
        return (ElevateBatchItemCreateResponse) System.JSON.deserialize(json, ElevateBatchItemCreateResponse.class);
    }

    public class Errors {
        public String message;
        public String failure_reason;
    }

    public ElevateBatchItemType batchItemType() {
        return batchItemType;
    }

    public Date nextPaymentDate() {
        return commitmentResponse?.schedules[0]?.nextPaymentDate;
    }

    public String frequency() {
        return commitmentResponse?.schedules[0]?.frequency;
    }

    public Datetime createdAt() {
        return commitmentResponse != null ? commitmentResponse.createdAt : purchaseResponse.createdAt;
    }

    public String gatewayId() {
        return commitmentResponse != null ? commitmentResponse.gatewayId : purchaseResponse.gatewayId;
    }

    public String gatewayTransactionId() {
        return purchaseResponse?.gatewayTransactionId;
    }

    public String id() {
        return commitmentResponse != null ? commitmentResponse.id : purchaseResponse.id;
    }

    public Integer frequencyInterval() {
        return commitmentResponse?.schedules[0]?.frequencyInterval;
    }

    public Integer version() {
        return commitmentResponse != null ? commitmentResponse.version : purchaseResponse.version;
    }

    public Datetime authorizedAt() {
        return purchaseResponse?.authorizedAt;
    }

    public Datetime authExpiration() {
        return purchaseResponse?.authExpiresAt;
    }

    public String cardLast4() {
        return commitmentResponse != null ? commitmentResponse.cardData?.last4 : purchaseResponse.cardData?.last4;
    }

    public String achLast4() {
        return commitmentResponse != null ? commitmentResponse.achData?.last4 : purchaseResponse.achData?.last4;
    }

    public String brand() {
        return commitmentResponse != null ? commitmentResponse.cardData?.brand : purchaseResponse.cardData?.brand;
    }

    public String expirationYear() {
        return commitmentResponse != null ? commitmentResponse.cardData?.expirationYear:
            purchaseResponse.cardData?.expirationYear;
    }

    public String expirationMonth() {
        return commitmentResponse != null ? commitmentResponse.cardData?.expirationMonth:
                purchaseResponse.cardData?.expirationMonth;
    }

    public String status() {
        return commitmentResponse != null ? commitmentResponse.status : purchaseResponse.status;
    }

    public String statusReason() {
        return commitmentResponse?.statusReason;
    }

    public String declineReason() {
        return purchaseResponse?.declineReason;
    }

    public String paymentMethod() {
        return commitmentResponse != null ? commitmentResponse.paymentMethodType : purchaseResponse.paymentType;
    }

    public String originalTransactionId() {
        return purchaseResponse?.originalTransactionId;
    }

    public String elevateBatchId() {
        return commitmentResponse != null ? commitmentResponse.batchId : purchaseResponse.batchId;
    }

    public List<Errors> errors() {
        return errors;
    }

}