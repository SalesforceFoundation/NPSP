/*
    Copyright (c) 2020 Salesforce.org
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
* @date 2020
* @group Gift Entry
* @group-content ../../ApexDocContent/GiftEntry.htm
* @description Unit tests to cover methods in GE_GiftEntryController.
*/
@IsTest
public with sharing class GE_GiftEntryController_TEST {
    private static final String TEST_PAYMENT_METHOD_CARD = 'CARD';
    private static final String TEST_PAYMENT_METHOD_ACH = 'ACH';

    @IsTest
    static void shouldReturn2OpenDonationsForTheGivenDonor() {
        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
            new npe01__Contacts_And_Orgs_Settings__c(npe01__Payments_Enabled__c = false));

        Account dummyOrg = UTIL_UnitTestData_TEST.buildOrganizationAccount();
        insert dummyOrg;

        List<Opportunity> opps = new List<Opportunity> {
            new Opportunity(Name='Dummy Opp 0', StageName=UTIL_UnitTestData_TEST.getOpenStage(), Amount=1, CloseDate=Date.today(), AccountId=dummyOrg.Id),
            new Opportunity(Name='Dummy Opp 1', StageName=UTIL_UnitTestData_TEST.getOpenStage(), Amount=2, CloseDate=Date.today(), AccountId=dummyOrg.Id)
        };
        insert opps;

        List<npe01__OppPayment__c> payments = new List<npe01__OppPayment__c> {
            new npe01__OppPayment__c(
                npe01__Paid__c=false,
                npe01__Written_Off__c=false,
                npe01__Opportunity__c=opps[0].Id
            ),
            new npe01__OppPayment__c(
                npe01__Paid__c=false,
                npe01__Written_Off__c=false,
                npe01__Opportunity__c=opps[0].Id
            ),
            new npe01__OppPayment__c(
                npe01__Paid__c=false,
                npe01__Written_Off__c=false,
                npe01__Opportunity__c=opps[0].Id
            )
        };
        insert payments;

        String openDonationsForDummyOrgString = GE_GiftEntryController.getOpenDonations(dummyOrg.Id, 'Account');
        List<GE_GiftEntryController.OpportunityWrapper> openDonationsForDummyOrg =
           (List<GE_GiftEntryController.OpportunityWrapper>)
           JSON.deserialize(openDonationsForDummyOrgString, List<GE_GiftEntryController.OpportunityWrapper>.class);

        System.assertEquals(2, openDonationsForDummyOrg.size());
        System.assertEquals('Dummy Opp 0', openDonationsForDummyOrg[0].opportunity.Name);
        System.assertEquals(3, openDonationsForDummyOrg[0].opportunity.npe01__OppPayment__r.size());

        DonationService donationService = new DonationService();
        DonationsView donationsView = donationService.getDonationsView(dummyOrg.Id);

        System.assertEquals(2, donationsView.donations.size());
        System.assertEquals('Dummy Opp 0', donationsView.donations[0].opportunity.get('Name'));
        System.assertEquals(3, donationsView.donations[0].unpaidPayments.size());
    }

    @IsTest
    static void shouldReturnAGiftView() {
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();
        Form_Template__c defaultTemplate = new Form_Template__c( Format_Version__c = '1.0' );

        GE_Template.Template template = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON = JSON.serialize(template);
        defaultTemplate.Template_JSON__c = templateJSON;
        insert defaultTemplate;

        giftEntryCustomSetting.Default_Gift_Entry_Template__c = defaultTemplate.Id;
        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);

        String additionalObjectStringWithSoftCredits =
            new UTIL_AdditionalObjectData_TEST()
            .withOpportunityContactRoles(2)
            .build();
        Date donationDate = Date.today();
        DataImport__c dataImport = new DataImport__c(
            Donation_Amount__c = 10,
            Account1_Name__c = 'Dummy First Name',
            Donation_Date__c = donationDate,
            Additional_Object_JSON__c = additionalObjectStringWithSoftCredits
        );
        insert dataImport;

        Test.startTest();
        GiftService service = new GiftService();
        GiftView viewModel = service.viewModelFrom(new GiftId(dataImport.id));

        String account1NameField = String.valueOf(DataImport__c.Account1_Name__c);
        System.assertEquals('Dummy First Name', viewModel.fields.get(account1NameField));
        System.assertEquals(2, viewModel.softCredits.all.size());
        Test.stopTest();
    }

    @IsTest
    static void createElevateBatchShouldReturnSuccessResponse() {
        GE_GiftEntryController.elevateBatchService = new ElevateBatchServiceValidRequest();
        AuraHandledException auraException;
        ElevateBatch elevateBatch;

        Test.startTest();
            try {
                elevateBatch = GE_GiftEntryController.createElevateBatch();
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        Test.stopTest();

        System.assertEquals(null, auraException, 'The aura exception object should be null since no error should have' +
                ' occurred with a valid request.');
        System.assertEquals(null, auraException, 'The aura exception object should be null since no error should have' +
                ' occurred with a valid request.');
        System.assertEquals('test-id', elevateBatch.elevateBatchId(), 'The elevate batch id should be ' +
                'populated on a successful response.');
    }

    @IsTest
    static void createElevateBatchShouldReturnFailureResponse() {
        GE_GiftEntryController.elevateBatchService = new ElevateBatchServiceInvalidRequest();
        String errorMessage = ElevateBatchResponse.parse(new ElevateBatchServiceInvalidRequest()
                .createElevateBatchErrorResponse())
                .errors()[0].message;
        AuraHandledException auraException;

        Test.startTest();
        try {
            GE_GiftEntryController.createElevateBatch();
        } catch (AuraHandledException ex) {
            auraException = ex;
        }
        Test.stopTest();

        System.assertEquals(errorMessage,
                auraException.getMessage(), 'The error message in the elevate batch response ' +
                        'should throw an exception and the message should be the create elevate batch error ' +
                        'message specified in the invalid request data type.');
    }

    @isTest
    static void batchItemRequestIsCorrectlyBuiltFromDTOValues() {
        ElevateCreateBatchItemRequestDTO dto = new ElevateCreateBatchItemRequestDTO();
        dto.amount = '2000';
        dto.firstName = 'test';
        dto.lastName = 'donor';
        dto.currencyCode = 'USD';
        dto.paymentMethodToken = '12345';
        dto.schedule = new Map<String,Object> {
            String.valueOf(npe03__Recurring_Donation__c.npe03__Installment_Period__c) => 'Monthly',
            String.valueOf(npe03__Recurring_Donation__c.InstallmentFrequency__c) => '1',
            String.valueOf(npe03__Recurring_Donation__c.StartDate__c) => String.valueOf(Date.today())
        };
        Test.startTest();
            ElevateCreateBatchItemRequest request = new ElevateBatchService().buildBatchItemRequestFrom(dto);
        Test.stopTest();

        System.assertEquals(ElevateBatchItemType.COMMITMENT, request.batchItemType, 'The request batch item type ' +
                'should be COMMITMENT');
        System.assertEquals(null, request.purchaseInfo, 'The request purchase info object should be null.');
        System.assert(request.commitmentInfo != null, 'The request commitment info object should not be null.');
        System.assertEquals('USD', request.commitmentInfo.currencyCode, 'The request currency code should match the ' +
                'DTO.');
        System.assertEquals('test', request.commitmentInfo.firstName, 'The request first name should match the ' +
                'DTO.');
        System.assertEquals('donor', request.commitmentInfo.lastName, 'The request last name should match the ' +
                'DTO.');
        System.assertEquals('SUSTAINER', request.commitmentInfo.type, 'The request type equal SUSTAINER.');

        PS_ProductMetadata.Origin metadataOrigin = (PS_ProductMetadata.Origin)
                request.commitmentInfo.productMetadata.get('origin');
        System.assertEquals('CRM', metadataOrigin.type, 'The request should have an Origin value of CRM' +
                'set in product metadata.');

        System.assertEquals(PS_Request.PRODUCT_METADATA_SCHEMA_URI, request.commitmentInfo.productMetadataSchemaUri,
                'The request should have the correct product metadata schema Uri set.');
        System.assertEquals(PS_CommitmentRequest.frequencyByInstallmentPeriod.get('Monthly'),
                request.commitmentInfo.schedules[0].frequency, 'The Elevate converted request frequency should match ' +
                        'the DTO schedule installment period.');
        System.assertEquals(1, request.commitmentInfo.schedules[0].frequencyInterval, 'The request frequency interval' +
                ' should match the DTO schedule installment frequency');
        System.assertEquals(2000, request.commitmentInfo.schedules[0].recurringPaymentAmount, 'The request ' +
                'recurring amount (in cents) should match the converted DTO amount (in cents).');

        Datetime startDateTime = Datetime.newInstance(Date.today().year(), Date.today().month(), Date.today().day());
        System.assertEquals(startDateTime.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),
                request.commitmentInfo.schedules[0].firstOccurrenceOnTimestamp, 'The request first occurrence ' +
                'timestamp should should match the DTO and be converted to ISO 8601 format.');
    }

    @isTest
    static void batchItemRequestIncludesDefaultGateway() {

        ElevateCreateBatchItemRequestDTO dto = new ElevateCreateBatchItemRequestDTO();
        dto.amount = '2000';
        dto.firstName = 'test';
        dto.lastName = 'donor';
        dto.currencyCode = 'USD';
        dto.paymentMethodToken = '12345';

        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        Test.startTest();
        ElevateCreateBatchItemRequest request = new ElevateBatchService().buildBatchItemRequestFrom(dto);
        Test.stopTest();

        System.assertEquals(ElevateBatchItemType.ONE_TIME, request.batchItemType, 'The request batch item type ' +
                'should be ONE_TIME');
        System.assertNotEquals(null, request.purchaseInfo, 'The request purchase info object should not be null.');
        System.assert(request.commitmentInfo == null, 'The request commitment info object should be null.');

        System.assertEquals(PS_IntegrationServiceConfig_TEST.testGatewayId, request.purchaseInfo.gatewayId,
                'The gateway Id should be populated with the default gateway when we do not override');
    }

    @isTest
    static void batchItemRequestIncludesOverrideGateway() {
        final String gatewayOverride = 'Override Gateway';
        ElevateCreateBatchItemRequestDTO dto = new ElevateCreateBatchItemRequestDTO();
        dto.amount = '2000';
        dto.firstName = 'test';
        dto.lastName = 'donor';
        dto.currencyCode = 'USD';
        dto.paymentMethodToken = '12345';
        dto.gatewayOverride = gatewayOverride;

        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        Test.startTest();
        ElevateCreateBatchItemRequest request = new ElevateBatchService().buildBatchItemRequestFrom(dto);
        Test.stopTest();

        System.assertEquals(ElevateBatchItemType.ONE_TIME, request.batchItemType, 'The request batch item type ' +
                'should be ONE_TIME');
        System.assertNotEquals(null, request.purchaseInfo, 'The request purchase info object should not be null.');
        System.assert(request.commitmentInfo == null, 'The request commitment info object should be null.');

        System.assertEquals(gatewayOverride, request.purchaseInfo.gatewayId,
                'The gateway Id should be populated with the Override Gateway');
    }

    @isTest
    static void addCardCommitmentToElevateBatchShouldReturnSuccessResponse() {
        GE_GiftEntryController.elevateBatchService = new ElevateBatchServiceValidRequest(
            ElevateBatchItemType.COMMITMENT, TEST_PAYMENT_METHOD_CARD);

        AuraHandledException auraException;
        ElevateBatchItem elevateBatchItem;

        Test.startTest();
            try {
                elevateBatchItem = GE_GiftEntryController.addToElevateBatch(new ElevateCreateBatchItemRequestDTO(),
                        'test-valid-id');
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        Test.stopTest();

        System.assertEquals(null, auraException, 'The aura exception object should be null since no error should have' +
                ' occurred with a valid request.');
        System.assertEquals(null, auraException, 'The aura exception object should be null since no error should have' +
                ' occurred with a valid request.');
        System.assertEquals('test-valid-id', elevateBatchItem.elevateBatchId(),
                'The elevate batch id should be populated on a successful response.');
    }

    @IsTest
    static void addACHCommitmentToElevateBatchShouldReturnSuccessResponse() {
        GE_GiftEntryController.elevateBatchService = new ElevateBatchServiceValidRequest(
                ElevateBatchItemType.COMMITMENT, TEST_PAYMENT_METHOD_ACH);

        AuraHandledException auraException;
        ElevateBatchItem elevateBatchItem;

        Test.startTest();
        try {
            elevateBatchItem = GE_GiftEntryController.addToElevateBatch(new ElevateCreateBatchItemRequestDTO(),
                    'test-valid-id');
        } catch (AuraHandledException ex) {
            auraException = ex;
        }
        Test.stopTest();

        System.assertEquals(null, auraException, 'The aura exception object should be null since no error should have' +
                ' occurred with a valid request.');
        System.assertEquals(null, auraException, 'The aura exception object should be null since no error should have' +
                ' occurred with a valid request.');
        System.assertEquals('test-valid-id', elevateBatchItem.elevateBatchId(),
                'The elevate batch id should be populated on a successful response.');
    }

    @IsTest
    static void addOneTimeCardToElevateBatchShouldReturnSuccessResponse() {
        GE_GiftEntryController.elevateBatchService = new ElevateBatchServiceValidRequest(
ElevateBatchItemType.ONE_TIME, TEST_PAYMENT_METHOD_CARD);

        AuraHandledException auraException;
        ElevateBatchItem elevateBatchItem;

        Test.startTest();
            try {
                elevateBatchItem = GE_GiftEntryController.addToElevateBatch(new ElevateCreateBatchItemRequestDTO(),
                    'test-valid-id');
            } catch (AuraHandledException ex) {
                auraException = ex;
            }
        Test.stopTest();

        System.assertEquals(null, auraException, 'The aura exception object should be null since no error should have' +
                ' occurred with a valid request.');
        System.assertEquals(null, auraException, 'The aura exception object should be null since no error should have' +
                ' occurred with a valid request.');
        System.assertEquals('test-valid-id', elevateBatchItem.elevateBatchId(),
                'The elevate batch id should be populated on a successful response.');
    }

    @IsTest
    static void addOneTimeACHToElevateBatchShouldReturnSuccessResponse() {
        GE_GiftEntryController.elevateBatchService = new ElevateBatchServiceValidRequest(
                ElevateBatchItemType.ONE_TIME, TEST_PAYMENT_METHOD_ACH);

        AuraHandledException auraException;
        ElevateBatchItem elevateBatchItem;

        Test.startTest();
        try {
            elevateBatchItem = GE_GiftEntryController.addToElevateBatch(new ElevateCreateBatchItemRequestDTO(),
                    'test-valid-id');
        } catch (AuraHandledException ex) {
            auraException = ex;
        }
        Test.stopTest();

        System.assertEquals(null, auraException, 'The aura exception object should be null since no error should have' +
                ' occurred with a valid request.');
        System.assertEquals(null, auraException, 'The aura exception object should be null since no error should have' +
                ' occurred with a valid request.');
        System.assertEquals('test-valid-id', elevateBatchItem.elevateBatchId(),
                'The elevate batch id should be populated on a successful response.');
    }

    /***
     * @description Verifies the purchase request response contains status code created
     * when one-time payment has been created in Elevate
     */
    @IsTest
    static void shouldReturnRecordCreatedResponseWhenPurchaseRequestSucceeds() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        String requestBodyParameters = GE_PaymentServices_TEST.GOOD_PURCHASE_CALL_BODY;
        String dataImportRecordId = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);

        Test.startTest();
        UTIL_Http_TEST.mockRecordCreatedCalloutResponse(GE_PaymentServices_TEST.SUCCESS_RESPONSE_BODY);

        UTIL_Http.Response response = GE_GiftEntryController.processPurchaseRequest(requestBodyParameters, dataImportRecordId);
        Test.stopTest();

        System.assertEquals(UTIL_Http.STATUS_CODE_CREATED, response.statusCode, 'Response status should match: ' + response);
    }

    @IsTest
    static void removeBatchItemFromElevateBatchReturnsSuccessResponse() {
        AuraHandledException auraException;
        ElevateBatchItem batchItem;

        Test.startTest();
        try {
            ElevateBatchItem testBatchItem = new ElevateBatchItem();
            testBatchItem.id = 'test-batch-item-id';

            ElevateBatch elevateBatch = new ElevateBatch('test-batch-id');
            elevateBatch.elevateBatchService = new ElevateBatchServiceValidRequest();
            batchItem = elevateBatch.elevateBatchService.removeFromElevateBatch(elevateBatch, testBatchItem);
        } catch (AuraHandledException ex) {
            auraException = ex;
        }
        Test.stopTest();

        System.assert(auraException == null, 'The aura handled exception should be null since an valid request ' +
                'has been sent.');
        System.assertEquals(batchItem.elevateBatchId, 'test-batch-id', 'the correct batch id is not set for the ' +
                'removed batch item.');
        System.assertEquals(batchItem.id, 'test-batch-item-id', 'the correct batch item id is not set for the ' +
                'removed batch item.');
    }

    @IsTest
    static void removeBatchItemFromElevateBatchReturnsErrorResponse() {
        AuraHandledException auraException;
        ElevateBatchItem batchItem;

        Test.startTest();
        try {
            ElevateBatch elevateBatch = new ElevateBatch('test-batch-id');
            elevateBatch.elevateBatchService = new ElevateBatchServiceInvalidRequest();
           batchItem = elevateBatch.elevateBatchService.removeFromElevateBatch(elevateBatch, new ElevateBatchItem());
        } catch (AuraHandledException ex) {
            auraException = ex;
        }
        Test.stopTest();

        System.assert(auraException != null, 'The aura handled exception should not be null since an invalid request ' +
                'has been sent.');
        System.assert(batchItem == null, 'The failed batch item should be null.');
        System.assertEquals('Bad Request',
                auraException.getMessage(), 'The error message in the elevate batch response ' +
                        'should throw an exception and the message should be the create elevate batch error ' +
                        'message specified in the invalid request data type.');
    }

    @IsTest
    static void addBatchItemToElevateBatchShouldReturnFailureResponse() {
        GE_GiftEntryController.elevateBatchService = new ElevateBatchServiceInvalidRequest();
        String errorMessage = ElevateBatchItemCreateResponse.parse(new ElevateBatchServiceInvalidRequest()
                .elevateBatchErrorResponse())
                .errors()[0].message;
        AuraHandledException auraException;

        Test.startTest();
        try {
            GE_GiftEntryController.addToElevateBatch(new ElevateCreateBatchItemRequestDTO(), 'test-valid-group-id');
        } catch (AuraHandledException ex) {
            auraException = ex;
        }
        Test.stopTest();

        System.assert(auraException != null, 'The aura handled exception should not be null since an invalid request ' +
                'has been sent.');
        System.assertEquals(errorMessage,
                auraException.getMessage(), 'The error message in the elevate batch response ' +
                        'should throw an exception and the message should be the create elevate batch error ' +
                        'message specified in the invalid request data type.');
    }



    /***
     * @description Verifies the purchase request response throws an excpetion
     * when building a purchase request body fails with an unexpected error
     */
    @IsTest
    static void shouldThrowExceptionWhenPurchaseRequestGetsUnexpectedError() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        String invalidBodyParameters = '{"amount":2500,"email"';
        String dataImportRecordId = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);

        Exception actualException;
        try {
            Test.startTest();
            GE_GiftEntryController.processPurchaseRequest(invalidBodyParameters, dataImportRecordId);
            Test.stopTest();

        } catch (Exception e) {
            actualException = e;
        }

        System.assertNotEquals(null, actualException, 'An exception should be returned due an invalid request body');
    }

    /***
     * @description Verifies the purchase request response contains timed out status code and message
     * when the purchase requests times out
     */
    @IsTest
    static void shouldLogErrorWhenPurchaseRequestTimesOut() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        final String requestTimeoutMessage = System.Label.geErrorRequestTimedout;
        String requestBodyParameters = GE_PaymentServices_TEST.GOOD_PURCHASE_CALL_BODY;
        String dataImportRecordId = UTIL_UnitTestData_TEST.mockId(DataImport__c.SObjectType);

        Test.startTest();
        UTIL_Http_TEST.mockErrorCalloutResponse(
            UTIL_Http.STATUS_CODE_REQUEST_TIMEOUT,
            UTIL_Http.STATUS_TIMED_OUT,
            GE_PaymentServices_TEST.FAILED_RESPONSE_BODY
        );

        UTIL_Http.Response response = GE_GiftEntryController.processPurchaseRequest(requestBodyParameters, dataImportRecordId);
        Test.stopTest();

        System.assertEquals(UTIL_Http.STATUS_CODE_REQUEST_TIMEOUT, response.statusCode,
            'Response status code should match: ' + response);

        System.assert(response.body.contains(GE_PaymentServices_TEST.FAILED_RESPONSE_MESSAGE),
            'Response body status should contain the timeout exception or timeout error response message: ' + response);

        System.assert(response.body.contains(requestTimeoutMessage),
            'Response message should contain a generic purchase request timed out message: ' + response);

        List<Error__c> errors = new TEST_SObjectGateway.ErrorGateway().getRecords();
        System.assertEquals(1, errors.size(), 'One error should be created on timeout response: ' + errors);

        final String recordDetailMessage = String.format(
            System.Label.stgErrorInvalidNameFormat,
            new String[] {
                Schema.SObjectType.DataImport__c.getLabel(),
                dataImportRecordId
            }
        );
        System.assertEquals(requestTimeoutMessage + ' ' + recordDetailMessage, errors[0].Full_Message__c,
            'Error log message should contain data import record detail');
    }

    /***
     * @description Confirm that the Data Import upsert method inserts and updates correctly.
     */
    @IsTest
    static void shouldUpsertDataImportRecord() {
        DataImport__c inMemoryDataImport = BDI_DataImport_TEST.newDI('First', 'Last', 100);
        DataImport__c dataImportRecord = GE_GiftEntryController.upsertDataImport(JSON.serialize(inMemoryDataImport));
        System.assert(dataImportRecord.Id != null);

        dataImportRecord.Payment_Authorization_Token__c = 'TEST_TOKEN';
        DataImport__c updatedDataImportRecord = GE_GiftEntryController.upsertDataImport(JSON.serialize(dataImportRecord));
        System.assertEquals(dataImportRecord.Id, updatedDataImportRecord.Id);
        System.assertEquals('TEST_TOKEN', updatedDataImportRecord.Payment_Authorization_Token__c);
    }

    /***
     * @description Confirm that a default RenderWrapper is correctly returned
     */
    @IsTest
    static void createAndReturnDefaultFormTemplate() {
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();
        Form_Template__c defaultTemplate = buildFormTemplate();

        GE_Template.Template template = UTIL_UnitTestData_TEST.createSampleTemplate();

        String templateJSON = JSON.serialize(template);
        defaultTemplate.Template_JSON__c = templateJSON;

        insert defaultTemplate;

        giftEntryCustomSetting.Default_Gift_Entry_Template__c = defaultTemplate.Id;

        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);

        GE_GiftEntryController.RenderWrapper frw = GE_GiftEntryController.getDefaultSGERenderWrapper();
        System.assert(frw.formTemplate != null);
        System.assert(frw.formTemplate.name == template.name);

        frw = GE_GiftEntryController.getRenderWrapperById(defaultTemplate.Id);
        System.assert(frw.formTemplate != null);
        System.assert(frw.formTemplate.name == template.name);

    }
    @IsTest
    static void createAndReturnFieldMappings() {

        UTIL_UnitTestData_TEST.createSampleFieldMappings();

        Test.startTest();

        BDI_FieldMappingSet bdiFieldMappingSet = GE_GiftEntryController.getFieldMappings();

        Test.stopTest();

        System.assertNotEquals(null, bdiFieldMappingSet, 'Expected to receive field mappings, got null.');
        System.assertEquals('Default_Field_Mapping_Set', bdiFieldMappingSet.DeveloperName);

    }

    /***
    * @description Confirming that method returns the correct number of records
    */
    @IsTest
    static void shouldReturnCorrectNumberOfRecords() {
        GE_Template.Template template0 = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON0 = JSON.serialize(template0);
        GE_GiftEntryController.storeFormTemplate(null,template0.name, template0.description, template0.version, templateJSON0);

        GE_Template.Template template1 = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON1 = JSON.serialize(template1);
        GE_GiftEntryController.storeFormTemplate(null,template1.name, template1.description, template1.version, templateJSON1);

        System.assertEquals(2, GE_GiftEntryController.getAllFormTemplates().size());
    }

    @IsTest
    static void shouldReturnFormTemplatesWithMatchingGatewayName() {
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();
        giftEntryCustomSetting.Enable_Gateway_Assignment__c = true;
        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);

        final String GATEWAY_ID = '123-sample-456';
        final String GATEWAY_ALIAS = 'Gateway Alias';
        final String VENDOR_NAME = 'Test Vendor Name';
        final String ENABLED_PAYMENT_METHODS = '';

        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = PS_GatewayService_TEST.getPopulatedGatewaysByMerchantSuccessMock(
                GATEWAY_ID, GATEWAY_ALIAS, VENDOR_NAME, ENABLED_PAYMENT_METHODS);

        Test.startTest();
        GE_Template.Template template0 = UTIL_UnitTestData_TEST.createSampleGatewayAssignmentTemplate(GATEWAY_ID);
        String templateJSON0 = JSON.serialize(template0);
        System.assert(true, templateJSON0.contains('uniqueKey'));
        GE_GiftEntryController.storeFormTemplate(null,template0.name, template0.description, template0.version, templateJSON0);
        Test.stopTest();

        GE_Template.Template[] templates = GE_GiftEntryController.getAllFormTemplates();
        System.assertEquals(1, templates.size(), 'There should be one template');
        System.assertEquals(GATEWAY_ALIAS, templates[0].elevateSettings.gatewayName,
                'Gateway alias should be ' + GATEWAY_ALIAS);
    }

    @IsTest
    static void shouldReturnFormTemplatesWithNoMatchingGatewayName() {
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();
        giftEntryCustomSetting.Enable_Gateway_Assignment__c = false;
        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);

        final String GATEWAY_ID = '123-sample-456';
        final String GATEWAY_ALIAS = 'Gateway Alias';
        final String VENDOR_NAME = 'Test Vendor Name';
        final String ENABLED_PAYMENT_METHODS = '';

        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = PS_GatewayService_TEST.getPopulatedGatewaysByMerchantSuccessMock(
                GATEWAY_ID, GATEWAY_ALIAS, VENDOR_NAME, ENABLED_PAYMENT_METHODS);

        Test.startTest();
        GE_Template.Template template0 = UTIL_UnitTestData_TEST.createSampleGatewayAssignmentTemplate(GATEWAY_ID);
        String templateJSON0 = JSON.serialize(template0);
        System.assert(true, templateJSON0.contains('uniqueKey'));
        GE_GiftEntryController.storeFormTemplate(null,template0.name, template0.description, template0.version, templateJSON0);
        Test.stopTest();

        GE_Template.Template[] templates = GE_GiftEntryController.getAllFormTemplates();
        System.assertEquals(1, templates.size(), 'There should be one template');
        System.assertEquals(null, templates[0].elevateSettings.gatewayName, 'Gateway name should be null.');
    }

    @IsTest
    static void shouldReturnTimeoutExceptionWhenAttemptingToRetrieveGatewayNames() {
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();
        giftEntryCustomSetting.Enable_Gateway_Assignment__c = true;
        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);

        final String GATEWAY_ID = '123-sample-456';
        final String TIMEOUT_MESSAGE = 'Read timed out';

        PS_IntegrationServiceConfig_TEST.enableElevateIntegrationService();
        UTIL_Http_TEST.CalloutMock calloutMock = PS_GatewayService_TEST.getGatewaysByMerchantErrorMock(TIMEOUT_MESSAGE);

        Test.startTest();
        GE_Template.Template template0 = UTIL_UnitTestData_TEST.createSampleGatewayAssignmentTemplate(GATEWAY_ID);
        String templateJSON0 = JSON.serialize(template0);
        System.assert(true, templateJSON0.contains('uniqueKey'));
        GE_GiftEntryController.storeFormTemplate(null,template0.name, template0.description, template0.version, templateJSON0);
        Test.stopTest();

        String errorMessage;
        try {
            GE_Template.Template[] templates = GE_GiftEntryController.getAllFormTemplates();
        }
        catch (Exception e) {
            errorMessage = e.getMessage();
        }

        System.assertEquals(TIMEOUT_MESSAGE, errorMessage, 'Should throw timeout error');
    }

    /***
    * @description Confirming that method deletes Form Template records with given ids.
    */
    @IsTest
    static void shouldDeleteFormTemplatesWithGivenIds() {
        GE_Template.Template template0 = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON0 = JSON.serialize(template0);
        GE_GiftEntryController.storeFormTemplate(null,template0.name, template0.description, template0.version, templateJSON0);

        GE_Template.Template template1 = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON1 = JSON.serialize(template1);
        GE_GiftEntryController.storeFormTemplate(null,template1.name, template1.description, template1.version, templateJSON1);

        Form_Template__c[] formTemplates = [SELECT Id, Name FROM Form_Template__c];

        System.assertEquals(2, formTemplates.size());
        GE_GiftEntryController.deleteFormTemplates(new String[]{ formTemplates[0].Id, formTemplates[1].Id });

        formTemplates = [SELECT Id, Name FROM Form_Template__c];
        System.assertEquals(0, formTemplates.size());
    }

    /***
    * @description Confirming that the lifecycle of storing and retrieving the template does not corrupt
    * the data.
    */
    @IsTest
    static void shouldCommitAndRetrieveTemplate() {
        GE_Template.Template template = UTIL_UnitTestData_TEST.createSampleTemplate();
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();

        String templateJSON = JSON.serialize(template);
        String storedFormTemplateId = GE_GiftEntryController.storeFormTemplate(null,
                template.name,
                template.description,
                template.version,
                templateJSON);

        giftEntryCustomSetting.Default_Gift_Entry_Template__c = storedFormTemplateId;
        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);

        GE_Template.Template templateResult = GE_GiftEntryController.retrieveDefaultSGEFormTemplate();
        String templateResultJSON = JSON.serialize(templateResult);

        System.assertEquals(templateJSON, templateResultJSON);
    }

    /***
    * @description Confirm that we're able to retrieve column headers based on a list name.
    */
    @IsTest
    static void shouldRetrieveColumnHeaderBasedOnListName() {

        Test.startTest();
        Custom_Column_Header__c[] allHeaders = UTIL_UnitTestData_TEST.createSampleColumnHeaders();
        insert allHeaders;
        Test.stopTest();

        GE_GiftEntryController.ColumnHeaderData selectedHeaders =
                GE_GiftEntryController.retrieveCustomColumnHeaders('Templates');

        System.assertEquals(3, allHeaders.size());
        System.assertEquals(1, selectedHeaders.columnHeaders.size());
    }

    /***
    * @description Confirm that we're able to retrieve column headers based on a list name.
    */
    @IsTest
    static void shouldPersistOnlyTheSelectedColumnHeadersForTheGivenList() {

        Test.startTest();
        Custom_Column_Header__c[] allHeaders = UTIL_UnitTestData_TEST.createSampleColumnHeaders();
        insert allHeaders;
        Test.stopTest();

        GE_GiftEntryController.ColumnHeaderData selectedHeaders =
                GE_GiftEntryController.retrieveCustomColumnHeaders('Batches');

        Custom_Column_Header__c columnHeaderToKeep = new Custom_Column_Header__c();
        columnHeaderToKeep.Name = 'sampleColumnHeader4';
        columnHeaderToKeep.List_Name__c = 'Batches';
        columnHeaderToKeep.Index__c = 0;
        columnHeaderToKeep.Field_Api_Name__c = 'Name';

        String columnHeaderStringToKeep = JSON.serialize(new Custom_Column_Header__c[]{columnHeaderToKeep});

        GE_GiftEntryController.upsertCustomColumnHeaders(columnHeaderStringToKeep, 'Batches');

        GE_GiftEntryController.ColumnHeaderData updatedColumnHeadersList =
                GE_GiftEntryController.retrieveCustomColumnHeaders('Batches');

        Custom_Column_Header__c columnHeaderToCheck = updatedColumnHeadersList.columnHeaders[0];

        System.assertEquals(1, selectedHeaders.columnHeaders.size());
        System.assertEquals(1, updatedColumnHeadersList.columnHeaders.size());
        System.assertEquals('Name', columnHeaderToCheck.Field_Api_Name__c);
    }

    /****
    * @description Confirm that we're able to build a query string and retrieve a list of records.
    */
    @IsTest
    static void shouldRetrieveRecordsBasedOnAQueryString() {

        Test.startTest();
        Custom_Column_Header__c[] allHeaders = UTIL_UnitTestData_TEST.createSampleColumnHeaders();
        insert allHeaders;
        Test.stopTest();

        String[] selectFields = new String[] {'Id', 'Name'};
        String sObjectApiName = SObjectType.Custom_Column_Header__c.name;
        String[] whereClause = new String[] {};
        String orderByClause = 'LastModifiedDate desc';
        Integer limitClause = 10;

        SObject[] objects = GE_GiftEntryController.retrieveRecords(
                selectFields, sObjectApiName, whereClause, orderByClause, limitClause);

        System.assertEquals(3, objects.size());
    }

    /****
    * @description Confirm that form template name uniqueness is enforced.
    */
    @IsTest
    static void shouldReturnFalseForExistingFormTemplateName() {
        GE_Template.Template template = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON = JSON.serialize(template);
        GE_GiftEntryController.storeFormTemplate(null,template.name, template.description, template.version, templateJSON);

        Form_Template__c[] formTemplates = [SELECT Id, Name, Template_JSON__c FROM Form_Template__c];

        Boolean isExistingName = GE_GiftEntryController.checkNameUniqueness(
                formTemplates[0].Name,
                null);

        Boolean isUniqueName = GE_GiftEntryController.checkNameUniqueness(
                'New Form Template Sample Name',
                null);

        System.assertEquals(false,
                isExistingName,
                'Existing template names should return false from `GE_GiftEntryController.checkNameUniqueness`');
        System.assertEquals(true,
                isUniqueName,
                'New template names should return true from `GE_GiftEntryController.checkNameUniqueness`');
    }

    @IsTest
    static void shouldRetrieveSGETemplateWithPermission() {
        UTIL_PermissionsMock utilPermissionsMockInstance = new UTIL_PermissionsMock(true);
        UTIL_Permissions utilPermissionsMock = (UTIL_Permissions) Test.createStub(
                UTIL_Permissions.class,
                utilPermissionsMockInstance);
        UTIL_Permissions.setInstance(utilPermissionsMock);

        GE_Template.Template template = UTIL_UnitTestData_TEST.createSampleTemplate();
        Gift_Entry_Settings__c giftEntrySettings = UTIL_CustomSettingsFacade.getGiftEntrySettings();
        String templateJSON = JSON.serialize(template);
        String storedFormTemplateId = GE_GiftEntryController.storeFormTemplate(null,
                template.name,
                template.description,
                template.version,
                templateJSON);

        giftEntrySettings.Default_Gift_Entry_Template__c = storedFormTemplateId;

        insert giftEntrySettings;

        UTIL_UnitTestData_TEST.createSampleFieldMappings();

        GE_Template.Template updatedTemplate = GE_GiftEntryController.retrieveDefaultSGEFormTemplate();

        System.assert(String.isBlank(updatedTemplate.permissionErrors),
                'There should be no permission errors when the user has all required CRUD and FLS permissions.');
        System.assertEquals(updatedTemplate.permissionErrorType, null,
                'The template should not have a permission error type if the user has all required CRUD and FLS permissions.');
    }

    /***
    * @description Confirms that a form template used by any Data Import Batch cannot be deleted.
    */
    @IsTest
    static void shouldPreventDeletionOfTemplateInUse() {
        GE_Template.Template template = UTIL_UnitTestData_TEST.createSampleTemplate();
        String templateJSON = JSON.serialize(template);
        GE_GiftEntryController.storeFormTemplate(null,
                template.name,
                template.description,
                template.version,
                templateJSON);

        Form_Template__c[] formTemplates = [
                SELECT Id, Name, Template_JSON__c
                FROM Form_Template__c
        ];

        DataImportBatch__c batch = createBatch('Test Batch', false);
        batch.Form_Template__c = formTemplates[0].Id;

        insert batch;

        AuraHandledException failure;

        try {
            GE_GiftEntryController.deleteFormTemplates(new String[]{ formTemplates[0].Id });
        } catch (AuraHandledException ex) {
            failure = ex;
        }

        formTemplates = [
                SELECT Id, Name
                FROM Form_Template__c
        ];

        System.assert(String.isNotBlank(failure.getMessage()));
        System.assertEquals(1, formTemplates.size(), 'A Form Template in use should not be deleted');

    }

    /***
    * @description Confirms that a form template used as default on Gift Entry settings cannot be deleted.
    */
    @IsTest
    static void shouldPreventDeletionOfTemplateReferencedByGiftEntry() {

        // aux vars
        String templateName = 'fooName';
        AuraHandledException failure;

        // test data
        GE_Template.Template template = createSampleTemplate();
        template.name = templateName;
        String templateJSON = JSON.serialize(template);
        // insert form template using service
        String templateId = GE_GiftEntryController.storeFormTemplate(null,
                template.name,
                template.description,
                template.version,
                templateJSON);

        // gift entry custom settings set up
        Gift_Entry_Settings__c giftEntryCustomSetting = new Gift_Entry_Settings__c();
        giftEntryCustomSetting.Default_Gift_Entry_Template__c = templateId;
        UTIL_CustomSettingsFacade.getGiftEntrySettingsForTests(giftEntryCustomSetting);

        // retrieve templates with id
        Form_Template__c[] formTemplates = [SELECT Id,
                Name,
                Template_JSON__c
        FROM Form_Template__c];

        System.assertEquals( formTemplates.size(), 1,
                'We should have only 1 form temp record at this time' );

        Test.startTest();
        try {
            // delete template using service
            GE_GiftEntryController.deleteFormTemplates(new String[]{ formTemplates[0].Id });
        } catch (AuraHandledException ex) {
            failure = ex;
        }
        Test.stopTest();

        formTemplates = [SELECT Id, Name FROM Form_Template__c];
        System.assert( String.isNotBlank(failure.getMessage()), 'Aura Exception found' );
        System.assertEquals( 1, formTemplates.size(), 'Template was not deleted' );

    }

    @IsTest
    private static void shouldDecryptEncryptedValue() {
        String testGatewayId = '1234-5678-90';
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);

        String encryptedGatewayId = GE_GiftEntryController.encryptGatewayId(testGatewayId);
        System.assertNotEquals(testGatewayId, encryptedGatewayId, 'Encrypted value should be different than original');

        String decryptedGatewayId = GE_GiftEntryController.decryptGatewayId(encryptedGatewayId);
        System.assertEquals(testGatewayId, decryptedGatewayId, 'Decrypted value should be the same as the original');
    }


    // Helpers
    /////////////////

    /***
    * @description Builds a test form template
    * @return Form_Template__c
    */
    private static Form_Template__c buildFormTemplate() {
        return new Form_Template__c(
            Name = 'Test',
            Format_Version__c = '1.0'
        );
    }

    //Utility method for creating a sample template.
    private static GE_Template.Template createSampleTemplate () {

        GE_Template.Element field = new GE_Template.Element('FormField',
                'True',
                null,
                'CustomLabel',
                new String[]{});

        GE_Template.Element widget = new GE_Template.Element('FormWidget',
                'DisplayRule',
                'ComponentName',
                new String[]{});

        GE_Template.Element[] elements = new GE_Template.Element[]{field,widget};

        GE_Template.Section section = new GE_Template.Section('SectionLabel',
                'Accordion',
                'Expanded',
                'True',
                elements);

        GE_Template.Layout layout = new GE_Template.Layout('DefaultMappingSet',
                new GE_Template.Section[]{section});

        GE_Template.Template template = new GE_Template.Template('Sample Template',
                'This is the description.',
                '1.0',
                layout);

        return template;
    }

    /***
     * @description Utility method that creates an NPSP Data Import Batch
     *
     * @param name
     * @param autoProcess
     *
     * @return DataImportBatch__c
     */
    private static DataImportBatch__c createBatch (String name, Boolean autoProcess) {
        DataImportBatch__c batch = new DataImportBatch__c();
        batch.Name = name;
        batch.Batch_Process_Size__c = 200;
        batch.Contact_Matching_Rule__c = 'Firstname,Lastname,Email';
        batch.Donation_Matching_Rule__c = UTIL_Namespace.StrTokenNSPrefix('Donation_Amount__c') +
                ';' + UTIL_Namespace.StrTokenNSPrefix('Donation_Date__c');
        batch.Donation_Matching_Behavior__c = BDI_DataImport_API.BestMatchOrCreate;
        batch.Process_Using_Scheduled_Job__c = autoProcess;
        return batch;
    }

    private class UTIL_PermissionsMock implements StubProvider {
        Boolean hasPermission;
        private UTIL_PermissionsMock(Boolean hasPermission) {
            this.hasPermission = hasPermission;
        }

        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                Type returnType, List<Type> listOfParamTypes, List<String> listOfParamNames,
                List<Object> listOfArgs) {

            switch on stubbedMethodName {
                when 'canRead' {
                    return hasPermission;
                }
                when 'canCreate' {
                    return hasPermission;
                }
                when 'canUpdate' {
                    return hasPermission;
                }
            }
            return null;
        }
    }
}
