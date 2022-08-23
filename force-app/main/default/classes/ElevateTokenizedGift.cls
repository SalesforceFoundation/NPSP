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
public with sharing class ElevateTokenizedGift {
    @AuraEnabled public Integer amount {get; set;}
    @AuraEnabled public String firstName {get; set;}
    @AuraEnabled public String lastName {get; set;}
    @AuraEnabled public String paymentMethodToken {get; set;}
    @AuraEnabled public String currencyCode {get; set;}
    @AuraEnabled public Map<String, Object> recurringSchedule {get; set;}

    public String batchItemType;
    public CommitmentInfo commitmentInfo;
    public PurchaseInfo purchaseInfo;

    public PS_IntegrationServiceConfig.Service configService;
    /***
     * Optional properties
     */
    public Map<String, Object> productMetadata;

    public ElevateTokenizedGift() {
        setBatchItemType();
        this.currencyCode = UserInfo.getDefaultCurrency();
        setProductMetadata();
        setProductMetadataSchemaUri();
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
        public Metadata productMetadata;
        public List<Schedules> schedules;
        public String type;
    }
    public class Schedules {
        public Integer amount;
        public String firstOccurrenceOnTimestamp;
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
        public Metadata productMetadata;
    }

    public class AchData {
        public String achCode;
        public String bankType;
        public String checkNumber;
        public String consent;
        public String type;
    }

    public class Metadata {}

    private void setBatchItemType() {
        if (recurringSchedule == null || recurringSchedule.isEmpty()) {
            batchItemType = ElevateBatchItemType.ONE_TIME.name();
        } else {
            batchItemType = ElevateBatchItemType.COMMITMENT.name();
        }
    }

    private void setProductMetadata() {
        PS_ProductMetadata productMetadata = new PS_ProductMetadata()
            .withOrigin(PS_Request.OriginType.CRM.name());    

        this.productMetadata = productMetadata.toUntypedMap();
    }

    private void setProductMetadataSchemaUri() {
        this.productMetadataSchemaUri = PS_Request.PRODUCT_METADATA_SCHEMA_URI;
    }
}