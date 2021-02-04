/*
    Copyright (c) 2012, Salesforce.org
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
* @date 2012 (2.0)
* @group Recurring Donations
* @description Test class for the RecurringDonations class
*/
@isTest
private with sharing class RD_RecurringDonations_TEST2 {
    private static final Date DEFAULT_ESTABLISHED_DATE = RD_RecurringDonations_TEST.DEFAULT_ESTABLISHED_DATE;
    private static final Date TODAY = System.today();
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.ErrorGateway errorGateway = new TEST_SObjectGateway.ErrorGateway();
    private static final Integer NUM_INSTALLMENTS = 12;


    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {        
        Account acc = buildAccount();
        insert acc;

        insert buildContact(acc.Id);
    }


    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeOppForOpenEndedRecurringDonationYearly() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(null);
        rd.npe03__Organization__c = getAccount().Id;
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        rd.npe03__Next_Payment_Date__c = TODAY;
        rd.OwnerId = System.UserInfo.getUserId();
        insert rd;

        List<Opportunity> originalOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        System.assertEquals(1, originalOpps.size());

        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;

        Test.startTest();
        update o;
        RD_RecurringDonations.evaluateRecurringDonationsForNewOppInsert(new List<npe03__Recurring_Donation__c>{rd});
        Test.stopTest();

        rd = rdGateway.getRecord(rd.id);
        System.assertEquals(0, RD_RecurringDonations_TEST.getOpenOppCount(rd.Id));
        System.assertEquals(TODAY, rd.npe03__Last_Payment_Date__c);
    }

    @isTest
    private static void closeOpenEndedRecurringDonationMarkOppsClosedLost() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();
        
        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationWeeklyInstallment(getContact().Id);
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        insert rd;

        List<Opportunity> originalOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        Integer cOpp = originalOpps.size();
        System.assert(cOpp == 52 || cOpp == 53);

        Test.startTest();
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_CLOSED;
        update rd;
        Test.stopTest();

        //assert all previously open opps are marked closed lost
        System.assertEquals(53, [select count() from Opportunity where isClosed = true and isWon = false and npe03__Recurring_Donation__c = :rd.id]);

    }

    @isTest
    private static void updateRecurringDonationWithClosedOpp() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationWeeklyInstallment(getContact().Id);
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;

        List<Opportunity> originalOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        update o;

        //fake the last payment date close operation
        rd.npe03__Last_Payment_Date__c = TODAY;
        update rd;
        Test.startTest();
        rd.npe03__Installment_Period__c = RD_Constants.INSTALLMENT_PERIOD_YEARLY;
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.id);

        System.assertEquals(1, RD_RecurringDonations_TEST.getOpenOppCount(rd.Id));
        System.assertEquals(TODAY, rd.npe03__Last_Payment_Date__c);
    }

    /*******************************************************************************************************
     * Verifies open Opportunities Close Date is updated when the Recurring Donation
     * Next Donation Date is changed.
     */
    @isTest
    private static void shouldUpdateOpenOppCloseDatesWhenRecDonationNextDonationDateIsChanged() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        Date nextDonationDate = TODAY.toStartOfMonth();
        Integer expectedInstallments = 2;

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationMonthlyInstallment(null);
        rd.npe03__Organization__c = getAccount().id;
        rd.npe03__Date_Established__c = nextDonationDate.addDays(-1);
        rd.npe03__Next_Payment_Date__c = nextDonationDate;
        insert rd;

        List<Opportunity> actualOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        System.assertEquals(expectedInstallments, actualOpps.size(), 'The installment on Monthly RD should match expected Opp size');
        System.assertEquals(nextDonationDate, actualOpps[0].CloseDate, 'The first Close Date should be Next Donation Date');

        nextDonationDate = nextDonationDate.addDays(1);
        rd.npe03__Next_Payment_Date__c = nextDonationDate;
        Test.startTest();
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(nextDonationDate, rd.npe03__Next_Payment_Date__c, 'The RD Next Donation Date should be updated');

        actualOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        System.assertEquals(expectedInstallments, actualOpps.size(), 'The installment on Monthly RD should match expected Opp size');
        System.assertEquals(nextDonationDate, actualOpps[0].CloseDate, 'The first Close Date should be updated Next Donation Date');

        System.assertEquals(expectedInstallments, RD_RecurringDonations_TEST.getOpenOppCount(rd.Id));
    }

    //test inserting a closed/won opportunity for an open recurring donation
    @isTest
    private static void insertClosedOppForOpenEndedRecurringDonation() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withPlannedInstallments(0)
            .withContact(getContact().Id)
            .withAmount(100)
            .withDateEstablished(DEFAULT_ESTABLISHED_DATE)
            .withOpenEndedStatusOpen()
            .withNextPaymentDate(TODAY.toStartOfMonth())
            .withOwnerId()
            .build();
        insert rd;

        Opportunity o = new Opportunity();
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        o.Amount = 50;
        o.AccountId = getAccount().Id;
        o.Name = 'test';
        o.npe03__Recurring_Donation__c = rd.Id;

        Test.startTest();
        insert o;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.id);
        System.assertEquals(50, rd.npe03__Paid_Amount__c);
    }

    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeOppForOpenEndedRecurringDonationBadRecurrance() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        Campaign camp = new Campaign(Name = 'MyTestCamp', isActive = true);
        insert camp;

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(null);
        rd.npe03__Organization__c = getAccount().Id;
        rd.npe03__Recurring_Donation_Campaign__c = camp.id;
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;

        List<Opportunity> originalOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);
        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;

        rd.npe03__Installment_Period__c = 'GarbageDate';

        // Need to simulate that this previously ran to prevent the Opp from being deleted.
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, true);
        update rd;
        TDTM_ProcessControl.setRecursionFlag(TDTM_ProcessControl.flag.RD, false);

        Test.startTest();
        update o;
        Test.stopTest();
    }

    //test closing an opportunity for an open recurring donation
    @isTest
    private static void closeRecurringDonationDeleteOpps() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        Campaign camp = new Campaign(Name = 'MyTestCamp', isActive = true);
        insert camp;

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(null);
        rd.npe03__Organization__c = getAccount().id;
        rd.npe03__Recurring_Donation_Campaign__c = camp.id;
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;

        System.assertNotEquals(0, RD_RecurringDonations_TEST.getOpenOppCount(rd.Id));
        //reset the semaphore
        Test.startTest();
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_CLOSED;
        update rd;
        Test.stopTest();

        //there should be no open donations
        System.assertEquals(0, RD_RecurringDonations_TEST.getOpenOppCount(rd.Id));
    }

    @isTest
    private static void multipleRDInsert() {
        RD_RecurringDonations_TEST.createRdSettingsWithForecast(6);

        delete [select id from npe03__Custom_Field_Mapping__c];
        npe03__Custom_Field_Mapping__c cfm1 = new npe03__Custom_Field_Mapping__c(
            npe03__Recurring_Donation_Field__c = 'Name',
            npe03__Opportunity_Field__c = 'Description',
            Name = 'CFMName00001-Test'
        );
        insert cfm1;

        Contact c = getContact();

        List<npe03__Recurring_Donation__c> rdlist = new List<npe03__Recurring_Donation__c>();
        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        rd.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rdlist.add(rd);

        npe03__Recurring_Donation__c r2 = RD_RecurringDonations_TEST.buildRecurringDonationMonthlyInstallment(c.Id);
        r2.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        r2.npe03__Next_Payment_Date__c = TODAY.toStartOfMonth();
        rdlist.add(r2);

        Test.startTest();
        insert rdlist;
        rdlist[0].npe03__Amount__c = 50;
        rdlist[1].npe03__Amount__c = 50;
        rdlist[1].npe03__Next_Payment_Date__c = TODAY.toStartOfMonth().addDays(5);
        update rdlist;
        Test.stopTest();

        List<Opportunity> originalOpps = new List<Opportunity>([select id, Name,amount,accountid,CloseDate,Description from Opportunity where npe03__Recurring_Donation__r.id = :rd.id or npe03__Recurring_Donation__c = :r2.id]);
        System.assertEquals(7, originalOpps.size());
        System.assertEquals(50, originalOpps[0].Amount);
        System.assertNotEquals(null, originalOpps[0].Description);
        System.assertNotEquals(null, originalOpps[1].Description);
    }
    @isTest
    private static void tooManyInstallments() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            npe03__Opportunity_Forecast_Months__c = 6,
            npe03__Maximum_Donations__c = 2,
            npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name()
        ));

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(getContact().Id);
        rd.npe03__Installments__c = 50;
        rd.npe03__Next_Payment_Date__c = TODAY;
        try{
            insert rd;
        } catch (exception e) {}

        //insert should fail because of too many installments
        System.assertEquals(null,rd.id);
    }
    @isTest
    private static void updateOppsFromMultipleRDs() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        //remove any existing custom field mappings
        delete [select id from npe03__Custom_Field_Mapping__c];
        npe03__Custom_Field_Mapping__c cfm = new npe03__Custom_Field_Mapping__c(
            npe03__Recurring_Donation_Field__c = 'Name',
            npe03__Opportunity_Field__c = 'Description',
            Name = 'CFMName00001-Test'
        );
        insert cfm;

        Contact c = getContact();

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(c.Id);
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;

        npe03__Recurring_Donation__c r2 = RD_RecurringDonations_TEST.buildRecurringDonationMonthlyInstallment(c.Id);
        r2.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        r2.npe03__Next_Payment_Date__c = TODAY;
        insert r2;

        List<Opportunity> originalOpps = new List<Opportunity>([select id, Name,amount,accountid,CloseDate from Opportunity where npe03__Recurring_Donation__r.id = :rd.id or npe03__Recurring_Donation__c = :r2.id]);
        System.assert(originalOpps.size() > 1);

        Test.startTest();
        originalOpps[0].Stagename = UTIL_UnitTestData_TEST.getClosedWonStage();
        originalOpps[1].stagename = UTIL_UnitTestData_TEST.getClosedWonStage();
        update originalOpps;
        Test.stopTest();

        System.assert(originalOpps.size() > [select count() from Opportunity where isClosed = false and (npe03__Recurring_Donation__c = :rd.id or npe03__Recurring_Donation__c = :r2.id)]);
    }

    @isTest
    private static void testErrorHandlingAllSysAdmins() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            npe03__Error_Email_Notifications__c = ERR_Notifier.ERROR_NOTIFICATION_RECIPIENT_ALL_SYS_ADMINS,
            npe03__Opportunity_Forecast_Months__c = NUM_INSTALLMENTS
        ));

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withAccount(getAccount().Id)
            .withAmount(100)
            .withInstallmentPeriodWeekly()
            .withOpenEndedStatusOpen()
            .withNextPaymentDate(TODAY)
            .build();
        insert rd;

        //create some opps
        List<Opportunity> olist = new List<Opportunity>();
        for (Integer i = 0; i<=10; i++) {
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = TODAY,
                Amount = 1.00,
                npe03__Recurring_Donation__c = rd.id
            );
            olist.add(o);
        }
        //invalidate one opp
        olist[0].Name = null;

        Database.saveresult[] lsr = Database.insert(olist, false);

        ERR_Handler.Errors errors = ERR_Handler.getErrors(lsr, olist);
        System.assertEquals(true, errors.errorsExist);
        System.assertEquals(1, errors.errorRecords.size());
    }

    @isTest
    private static void testErrorHandlingUser() {
        User u = [select id from User limit 1];
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            npe03__Error_Email_Notifications__c = u.id,
            npe03__Opportunity_Forecast_Months__c = NUM_INSTALLMENTS
        ));

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withAccount(getAccount().Id)
            .withAmount(100)
            .withInstallmentPeriodWeekly()
            .withOpenEndedStatusOpen()
            .withNextPaymentDate(TODAY)
            .build();
        insert rd;

         //create some opps
        List<Opportunity> olist = new List<Opportunity>();
        for (Integer i = 0; i<=10; i++) {
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = TODAY,
                Amount = 1.00,
                npe03__Recurring_Donation__c = rd.id
            );
            olist.add(o);
        }
        //invalidate one opp
        olist[0].Name = null;

        Database.saveresult[] lsr = Database.insert(olist, false);

        ERR_Handler.Errors errors = ERR_Handler.getErrors(lsr, olist);
        System.assertEquals(true, errors.errorsExist);
        System.assertEquals(1, errors.errorRecords.size());
    }

    @isTest
    private static void testErrorHandlingPublicGroup() {
        Group g = new Group(Name = 'MyGroup');
        insert g;
        UTIL_Debug.debug('GID IS: ' + g.id);
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            npe03__Error_Email_Notifications__c = g.id,
            npe03__Opportunity_Forecast_Months__c = NUM_INSTALLMENTS
        ));

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withAccount(getAccount().Id)
            .withAmount(100)
            .withInstallmentPeriodWeekly()
            .withOpenEndedStatusOpen()
            .withNextPaymentDate(TODAY)
            .build();
        insert rd;

        //create some opps
        List<Opportunity> olist = new List<Opportunity>();
        for (Integer i = 0; i<=10; i++) {
            Opportunity o = new Opportunity(
                StageName = 'Closed Won',
                Name = 'Opp ' + i,
                CloseDate = TODAY,
                Amount = 1.00,
                npe03__Recurring_Donation__c = rd.id
            );
            olist.add(o);
        }
        //invalidate one opp
        olist[0].Name = null;

        Database.saveresult[] lsr = Database.insert(olist, false);

        ERR_Handler.Errors errors = ERR_Handler.getErrors(lsr, olist);
        System.assertEquals(true, errors.errorsExist);
        System.assertEquals(1, errors.errorRecords.size());
    }

    //--------------------TEST METHOD from RD_RecurringDonations_BATCH -----------------------
    @isTest
    private static void batchStatusBarTest() {
        UTIL_JobProgress_CTRL controller = new UTIL_JobProgress_CTRL();
        controller.getBatchJobs();
    }

    //--------------- from RD_RecurringDonations_BATCH -----------------
    @isTest
    public static void testBatch() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationWeeklyInstallment(null);
        rd.npe03__Organization__c = getAccount().Id;
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;

        List<Opportunity> originalOpps = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.Id);

        Opportunity o = originalOpps[0];
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        update o;

        //kick it off from the vf page
        Test.setCurrentPageReference(new PageReference('Page.RecurringDonationsSettings'));

        Test.StartTest();
        RD_RecurringDonations_BATCH rdbatch = new RD_RecurringDonations_BATCH();
        ID ApexJobId = Database.executeBatch(rdbatch, 10);
        Test.stopTest();
    }

    /***
     * @description Verifies RD batch is not executed when another RD batch job is running
     */
    @isTest
    public static void shouldNotExecuteBatchWhenAnotherJobIsRunning() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationWeeklyInstallment(null);
        rd.npe03__Organization__c = getAccount().Id;
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;

        Test.startTest();
        RD_RecurringDonations_BATCH rdbatch = new RD_RecurringDonations_BATCH();
        rdbatch.isConcurrentBatch = true;
        Database.executeBatch(rdbatch);
        Test.stopTest();
        
        List<Error__c> errors = errorGateway.getRecords();
        System.assertEquals(1, errors.size(), 'One error should be created: ' + errors);
        
        String expectedMessage = String.format(
            System.Label.commonConcurrentBatchError,
            new String[]{ RD_RecurringDonations_BATCH.class.getName() }
        );
        System.assertEquals(expectedMessage, errors[0].Full_Message__c, 'Error message should match');
    }
    
    /***
     * @description Verifies Recurring Donations are returned when enhanced Recurring Donations are not enabled
     */
    @isTest
    private static void shouldReturnRDsWhenEnhancedRDIsNotEnabled() {
        List<npe03__Recurring_Donation__c> records = new List<npe03__Recurring_Donation__c>();
        records = executeBatchStart();
        System.assertEquals(1, records.size(), 'Recurring Donation record should be returned from the start() method');
    }

    /***
     * @description Verifies Recurring Donations are not returned when enhanced Recurring Donations are enabled
     */
    @isTest
    private static void shouldThrowExceptionLegacyJobWhenEnhancedRDIsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        List<npe03__Recurring_Donation__c> records = new List<npe03__Recurring_Donation__c>();
        try {
            records = executeBatchStart();
        } catch (Exception ex) { }

        System.assertEquals(true, records.isEmpty(), 'No record should be returned from the start() method: ' + records);
    }

    /**
     * @description Verify that when Enhanced RD is enabled in an org, attempting to execute the older RD1 batch
     * job throws an exception
     */
    @IsTest
    private static void shouldThrowExceptionForLegacyJobIfEnhancedRDIsEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        Exception actualException;
        try {
            Test.startTest();
            Database.executeBatch(new RD_RecurringDonations_BATCH());
            Test.stopTest();
        } catch (Exception ex) {
            actualException = ex;
        }
        System.assert(actualException != null, 'An exception should have been thrown because Enhanced RD is enabled');
        System.assert(actualException.getMessage().containsIgnoreCase(System.Label.RD_ErrorLegacyBatchJobCannotBeRun),
            'The exception should have indicated that the job cannot be executed because Enhanced RD is enabled ' + actualException.getMessage());
    }

    /***
     * @description Executes legacy RD batch "start()" method and returns Recurring Donations for verification
     */
    private static List<npe03__Recurring_Donation__c> executeBatchStart() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withAccount(getAccount().Id)
            .withAmount(100)
            .withPlannedInstallments(2)
            .withInstallmentPeriodYearly()
            .withDateEstablished(DEFAULT_ESTABLISHED_DATE)
            .withNextPaymentDate(TODAY)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen() //The batch filters on Open "Open Ended Status"
            .build();
        insert rd;

        RD_RecurringDonations_BATCH batch = new RD_RecurringDonations_BATCH();
        String query = batch.start(null).getQuery();

        return Database.query(query);
    }

    /*******************************************************************************************************
    * @description test method for custom field mapping on insert and update of Fixed Length RDs
    */
    @isTest
    private static void testRDCustomFieldMappingFixedRD() {
        UTIL_Debug.debug('multiply: ' + RD_Constants.SCHEDULE_TYPE_MULTIPLY_BY);
        UTIL_Debug.debug('divide: ' + RD_Constants.SCHEDULE_TYPE_DIVIDE_BY);

        //Create new CFM
        delete [select id from npe03__Custom_Field_Mapping__c];
        npe03__Custom_Field_Mapping__c cfm = new npe03__Custom_Field_Mapping__c(
            npe03__Recurring_Donation_Field__c = 'Name',
            npe03__Opportunity_Field__c = 'Description',
            Name = 'CFMName00001-Test'
        );
        insert cfm;


        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(getContact().Id);
        rd.Name = 'TestRD CFM Insert';
        insert rd;

        //check that opps have picked up the value of the RD field set through custom field mapping
        Opportunity[] installments1 = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.id);
        for (opportunity opp:installments1) {
            System.assertEquals(rd.name, opp.description);
        }

        Test.startTest();
        rd.name='TestRD CFM Update';
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.id);
        System.assertEquals(rd.name,'TestRD CFM Update');

        //check that opps have picked up the upated value of the RD field set through custom field mapping
        Opportunity[] installments2 = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.id);
        for (opportunity opp:installments2) {
            System.assertEquals(rd.name, opp.description);
        }
    }

    /*******************************************************************************************************
    * @description test method for custom field mapping on insert and update on Open Ended RD's
    */
    @isTest
    private static void testRDCustomFieldMappingOpenRD() {
        UTIL_Debug.debug('multiply: ' + RD_Constants.SCHEDULE_TYPE_MULTIPLY_BY);
        UTIL_Debug.debug('divide: ' + RD_Constants.SCHEDULE_TYPE_DIVIDE_BY);

        //Create new CFM
        delete [select id from npe03__Custom_Field_Mapping__c];
        npe03__Custom_Field_Mapping__c cfm = new npe03__Custom_Field_Mapping__c(
            npe03__Recurring_Donation_Field__c = 'Name',
            npe03__Opportunity_Field__c = 'Description',
            Name = 'CFMName00001-Test'
        );
        insert cfm;


        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withContact(getContact().Id)
            .withAmount(100)
            .withInstallmentPeriodMonthly()
            .withDateEstablished(TODAY)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .build();
        insert rd;

        //check that opps have picked up the value of the RD field set through custom field mapping
        Opportunity[] installments1 = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.id);
        System.assertNotEquals(0, installments1.size());
        for (opportunity opp:installments1) {
            System.assertEquals(rd.name, opp.description);
        }

        Test.startTest();
        rd.name='TestRD CFM Update';
        update rd;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.id);
        System.assertEquals(rd.name, 'TestRD CFM Update');

        //check that opps have picked up the upated value of the RD field set through custom field mapping
        Opportunity[] installments2 = RD_RecurringDonations_TEST.getOppsOrderByCloseDate(rd.id);
        System.assertNotEquals(0, installments2.size());
        for (opportunity opp:installments2) {
            System.assertEquals(rd.name, opp.description);
        }
    }

    @isTest
    private static void testInstallmentNumbers() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        Campaign camp = new Campaign(Name = 'MyTestCamp', isActive = true);
        insert camp;

        npe03__Recurring_Donation__c rd = RD_RecurringDonations_TEST.buildRecurringDonationYearlyInstallment(null);
        rd.npe03__Installments__c = 10;
        rd.npe03__Organization__c = getAccount().id;
        rd.npe03__Recurring_Donation_Campaign__c = camp.id;
        rd.npe03__Open_Ended_Status__c = RD_Constants.OPEN_ENDED_STATUS_OPEN;
        rd.npe03__Next_Payment_Date__c = TODAY;
        insert rd;

        List<opportunity> queryopp = [SELECT Id, Recurring_Donation_Installment_Number__c FROM Opportunity ORDER BY CloseDate];

        for (Integer i=0; i<queryopp.size(); i++) {
            System.assertEquals(i+1,queryopp[i].Recurring_Donation_Installment_Number__c, 'Recurring Donation opportunities should have the correct installment number.');
            queryopp[i].Recurring_Donation_Installment_Number__c = null;
        }
        update queryopp;

        queryopp = [SELECT Id, Recurring_Donation_Installment_Number__c FROM Opportunity ORDER BY CloseDate];

        for (opportunity opp : queryopp) {
            System.assertEquals(null, opp.Recurring_Donation_Installment_Number__c, 'Recurring Donation opportunities shouldn\'t have an installment number.');
        }

        Test.startTest();
        Test.testInstall(new STG_InstallScript(), null, true);
        Test.stopTest();

        queryopp = [SELECT Id, Recurring_Donation_Installment_Number__c FROM Opportunity ORDER BY CloseDate];

        for (Integer i=0; i<queryopp.size(); i++) {
            System.assertEquals(i+1,queryopp[i].Recurring_Donation_Installment_Number__c, 'Recurring Donation opportunities should have the correct installment number.');
            queryopp[i].Recurring_Donation_Installment_Number__c = null;
        }
    }

    @isTest
    private static void testOpenEndedMonthlyEndDates_28th() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            npe03__Opportunity_Forecast_Months__c = NUM_INSTALLMENTS,
            npe03__Maximum_Donations__c = 50
        ));

        Contact c = buildContact(null);
        insert c;
        Account a = [SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :c.Id) LIMIT 1];

        // This should create Installments with a date of the 28th.
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withName('test28th')
            .withContact(c.Id)
            .withAmount(100)
            .withInstallmentPeriodMonthly()
            .withDateEstablished(TODAY.toStartOfMonth().addDays(27))
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<Opportunity> listOpp28th = [SELECT Id, CloseDate FROM Opportunity WHERE npe03__Recurring_Donation__r.Name = 'test28th' order by CloseDate];
        System.assertEquals(NUM_INSTALLMENTS, listOpp28th.size(), 'There should be 12 Opps with a Close Date of the 28th');
        for (Opportunity opp : listOpp28th) {
            System.assertEquals(28, opp.CloseDate.Day(), 'The Opp.CloseDate.Day should be the 28th');
        }
    }

    @isTest
    private static void testOpenEndedMonthlyEndDates_30th() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                npe03__Opportunity_Forecast_Months__c = NUM_INSTALLMENTS,
                npe03__Maximum_Donations__c = 50
            ));

        Contact c = buildContact(null);
        insert c;
        Account a = [SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :c.Id) LIMIT 1];

        // Find a start date for a month that has 30 days and calculate an offset from the current month
        // to use in the asserts below to account for the fact that Opp installments are only created from
        // the current month forward even if the start date is months in the future. Theoretically could just
        // subtract a day from 10/31 to get 10/31 (for example), but that won't work in February. As a result
        // it's better to just skip ahead months to find one with exactly 30 days and then use that offset
        // for the asserts.
        Date startDt = TODAY.toStartOfMonth().addMonths(1).addDays(-1);
        Integer opps30thMonthOffset = 0;
        while (startDt.day() != 30) {
            startDt = startDt.addMonths(2).toStartOfMonth().addDays(-1);
            opps30thMonthOffset++;
        }

        // This should create Installments with a date of the 28th.
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withName('test30th')
            .withContact(c.Id)
            .withAmount(100)
            .withInstallmentPeriodMonthly()
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .withDateEstablished(startDt)
            .withNextPaymentDate(null)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        // All Installments should be on the 30th except for February, which should be on the last day of the month
        List<Opportunity> listOpp30th = [SELECT Id, CloseDate FROM Opportunity WHERE npe03__Recurring_Donation__r.Name = 'test30th' order by CloseDate];
        System.assertEquals(12-opps30thMonthOffset, listOpp30th.size(),
            'There should be ' + (12-opps30thMonthOffset) + ' Opps with a Close Date of the 30th');

        for (Opportunity opp : listOpp30th) {
            if (opp.CloseDate.Month() != 2) {
                System.assertEquals(30, opp.CloseDate.Day(), 'The Opp.CloseDate.Day should be the 30th');
            } else {
                System.assertEquals(Date.DaysInMonth(opp.CloseDate.Year(), 2), opp.CloseDate.Day(),
                    'The installment close date for February should be on the last day of February for the year');
            }
        }
    }

    @isTest
    private static void testOpenEndedMonthlyEndDates_EOM() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                npe03__Opportunity_Forecast_Months__c = NUM_INSTALLMENTS,
                npe03__Maximum_Donations__c = 50
            ));

        Contact c = buildContact(null);
        insert c;
        Account a = [SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Id = :c.Id) LIMIT 1];

        // This should create Installments with a date of the 28th.
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withName('testEndOfMonth')
            .withContact(c.Id)
            .withAmount(100)
            .withInstallmentPeriodMonthly()
            .withDateEstablished(TODAY.toStartOfMonth().addDays(12))    // this shouldn't matter
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .withAlwaysUseLastDayOfMonth(true)
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        // All Installments should be on the last day of the month
        List<Opportunity> listOppEnd = [SELECT Id, CloseDate FROM Opportunity WHERE npe03__Recurring_Donation__r.Name = 'testEndOfMonth' order by CloseDate];
        System.assertEquals(NUM_INSTALLMENTS, listOppEnd.size(), 'There should be 12 Opps with a close date of the last day of the month');
        for (Opportunity opp : listOppEnd) {
            System.assertEquals(Date.DaysInMonth(opp.CloseDate.Year(), opp.CloseDate.Month()), opp.CloseDate.Day(),
                    'The Opps Close Date should be the very last day of the month: ' + opp.CloseDate);
        }
    }

    @isTest
    private static void adjustDayOfMonthReturnsDateBasedOnNextDonationDay() {
        Date nextDonationDate = Date.newInstance(TODAY.year(), 1, 31);
        Date dateEstablished = nextDonationDate.toStartOfMonth();
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 28);
        Integer expectedDay;
        Integer actualDay;

        npe03__Recurring_Donation__c recurringDonation = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withNextPaymentDate(nextDonationDate)
            .withDateEstablished(dateEstablished)
            .withInstallmentPeriodMonthly()
            .withAlwaysUseLastDayOfMonth(false)
            .build();

        for (Integer i = 0; i < 3; i++) {
            recurringDonation.npe03__Next_Payment_Date__c = nextDonationDate.addDays(-i);
            expectedDay = nextDonationDate.addDays(-i).day();
            actualDay = RD_RecurringDonations.adjustDayOfMonth(installmentDate, recurringDonation).day();
            System.assertEquals(expectedDay, actualDay);
        }
    }

    @isTest
    private static void adjustDayOfMonthReturnsSameDateWhenNotEndOfMonthDay() {
        Date nextDonationDate = Date.newInstance(TODAY.year(), 1, 31);
        Date dateEstablished = nextDonationDate.toStartOfMonth();
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 27);
        Date expectedDate = installmentDate;
        Date actualDate;

        npe03__Recurring_Donation__c recurringDonation = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withNextPaymentDate(nextDonationDate)
            .withDateEstablished(dateEstablished)
            .withInstallmentPeriodMonthly()
            .withAlwaysUseLastDayOfMonth(false)
            .build();

        actualDate = RD_RecurringDonations.adjustDayOfMonth(installmentDate, recurringDonation);
        System.assertEquals(expectedDate, actualDate);
    }

    @isTest
    private static void adjustDayOfMonthReturnsDateBasedOnEstablishedDay() {
        Date dateEstablished = Date.newInstance(TODAY.year(), 1, 31);
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 28);
        Integer expectedDay;
        Integer actualDay;

        npe03__Recurring_Donation__c recurringDonation = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withNextPaymentDate(null)
            .withDateEstablished(dateEstablished)
            .withInstallmentPeriodMonthly()
            .withAlwaysUseLastDayOfMonth(false)
            .build();

        for (Integer i = 0; i < 3; i++) {
            expectedDay = dateEstablished.day();
            actualDay = RD_RecurringDonations.adjustDayOfMonth(installmentDate.addDays(i), recurringDonation).day();
            System.assertEquals(expectedDay, actualDay);
        }
    }

    @isTest
    private static void adjustDayOfMonthReturnsSameDateWhenNextDonationNotEndOfMonth() {
        Date dateEstablished = Date.newInstance(TODAY.year(), 1, 11);
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 28);
        Date expectedDate;
        Date actualDate;

        npe03__Recurring_Donation__c recurringDonation = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withNextPaymentDate(dateEstablished)
            .withDateEstablished(dateEstablished)
            .withInstallmentPeriodMonthly()
            .withAlwaysUseLastDayOfMonth(false)
            .withDayOfMonth(null)
            .build();

        for (Integer i = 0; i < 3; i++) {
            expectedDate = installmentDate.addDays(i);
            actualDate = RD_RecurringDonations.adjustDayOfMonth(expectedDate, recurringDonation);
            System.assertEquals(expectedDate, actualDate);
        }
    }

    @isTest
    private static void adjustDayOfMonthReturnsEndOfMonthWhenAlwaysEndOfMonthIsSet() {
        Date nextDonationDate = Date.newInstance(TODAY.year(), 1, 30);
        Date dateEstablished = nextDonationDate.toStartOfMonth();
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 28);
        Integer expectedDay;
        Integer actualDay;

        npe03__Recurring_Donation__c recurringDonation = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withNextPaymentDate(nextDonationDate)
            .withDateEstablished(dateEstablished)
            .withInstallmentPeriodMonthly()
            .withAlwaysUseLastDayOfMonth(true)
            .withDayOfMonth('11')
            .build();

        expectedDay = Date.daysInMonth(installmentDate.year(), installmentDate.Month());
        actualDay = RD_RecurringDonations.adjustDayOfMonth(installmentDate, recurringDonation).day();
        System.assertEquals(expectedDay, actualDay);
    }

    @isTest
    private static void adjustDayOfMonthReturnsDayOfMonthSelected() {
        Date nextDonationDate = Date.newInstance(TODAY.year(), 1, 31);
        Date dateEstablished = nextDonationDate.toStartOfMonth();
        Date installmentDate = Date.newInstance(TODAY.year(), 3, 28);
        Integer expectedDay;
        Integer actualDay;

        npe03__Recurring_Donation__c recurringDonation = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withNextPaymentDate(nextDonationDate)
            .withDateEstablished(dateEstablished)
            .withInstallmentPeriodMonthly()
            .withAlwaysUseLastDayOfMonth(false)
            .withDayOfMonth('11')
            .build();

        expectedDay = Integer.valueOf(recurringDonation.Day_Of_Month__c);
        actualDay = RD_RecurringDonations.adjustDayOfMonth(installmentDate, recurringDonation).day();
        System.assertEquals(expectedDay, actualDay);

        recurringDonation.npe03__Next_Payment_Date__c = null;
        actualDay = RD_RecurringDonations.adjustDayOfMonth(installmentDate, recurringDonation).day();
        System.assertEquals(expectedDay, actualDay);
    }


    /*********************************************************************************************************
    * @description Verifies start date (first Opportunity Close Date)
    * is on the Day of Month date that is greater or equal to the Date Established.
    */
    @isTest
    private static void nextDonationDateIsGreaterOrEqualToDateEstablished() {
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withDateEstablished(Date.newInstance(2000, 11, 19)) //day is greater than Day of Month
            .withInstallmentPeriodMonthly()
            .withAlwaysUseLastDayOfMonth(false)
            .withDayOfMonth('15')
            .build();

        System.assertEquals(Date.newInstance(2000, 12, 15), RD_RecurringDonations.getStartDate(rd),
            'Expecting Next Donation Date to be greater than Date Established');

        rd.npe03__Date_Established__c = Date.newInstance(2000, 11, 14);//day is less than Day of Month

        System.assertEquals(Date.newInstance(2000, 11, 15), RD_RecurringDonations.getStartDate(rd),
            'Expecting Next Donation Date for the same month as Date Established');
    }

    /*********************************************************************************************************
    * @description Verifies calculated Next Donation Date based on the current
    * Next Donation Date, Date Established and Day of Month values
    */
    @isTest
    private static void nextDonationDateIsCalculatedBasedOnDayOfMonthAndCurrentNextDonationDate() {
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withDateEstablished(Date.newInstance(2000, 11, 19))
            .withNextPaymentDate(Date.newInstance(2000, 11, 21))
            .withInstallmentPeriodMonthly()
            .withAlwaysUseLastDayOfMonth(false)
            .withDayOfMonth('20') // Day of Month is in between Date Established and Next Donation Date
            .build();

        System.assertEquals(Date.newInstance(2000, 11, 20), RD_RecurringDonations.getStartDate(rd),
            'Expecting Next Donation Date in the same month as Next Donation Date');

        rd.Day_Of_Month__c = '23';//day is greater than Date Established and Next Donation Date days
        System.assertEquals(Date.newInstance(2000, 11, 23), RD_RecurringDonations.getStartDate(rd),
            'Expecting Next Donation Date for the same month as Next Donation Date');

        rd.Day_Of_Month__c = '2';//day is less than Date Established and Next Donation Date days
        System.assertEquals(Date.newInstance(2000, 12, 2), RD_RecurringDonations.getStartDate(rd),
            'Expecting Next Donation Date greater than Date Established');

        rd.npe03__Next_Payment_Date__c = Date.newInstance(2000, 10, 30);//date is in a month before Date Established
        System.assertEquals(Date.newInstance(2000, 12, 2), RD_RecurringDonations.getStartDate(rd),
            'Expecting Next Donation Date greater than Date Established');

        rd.npe03__Date_Established__c = Date.newInstance(2000, 10, 19);
        rd.npe03__Next_Payment_Date__c = Date.newInstance(2000, 9, 21);
        rd.Day_Of_Month__c = '31';
        System.assertEquals(Date.newInstance(2000, 10, 31), RD_RecurringDonations.getStartDate(rd),
            'Expecting end of month based on Day of Month and Date Established');

    }

    /*********************************************************************************************************
    * @description Verifies Close Date values on recurring donation Opportunities based on Day of Month value
    * that does not exist in the current Next Donation Date month
    */
    @isTest
    private static void closeDateIsCalculatedBasedOnDayOfMonthStartDateEndOfMonth() {
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withDateEstablished(Date.newInstance(2000, 9, 19))
            .withNextPaymentDate(Date.newInstance(2000, 9, 21))
            .withInstallmentPeriodMonthly()
            .withAlwaysUseLastDayOfMonth(false)
            .withDayOfMonth('31') // Day of Month that does not exist in the current Next Donation Date
            .build();

        Date expectedStartDate = Date.newInstance(2000, 9, 30);
        System.assertEquals(expectedStartDate, RD_RecurringDonations.getStartDate(rd),
            'Start Date is end of the same month as Next Donation Date, greater than Date Established');

        Date nextDate = RD_RecurringDonations.getNextDate(expectedStartDate, rd);
        System.assertEquals(Date.newInstance(2000, 10, 31), nextDate, 'Expecting next month Day of Month date');

        nextDate = RD_RecurringDonations.getNextDate(nextDate, rd);
        System.assertEquals(Date.newInstance(2000, 11, 30), nextDate, 'Expecting next month end of month date');

        nextDate = RD_RecurringDonations.getNextDate(nextDate, rd);
        System.assertEquals(Date.newInstance(2000, 12, 31), nextDate, 'Expecting next month Day of Month date');
    }

    /*********************************************************************************************************
    * @description Verifies Close Date values on recurring donation Opportunities based on Day of Month value
    * that exists in the current Next Donation Date month
    */
    @isTest
    private static void closeDateIsCalculatedBasedOnDayOfMonth() {
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withDateEstablished(Date.newInstance(2000, 7, 19))
            .withNextPaymentDate(Date.newInstance(2000, 7, 21))
            .withInstallmentPeriodMonthly()
            .withAlwaysUseLastDayOfMonth(false)
            .withDayOfMonth('31') // Day of Month exists in the current Next Donation Date
            .build();

        Date expectedStartDate = Date.newInstance(2000, 7, 31);
        System.assertEquals(expectedStartDate, RD_RecurringDonations.getStartDate(rd),
            'Start Date is Day of Month date in the same month as Next Donation Date and greater than Date Established');

        Date nextDate = RD_RecurringDonations.getNextDate(expectedStartDate, rd);
        System.assertEquals(Date.newInstance(2000, 8, 31), nextDate, 'Expecting next month Day of Month date');

        nextDate = RD_RecurringDonations.getNextDate(nextDate, rd);
        System.assertEquals(Date.newInstance(2000, 9, 30), nextDate, 'Expecting next month end of month date');

        nextDate = RD_RecurringDonations.getNextDate(nextDate, rd);
        System.assertEquals(Date.newInstance(2000, 10, 31), nextDate, 'Expecting next month Day of Month date');
    }

    @isTest
    private static void testOrphanedRd() {
        Contact con = new Contact(LastName='test');
        insert con;

        List<npe03__Recurring_Donation__c> rdList = new List<npe03__Recurring_Donation__c>();
        rdList.add(new npe03__Recurring_Donation__c(
            Name='Orphan',
            npe03__Open_Ended_Status__c= Label.npe03.RecurringDonationOpenStatus
        ));
        rdList.add(new npe03__Recurring_Donation__c(
            Name='Orphan2',
            npe03__Open_Ended_Status__c= Label.npe03.RecurringDonationOpenStatus
        ));
        rdList.add(TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withContact(con.Id)
            .withAmount(100)
            .withPlannedInstallments(2)
            .withInstallmentPeriodMonthly()
            .withDateEstablished(DEFAULT_ESTABLISHED_DATE)
            .withScheduleTypeMultiplyValue()
            .withOpenEndedStatusOpen()
            .withNextPaymentDate(TODAY)
            .build()
        );

        //disable triggers to skip opp creation and validation, which would prevent the insertion of the orphan
        //orphaned RDs may exist due to a historical lack of RD cascade deletion when contacts and accounts were deleted
        TDTM_TriggerHandler.disableTDTM = true;
        insert rdList;
        TDTM_TriggerHandler.disableTDTM = false;

        Test.startTest();
        Database.executeBatch(new RD_RecurringDonations_BATCH(), 10);
        Test.stopTest();

        List<Opportunity> rdOpps = [SELECT Id FROM Opportunity WHERE npe03__Recurring_Donation__c IN :rdList];
        System.assertEquals(NUM_INSTALLMENTS,rdOpps.size(), 'Twelve opps should be created for the well formed recurring donation.');

    }


    //========================================================================
    // Test that the Open Recurring Donation's npe03__Paid_Amount__c is updated
    // when a ClosedWon Opportunity is associate with the open Recurring Donation
    //========================================================================
    @isTest
    private static void updateOpenEndedRecurringDonationsPaidAmountWithAClosedWonOpp() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        Account a = getAccount();

        //--------------------------------
        // Setup the Recurring Donation
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withPlannedInstallments(0)
            .withContact(getContact().Id)
            .withAmount(100)
            .withDateEstablished(DEFAULT_ESTABLISHED_DATE)
            .withOpenEndedStatusOpen()
            .withNextPaymentDate(TODAY.toStartOfMonth())
            .withOwnerId()
            .build();
        insert rd;

        //--------------------------------
        // Setup the First Opportunity
        Opportunity o = new Opportunity();
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        o.Amount = 50;
        o.AccountId = a.Id;
        o.Name = 'test';
        o.npe03__Recurring_Donation__c = rd.Id;

        //--------------------------------
        // Setup the Second Opportunity
        Opportunity oppty2 = new Opportunity();
        oppty2.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        oppty2.CloseDate = TODAY;
        oppty2.Amount = 100;
        oppty2.AccountId = a.Id;
        oppty2.Name = 'test2';
        oppty2.npe03__Recurring_Donation__c = null;

        //--------------------------------
        // Insert the two Opportunities
        Test.startTest();
        insert o;
        insert oppty2;

        //--------------------------------
        // Confirm that only the First Opportunity has updated the Recurring Donation's npe03__Paid_Amount__c
        rd = rdGateway.getRecord(rd.id);
        System.assertEquals(50, rd.npe03__Paid_Amount__c);

        //--------------------------------
        // Update the Second Opportunity's Recurring Donation field
        oppty2.npe03__Recurring_Donation__c = rd.Id;
        update oppty2;
        Test.stopTest();

        //--------------------------------
        // Confirm that the Second Opportunity has updated the Recurring Donation's npe03__Paid_Amount__c
        rd = rdGateway.getRecord(rd.id);
        System.assertEquals(150, rd.npe03__Paid_Amount__c);
    }


    //========================================================================
    // Test that changing a ClosedWon Opportunity from one Recurring Donation
    // to another Recurring Donation updates the npe03__Paid_Amount__c value
    // for both Recurring Donations accordingly
    //========================================================================
    @isTest
    private static void updateMultipleOpenEndedRecurringDonationsPaidAmountWithAClosedWonOpp() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        Account a = getAccount();

        //--------------------------------
        // Setup the First Recurring Donation
        TEST_RecurringDonationBuilder rdBuilder = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withPlannedInstallments(0)
            .withContact(getContact().Id)
            .withAmount(100)
            .withDateEstablished(DEFAULT_ESTABLISHED_DATE)
            .withOpenEndedStatusOpen()
            .withNextPaymentDate(TODAY.toStartOfMonth())
            .withOwnerId();

        npe03__Recurring_Donation__c rd = rdBuilder.build();
        insert rd;

        //--------------------------------
        // Setup the Second Recurring Donation
        npe03__Recurring_Donation__c r2 = rdBuilder.build();
        insert r2;

        //--------------------------------
        // Setup the Opportunity
        Opportunity o = new Opportunity();
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        o.Amount = 50;
        o.AccountId = a.Id;
        o.Name = 'test';
        o.npe03__Recurring_Donation__c = rd.Id;

        //--------------------------------
        // Insert the Opportunity
        Test.startTest();
        insert o;

        //--------------------------------
        // Confirm the Opportunity has updated only the Recurring Donation's (rd) npe03__Paid_Amount__c
        rd = rdGateway.getRecord(rd.id);
        System.assertEquals(50, rd.npe03__Paid_Amount__c);

        r2 = rdGateway.getRecord(r2.id);
        System.assertEquals(null, r2.npe03__Paid_Amount__c);

        //--------------------------------
        // Update the Opportunity's Recurring Donation field
        o.npe03__Recurring_Donation__c = r2.Id;
        update o;
        Test.stopTest();

        //--------------------------------
        // Confirm the Opportunity has updated the npe03__Paid_Amount__c for both Recurring Donations (rd & r2)
        rd = rdGateway.getRecord(rd.id);
        System.assertEquals(null, rd.npe03__Paid_Amount__c);

        r2 = rdGateway.getRecord(r2.id);
        System.assertEquals(50, r2.npe03__Paid_Amount__c);
    }


    //========================================================================
    // Test that removing a ClosedWon Opportunity from one Recurring Donation
    // updates the npe03__Paid_Amount__c value
    //========================================================================
    @isTest
    private static void updateOpenEndedRecurringDonationsPaidAmountByRemovingAClosedWonOpp() {
        RD_RecurringDonations_TEST.createRdSettingsWithYearForecast();

        Account a = getAccount();

        //--------------------------------
        // Setup the First Recurring Donation
        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withPlannedInstallments(0)
            .withContact(getContact().Id)
            .withAmount(100)
            .withDateEstablished(DEFAULT_ESTABLISHED_DATE)
            .withOpenEndedStatusOpen()
            .withNextPaymentDate(TODAY.toStartOfMonth())
            .withOwnerId()
            .build();
        insert rd;

        //--------------------------------
        // Setup the Opportunity
        Opportunity o = new Opportunity();
        o.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        o.CloseDate = TODAY;
        o.Amount = 50;
        o.AccountId = a.Id;
        o.Name = 'test';
        o.npe03__Recurring_Donation__c = rd.Id;

        //--------------------------------
        // Insert the Opportunity
        Test.startTest();
        insert o;

        //--------------------------------
        // Confirm the Opportunity has updated the Recurring Donation's (rd) npe03__Paid_Amount__c
        rd = rdGateway.getRecord(rd.id);
        System.assertEquals(50, rd.npe03__Paid_Amount__c);

        //--------------------------------
        // Remove the Opportunity's Recurring Donation value by setting the field to null
        o.npe03__Recurring_Donation__c = null;
        update o;
        Test.stopTest();

        //--------------------------------
        // Confirm the Opportunity has updated the npe03__Paid_Amount__c for both Recurring Donation (rd)
        rd = rdGateway.getRecord(rd.id);
        System.assertEquals(null, rd.npe03__Paid_Amount__c);
    }

    /**
    * @description Ensures that the DisableRollupsWhenCreatingInstallments__c flag is not used to disable
    * legacy rollups in the RD Batch Job even if the field is set to True.
    */
    @IsTest
    private static void shouldRecalcRollupsOnRdAfterBatchJobWithLegacyRollups() {

        configureForBatchJobWithRollupDisableTests(false, true);
        npe03__Recurring_Donation__c rd = createTestDataForRollupRecalcTest();
        System.assertEquals(null, rd.npe03__Next_Payment_Date__c, 'Next Payment Date should be null');

        Database.executeBatch(new RD_RecurringDonations_BATCH(), 10);
        Test.stopTest();

        System.assertEquals(NUM_INSTALLMENTS, [SELECT Count() FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id],
            'There should be ' + NUM_INSTALLMENTS + ' installment Opportunities created for this RD');

        rd = rdGateway.getRecord(rd.Id);
        System.assertNotEquals(null, rd.npe03__Next_Payment_Date__c, 'Next Payment Date should NOT be null');
    }

    /**
    * @description Ensures that when the DisableRollupsWhenCreatingInstallments__c flag is NOT set
    * and CRLP is enabled, the rollups do execute properly when the RD Batch Job is run
    */
    @IsTest
    private static void shouldRecalcRollupsOnRdAfterBatchJobWithCRLP() {

        configureForBatchJobWithRollupDisableTests(true, false);
        npe03__Recurring_Donation__c rd = createTestDataForRollupRecalcTest();
        System.assertEquals(null, rd.npe03__Next_Payment_Date__c, 'Next Payment Date should be null');

        Database.executeBatch(new RD_RecurringDonations_BATCH(), 10);
        Test.stopTest();

        System.assertEquals(NUM_INSTALLMENTS, [SELECT Count() FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id],
            'There should be ' + NUM_INSTALLMENTS + ' installment Opportunities created for this RD');

        rd = rdGateway.getRecord(rd.Id);
        System.assertNotEquals(null, rd.npe03__Next_Payment_Date__c, 'Next Payment Date should NOT be null');
    }

    /**
    * @description Ensures that when the DisableRollupsWhenCreatingInstallments__c flag IS set
    * and CRLP is enabled, the rollups do NOT execute when the RD Batch Job is run
    */
    @IsTest
    private static void shouldNotRecalcRollupsOnRdAfterBatchJobWithCRLP() {

        configureForBatchJobWithRollupDisableTests(true, true);
        npe03__Recurring_Donation__c rd = createTestDataForRollupRecalcTest();
        System.assertEquals(null, rd.npe03__Next_Payment_Date__c, 'Next Payment Date should be null');

        Database.executeBatch(new RD_RecurringDonations_BATCH(), 10);
        Test.stopTest();

        System.assertEquals(NUM_INSTALLMENTS, [SELECT Count() FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id],
            'There should be ' + NUM_INSTALLMENTS + ' installment Opportunities created for this RD');

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(null, rd.npe03__Next_Payment_Date__c, 'Next Payment Date should be null');
    }

    // Helpers
    ////////////

    /**
    * @description Configure Settings for validating the behavior of the DisableRollupsWhenCreatingInstallments__c
    * setting in the RD Batch Job. Also mocks the CRLP settings for Legacy Recurring Donations, and
    * disables the internal setting that would normally prevent a null field from being updated to a zero
    * value during rollups. This is used to tell that rollups did or did not run in the batch job.
    */
    private static void configureForBatchJobWithRollupDisableTests(Boolean isCRLP, Boolean isDisableRollups) {

        if (isCRLP) {
            UTIL_CustomSettingsFacade.getRollupSettingsForTests(new Customizable_Rollup_Settings__c (
                Customizable_Rollups_Enabled__c = true
            ));
            CMT_UnitTestData_TEST.mockRecurringDonationRollupCMTValues();
        }

        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(new npe03__Recurring_Donations_Settings__c(
            DisableRollupsWhenCreatingInstallments__c = isDisableRollups,
            npe03__Maximum_Donations__c = 50,
            npe03__Opportunity_Forecast_Months__c = NUM_INSTALLMENTS,
            npe03__Open_Opportunity_Behavior__c = RD_RecurringDonations.RecurringDonationCloseOptions.Mark_Opportunities_Closed_Lost.name(),
            npe03__Add_Campaign_to_All_Opportunites__c = true
        ));

    }

    /**
    * @description Create a single Legacy Recurring Donation to use for validating
    * the behavior of the DisableRollupsWhenCreatingInstallments__c setting in the RD Batch Job.
    * Triggers are disabled to prevent an installment opp from being created since that is what we want to
    * test in the batch job logic.
    * @return Created Recurring Donation Record
    */
    private static npe03__Recurring_Donation__c createTestDataForRollupRecalcTest() {
        Contact c = UTIL_UnitTestData_TEST.getContact();
        insert c;

        npe03__Recurring_Donation__c rd = TEST_RecurringDonationBuilder.constructLegacyBuilder()
            .withContact(c.Id)
            .withAmount(100)
            .withDateEstablished(Date.today())
            .withInstallmentPeriodMonthly()
            .withAlwaysUseLastDayOfMonth(true)
            .withOpenEndedStatusOpen()
            .withOwnerId()
            .withPlannedInstallments(null)
            .build();
        rd.npe03__Installments__c = null;   // force this to null because the default is 1
        Test.startTest();

        TDTM_TriggerHandler.disableTDTM = true;
        insert rd;
        TDTM_TriggerHandler.disableTDTM = false;

        System.assertEquals(0, [SELECT Count() FROM Opportunity WHERE npe03__Recurring_Donation__c = :rd.Id],
            'There should be no installment Opportunities created for this RD');

        return rdGateway.getRecord(rd.Id);
    }

    /*******************************************************************************************************
    * @description Builds an account record with default values
    * @return Account
    */
    private static Account buildAccount() {
        return new Account(Name = 'test Individual');
    }

    /*******************************************************************************************************
    * @description Builds a contact record with default values
    * @param accId Id of the account to assign to the contact
    * @return Contact
    */
    private static Contact buildContact(Id accId) {
        Contact c = UTIL_UnitTestData_TEST.getContact();
        c.AccountId = accId;

        return c;
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

    /****
    * @description Returns Account record
    * @return Account
    */
    private static Account getAccount() {
        return [
            SELECT Id, Name
            FROM Account
            LIMIT 1
        ];
    }


}
