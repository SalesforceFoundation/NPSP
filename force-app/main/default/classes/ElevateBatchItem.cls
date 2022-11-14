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
public with sharing class ElevateBatchItem {
    @AuraEnabled public String id {get; set;}
    @AuraEnabled public DateTime authExpiration {get; set;}
    @AuraEnabled public String status {get; set;}
    @AuraEnabled public String statusReason {get; set;}
    @AuraEnabled public String paymentMethod {get; set;}
    @AuraEnabled public String originalTransactionId {get; set;}
    @AuraEnabled public String elevateBatchId {get; set;}
    @AuraEnabled public String declineReason {get; set;}
    @AuraEnabled public String cardLast4 {get; set;}
    @AuraEnabled public String achLast4 {get; set;}
    @AuraEnabled public String cardNetwork {get; set;}
    @AuraEnabled public String cardExpirationMonth {get; set;}
    @AuraEnabled public String cardExpirationYear {get; set;}
    @AuraEnabled public Datetime authorizedAt {get; set;}
    @AuraEnabled public String gatewayTransactionId {get; set;}
    @AuraEnabled public String gatewayId {get; set;}
    @AuraEnabled public Datetime createdAt {get; set;}
    @AuraEnabled public String dayOfMonth {get; set;}
    @AuraEnabled public String installmentPeriod {get; set;}
    @AuraEnabled public String batchItemType {get; set;}
    @AuraEnabled public Integer version {get; set;}

    public ElevateBatchItem(ElevateBatchItemCreateResponse createBatchItemResponse) {
        this.batchItemType = createBatchItemResponse.batchItemType().name();
        this.id = createBatchItemResponse.id();
        this.authorizedAt = createBatchItemResponse.authorizedAt();
        this.authExpiration = createBatchItemResponse.authExpiration();
        this.gatewayTransactionId = createBatchItemResponse.gatewayTransactionId();
        this.paymentMethod = createBatchItemResponse.paymentMethod();
        this.elevateBatchId  = createBatchItemResponse.elevateBatchId();
        this.originalTransactionId = createBatchItemResponse.originalTransactionId();
        this.declineReason = createBatchItemResponse.declineReason();
        this.cardLast4 = createBatchItemResponse.cardLast4();
        this.achLast4 = createBatchItemResponse.achLast4();
        this.status = createBatchItemResponse.status();
        this.statusReason = createBatchItemResponse.statusReason();
        this.cardNetwork = createBatchItemResponse.brand();
        this.cardExpirationMonth = createBatchItemResponse.expirationMonth();
        this.cardExpirationYear = createBatchItemResponse.expirationYear();
        this.gatewayId = createBatchItemResponse.gatewayId();
        this.createdAt = createBatchItemResponse.createdAt();
        this.version = createBatchItemResponse.version();
    }

    public ElevateBatchItem() {}

    public String elevateBatchId() {
        return elevateBatchId;
    }

    public String gatewayId() {
        return gatewayId;
    }

    public String gatewayTransactionId() {
        return gatewayTransactionId;
    }

    public DateTime authorizedAt() {
        return authorizedAt;
    }

    public String cardLast4() {
        return cardLast4;
    }

    public String cardNetwork() {
        return cardNetwork;
    }

    public String cardExpirationMonth() {
        return cardExpirationMonth;
    }

    public String cardExpirationYear() {
        return cardExpirationYear;
    }

    public String id() {
        return id;
    }

    public DateTime authExpiration() {
        return authExpiration;
    }

    public String status() {
        return status;
    }

    public String paymentMethod() {
        return paymentMethod;
    }

    public String originalTransactionId() {
        return originalTransactionId;
    }

    public String declineReason() {
        return declineReason;
    }
}