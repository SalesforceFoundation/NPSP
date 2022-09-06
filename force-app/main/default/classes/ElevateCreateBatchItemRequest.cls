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
    //TODO: If we choose to support ACH we will need to explicitly pass paymentMethodType or the callout will fail

    public ElevateBatchItemType batchItemType;
    public CommitmentInfo commitmentInfo;
    public PurchaseInfo purchaseInfo;

    public ElevateCreateBatchItemRequest(ElevateCreateBatchItemRequestDTO batchItemRequestDTO) {
        if (batchItemRequestDTO.schedule == null || batchItemRequestDTO.schedule.isEmpty()) {
            batchItemType = ElevateBatchItemType.ONE_TIME;
        } else {
            batchItemType = ElevateBatchItemType.COMMITMENT;
        }

        buildRequestBody(batchItemRequestDTO);
    }

    private void buildRequestBody(ElevateCreateBatchItemRequestDTO batchItemRequestDTO) {
        PS_IntegrationServiceConfig.Service configService = new PS_IntegrationServiceConfig.Service();

        if (batchItemType == ElevateBatchItemType.COMMITMENT) {
            buildCommitmentInfoBody(batchItemRequestDTO, configService);
        } else {
            buildPurchaseInfoBody(batchItemRequestDTO, configService);
        }
    }

    private void buildPurchaseInfoBody(ElevateCreateBatchItemRequestDTO batchItemRequestDTO,
                                       PS_IntegrationServiceConfig.Service configService) {
        purchaseInfo = new ElevateCreateBatchItemRequest.PurchaseInfo();
        purchaseInfo.merchantId = configService.getMerchantIds();
        purchaseInfo.gatewayId = configService.getGatewayIds();

        purchaseInfo.currencyCode = UserInfo.getDefaultCurrency();
        purchaseInfo.amount = Integer.valueOf(batchItemRequestDTO.amount);
        purchaseInfo.firstName = batchItemRequestDTO.firstName;
        purchaseInfo.lastName = batchItemRequestDTO.lastName;
        purchaseInfo.paymentMethodToken = batchItemRequestDTO.paymentMethodToken;
    }

    private void buildCommitmentInfoBody(ElevateCreateBatchItemRequestDTO batchItemRequestDTO,
                                         PS_IntegrationServiceConfig.Service configService) {

        commitmentInfo = new ElevateCreateBatchItemRequest.CommitmentInfo();
        commitmentInfo.gatewayId = configService.getGatewayIds();
        commitmentInfo.merchantId = configService.getMerchantIds();

        commitmentInfo.currencyCode = UserInfo.getDefaultCurrency();
        commitmentInfo.firstName = batchItemRequestDTO.firstName;
        commitmentInfo.lastName = batchItemRequestDTO.lastName;
        commitmentInfo.schedules = new List<Schedule>{
            commitmentInfo.buildTypedSchedule(batchItemRequestDTO.schedule, Integer.valueOf(
                batchItemRequestDTO.amount))
        };
        commitmentInfo.paymentMethodToken = batchItemRequestDTO.paymentMethodToken;
        commitmentInfo.productMetadataSchemaUri = PS_Request.PRODUCT_METADATA_SCHEMA_URI;
    }

    public class CommitmentInfo {
        public String currencyCode;
        public String email;
        public String firstName;
        public String lastName;
        public String gatewayId;
        public String merchantId;
        public String paymentMethodToken;
        public Map<String, Object> productMetadata;
        public String productMetadataSchemaUri;
        public List<Schedule> schedules;
        public String type;

        public CommitmentInfo() {
            this.productMetadata = getProductMetadata();
            this.productMetadataSchemaUri = PS_Request.PRODUCT_METADATA_SCHEMA_URI;
            this.type = PS_CommitmentRequest.CommitmentType.SUSTAINER.name();
        }

        public Schedule buildTypedSchedule(Map<String, Object> scheduleUntyped, Integer amount) {
            Map<String, String> elevateFrequencyByInstallmentPeriod = PS_CommitmentRequest.frequencyByInstallmentPeriod;
            Schedule schedule = new Schedule();
            schedule.recurringPaymentAmount = amount;

            for (String field : scheduleUntyped.keySet()) {

                String installmentPeriodFieldName = String.valueOf(
                    npe03__Recurring_Donation__c.npe03__Installment_Period__c);
                String installmentFrequencyFieldName = String.valueOf(
                    npe03__Recurring_Donation__c.InstallmentFrequency__c
                );
                String startDateFieldName = String.valueOf(
                        npe03__Recurring_Donation__c.StartDate__c);

                schedule.frequency =
                    elevateFrequencyByInstallmentPeriod?.get(
                        String.valueOf(scheduleUntyped?.get(installmentPeriodFieldName))
                    );

                Integer installmentFrequency = Integer.valueOf(scheduleUntyped?.get(installmentFrequencyFieldName));
                schedule.frequencyInterval = installmentFrequency > 0 ? installmentFrequency : 1;

                Date startDate = Date.valueOf(
                    String.valueOf(scheduleUntyped?.get(startDateFieldName))
                );

                Datetime startDateTime = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day());
                schedule.firstOccurrenceOnTimestamp = startDateTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
            }
            return schedule;
        }

    }
    public class Schedule {
        public Integer recurringPaymentAmount;
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
        public String email;
        public String paymentMethodToken;
        public Map<String, Object> productMetadata;
        public String productMetadataSchemaUri;

        public PurchaseInfo() {
            this.productMetadata = getProductMetadata();
            this.productMetadataSchemaUri = PS_Request.PRODUCT_METADATA_SCHEMA_URI;
        }
    }

    public class AchData {
        public String achCode;
        public String bankType;
        public String checkNumber;
        public String consent;
        public String type;
    }

    private static Map<String, Object> getProductMetadata() {
        PS_ProductMetadata productMetadata = new PS_ProductMetadata()
            .withOrigin(PS_Request.OriginType.CRM.name());    

        return productMetadata.toUntypedMap();
    }
}