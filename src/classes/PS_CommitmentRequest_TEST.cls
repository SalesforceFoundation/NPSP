/*
    Copyright (c) 2020, Salesforce.org
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
* @group Elevate Payment Services
* @description Tests verifying Elevate payment services commitment request
*/
@IsTest(IsParallel=false)
private with sharing class PS_CommitmentRequest_TEST {

    private static final String PAYMENT_TOKEN = 'token-abcd-efgh-ijkl-mnop-qrst';
    private static final Integer USD_CURRENCY_MULTIPLIER = 100;

    private static final Integer DAY_OF_MONTH = 20;
    private static final Date START_DATE = Date.newInstance(2019, 3, DAY_OF_MONTH);
    private static final Datetime FIRST_PAYMENT_DATE = Datetime.newInstance(2019, 3, DAY_OF_MONTH);
    private static final Date CURRENT_DATE = START_DATE.addDays(-3);
    private static final Integer INSTALLMENT_FREQUENCY = 2;
    private static final String PAYMENT_CHECK = 'Check';
    private static final Double AMOUNT = 100.23;

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        RD2_ScheduleService.currentDate = CURRENT_DATE;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;
    }

    /****
    * @description Verifies Commitment Request body to attach to the HttpRequest
    * is built based on Recurring Donation fields and its schedule
    */
    @isTest
    private static void shouldBuildCommitmentRequestBody() {
        RD2_ScheduleService.currentDate = CURRENT_DATE;
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Campaign rdCampaign = new Campaign(name = 'Annual Campaign');
        insert rdCampaign;

        Contact contact = getContact();
        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(contact.Id)
            .withInstallmentFrequency(INSTALLMENT_FREQUENCY)
            .withCampaign(rdCampaign.Id)
            .build();

        PS_CommitmentRequest request = new PS_CommitmentRequest();
        PS_CommitmentRequest.RequestBody requestBody = request.getRequestBody(rd, PAYMENT_TOKEN);

        System.assertEquals(contact.FirstName, requestBody.firstName, 'First Name should match');
        System.assertEquals(contact.LastName, requestBody.lastName, 'Last Name should match');
        System.assertEquals(PS_IntegrationServiceConfig_TEST.testMerchantId, requestBody.merchantId, 'Merchant Id should match');
        System.assertEquals(PS_IntegrationServiceConfig_TEST.testGatewayId, requestBody.gatewayId, 'Gateway Id should match');
        System.assertEquals(PS_CommitmentRequest.CommitmentType.SUSTAINER.name(), requestBody.type, 'Commitment Type should match');
        System.assertEquals(PS_CommitmentRequest.PaymentMethod.CARD.name(), requestBody.paymentMethodType, 'First Name should match');
        System.assertEquals(PAYMENT_TOKEN, requestBody.paymentMethodToken, 'Payment Method Token should match');
        System.assertEquals(UserInfo.getDefaultCurrency(), requestBody.currencyCode, 'Currency Code should match');

        System.assertNotEquals(null, requestBody.metadata, 'Metadata should be set by default');
        System.assertEquals(PS_Request.OriginType.CRM.name(), requestBody.metadata.originType,
            'Metadata origin type should be CRM');
        System.assertEquals(rd.npe03__Recurring_Donation_Campaign__c, requestBody.metadata.campaignCode,
            'Metadata campaign code should be set to RD campaign');

        System.assertNotEquals(null, requestBody.productMetaData, 'Product Metadata should be set by default');
        System.assertEquals(PS_Request.OriginType.CRM.name(), requestBody.productMetaData.origin.type,
            'Product Metadata origin type should be CRM');
        System.assertEquals(rd.npe03__Recurring_Donation_Campaign__c, requestBody.productMetaData.campaign.id,
            'Product Metadata campaign id should be set to RD campaign');
        
        System.assertEquals(1, requestBody.schedules.size(),
            'One schedule should be passed to the API: ' + requestBody.schedules);

        PS_CommitmentRequest.Schedule schedule = requestBody.schedules[0];
        System.assertEquals(AMOUNT * USD_CURRENCY_MULTIPLIER, schedule.recurringPaymentAmount, 'Recurring Amount should match');
        System.assertEquals('MONTH', schedule.frequency, 'Donation should be made monthly');
        System.assertEquals(INSTALLMENT_FREQUENCY, schedule.frequencyInterval, 'Donation frequency should match');
        System.assertEquals(FIRST_PAYMENT_DATE.format('yyyy-MM-dd'), schedule.firstOccurrenceOn, 'First Payment Date should match');
    }

    /****
    * @description Verifies two schedules are populated in the Commitment Request
    * when Installment Period is 1st and 15th.
    */
    @isTest
    private static void shouldBuildTwoSchedulesWhenInstalmentPeriodIs1stAnd15th() {
        RD2_ScheduleService.currentDate = CURRENT_DATE;
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withInstallmentPeriod(RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH)
            .withInstallmentFrequency(1)
            .withDayOfMonth(null)
            .build();

        PS_CommitmentRequest request = new PS_CommitmentRequest();
        PS_CommitmentRequest.RequestBody requestBody = new PS_CommitmentRequest.RequestBody();
        request.setSchedules(requestBody, new RD2_ScheduleService().buildNewSchedules(rd), 'USD');

        System.assertEquals(2, requestBody.schedules.size(),
            'Two schedules should be passed to the API: ' + requestBody.schedules);

        for (PS_CommitmentRequest.Schedule schedule : requestBody.schedules) {
            System.assertEquals(AMOUNT * USD_CURRENCY_MULTIPLIER, schedule.recurringPaymentAmount, 'Recurring Amount should match');
            System.assertEquals('MONTH', schedule.frequency, 'Donation should be made monthly');
            System.assertEquals(1, schedule.frequencyInterval, 'Donation should be made every month');
        }

        System.assertEquals('2019-04-01', requestBody.schedules[0].firstOccurrenceOn,
            'First Payment Date on the 1st schedule should match');
        System.assertEquals('2019-04-15', requestBody.schedules[1].firstOccurrenceOn,
            'First Payment Date on the 15th schedule should match');
    }

    /****
    * @description Verifies donor information is set to Organization
    * when it is specified regardless if the Contact is specified
    */
    @isTest
    private static void shouldSetDonorInfoWhenOrganizationIsSpecified() {
        RD2_ScheduleService.currentDate = CURRENT_DATE;
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Account organization = UTIL_UnitTestData_TEST.buildOrganizationAccount();
        insert organization;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder()
            .withAccount(organization.Id)
            .withInstallmentFrequency(INSTALLMENT_FREQUENCY)
            .build();

        PS_CommitmentRequest request = new PS_CommitmentRequest();
        PS_CommitmentRequest.RequestBody requestBody = new PS_CommitmentRequest.RequestBody();
        
        request.setDonorInfo(requestBody, rd);

        System.assertEquals(organization.Name, requestBody.firstName, 'Request First Name should match Organization Name');
        System.assertEquals(organization.Name, requestBody.lastName, 'Request Last Name should match Organization Name');
    }

    /**
    * @description Verifies a valid create commitment HttpRequest is returned
    */
    @isTest
    private static void shouldBuildCreateCommitmentRequest() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        final String jsonRequestBody = 'commitment request body';

        Test.startTest();
        String commitmentId = null;
        HttpRequest request = new PS_CommitmentRequest().buildRequest(commitmentId, jsonRequestBody);
        Test.stopTest();

        final String expectedEndpoint = PS_IntegrationServiceConfig_TEST.testBaseUrl
            + PS_Request.ENDPOINT_COMMITMENT;
        System.assertEquals(expectedEndpoint, request.getEndpoint(), 'Endpoint should match');

        System.assertEquals(UTIL_Http.Method.POST.name(), request.getMethod(), 'The HttpRequest method should match');
        System.assertEquals(jsonRequestBody, request.getBody(), 'Request body should match');
    }

    /**
    * @description Verifies a valid edit commitment HttpRequest is returned
    */
    @isTest
    private static void shouldBuildEditCommitmentRequest() {
        PS_IntegrationService.setConfiguration(PS_IntegrationServiceConfig_TEST.testConfig);
        final String jsonRequestBody = 'commitment request body';

        Test.startTest();
        String commitmentId = RD2_ElevateIntegrationService_TEST.COMMITMENT_ID;
        HttpRequest request = new PS_CommitmentRequest().buildRequest(commitmentId, jsonRequestBody);
        Test.stopTest();

        final String expectedEndpoint = PS_IntegrationServiceConfig_TEST.testBaseUrl
            + PS_Request.ENDPOINT_COMMITMENT;
        System.assertEquals(expectedEndpoint, request.getEndpoint(), 'Endpoint should match');

        System.assertEquals(UTIL_Http.Method.PATCH.name(), request.getMethod(), 'The HttpRequest method should match');
        System.assertEquals(jsonRequestBody, request.getBody(), 'Request body should match');
    }



    // Helpers
    ///////////////

    /**
     * @description Build open Recurring Donation
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder() {
        return getRecurringDonationBuilder(getContact().Id);
    }

    /**
     * @description Base common Recurring Donation record
     * @param contactId Contact Id
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(contactId)
            .withAmount(AMOUNT)
            .withCurrencyIsoCode(UserInfo.getDefaultCurrency())
            .withPaymentMethod(PAYMENT_CHECK)
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withDayOfMonth(String.valueOf(DAY_OF_MONTH));
    }

    /****
    * @description Returns contact record
    * @return Contact
    */
    private static Contact getContact() {
        return [
            SELECT FirstName, LastName, AccountId, Account.Name
            FROM Contact
            LIMIT 1
        ];
    }

}
