/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @group Recurring Donations
* @description All logic specific to Enhanced Recurring Donation Change Logs
*
*/
@IsTest
public with sharing class RD2_ChangeLogService_TEST {
    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();

    private static final Date START_DATE = Date.newInstance(2019, 9, 15);
    private static final Integer MONTHS_TO_DEC = START_DATE.monthsBetween(Date.newInstance(2019, 12, 15));
    private static final Integer MONTHS_TO_YEAR_END = START_DATE.monthsBetween(Date.newInstance(2020, 1, 1));
    private static final String PAYMENT_CREDIT_CARD = 'Credit Card';
    private static final String PAYMENT_CHECK = 'Check';
    private static final Decimal RD_AMOUNT = 100;
    private static final Decimal RD_NEW_AMOUNT = 200;
    private static final String RD_PERIOD = RD2_Constants.INSTALLMENT_PERIOD_MONTHLY;
    private static final String RD_PERIOD_WEEKLY = RD2_Constants.INSTALLMENT_PERIOD_WEEKLY;
    private static final String RD_PERIOD_FIRST_AND_FIFTEENTH = RD2_Constants.INSTALLMENT_PERIOD_FIRST_AND_FIFTEENTH;
    private static final Decimal RD_NEW_FREQUENCY = 3;
    private static final String CHANGE_TYPE_CUSTOM = 'Custom Change Type';

    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation without Enabling Change Log 
     * does not create any Change Log records
     */
    @IsTest
    private static void shouldNotCreateChangeLogWhenSettingIsNotEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .build();
        rd.ChangeType__c = RD2_Constants.CHANGE_TYPE_UPGRADE;

        insert rd;

        List<RecurringDonationChangeLog__c> changeLogs = getRecurringDonationChangeLog(rd.Id);
        System.assertEquals(0, changeLogs.size(), 'There should be no Change Log after RD insert');

        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.ChangeType__c = RD2_Constants.CHANGE_TYPE_DOWNGRADE;

        Test.startTest();
        update rd;
        Test.stopTest();

        changeLogs = getRecurringDonationChangeLog(rd.Id);
        System.assertEquals(0, changeLogs.size(), 'There should be no Change Log with the Setting not Enabled');

        // Make sure that the Change Type is cleared, even if it wasn't used
        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(null, rd.ChangeType__c, 'The Change Type should be null');
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation's Change Type after
     *  Enabling Change Log does not create any Change Log records, and the Change Type is reset
     */
    @IsTest
    private static void shouldClearChangeTypeAndNotCreateChangeLogWhenSettingIsEnabled() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .build();

        insert rd;

        List<RecurringDonationChangeLog__c> changeLogs = getRecurringDonationChangeLog(rd.Id);
        System.assertEquals(0, changeLogs.size(), 'There should be no Change Log after RD insert');

        rd.ChangeType__c = CHANGE_TYPE_CUSTOM;

        Test.startTest();
        update rd;
        Test.stopTest();

        changeLogs = getRecurringDonationChangeLog(rd.Id);
        System.assertEquals(0, changeLogs.size(), 'There should be no Change Log with the Setting not Enabled');

        // Make sure that the Change Type is cleared, even if it wasn't used
        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(null, rd.ChangeType__c, 'The Change Type should be null');
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation Amount
     * with Change Log Enabled does create Change Log records
     */
    @IsTest
    private static void shouldCreateChangeLogWhenAmountChanges() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        insert rd;

        List<RecurringDonationChangeLog__c> changeLogs = getRecurringDonationChangeLog(rd.Id);
        System.assertEquals(0, changeLogs.size(), 'There should be no Change Log after RD insert');
        
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        
        Test.startTest();
        update rd;
        Test.stopTest();

        changeLogs = getRecurringDonationChangeLog(rd.Id);
        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        System.assertEquals(RD_NEW_AMOUNT, changeLog.NewAmount__c, 'New Amount should be ' + RD_NEW_AMOUNT);
        System.assertEquals(RD_AMOUNT, changeLog.PreviousAmount__c, 'Previous Amount should be ' + RD_AMOUNT);
        System.assertEquals(RD_NEW_AMOUNT * 12, changeLog.NewAnnualValue__c, 'New Annual Value should be ' + RD_NEW_AMOUNT * 12);
        System.assertEquals(RD_AMOUNT * 12, changeLog.PreviousAnnualValue__c, 'Previous Annual Value should be ' + RD_AMOUNT * 12);
        System.assertEquals(RD2_Constants.CHANGE_TYPE_UPGRADE, changeLog.ChangeType__c, 
            'The Change Type should be ' + RD2_Constants.CHANGE_TYPE_UPGRADE);
    }

    /**
     * @description Verifies that creating and updating multiple Recurring Donations
     * with Change Log Enabled does create Change Log records
     */
    @IsTest
    private static void shouldCreateChangeLogWhenMultipleRdsAreUpdated() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        npe03__Recurring_Donation__c rd2 = rd.clone();

        List<npe03__Recurring_Donation__c> rdList = new List<npe03__Recurring_Donation__c>{
            rd, rd2
        };
        insert rdList;

        rdList[0].npe03__Amount__c = RD_NEW_AMOUNT;
        rdList[1].Status__c = RD2_Constants.STATUS_LAPSED;
        rdList[1].ChangeType__c = RD2_Constants.CHANGE_TYPE_DOWNGRADE;

        Test.startTest();
        update rdList;
        Test.stopTest();

        // Check first change
        List<RecurringDonationChangeLog__c> changeLogs = getRecurringDonationChangeLog(rd.Id);
        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        System.assertEquals(RD_NEW_AMOUNT, changeLog.NewAmount__c, 'New Amount should be ' + RD_NEW_AMOUNT);
        System.assertEquals(RD_AMOUNT, changeLog.PreviousAmount__c, 'Previous Amount should be ' + RD_AMOUNT);
        System.assertEquals(RD_NEW_AMOUNT * 12, changeLog.NewAnnualValue__c, 'New Annual Value should be ' + RD_NEW_AMOUNT * 12);
        System.assertEquals(RD_AMOUNT * 12, changeLog.PreviousAnnualValue__c, 'Previous Annual Value should be ' + RD_AMOUNT * 12);
        System.assertEquals(RD2_Constants.CHANGE_TYPE_UPGRADE, changeLog.ChangeType__c, 
            'The Change Type should be ' + RD2_Constants.CHANGE_TYPE_UPGRADE);

        // Check second change
        Id rd2Id = rd2.Id;
        changeLogs = getRecurringDonationChangeLog(rd2Id);
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        RecurringDonationChangeLog__c changeLog2 = changeLogs[0];
        System.assertEquals(RD2_Constants.STATUS_LAPSED, changeLog2.NewStatus__c, 
            'New Status should be ' + RD2_Constants.STATUS_LAPSED);
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, changeLog2.PreviousStatus__c, 
            'Previous Status should be ' + RD2_Constants.STATUS_ACTIVE);
        System.assertEquals(RD2_Constants.CHANGE_TYPE_DOWNGRADE, changeLog2.ChangeType__c, 
            'The Change Type should be ' + RD2_Constants.CHANGE_TYPE_DOWNGRADE);

        rd2 = rdGateway.getRecord(rd2Id);
        System.assertEquals(null, rd2.ChangeType__c, 'The Change Type should be null');
    }

    /**
     * @description Verifies that creating and updating multiple Recurring Donations
     * with Change Log Enabled does create Change Log records
     */
    @IsTest
    private static void shouldCreateChangeLogOnGoodRDWhen1RDUpdateFail() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c goodRd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        npe03__Recurring_Donation__c badRd = goodRd.clone();

        List<npe03__Recurring_Donation__c> rdList = new List<npe03__Recurring_Donation__c>{
            goodRd, badRd
        };
        insert rdList;

        rdList[0].npe03__Amount__c = RD_NEW_AMOUNT;
        rdList[1].npe03__Amount__c = 0;

        Test.startTest();
        Database.update(rdList, false);
        Test.stopTest();

        // Check first change
        List<RecurringDonationChangeLog__c> changeLogs = getRecurringDonationChangeLog(goodRd.Id);
        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        System.assertEquals(RD_NEW_AMOUNT, changeLog.NewAmount__c, 'New Amount should be ' + RD_NEW_AMOUNT);
        System.assertEquals(RD_AMOUNT, changeLog.PreviousAmount__c, 'Previous Amount should be ' + RD_AMOUNT);
        System.assertEquals(RD_NEW_AMOUNT * 12, changeLog.NewAnnualValue__c, 'New Annual Value should be ' + RD_NEW_AMOUNT * 12);
        System.assertEquals(RD_AMOUNT * 12, changeLog.PreviousAnnualValue__c, 'Previous Annual Value should be ' + RD_AMOUNT * 12);
        System.assertEquals(RD2_Constants.CHANGE_TYPE_UPGRADE, changeLog.ChangeType__c, 
            'The Change Type should be ' + RD2_Constants.CHANGE_TYPE_UPGRADE);

        System.assertEquals(0, getRecurringDonationChangeLog(badRd.Id)?.size(),
            'There should be no Change Log created for the failed RD');
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation Period
     * with Change Log Enabled does create Change Log records with Change Types
     */
    @IsTest
    private static void shouldCreateChangeLogDowngradeWhenPeriodDecreases() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .withInstallmentPeriodWeekly()
            .build();

        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        rdUpdate.npe03__Installment_Period__c = RD_PERIOD_FIRST_AND_FIFTEENTH;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();
        System.assertEquals(1, changeLogs.size(), 'There should be no Change Log after RD insert');

        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        System.assertEquals(RD_PERIOD_FIRST_AND_FIFTEENTH, changeLog.NewInstallmentPeriod__c, 
            'New Period should be ' + RD_PERIOD_FIRST_AND_FIFTEENTH);
        System.assertEquals(RD_PERIOD_WEEKLY, changeLog.PreviousInstallmentPeriod__c, 
            'Previous Period should be ' + RD_PERIOD);
        System.assertEquals(RD_AMOUNT * 24, changeLog.NewAnnualValue__c, 
            'New Annual Value should be ' + RD_NEW_AMOUNT * 24);
        System.assertEquals(RD_AMOUNT * 52, changeLog.PreviousAnnualValue__c, 
            'Previous Annual Value should be ' + RD_AMOUNT * 52);
        System.assertEquals(RD2_Constants.CHANGE_TYPE_DOWNGRADE, changeLog.ChangeType__c, 
            'The Change Type should be ' + RD2_Constants.CHANGE_TYPE_DOWNGRADE);
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation Amount
     * with Change Log Enabled does create Change Log records with Change Types
     */
    @IsTest
    private static void shouldCreateChangeLogDowngradeWhenAmountLowers() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        Decimal lowerAmount = RD_AMOUNT - 10;
        rdUpdate.npe03__Amount__c = lowerAmount;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();
        System.assertEquals(1, changeLogs.size(), 'There should be no Change Log after RD insert');

        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        System.assertEquals(lowerAmount, changeLog.NewAmount__c, 'New Amount should be ' + lowerAmount);
        System.assertEquals(RD_AMOUNT, changeLog.PreviousAmount__c, 'Previous Amount should be ' + RD_AMOUNT);
        System.assertEquals(lowerAmount * 12, changeLog.NewAnnualValue__c, 'New Annual Value should be ' + RD_NEW_AMOUNT * 12);
        System.assertEquals(RD_AMOUNT * 12, changeLog.PreviousAnnualValue__c, 'Previous Annual Value should be ' + RD_AMOUNT * 12);
        System.assertEquals(RD2_Constants.CHANGE_TYPE_DOWNGRADE, changeLog.ChangeType__c, 
            'The Change Type should be ' + RD2_Constants.CHANGE_TYPE_DOWNGRADE);
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation's Day of Month
     *  with Change Log Enabled does not create Change Log records
     */
    @IsTest
    private static void shouldNotCreateChangeLogWhenDayOfMonthChanges() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        rdUpdate.Day_Of_Month__c = '10';

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();
        System.assertEquals(0, changeLogs.size(), 'There should be 0 Change Logs after the update');
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation's Type from
     * Open to Fixed creates a Change Log with the Type change and new Installment number
     */
    @IsTest
    private static void shouldCreateChangeLogWhenRecurringTypeChanges() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        rdUpdate.RecurringType__c = RD2_Constants.RECURRING_TYPE_FIXED;
        Decimal numberOfInstallments = 10;
        rdUpdate.npe03__Installments__c = numberOfInstallments;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(RD2_Constants.RECURRING_TYPE_FIXED, changeLog.NewRecurringType__c, 
            'New Recurring Type should be ' + RD2_Constants.RECURRING_TYPE_FIXED);
        System.assertEquals(RD2_Constants.RECURRING_TYPE_OPEN, changeLog.PreviousRecurringType__c, 
            'Previous Recurring Type should be ' + RD2_Constants.RECURRING_TYPE_OPEN);
        System.assertEquals(numberOfInstallments, changeLog.NewPlannedInstallments__c, 
            'New Planned Installments should be ' + numberOfInstallments);
        System.assertEquals(null, changeLog.PreviousPlannedInstallments__c, 
            'Previous Planned Installments should be null');
        System.assertEquals(null, changeLog.NewAnnualValue__c, 'New Annual Value should be null');
        Decimal previousAnnualValue = RD_AMOUNT * 12;
        System.assertEquals(previousAnnualValue, changeLog.PreviousAnnualValue__c, 
            'Previous Annual Value should be ' + previousAnnualValue);
        Decimal newTotalValue = RD_AMOUNT * 10;
        System.assertEquals(newTotalValue, changeLog.NewExpectedTotalValue__c, 
            'New Total Value should be ' + newTotalValue);
        System.assertEquals(null, changeLog.PreviousExpectedTotalValue__c, 'Previous Total Value should be null');
        System.assertEquals(null, changeLog.ChangeType__c, 'The Change Type should be null');
    }

    /**
     * @description Verifies that creating and updating a Fixed Recurring Donation's Amount
     * after Opportunities have been closed creates a Change Log with the correct Total Value
     */
    @IsTest
    private static void shouldCreateChangeLogWhenFixedAmountChangesAfterPayments() {
        configureRecurringDonationChangeLogEnabled();

        Integer originalInstallmentNumber = 10;
        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withRecurringTypeFixed()
            .withPlannedInstallments(originalInstallmentNumber)
            .build();

        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        rdUpdate.npe03__Amount__c = RD_NEW_AMOUNT;
        Integer paidInstallments = 2;
        rdUpdate.npe03__Total_Paid_Installments__c = paidInstallments;
        rdUpdate.npe03__Paid_Amount__c = paidInstallments * RD_AMOUNT;
        Decimal newInstallmentNumber = 5;
        rdUpdate.npe03__Installments__c = newInstallmentNumber;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        RecurringDonationChangeLog__c changeLog = changeLogs[0];

        System.assertEquals(newInstallmentNumber, changeLog.NewPlannedInstallments__c, 
            'New Planned Installments should be ' + newInstallmentNumber);
        System.assertEquals(originalInstallmentNumber, changeLog.PreviousPlannedInstallments__c, 
            'Previous Planned Installments should be ' + originalInstallmentNumber);

        System.assertEquals(null, changeLog.NewAnnualValue__c, 'New Annual Value should be null');        
        System.assertEquals(null, changeLog.PreviousAnnualValue__c, 'Previous Annual Value should be null');
        
        Decimal newTotalValue = (RD_AMOUNT * paidInstallments) 
            + (RD_NEW_AMOUNT * (newInstallmentNumber - paidInstallments));
        Decimal previousTotalValue = RD_AMOUNT * originalInstallmentNumber;
        System.assertEquals(previousTotalValue, changeLog.PreviousExpectedTotalValue__c, 
            'Previous Total Value should be ' + previousTotalValue);
        System.assertEquals(newTotalValue, changeLog.NewExpectedTotalValue__c, 
            'New Total Value should be ' + newTotalValue);
        System.assertEquals(RD2_Constants.CHANGE_TYPE_DOWNGRADE, changeLog.ChangeType__c, 
            'The Change Type should be ' + RD2_Constants.CHANGE_TYPE_DOWNGRADE);
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation Payment Method
     *  with Change Log Enabled does create Change Log records
     */
    @IsTest
    private static void shouldCreateChangeLogWhenPaymentMethodChanges() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();
        rdUpdate.ChangeType__c = CHANGE_TYPE_CUSTOM;
        rdUpdate.PaymentMethod__c = PAYMENT_CREDIT_CARD;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);
        rdEntity.storeAndClearChangeType();

        changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();
        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        System.assertEquals(PAYMENT_CREDIT_CARD, changeLog.NewPaymentMethod__c, 'New Payment Method should be ' + PAYMENT_CREDIT_CARD);
        System.assertEquals(PAYMENT_CHECK, changeLog.PreviousPaymentMethod__c, 'Previous Payment Method should be ' + PAYMENT_CHECK);
        System.assertEquals(CHANGE_TYPE_CUSTOM, changeLog.ChangeType__c, 'The Change Type should be ' + CHANGE_TYPE_CUSTOM);
        System.assertEquals(null, rd.ChangeType__c, 'The RD Change Type should be null');
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation with Change Log Enabled
     * creates a single Change Log record when multiple fields are changed
     */
    @IsTest
    private static void shouldCreateSingleChangeLogWhenMultipleFieldsChanges() {
        configureRecurringDonationChangeLogEnabled();

        Campaign campaign = new Campaign(Name = 'UpgradeCampaign', IsActive = true);
        insert campaign;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        rdUpdate.npe03__Recurring_Donation_Campaign__c = campaign.Id;
        rdUpdate.InstallmentFrequency__c = RD_NEW_FREQUENCY;
        rdUpdate.npe03__Installment_Period__c = RD_PERIOD_WEEKLY;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();
        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        System.assertEquals(RD_NEW_FREQUENCY, changeLog.NewInstallmentFrequency__c, 'New Installment Frequency should be ' + RD_NEW_FREQUENCY);
        System.assertEquals(1, changeLog.PreviousInstallmentFrequency__c, 'Previous Installment Frequency should be ' + 1);
        System.assertEquals(RD_PERIOD_WEEKLY, changeLog.NewInstallmentPeriod__c, 'New Installment Period should be ' + RD_PERIOD_WEEKLY);
        System.assertEquals(RD2_Constants.INSTALLMENT_PERIOD_MONTHLY, changeLog.PreviousInstallmentPeriod__c, 'Previous Installment Period should be ' + RD2_Constants.INSTALLMENT_PERIOD_MONTHLY);
        System.assertEquals(campaign.Id, changeLog.NewCampaign__c, 'New Campaign should be ' + campaign.Id);
        System.assertEquals(null, changeLog.PreviousCampaign__c, 'Previous Campaign should be ' + null);

        Decimal newYearlyValue = RD_AMOUNT * (RD2_Constants.PERIOD_TO_YEARLY_FREQUENCY.get(RD_PERIOD_WEEKLY) / RD_NEW_FREQUENCY);
        Decimal previousYearlyValue = RD_AMOUNT * (RD2_Constants.PERIOD_TO_YEARLY_FREQUENCY.get(RD_PERIOD) / 1);

        System.assertEquals(newYearlyValue.setScale(2), changeLog.NewAnnualValue__c, 'New Annual Value should be match' );
        System.assertEquals(previousYearlyValue.setScale(2), changeLog.PreviousAnnualValue__c, 'Previous Annual Value should match');
        System.assertEquals(RD2_Constants.CHANGE_TYPE_UPGRADE, changeLog.ChangeType__c, 
            'The Change Type should be ' + RD2_Constants.CHANGE_TYPE_UPGRADE);
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation with Change Log Enabled
     * creates a Change Log record for each update.
     * Using DML to test 2 separate Update calls does not work since they are both async
     */
    @IsTest
    private static void shouldCreateChangeLogForEachUpdateWhereFieldsChange() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        // First Update
        npe03__Recurring_Donation__c rdUpdate = rd.clone();
        
        rdUpdate.PaymentMethod__c = PAYMENT_CREDIT_CARD;
        
        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();
        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);
        changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        
        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(PAYMENT_CREDIT_CARD, changeLog.NewPaymentMethod__c, 'New Payment Method should be ' + PAYMENT_CREDIT_CARD);
        System.assertEquals(PAYMENT_CHECK, changeLog.PreviousPaymentMethod__c, 'Previous Payment Method should be ' + PAYMENT_CHECK);
        System.assertEquals(null, changeLog.ChangeType__c, 'The Change Type should be null');

        // Second Update
        npe03__Recurring_Donation__c rdUpdate2 = rdUpdate.clone();

        rdUpdate2.Status__c = RD2_Constants.STATUS_LAPSED;

        RD2_RecurringDonation rdEntity2 = new RD2_RecurringDonation(rdUpdate2);
        changeLogService.handleLogFieldChanged(rdEntity2, rdEntity);

        changeLogs = changeLogService.getChangeLogRecords();
        System.assertEquals(2, changeLogs.size(), 'There should be 2 Change Logs after the update');

        RecurringDonationChangeLog__c changeLog2 = changeLogs[1];
        System.assertEquals(RD2_Constants.STATUS_LAPSED, changeLog2.NewStatus__c, 'New Status should be ' + RD2_Constants.STATUS_LAPSED);
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, changeLog2.PreviousStatus__c, 'Previous Status should be ' + RD2_Constants.STATUS_ACTIVE);
        System.assertEquals(null, changeLog2.ChangeType__c, 'The Change Type should be null');
    }

    /**
     * @description Verifies that Change Log can be created regardless of User permissions
     */
    @IsTest
    private static void shouldCreateChangeLogWithoutPermissionsToObject(){
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        rdUpdate.InstallmentFrequency__c = RD_NEW_FREQUENCY;
        rdUpdate.npe03__Installment_Period__c = RD_PERIOD_WEEKLY;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();

        System.runAs(UTIL_UnitTestData_TEST.createUser(UTIL_Profile.PROFILE_STANDARD_USER)) {
            System.assertEquals(false, Schema.SObjectType.RecurringDonationChangeLog__c.fields
                    .NewInstallmentFrequency__c.isAccessible(),
                    'This Standard User created for the test should not have read access ' +
                            'to RD Change Log New Installment field.');
            System.assertEquals(false, Schema.SObjectType.RecurringDonationChangeLog__c.fields
                    .NewInstallmentFrequency__c.isUpdateable(),
                    'This Standard User created for the test should not have edit access ' +
                            'to RD Change Log New Installment field.');

            // User without permissions runs the code to generate Change Log records
            changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);
        }

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();
        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        System.assertEquals(RD_NEW_FREQUENCY, changeLog.NewInstallmentFrequency__c, 'New Installment Frequency should be ' + RD_NEW_FREQUENCY);
        System.assertEquals(1, changeLog.PreviousInstallmentFrequency__c, 'Previous Installment Frequency should be ' + 1);
        System.assertEquals(RD_PERIOD_WEEKLY, changeLog.NewInstallmentPeriod__c, 'New Installment Period should be ' + RD_PERIOD_WEEKLY);
        System.assertEquals(RD2_Constants.CHANGE_TYPE_UPGRADE, changeLog.ChangeType__c, 
            'The Change Type should be ' + RD2_Constants.CHANGE_TYPE_UPGRADE);
    }

    /**
     * @description Verifies that setting the Change Type on an RD overrides the default value
     * when the Amount changes
     */
    @IsTest
    private static void shouldOverrideDefaultChangeTypeWhenValueIsSetOnRD() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();
        
        rdUpdate.ChangeType__c = RD2_Constants.CHANGE_TYPE_DOWNGRADE;
        rdUpdate.npe03__Amount__c = RD_NEW_AMOUNT;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);
        rdEntity.storeAndClearChangeType();

        changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();
        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after the update');
        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(RD_NEW_AMOUNT, changeLog.NewAmount__c, 'New Amount should be ' + RD_NEW_AMOUNT);
        System.assertEquals(RD_AMOUNT, changeLog.PreviousAmount__c, 'Previous Amount should be ' + RD_AMOUNT);
        System.assertEquals(RD_NEW_AMOUNT * 12, changeLog.NewAnnualValue__c, 'New Annual Value should be ' + RD_NEW_AMOUNT * 12);
        System.assertEquals(RD_AMOUNT * 12, changeLog.PreviousAnnualValue__c, 'Previous Annual Value should be ' + RD_AMOUNT * 12);
        System.assertEquals(RD2_Constants.CHANGE_TYPE_DOWNGRADE, changeLog.ChangeType__c, 
            'The Change Type should be ' + RD2_Constants.CHANGE_TYPE_DOWNGRADE);
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation with a Currency Code
     * correctly uses that Currency in the Change Log record
     */
    @IsTest
    private static void shouldTrackIsoCodeWhenMultiCurrencyIsEnabled() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();
        rdUpdate.npe03__Amount__c = RD_NEW_AMOUNT;

        Boolean isMultiCurrencyEnabled = UserInfo.isMultiCurrencyOrganization();
        String nonDefaultCurrencyCode = null;

        if (isMultiCurrencyEnabled) {
            // If there is no active non-default currency, exit
            if (nonDefaultCurrencyType == null) {
                return;
            }

            nonDefaultCurrencyCode = (String)nonDefaultCurrencyType.get('IsoCode');
            rd.put('CurrencyIsoCode', nonDefaultCurrencyCode);
            rdUpdate.put('CurrencyIsoCode', nonDefaultCurrencyCode);
        }

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();

        System.assertEquals(1, changeLogs.size(), 'There should be 1 Change Log after RD currency update');
        RecurringDonationChangeLog__c changeLog = changeLogs[0];
        System.assertEquals(RD2_Constants.CHANGE_TYPE_UPGRADE, 
                changeLog.ChangeType__c, 'The Change Type should be ' + RD2_Constants.CHANGE_TYPE_UPGRADE);
        
        if (isMultiCurrencyEnabled) {
            System.assertEquals(nonDefaultCurrencyCode, changeLog.get('CurrencyIsoCode'), 
                'New currency should be ' + nonDefaultCurrencyCode);
        }
    }

    /**
     * @description Verifies that only setting the Change Type on an RD does not create a
     * Change Log record
     */
    @IsTest
    private static void shouldNotCreateChangeLogWhenOnlyChangeTypeChanges() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeLogService changeLogService = new RD2_ChangeLogService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();
        rdUpdate.ChangeType__c = RD2_Constants.CHANGE_TYPE_UPGRADE;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        changeLogService.handleLogFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeLog__c> changeLogs = changeLogService.getChangeLogRecords();
        System.assertEquals(0, changeLogs.size(), 'There should be 0 Change Logs after the update');
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation Status
     * to Paused without Pausing the schedule does not create a Change Log record
     */
    @IsTest
    private static void shouldNotCreateChangeLogWhenStatusUpdateIsReverted() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withCalculateNextDonationDate()
            .build();

        insert rd;

        List<RecurringDonationChangeLog__c> changeLogs = getRecurringDonationChangeLog(rd.Id);
        System.assertEquals(0, changeLogs.size(), 'There should be no Change Log after RD insert');
        
        rd.Status__c = RD2_Constants.STATUS_PAUSED;
        rd.ClosedReason__c = 'Card Expired';
        
        Test.startTest();
        update rd;
        Test.stopTest();

        Id rdId = rd.Id;
        changeLogs = getRecurringDonationChangeLog(rdId);
        System.assertEquals(0, changeLogs.size(), 'There should be 1 Change Log after the update');

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(null, rd.ClosedReason__c, 'The Status Reason should be blank');
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, rd.Status__c, 'The Status should be Active');
    }

    @IsTest
    private static void changesAreShownInChangeLogView() {
        configureRecurringDonationChangeLogEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
                .withDayOfMonth('20')
                .withCalculateNextDonationDate()
                .withPaymentMethod(null)
                .build();

        insert rd;

        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.PaymentMethod__c = PAYMENT_CREDIT_CARD;
        rd.InstallmentFrequency__c = RD_NEW_FREQUENCY;
        rd.npe03__Installment_Period__c = RD_PERIOD_WEEKLY;

        Test.startTest();
        update rd;
        Test.stopTest();

        RD2_ChangeLogView historyView = RD2_ChangeLogController.getChangeLog(rd.Id, 3, null);

        System.assertEquals(1, historyView.changes.size(), 'Unexpected number of changes.');

        RD2_ChangeView changeView = historyView.changes[0];
        System.assertEquals(5, changeView.fields.size(), 'Unexpected number of field changes.');

        // field order is important
        System.assertEquals(RD_AMOUNT, changeView.fields[0].oldValue, 'Unexpected old Amount');
        System.assertEquals(RD_NEW_AMOUNT, changeView.fields[0].newValue, 'Unexpected new Amount');

        Decimal newYearlyValue = RD_NEW_AMOUNT * (RD2_Constants.PERIOD_TO_YEARLY_FREQUENCY.get(RD_PERIOD_WEEKLY) / RD_NEW_FREQUENCY);
        Decimal previousYearlyValue = RD_AMOUNT * (RD2_Constants.PERIOD_TO_YEARLY_FREQUENCY.get(RD_PERIOD) / 1);
        System.assertEquals(previousYearlyValue.setScale(2), changeView.fields[1].oldValue, 'Unexpected old Annual Value');
        System.assertEquals(newYearlyValue.setScale(2), changeView.fields[1].newValue, 'Unexpected new Annual Value');

        System.assertEquals(1, changeView.fields[2].oldValue, 'Unexpected old Installment Frequency');
        System.assertEquals(RD_NEW_FREQUENCY, changeView.fields[2].newValue, 'Unexpected new Installment Frequency');

        System.assertEquals(RD_PERIOD, changeView.fields[3].oldValue, 'Unexpected old Installment Period');
        System.assertEquals(RD_PERIOD_WEEKLY, changeView.fields[3].newValue, 'Unexpected new Installment Period');

        System.assertEquals(Label.stgLabelFieldValueNone, changeView.fields[4].oldValue, 'Unexpected old payment method value.');
        System.assertEquals(PAYMENT_CREDIT_CARD, changeView.fields[4].newValue, 'Unexpected old payment method value.');

    }

    // Helpers
    ///////////////////

    /** @description Non default currency type sObject for this org.*/
    public static sObject nonDefaultCurrencyType {
        get {
            if (nonDefaultCurrencyType == null) {
                setupISOCodes();
            }
            return nonDefaultCurrencyType;
        }
        set;
    }

    /** @description Default currency type sObject for this org.*/
    public static sObject defaultCurrencyType {
        get {
            if (defaultCurrencyType == null) {
                setupISOCodes();
            }
            return defaultCurrencyType;
        }
        set;
    }

    /****
    * @description Queries currency types and fills class variables for testing currency change
    */
    public static void setupISOCodes() {
        for (sObject ct : database.query('SELECT IsoCode, ConversionRate, IsCorporate FROM CurrencyType')) {
            if ((boolean)ct.get('IsCorporate')) {
                defaultCurrencyType = ct;
            } else {
                nonDefaultCurrencyType = ct;
            }
        }
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

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @param c Contact
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder(Contact c) {
        return getRecurringDonationBuilder(c.Id);
    }

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @param contactId Contact Id
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder(Id contactId) {
        return TEST_RecurringDonationBuilder.constructEnhancedBuilder()
            .withDefaultValues()
            .withContact(contactId)
            .withAmount(RD_AMOUNT)
            .withPaymentMethod(PAYMENT_CHECK)
            .withDateEstablished(START_DATE)
            .withStartDate(START_DATE)
            .withCalculateNextDonationDate();
    }

    /**
     * @description Return Change Logs associated with the provided Recurring Donation Id
     * @param rdId Reuccring Donation Id
     * @return List<RecurringDonationChangeLog__c>
     */
    public static List<RecurringDonationChangeLog__c> getRecurringDonationChangeLog(Id rdId){
        return [
            SELECT Id, EffectiveDate__c, ChangeType__c, RecurringDonation__c, NewAmount__c, 
                NewCampaign__c, NewInstallmentFrequency__c, NewInstallmentPeriod__c, NewPaymentMethod__c, 
                NewStatus__c, NewStatusReason__c, NewAnnualValue__c, NewExpectedTotalValue__c,
                NewPlannedInstallments__c,
                PreviousAmount__c, PreviousCampaign__c, PreviousInstallmentFrequency__c, 
                PreviousInstallmentPeriod__c, PreviousPaymentMethod__c, PreviousStatus__c, 
                PreviousStatusReason__c, PreviousAnnualValue__c, PreviousExpectedTotalValue__c,
                PreviousPlannedInstallments__c
            FROM RecurringDonationChangeLog__c
            WHERE RecurringDonation__c =: rdId
            ORDER BY CreatedDate ASC
        ];
    }

    /***
    * @description Stubs custom settings configuration to enable enhanced Recurring Donations
    * @return none
    */
    private static void configureRecurringDonationChangeLogEnabled() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                IsRecurringDonations2Enabled__c = true,
                EnableChangeLog__c = true
            )
        );

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
    }

}
