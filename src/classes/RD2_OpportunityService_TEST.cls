/*
    Copyright (c) 2019 Salesforce.org
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
* @date 2019
* @group Recurring Donations
* @description Test for Create Opportunities from Recurring Donations
*
*/
@isTest
private with sharing class RD2_OpportunityService_TEST {

    private static final String AFFILIATION_OCR_ROLE_SOLICITOR = 'Solicitor';
    private static final String RELATIONSHIP_TYPE_EMPLOYEE = 'Employee';
    private static final String RELATIONSHIP_STATUS_CURRENT = 'Current';
    private static final String STAGE_NAME_PLEDGED = 'Pledged';
    private static final String STAGE_NAME_PROMISED = 'Promised';
    private static final String PAYMENT_CREDIT_CARD = 'Credit Card';
    private static final String PAYMENT_CHECK = 'Check';

    private static final Date START_DATE = Date.newInstance(2019, 9, 15);
    private static final Date TODAY = START_DATE.addDays(1);
    private static final Date CLOSE_DATE = TODAY.addDays(1);
    private static final String DAY_OF_MONTH = String.valueOf(CLOSE_DATE.day());
    private static final Decimal RD_AMOUNT = 400;
    private static final Decimal RD_NEW_AMOUNT = 100;

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();


    /****
     * @description Creates data required for unit tests
     */
    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /***
     * @description Verifies a Pledged Opp is created for the new recurring donation when
     * Installment Opportunity Stage Name in settings is Pledged
     */
    @isTest
    private static void shouldCreateOppWhenRDHasContact() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration(STAGE_NAME_PLEDGED);

        Test.startTest();
        npe03__Recurring_Donation__c rd = createRecurringDonation();
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'One Installment Opp should be created on RD insert: ' + opps);

        System.assertEquals(getExpectedOppName(rd, CLOSE_DATE), opps[0].Name, 'Opportunity Name should match');
        System.assertEquals(getContact().Id, opps[0].npe01__Contact_Id_for_Role__c);
        System.assertEquals(rd.npe03__Amount__c, opps[0].Amount);
        System.assertEquals(rd.npe03__Contact__c, opps[0].Primary_Contact__c);
        System.assertEquals(CLOSE_DATE, opps[0].CloseDate);
        System.assertEquals(rd.npe03__Recurring_Donation_Campaign__c, opps[0].CampaignId);
        System.assertEquals(STAGE_NAME_PLEDGED, opps[0].StageName);
        System.assertEquals(PAYMENT_CREDIT_CARD, getPayments(opps)[0].npe01__Payment_Method__c);
    }

    /***
     * @description Verifies a Promised Opp is created for the new recurring donation when
     * Installment Opportunity Stage Name in settings is Promised
     */
    @isTest
    private static void shouldCreateOppWhenRDHasOrgAffiliation() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration(STAGE_NAME_PROMISED);

        Account acc = UTIL_UnitTestData_TEST.buildOrganizationAccount();
        insert acc;

        insert new npe5__Affiliation__c(
            npe5__Organization__c = acc.Id,
            npe5__Role__c = RELATIONSHIP_TYPE_EMPLOYEE,
            npe5__Contact__c = getContact().Id,
            npe5__Status__c = RELATIONSHIP_STATUS_CURRENT,
            Related_Opportunity_Contact_Role__c = AFFILIATION_OCR_ROLE_SOLICITOR
        );

        Test.startTest();
        npe03__Recurring_Donation__c rd = createRecurringDonation(acc);
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'One Installment Opp should be created on RD insert: ' + opps);

        System.assertEquals(getExpectedOppName(rd, CLOSE_DATE), opps[0].Name, 'Opportunity Name should match');
        System.assertEquals(rd.npe03__Amount__c, opps[0].Amount);
        System.assertEquals(rd.npe03__Recurring_Donation_Campaign__c, opps[0].CampaignId);
        System.assertEquals(CLOSE_DATE, opps[0].CloseDate);
        System.assertEquals(STAGE_NAME_PROMISED, opps[0].StageName); 
        System.assertEquals(PAYMENT_CREDIT_CARD, getPayments(opps)[0].npe01__Payment_Method__c);

        List<OpportunityContactRole> ocrs = getOppContactRoles(new Set<Id>{ opps[0].Id });
        System.assertEquals(1, ocrs.size(), 'One OCR should be created: ' + ocrs);
        System.assertEquals(AFFILIATION_OCR_ROLE_SOLICITOR, ocrs[0].Role, 'OCR Contact Role should match');
    }

    /***
     * @description Verifies an Opportunity name has the specialized format when
     * Opportunity naming is not configured in NPSP Settings
     */
    @isTest
    private static void shouldCreateOppWithSpecialFormatWhenNoOppNamingSpecified() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration();

        Test.startTest();
        npe03__Recurring_Donation__c rd = createRecurringDonation();
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'One Installment Opp should be created on RD insert: ' + opps);
        System.assertEquals(getExpectedOppName(rd, CLOSE_DATE), opps[0].Name, 'Opportunity Name should match');
    }

    /***
     * @description Verifies an Opportunity name is set as configured in NPSP Settings Opportunity naming
     */
    @isTest
    private static void shouldCreateOppNameWithOppNamingSpecifiedInSettings() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        insert new Opportunity_Naming_Settings__c(
            Name = 'Test Opp Naming Settings',
            Opportunity_Name_Format__c = '{!Contact.Name} {!CloseDate}',
            Attribution__c = System.Label.oppNamingBoth
        );

        //blank out cached version so the newly created setting takes effect
        UTIL_ListCustomSettingsFacade.mapOppNamingSettings = null;

        setUpConfiguration();
        
        Test.startTest();
        npe03__Recurring_Donation__c rd = createRecurringDonation();
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'One Installment Opp should be created on RD insert: ' + opps);

        DateTime closeDatetime = Datetime.newInstance(CLOSE_DATE.year(), CLOSE_DATE.month(), CLOSE_DATE.day());
        System.assertEquals(rd.npe03__Donor_Name__c + ' ' + closeDatetime.format('yyyy.MM.dd'), opps[0].Name, 'Opportunity Name should match');
    }

    /***
    * @description Verifies the installment opportunities are created with the record types set in the NPSP setting
    */
    @isTest
    private static void shouldSetOppRecordTypeIdFromSettings() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Id rdSettingRecordTypeId = UTIL_RecordTypes_TEST.getRandomRecordTypeId(Opportunity.SObjectType);

        setUpConfiguration(new Map<String, Object>{
            'npe03__Record_Type__c' => rdSettingRecordTypeId
        });

        Test.startTest();
        npe03__Recurring_Donation__c rd = createRecurringDonation();
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An opportunity should be created');

        System.assertEquals(rdSettingRecordTypeId, opps[0].RecordTypeId,
            'The record type should be configured according to the NPSP Opportunity Default Record Type');
    }

    /***
    * @description The installment opportunity should have the default record type of the current user when the record
    * type is not set in NPSP setting
    */
    @isTest
    private static void shouldSetOppRecordTypeToDefaultWhenSettingsNotConfigured() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration();

        Test.startTest();
        npe03__Recurring_Donation__c rd = createRecurringDonation();
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An opportunity should be created');

        Id defaultRecordTypeId = UTIL_RecordTypes_TEST.getDefaultRecordTypeId(Opportunity.SObjectType);
        System.assertEquals(defaultRecordTypeId, opps[0].RecordTypeId,
            'The record type should be the default opp record type when NPSP default record type is null');
    }

    /***
    * @description Verify RD is created while opportunity is not created when NPSP setting Opp Record Type is not valid
    */
    @isTest
    private static void shouldNotCreateOppWhenSettingRecordTypeIsInvalid() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration(new Map<String, Object>{
            'npe03__Record_Type__c' => UTIL_RecordTypes_TEST.MOCK_ID
        });

        Test.startTest();
        npe03__Recurring_Donation__c rd = createRecurringDonation();
        Test.stopTest();

        System.assertEquals(0, oppGateway.getRecords(rd).size(),
            'No installment opportunity should be created when the RD Settings record type is invalid');

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'An error should be created for the invalid record type Id');
        System.assert(errors[0].Full_Message__c.contains(String.valueOf(UTIL_RecordTypes_TEST.MOCK_ID)),
            'The error message should be related to the invalid record type Id: ' + errors[0]);
    }

    /***
    * @description Verify opp is updated with installment fields and payment method in payment object
    * if close date is in the future
    */
    @isTest
    private static void shouldUpdateOppWhenCloseDateIsInFuture() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();

        Date nextCloseDate = CLOSE_DATE.addDays(1);

        setUpConfiguration();

        npe03__Recurring_Donation__c rd = createRecurringDonation();

        //create an installment Opp since installment Opps are not created
        //due to async call to opp service
        insert getOpportunityBuilder(rd)
            .withCloseDate(CLOSE_DATE)
            .withOpenStage()
            .build();

        Test.startTest();
        rd.Day_Of_Month__c = String.valueOf(nextCloseDate.day());
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.PaymentMethod__c = PAYMENT_CHECK;
        update rd;
        Test.stopTest();
        
        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'One opportunity should exist: ' + opps);

        System.assertEquals(RD_NEW_AMOUNT, opps[0].Amount, 'Amount should be updated');
        System.assertEquals(nextCloseDate, opps[0].CloseDate, 'Close Date should be updated');
        System.assertEquals(getExpectedOppName(rd, nextCloseDate), opps[0].Name, 'Opportunity name should contain new Close Date');
        System.assertEquals(PAYMENT_CHECK, getPayments(opps)[0].npe01__Payment_Method__c, 'Payment method should be updated on Payment');
    }

    /***
    * @description Verifies an Opp with Close Date in past is not updated when RD is updated.
    * A new Opp with the next Close Date is created when RD is updated if the existing Opp Close Date is in past.
    */
    @isTest
    private static void shouldNotUpdateOppWhenCloseDateInThePast() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration();
        RD2_ScheduleService.currentDate = CLOSE_DATE.addDays(1);
        
        npe03__Recurring_Donation__c rd = createRecurringDonation();

        Opportunity opp = getOpportunityBuilder(rd)
            .withCloseDate(CLOSE_DATE)
            .withOpenStage()
            .build();
        insert opp;

        Test.startTest();
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        update rd;
        Test.stopTest();

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(2, oppById.size(), 
            'New Opp for the next Close Date should be created on RD update: ' + oppById.values());

        opp = oppById.remove(opp.Id);
        System.assertEquals(RD_AMOUNT, opp.Amount, 'Existing Opp Amount should be unchanged');
        System.assertEquals(CLOSE_DATE, opp.CloseDate, 'Existing Opp Close Date should be unchanged');

        opp = oppById.values()[0];
        System.assertEquals(RD_NEW_AMOUNT, opp.Amount, 'New Opp Amount should match RD Amount');
        System.assertEquals(CLOSE_DATE.addMonths(1), opp.CloseDate, 'New Opp Close Date should be next Close Date');
    }

    /***
    * @description Verify opportunity is updated with installment fields 
    * when Close Date is today and the Opp is open
    */
    @isTest
    private static void shouldUpdateOppWhenOpenAndCloseDateIsToday() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration();
        
        npe03__Recurring_Donation__c rd = createRecurringDonation();

        insert getOpportunityBuilder(rd)
            .withCloseDate(TODAY)
            .withOpenStage()
            .build();

        Test.startTest();
        rd.Day_Of_Month__c = String.valueOf(TODAY.day());
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.PaymentMethod__c = PAYMENT_CHECK;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'One opportunity should exist: ' + opps);
        System.assertEquals(RD_NEW_AMOUNT, opps[0].Amount, 'Amount should be changed');

        List<npe01__OppPayment__c> payments = getPayments(opps);
        System.assertEquals(opps.size(), payments.size(), 'Payment should exist for the Opp: ' + payments);
        System.assertEquals(PAYMENT_CHECK, payments[0].npe01__Payment_Method__c, 
            'Payment method should be updated for the open Opp with Close Date = today');
    }

    /***
    * @description Verify opportunity is not updated with installment fields 
    * when Close Date is today and the Opp is Closed Lost/Won
    */
    @isTest
    private static void shouldNotUpdateOppWhenClosedAndCloseDateIsToday() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration();
        
        npe03__Recurring_Donation__c rd = createRecurringDonation();

        insert getOpportunityBuilder(rd)
            .withCloseDate(TODAY)
            .withClosedLostStage()
            .build();

        Test.startTest();
        rd.Day_Of_Month__c = String.valueOf(TODAY.day());
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.PaymentMethod__c = PAYMENT_CHECK;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'One opportunity should exist: ' + opps);
        System.assertEquals(RD_AMOUNT, opps[0].Amount, 'Amount should be unchanged');

        List<npe01__OppPayment__c> payments = getPayments(opps);
        System.assertEquals(opps.size(), payments.size(), 'Payment should exist for the Opp: ' + payments);
        System.assertNotEquals(PAYMENT_CHECK, payments[0].npe01__Payment_Method__c, 
            'Payment method should not be updated for the closed Opp with Close Date = today');
    }

    /***
    * @description Verify opportunity is not updated with installment fields 
    * when Close Date is today and the Opp is Closed Lost/Won
    * and another future open Opp exists after it
    */
    @isTest
    private static void shouldNotUpdateOppWhenClosedAndCloseDateIsTodayAndFutureOpenOppExists() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration();
        
        npe03__Recurring_Donation__c rd = createRecurringDonation();

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withInstallmentNumber(1)
                .withCloseDate(TODAY)
                .withClosedLostStage()
                .build(),
            oppBuilder
                .withInstallmentNumber(2)
                .withCloseDate(TODAY.addMonths(1))
                .withOpenStage()
                .build()
        };
        insert opps;

        Test.startTest();
        rd.Day_Of_Month__c = String.valueOf(TODAY.day());
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.PaymentMethod__c = PAYMENT_CHECK;
        update rd;
        Test.stopTest();

        Map<Id, Opportunity> actualOppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size(), actualOppById.size(), 'Opportunity number should match: ' + actualOppById);
        for (Opportunity opp : actualOppById.values()) {
            if (opp.Id == opps[0].Id) { 
                System.assertEquals(RD_AMOUNT, opp.Amount, 
                    'Amount should not be updated for the closed Opp with Close Date = today');
            } else {
                System.assertEquals(RD_NEW_AMOUNT, opp.Amount, 
                    'Amount should be updated for the future open Opp');
            }
        }

        List<npe01__OppPayment__c> payments = getPayments(opps);
        System.assertEquals(opps.size(), payments.size(), 'Payment should exist for each Opp: ' + payments);
        for (npe01__OppPayment__c payment : payments) {
            if (payment.npe01__Opportunity__c == opps[0].Id) { 
                System.assertNotEquals(PAYMENT_CHECK, payment.npe01__Payment_Method__c, 
                    'Payment method should not be updated for the closed Opp with Close Date = today');
            } else {
                System.assertEquals(PAYMENT_CHECK, payment.npe01__Payment_Method__c, 
                    'Payment method should be updated for the future open Opp');
            }
        }
    }

    /***
    * @description Verify current date and a future open Opp are updated with installment fields on RD update.
    * This test verifies that current date and future Opps are matched correctly with the RD Schedule installments.
    */
    @isTest
    private static void shouldUpdateOppWhenOpenAndCloseDateAreTodayAndInFuture() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        RD2_ScheduleService scheduleService = new RD2_ScheduleService();

        setUpConfiguration();

        npe03__Recurring_Donation__c rd = createRecurringDonation();

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd)
            .withOpenStage();

        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withInstallmentNumber(1)
                .withCloseDate(TODAY)
                .build(),
            oppBuilder
                .withInstallmentNumber(2)
                .withCloseDate(TODAY.addMonths(1))
                .build()
        };
        insert opps;

        Test.startTest();
        rd.Day_Of_Month__c = String.valueOf(TODAY.day());
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.PaymentMethod__c = PAYMENT_CHECK;
        update rd;
        Test.stopTest();
        
        Map<Id, Opportunity> actualOppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(opps.size(), actualOppById.size(), 'Opportunity number should match: ' + actualOppById);
        for (Opportunity opp : actualOppById.values()) {
            System.assertEquals(RD_NEW_AMOUNT, opp.Amount, 
                opp.Id == opps[0].Id 
                ? 'Amount should be updated for the Opp with Close Date = today'
                : 'Amount should be updated for the future Opp');
        }

        List<npe01__OppPayment__c> payments = getPayments(opps);
        System.assertEquals(opps.size(), payments.size(), 'Payment should exist for each Opp: ' + payments);

        for (npe01__OppPayment__c payment : payments) {
            System.assertEquals(PAYMENT_CHECK, payment.npe01__Payment_Method__c, 
                payment.npe01__Opportunity__c == opps[0].Id 
                ? 'Payment method should be updated for the Opp with Close Date = today'
                : 'Payment method should be updated for the future Opp');
        }
    }

    /***
    * @description Verify Opportunity's campaign is not updated when there is update to the campaign on the RD
    * and the opportunity's status is closed
    */
    @isTest
    private static void shouldNotUpdateOppWhenFutureOppIsClosed() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration();

        npe03__Recurring_Donation__c rd = createRecurringDonation();

        insert getOpportunityBuilder(rd)
            .withCampaign(rd.npe03__Recurring_Donation_Campaign__c)
            .withCloseDate(CLOSE_DATE)
            .withClosedWonStage()
            .build();

        System.assert(TODAY < CLOSE_DATE, 'Opp Close Date should be in future');
        
        Test.startTest();
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An opportunity should exist: ' + opps);
        System.assertEquals(RD_AMOUNT, opps[0].Amount, 'Opp Amount should be unchanged');
    }

     /***
    * @description Verify Opportunity's campaign is not updated when there start date on the RD
    * is greater than close date on the opportunity
    */
    @isTest
    private static void shouldNotUpdateOppWhenOppCloseDateIsBeforeRDStartDate() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration();

        npe03__Recurring_Donation__c rd = createRecurringDonation();

        insert getOpportunityBuilder(rd)
            .withCampaign(rd.npe03__Recurring_Donation_Campaign__c)
            .withCloseDate(CLOSE_DATE)
            .withOpenStage()
            .build();

        Date newStartDate = CLOSE_DATE.addDays(2);
        System.assertEquals(START_DATE, rd.StartDate__c, 'RD Start Date should be set');
        System.assert(START_DATE < TODAY && TODAY < newStartDate, 'New Start Date should be in future and greater than old Start Date');
        System.assert(TODAY < CLOSE_DATE && CLOSE_DATE < newStartDate, 'Close Date should be in future but less than new Start Date');

        Test.startTest();
        rd.StartDate__c = newStartDate;
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        update rd;
        Test.stopTest();

        System.assertEquals(newStartDate, rdGateway.getRecord(rd.Id).StartDate__c, 'RD Start Date should match');

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An opportunity should exist: ' + opps);
        System.assertEquals(RD_AMOUNT, opps[0].Amount, 'Opp Amount should be unchanged: ' + opps);
    }

    /***
    * @description Verify Opportunity's campaign is updated when 
    * there is update to the campaign on the RD
    * and add campaign is enabled in RD custom settings
    */
    @isTest
    private static void shouldUpdateOppCampaignWhenSettingsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration();

        npe03__Recurring_Donation__c rd = createRecurringDonation();

        insert getOpportunityBuilder(rd)
            .withCampaign(rd.npe03__Recurring_Donation_Campaign__c)
            .withCloseDate(CLOSE_DATE)
            .withOpenStage()
            .build();
  
        Campaign campaign = new Campaign(Name = 'ChildrenCampaign', IsActive = true); 
        insert campaign;

        Test.startTest();
        rd.npe03__Recurring_Donation_Campaign__c = campaign.id;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An opportunity should exist: ' + opps);
        System.assertEquals(campaign.id, opps[0].CampaignId, 'Opp Campaign should be updated');
    }

    /***
    * @description Verify Opportunity's campaign is not updated when there is update to the campaign on the RD
    * and add campaign is disabled in RD custom settings
    */
    @isTest
    private static void shouldNotUpdateOppCampaignWhenSettingsDisabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration();

        npe03__Recurring_Donation__c rd = createRecurringDonation();
        Id rdCampaignId = rd.npe03__Recurring_Donation_Campaign__c;
        System.assertNotEquals(null, rdCampaignId, 'Campaign Id should be set on the RD');

        insert getOpportunityBuilder(rd)
            .withCampaign(rdCampaignId)
            .withCloseDate(CLOSE_DATE)
            .withOpenStage()
            .build();

        setUpConfiguration(new Map<String, Object>{
            'npe03__Add_Campaign_to_All_Opportunites__c' => false
        });
  
        Test.startTest();
        Campaign campaign = new Campaign(Name = 'ChildrenCampaign', IsActive = true);
        insert campaign;
        
        rd.npe03__Recurring_Donation_Campaign__c = campaign.id;
        update rd;
        Test.stopTest();

        List<Opportunity> opps = oppGateway.getRecords(rd);
        System.assertEquals(1, opps.size(), 'An opportunity should exist: ' + opps);
        System.assertEquals(rdCampaignId, opps[0].CampaignId, 'Opp Campaign should be unchanged');
    }

    /***
    * @description Verify if the updates to the opportunity do not give error message
    * when no opportunity records are passed.
    */
    @isTest
    private static void shouldReturnNoErrorWhenUpdatedRDHasNoOpp() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        setUpConfiguration();

        Test.startTest();
        npe03__Recurring_Donation__c rd = createRecurringDonation();
        Test.stopTest();

        delete new TEST_SObjectGateway.OpportunityGateway().getRecords(rd);

        List<npe03__Recurring_Donation__c> rds = new RD2_OpportunityEvaluationService()
            .getRecurringDonations(new Set<Id>{ rd.Id });

        Exception actualException;
        try {
            rd.npe03__Amount__c = RD_NEW_AMOUNT;
            new RD2_OpportunityService(TODAY, new  RD2_OpportunityEvaluationService.DatabaseService())
                .updateOpportunities(rds);

        } catch (Exception e) {
            actualException = e;
        }

        System.assertEquals(null, actualException, 'No Exception should be thrown: ' + actualException);

        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(0, errors.size(), 'No error should be created: ' + errors);
    }



    // Helper Methods
    //////////////////

    /***
    * @description Creates a single Recurring Donation record
    * @return npe03__Recurring_Donation__c
    */
    private static npe03__Recurring_Donation__c createRecurringDonation() {
        return createRecurringDonations(null, getContact(), 1)[0];
    }

    /***
    * @description Creates a list of Recurring Donation records
    * @param organization Ann Organization Account assigned to the Recurring Donation
    * @return npe03__Recurring_Donation__c
    */
    private static npe03__Recurring_Donation__c createRecurringDonation(Account organization) {
        return createRecurringDonations(organization, null, 1)[0];
    }

    /***
    * @description Creates a list of Recurring Donation records
    * @param size Number of RDs to be created
    * @return npe03__Recurring_Donation__c
    */
    private static List<npe03__Recurring_Donation__c> createRecurringDonations(Account organization, Contact contact, Integer size) {
        Campaign campaign = new Campaign(Name = 'Test Campaign', IsActive = true);
        insert campaign;

        TEST_RecurringDonationBuilder builder = TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withAmount(RD_AMOUNT)            
            .withPaymentMethod(PAYMENT_CREDIT_CARD)
            .withCampaign(campaign.Id)
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withDayOfMonth(DAY_OF_MONTH);

        if (contact != null) {
            builder.withContact(contact.Id);
        } else if (organization != null) {
            builder.withAccount(organization.Id);
        }

        List<npe03__Recurring_Donation__c> rds = builder.build(size);
        insert rds;

        return rdGateway.getRecords(rds);
    }


    /***
    * @description Generic version of creating Recurring Donations Settings
    * @return void
    */
    private static void setUpConfiguration() {
        setUpConfiguration(STAGE_NAME_PLEDGED);
    }

    /***
    * @description Creates Recurring Donation settings and configures Installment Opp Stage 
    * @param stageName Installment Opportunity Stage
    * @return void
    */
    private static void setUpConfiguration(String stageName) {
        setUpConfiguration(new Map<String, Object>{ 'InstallmentOppStageName__c' => stageName });
    }

    /***
    * @description Generic version of creating Recurring Donations Settings
    * Apply current date override for the Opp service.
    *
    * @param valueByField A map of field name to value
    * @return void
    */
    private static void setUpConfiguration(Map<String, Object> valueByField) {
        RD2_Settings_TEST.setUpConfiguration(valueByField);

        //set current date override
        RD2_ScheduleService.currentDate = TODAY;
    }

    /***
    * @description Builds Specialized name format for opportunity
    * @param rd Recurring Donation record
    * @param closeDate Opportunity Close Date
    * @return String Expected Opportunity name
    */
    public static String getExpectedOppName(npe03__Recurring_Donation__c rd, Date closeDate) {
        return
            rd.npe03__Donor_Name__c +  ' ' +
            System.Label.npe03.RecurringDonationPrefix + ' (' +
            (rd.npe03__Total_Paid_Installments__c != null ? rd.npe03__Total_Paid_Installments__c + 1 : 1) + ') ' +
            closeDate.format();
    }

    /**
     * @description Instantiate an Opportunity builder for the specified Recurring Donation
     * @param rd Recurring Donation
     * @return TEST_OpportunityBuilder New Opportunity builder
     */
    private static TEST_OpportunityBuilder getOpportunityBuilder(npe03__Recurring_Donation__c rd) {
        return new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c)
            .withInstallmentNumber(1);
    }

    /***
    * @description Queries OCRs for specified Opportunities
    * @param oppIds Opportunity Ids
    * @return List<OpportunityContactRole> OCRs assigned to provided Opportunities
    */
    private static List<OpportunityContactRole> getOppContactRoles(Set<Id> oppIds) {
        return [
            SELECT OpportunityId, Opportunity.AccountId, ContactId, Contact.Name, IsPrimary, Role
            FROM OpportunityContactRole
            WHERE OpportunityId IN :oppIds
        ];
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

    /***
    * @description Retrieves Payments for specified Opportunities
    * @param opps Specified Opportunities
    * @return List<npe01__OppPayment__c>
    */
    private static List<npe01__OppPayment__c> getPayments(List<Opportunity> opps) {
        return [
            SELECT npe01__Payment_Method__c, npe01__Opportunity__c
            FROM npe01__OppPayment__c
            WHERE npe01__Opportunity__c IN :opps
        ];
    }
}