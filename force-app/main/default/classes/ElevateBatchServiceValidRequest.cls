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
@IsTest
public class ElevateBatchServiceValidRequest extends ElevateBatchService {
    ElevateBatchItemType batchItemType;
    String paymentMethod;

    private String oneTimeResponse {
        get {
            if (paymentMethod == 'CARD') {
                return oneTimeCardSuccessResponse();
            } else {
                return oneTimeACHSuccessResponse();
            }
        }
        set;
    }
    private String commitmentResponse {
        get {
            if (paymentMethod == 'CARD') {
                return commitmentCardSuccessResponse();
            } else {
                return commitmentACHSuccessResponse();
            }
        }
        set;
    }

    public ElevateBatchServiceValidRequest(){}
    public ElevateBatchServiceValidRequest(ElevateBatchItemType batchItemType, String paymentMethod){
        this.batchItemType = batchItemType;
        this.paymentMethod = paymentMethod;
    }

    public override ElevateBatchItem addToElevateBatch(ElevateCreateBatchItemRequestDTO createBatchItemRequestDTO,
                                                       String elevateBatchId) {
        ElevateBatchItemCreateResponse giftResponse;

        if (batchItemType == ElevateBatchItemType.ONE_TIME) {
            giftResponse = ElevateBatchItemCreateResponse.parse(oneTimeResponse);
        } else {
            giftResponse = ElevateBatchItemCreateResponse.parse(commitmentResponse);
        }

        return new ElevateBatchItem(giftResponse);
    }

    public override ElevateBatch createElevateBatch() {
        ElevateBatchResponse elevateBatchResponse = ElevateBatchResponse.parse(createBatchSuccessResponse());
        return new ElevateBatch(elevateBatchResponse);
    }

    public override UTIL_Http.Response sendRemoveRequest(String elevatePaymentId, String elevateBatchId) {
        return (UTIL_Http.Response) JSON.deserialize(removeBatchItemSuccessResponse(), UTIL_Http.Response.class);
    }

    private static String removeBatchItemSuccessResponse() {
        return '{\n' +
                '"statusCode": "204",\n' +
                '"status": "Remove successful"\n' +
                '}';
    }

    private static String oneTimeCardSuccessResponse() {
        return '{\n' +
                '  "batchItemType": "ONE_TIME",\n' +
                '  "purchaseResponse": {\n' +
                '    "accountName": "test account",\n' +
                '    "cardData": {\n' +
                '      "brand": "Visa",\n' +
                '      "expirationMonth": "11",\n' +
                '      "expirationYear": "2025",\n' +
                '      "fingerprint": "123456",\n' +
                '      "firstName": "test",\n' +
                '      "lastName": "user",\n' +
                '      "last4": "0123"\n' +
                '    },\n' +
                '    "addressLine1": "string",\n' +
                '    "addressLine2": "string",\n' +
                '    "amount": 0,\n' +
                '    "authExpiresAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "authorizedAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "batchId": "test-valid-id",\n' +
                '    "city": "string",\n' +
                '    "country": "US",\n' +
                '    "createdAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "currencyCode": "ADP",\n' +
                '    "email": "string",\n' +
                '    "firstName": "string",\n' +
                '    "gatewayFee": 0,\n' +
                '    "gatewayId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "gatewayTransactionId": "string",\n' +
                '    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "lastName": "string",\n' +
                '    "merchantId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "merchantName": "string",\n' +
                '    "metadata": {},\n' +
                '    "mostRecentReceiptId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "originalTransactionId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "paymentType": "CARD",\n' +
                '    "phone": "string",\n' +
                '    "platformFee": 0,\n' +
                '    "postalCode": "string",\n' +
                '    "processedAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "productMetadata": {},\n' +
                '    "productMetadataSchemaUri": "string",\n' +
                '    "receiptTimezone": "string",\n' +
                '    "remainingBalance": 0,\n' +
                '    "salutation": "string",\n' +
                '    "state": "string",\n' +
                '    "status": "PENDING",\n' +
                '    "submittedAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "suffix": "string",\n' +
                '    "totalFee": 0,\n' +
                '    "type": "PAYMENT",\n' +
                '    "version": 0\n' +
                '  }\n' +
                '}';
    }

    private static String oneTimeACHSuccessResponse() {
        return '{\n' +
                '  "batchItemType": "ONE_TIME",\n' +
                '  "purchaseResponse": {\n' +
                '    "accountName": "string",\n' +
                '    "achData": {\n' +
                '      "accountHolderBankType": "CHECKING",\n' +
                '      "accountHolderType": "INDIVIDUAL",\n' +
                '      "achCode": "ARC",\n' +
                '      "bankName": "string",\n' +
                '      "checkNumber": "string",\n' +
                '      "consentMessage": "string",\n' +
                '      "last4": "string"\n' +
                '    },\n' +
                '    "addressLine1": "string",\n' +
                '    "addressLine2": "string",\n' +
                '    "amount": 0,\n' +
                '    "batchId": "test-valid-id",\n' +
                '    "city": "string",\n' +
                '    "country": "US",\n' +
                '    "createdAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "currencyCode": "ADP",\n' +
                '    "email": "string",\n' +
                '    "firstName": "string",\n' +
                '    "gatewayFee": 0,\n' +
                '    "gatewayId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "gatewayTransactionId": "string",\n' +
                '    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "lastName": "string",\n' +
                '    "merchantId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "merchantName": "string",\n' +
                '    "metadata": {},\n' +
                '    "mostRecentReceiptId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "originalTransactionId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "paymentType": "CARD",\n' +
                '    "phone": "string",\n' +
                '    "platformFee": 0,\n' +
                '    "postalCode": "string",\n' +
                '    "processedAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "productMetadata": {},\n' +
                '    "productMetadataSchemaUri": "string",\n' +
                '    "receiptTimezone": "string",\n' +
                '    "remainingBalance": 0,\n' +
                '    "salutation": "string",\n' +
                '    "state": "string",\n' +
                '    "status": "PENDING",\n' +
                '    "submittedAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "suffix": "string",\n' +
                '    "totalFee": 0,\n' +
                '    "type": "PAYMENT",\n' +
                '    "version": 0\n' +
                '  }\n' +
                '}';
    }

    private static String commitmentCardSuccessResponse() {
        return '{\n' +
                '  "batchItemType": "COMMITMENT",\n' +
                '  "commitmentResponse": {\n' +
                '    "accountName": "test account",\n' +
                '    "cardData": {\n' +
                '      "brand": "Visa",\n' +
                '      "expirationMonth": "11",\n' +
                '      "expirationYear": "2025",\n' +
                '      "fingerprint": "123456",\n' +
                '      "firstName": "test",\n' +
                '      "lastName": "user",\n' +
                '      "last4": "0123"\n' +
                '    },\n' +
                '    "addressLine1": "string",\n' +
                '    "addressLine2": "string",\n' +
                '    "amount": 0,\n' +
                '    "batchId": "test-valid-id",\n' +
                '    "city": "string",\n' +
                '    "commitmentType": "SUSTAINER",\n' +
                '    "country": "US",\n' +
                '    "createdAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "currencyCode": "ADP",\n' +
                '    "email": "string",\n' +
                '    "firstName": "string",\n' +
                '    "gatewayFee": 0,\n' +
                '    "gatewayId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "gatewayTransactionId": "string",\n' +
                '    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "lastName": "string",\n' +
                '    "merchantId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "merchantName": "string",\n' +
                '    "metadata": {},\n' +
                '    "mostRecentReceiptId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "originalTransactionId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "paymentType": "CARD",\n' +
                '    "phone": "string",\n' +
                '    "platformFee": 0,\n' +
                '    "postalCode": "string",\n' +
                '    "processedAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "productMetadata": {},\n' +
                '    "productMetadataSchemaUri": "string",\n' +
                '    "receiptTimezone": "string",\n' +
                '    "remainingBalance": 0,\n' +
                '    "salutation": "string",\n' +
                '    "schedules": [\n' +
                '      {\n' +
                '        "amount": 0,\n' +
                '        "canceledAt": "2022-08-20T05:40:24.576Z",\n' +
                '        "createdAt": "2022-08-20T05:40:24.576Z",\n' +
                '        "currencyCode": "ADP",\n' +
                '        "firstOccurrenceOnTimestamp": "2022-08-20T05:40:24.576Z",\n' +
                '        "frequency": "DAY",\n' +
                '        "frequencyInterval": 0,\n' +
                '        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '        "merchantId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '        "modifiedAt": "2022-08-20T05:40:24.576Z",\n' +
                '        "nextPaymentAmount": 0,\n' +
                '        "nextPaymentDate": "2022-08-20",\n' +
                '        "nextPaymentTimestamp": "2022-08-20T05:40:24.576Z",\n' +
                '        "previousId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '        "recentTransactionId": "string",\n' +
                '        "status": "ACTIVE"\n' +
                '      }],\n' +
                '    "state": "string",\n' +
                '    "status": "PENDING",\n' +
                '    "submittedAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "suffix": "string",\n' +
                '    "totalFee": 0,\n' +
                '    "type": "PAYMENT",\n' +
                '    "version": 0\n' +
                '  }\n' +
                '}';
    }

    private static String commitmentACHSuccessResponse() {
        return '{\n' +
                '  "batchItemType": "COMMITMENT",\n' +
                '  "commitmentResponse": {\n' +
                '    "accountName": "string",\n' +
                '    "achData": {\n' +
                '      "accountHolderBankType": "CHECKING",\n' +
                '      "accountHolderType": "INDIVIDUAL",\n' +
                '      "achCode": "ARC",\n' +
                '      "bankName": "string",\n' +
                '      "checkNumber": "string",\n' +
                '      "consentMessage": "string",\n' +
                '      "last4": "string"\n' +
                '    },\n' +
                '    "addressLine1": "string",\n' +
                '    "addressLine2": "string",\n' +
                '    "amount": 0,\n' +
                '    "batchId": "test-valid-id",\n' +
                '    "city": "string",\n' +
                '    "country": "US",\n' +
                '    "createdAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "currencyCode": "ADP",\n' +
                '    "email": "string",\n' +
                '    "firstName": "string",\n' +
                '    "gatewayFee": 0,\n' +
                '    "gatewayId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "gatewayTransactionId": "string",\n' +
                '    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "lastName": "string",\n' +
                '    "merchantId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "merchantName": "string",\n' +
                '    "metadata": {},\n' +
                '    "mostRecentReceiptId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "originalTransactionId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '    "paymentType": "CARD",\n' +
                '    "phone": "string",\n' +
                '    "platformFee": 0,\n' +
                '    "postalCode": "string",\n' +
                '    "processedAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "productMetadata": {},\n' +
                '    "productMetadataSchemaUri": "string",\n' +
                '    "receiptTimezone": "string",\n' +
                '    "remainingBalance": 0,\n' +
                '    "salutation": "string",\n' +
                '    "schedules": [\n' +
                '      {\n' +
                '        "amount": 0,\n' +
                '        "canceledAt": "2022-08-20T05:40:24.576Z",\n' +
                '        "createdAt": "2022-08-20T05:40:24.576Z",\n' +
                '        "currencyCode": "ADP",\n' +
                '        "firstOccurrenceOnTimestamp": "2022-08-20T05:40:24.576Z",\n' +
                '        "frequency": "DAY",\n' +
                '        "frequencyInterval": 0,\n' +
                '        "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '        "merchantId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '        "modifiedAt": "2022-08-20T05:40:24.576Z",\n' +
                '        "nextPaymentAmount": 0,\n' +
                '        "nextPaymentDate": "2022-08-20",\n' +
                '        "nextPaymentTimestamp": "2022-08-20T05:40:24.576Z",\n' +
                '        "previousId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",\n' +
                '        "recentTransactionId": "string",\n' +
                '        "status": "ACTIVE"\n' +
                '     }],\n' +
                '    "state": "string",\n' +
                '    "status": "PENDING",\n' +
                '    "statusReason": "COMMITMENT_CREATED",\n' +
                '    "submittedAt": "2022-08-20T05:40:24.576Z",\n' +
                '    "suffix": "string",\n' +
                '    "totalFee": 0,\n' +
                '    "type": "PAYMENT",\n' +
                '    "version": 0\n' +
                '  }\n' +
                '}';
    }

    private static String createBatchSuccessResponse() {
        return '{\n' +
                '  "id": "test-id",\n' +
                '  "status": "Open"\n' +
                '}';
    }
}