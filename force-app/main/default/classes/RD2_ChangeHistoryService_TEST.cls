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
* @description All logic specific to Enhanced Recurring Donation Change History
*
*/
@IsTest
public with sharing class RD2_ChangeHistoryService_TEST {

    private static final Date START_DATE = Date.newInstance(2019, 9, 15);
    private static final Integer MONTHS_TO_DEC = START_DATE.monthsBetween(Date.newInstance(2019, 12, 15));
    private static final Integer MONTHS_TO_YEAR_END = START_DATE.monthsBetween(Date.newInstance(2020, 1, 1));
    private static final String PAYMENT_CREDIT_CARD = 'Credit Card';
    private static final String PAYMENT_CHECK = 'Check';
    private static final Decimal RD_AMOUNT = 100;
    private static final Decimal RD_NEW_AMOUNT = 200;
    private static final String RD_PERIOD = RD_Constants.INSTALLMENT_PERIOD_MONTHLY;
    private static final String RD_NEW_PERIOD = RD_Constants.INSTALLMENT_PERIOD_WEEKLY;
    private static final Decimal RD_NEW_FREQUENCY = 3;

    @TestSetup
    private static void setUp() {
        insert UTIL_UnitTestData_TEST.getContact();
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation without Enabling Change History 
     * does not create any Change History records
     */
    @IsTest
    private static void shouldNotCreateChangeHistoryWhenSettingIsNotEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .build();

        insert rd;

        List<RecurringDonationChangeHistory__c> rdchList = getRecurringDonationChangeHistory(rd.Id);
        System.assertEquals(0, rdchList.size(), 'There should be no Change History after RD insert');

        rd.npe03__Amount__c = RD_NEW_AMOUNT;

        Test.startTest();
        update rd;
        Test.stopTest();

        rdchList = getRecurringDonationChangeHistory(rd.Id);
        System.assertEquals(0, rdchList.size(), 'There should be no Change History with the Setting not Enabled');
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation Amount
     * with Change History Enabled does create Change History records
     */
    @IsTest
    private static void shouldCreateChangeHistoryWhenAmountChanges() {
        configureRecurringDonationChangeHistoryEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        insert rd;

        List<RecurringDonationChangeHistory__c> rdchList = getRecurringDonationChangeHistory(rd.Id);
        System.assertEquals(0, rdchList.size(), 'There should be no Change History after RD insert');
        
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        
        Test.startTest();
        update rd;
        Test.stopTest();

        rdchList = getRecurringDonationChangeHistory(rd.Id);
        RecurringDonationChangeHistory__c rdch = rdchList[0];
        System.assertEquals(1, rdchList.size(), 'There should be 1 Change History after the update');
        System.assertEquals(RD_NEW_AMOUNT, rdch.NewAmount__c, 'New Amount should be ' + RD_NEW_AMOUNT);
        System.assertEquals(RD_AMOUNT, rdch.PreviousAmount__c, 'Previous Amount should be ' + RD_AMOUNT);
        System.assertEquals(RD_NEW_AMOUNT * 12, rdch.NewAnnualValue__c, 'New Annual Value should be ' + RD_NEW_AMOUNT * 12);
        System.assertEquals(RD_AMOUNT * 12, rdch.PreviousAnnualValue__c, 'Previous Annual Value should be ' + RD_AMOUNT * 12);
        System.assertEquals(RD2_ChangeHistoryService.CHANGE_TYPE_UPGRADE, rdch.ChangeType__c, 
            'The Change Type should be ' + RD2_ChangeHistoryService.CHANGE_TYPE_UPGRADE);
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation Amount
     * with Change History Enabled does create Change History records
     */
    @IsTest
    private static void shouldCreateChangeHistoryDowngradeWhenAmountLowers() {
        configureRecurringDonationChangeHistoryEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeHistoryService rdchService = new RD2_ChangeHistoryService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        Decimal lowerAmount = RD_AMOUNT - 10;
        rdUpdate.npe03__Amount__c = lowerAmount;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        rdchService.handleHistoryFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeHistory__c> rdchList = rdchService.getChangeHistoryRecords();
        System.assertEquals(1, rdchList.size(), 'There should be no Change History after RD insert');

        RecurringDonationChangeHistory__c rdch = rdchList[0];
        System.assertEquals(1, rdchList.size(), 'There should be 1 Change History after the update');
        System.assertEquals(lowerAmount, rdch.NewAmount__c, 'New Amount should be ' + lowerAmount);
        System.assertEquals(RD_AMOUNT, rdch.PreviousAmount__c, 'Previous Amount should be ' + RD_AMOUNT);
        System.assertEquals(lowerAmount * 12, rdch.NewAnnualValue__c, 'New Annual Value should be ' + RD_NEW_AMOUNT * 12);
        System.assertEquals(RD_AMOUNT * 12, rdch.PreviousAnnualValue__c, 'Previous Annual Value should be ' + RD_AMOUNT * 12);
        System.assertEquals(RD2_ChangeHistoryService.CHANGE_TYPE_DOWNGRADE, rdch.ChangeType__c, 
            'The Change Type should be ' + RD2_ChangeHistoryService.CHANGE_TYPE_DOWNGRADE);
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation's Day of Month
     *  with Change History Enabled does not create Change History records
     */
    @IsTest
    private static void shouldNotCreateChangeHistoryWhenDayOfMonthChanges() {
        configureRecurringDonationChangeHistoryEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeHistoryService rdchService = new RD2_ChangeHistoryService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        rdUpdate.Day_Of_Month__c = '10';

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        rdchService.handleHistoryFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeHistory__c> rdchList = rdchService.getChangeHistoryRecords();
        System.assertEquals(0, rdchList.size(), 'There should be 0 Change History after the update');
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation Payment Method
     *  with Change History Enabled does create Change History records
     */
    @IsTest
    private static void shouldCreateChangeHistoryWhenPaymentMethodChanges() {
        configureRecurringDonationChangeHistoryEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeHistoryService rdchService = new RD2_ChangeHistoryService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        rdUpdate.PaymentMethod__c = PAYMENT_CREDIT_CARD;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        rdchService.handleHistoryFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeHistory__c> rdchList = rdchService.getChangeHistoryRecords();
        RecurringDonationChangeHistory__c rdch = rdchList[0];
        System.assertEquals(1, rdchList.size(), 'There should be 1 Change History after the update');
        System.assertEquals(PAYMENT_CREDIT_CARD, rdch.NewPaymentMethod__c, 'New Payment Method should be ' + PAYMENT_CREDIT_CARD);
        System.assertEquals(PAYMENT_CHECK, rdch.PreviousPaymentMethod__c, 'Previous Payment Method should be ' + PAYMENT_CHECK);
        System.assertEquals(null, rdch.ChangeType__c, 'The Change Type should be null');
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation with Change History Enabled
     * creates a single Change History record when multiple fields are changed
     */
    @IsTest
    private static void shouldCreateSingleChangeHistoryWhenMultipleFieldsChanges() {
        configureRecurringDonationChangeHistoryEnabled();

        Campaign campaign = new Campaign(Name = 'UpgradeCampaign', IsActive = true);
        insert campaign;

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        RD2_ChangeHistoryService rdchService = new RD2_ChangeHistoryService();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        rdUpdate.npe03__Recurring_Donation_Campaign__c = campaign.Id;
        rdUpdate.InstallmentFrequency__c = RD_NEW_FREQUENCY;
        rdUpdate.npe03__Installment_Period__c = RD_NEW_PERIOD;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        rdchService.handleHistoryFieldChanged(rdEntity, oldRdEntity);

        List<RecurringDonationChangeHistory__c> rdchList = rdchService.getChangeHistoryRecords();
        RecurringDonationChangeHistory__c rdch = rdchList[0];
        System.assertEquals(1, rdchList.size(), 'There should be 1 Change History after the update');
        System.assertEquals(RD_NEW_FREQUENCY, rdch.NewInstallmentFrequency__c, 'New Installment Frequency should be ' + RD_NEW_FREQUENCY);
        System.assertEquals(1, rdch.PreviousInstallmentFrequency__c, 'Previous Installment Frequency should be ' + 1);
        System.assertEquals(RD_NEW_PERIOD, rdch.NewInstallmentPeriod__c, 'New Installment Period should be ' + RD_NEW_PERIOD);
        System.assertEquals(RD_Constants.INSTALLMENT_PERIOD_MONTHLY, rdch.PreviousInstallmentPeriod__c, 'Previous Installment Period should be ' + RD_Constants.INSTALLMENT_PERIOD_MONTHLY);
        System.assertEquals(campaign.Id, rdch.NewCampaign__c, 'New Campaign should be ' + campaign.Id);
        System.assertEquals(null, rdch.PreviousCampaign__c, 'Previous Campaign should be ' + null);

        Decimal newYearlyValue = RD_AMOUNT * (RD_Constants.PERIOD_TO_YEARLY_FREQUENCY.get(RD_NEW_PERIOD) / RD_NEW_FREQUENCY);
        Decimal previousYearlyValue = RD_AMOUNT * (RD_Constants.PERIOD_TO_YEARLY_FREQUENCY.get(RD_PERIOD) / 1);

        System.assertEquals(newYearlyValue.setScale(2), rdch.NewAnnualValue__c, 'New Annual Value should be match' );
        System.assertEquals(previousYearlyValue.setScale(2), rdch.PreviousAnnualValue__c, 'Previous Annual Value should match');
        System.assertEquals(RD2_ChangeHistoryService.CHANGE_TYPE_UPGRADE, rdch.ChangeType__c, 
            'The Change Type should be ' + RD2_ChangeHistoryService.CHANGE_TYPE_UPGRADE);
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation with Change History Enabled
     * does create Change History records
     */
    @IsTest
    private static void shouldCreateChangeHistoryForEachUpdateWhereFieldsChange() {
        configureRecurringDonationChangeHistoryEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        insert rd;
        
        rd.PaymentMethod__c = PAYMENT_CREDIT_CARD;
        
        Test.startTest();
        update rd;
        Test.stopTest();

        List<RecurringDonationChangeHistory__c> rdchList = getRecurringDonationChangeHistory(rd.Id);
        RecurringDonationChangeHistory__c rdch = rdchList[0];
        System.assertEquals(1, rdchList.size(), 'There should be 1 Change History after the update');
        System.assertEquals(PAYMENT_CREDIT_CARD, rdch.NewPaymentMethod__c, 'New Payment Method should be ' + PAYMENT_CREDIT_CARD);
        System.assertEquals(PAYMENT_CHECK, rdch.PreviousPaymentMethod__c, 'Previous Payment Method should be ' + PAYMENT_CHECK);
        System.assertEquals(null, rdch.ChangeType__c, 'The Change Type should be null');

        rd.Status__c = RD2_Constants.STATUS_LAPSED;
        update rd;

        rdchList = getRecurringDonationChangeHistory(rd.Id);
        RecurringDonationChangeHistory__c rdch2 = rdchList[1];

        System.assertEquals(2, rdchList.size(), 'There should be 2 Change Histories after the update');
        System.assertEquals(RD2_Constants.STATUS_LAPSED, rdch2.NewStatus__c, 'New Status should be ' + RD2_Constants.STATUS_LAPSED);
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, rdch2.PreviousStatus__c, 'Previous Status should be ' + RD2_Constants.STATUS_ACTIVE);
        System.assertEquals(null, rdch2.ChangeType__c, 'The Change Type should be null');
    }

    /**
     * @description Verifies that Change History can be created regardless of User permissions
     */
    @IsTest
    private static void shouldCreateChangeHistoryWithoutPermissionsToObject(){
        configureRecurringDonationChangeHistoryEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();

        rdUpdate.InstallmentFrequency__c = RD_NEW_FREQUENCY;
        rdUpdate.npe03__Installment_Period__c = RD_NEW_PERIOD;

        RD2_RecurringDonation rdEntity = new RD2_RecurringDonation(rdUpdate);
        RD2_RecurringDonation oldRdEntity = new RD2_RecurringDonation(rd);

        RD2_ChangeHistoryService rdchService = new RD2_ChangeHistoryService();

        System.runAs(UTIL_UnitTestData_TEST.createUser(UTIL_Profile.PROFILE_STANDARD_USER)) {
            System.assertEquals(false, Schema.SObjectType.RecurringDonationChangeHistory__c.fields
                    .NewInstallmentFrequency__c.isAccessible(),
                    'This Standard User created for the test should not have read access ' +
                            'to RD Change History New Installment field.');
            System.assertEquals(false, Schema.SObjectType.RecurringDonationChangeHistory__c.fields
                    .NewInstallmentFrequency__c.isUpdateable(),
                    'This Standard User created for the test should not have edit access ' +
                            'to RD Change History New Installment field.');

            // User without permissions runs the code to generate Change History records
            rdchService.handleHistoryFieldChanged(rdEntity, oldRdEntity);
        }

        List<RecurringDonationChangeHistory__c> rdchList = rdchService.getChangeHistoryRecords();
        RecurringDonationChangeHistory__c rdch = rdchList[0];
        System.assertEquals(1, rdchList.size(), 'There should be 1 Change History after the update');
        System.assertEquals(RD_NEW_FREQUENCY, rdch.NewInstallmentFrequency__c, 'New Installment Frequency should be ' + RD_NEW_FREQUENCY);
        System.assertEquals(1, rdch.PreviousInstallmentFrequency__c, 'Previous Installment Frequency should be ' + 1);
        System.assertEquals(RD_NEW_PERIOD, rdch.NewInstallmentPeriod__c, 'New Installment Period should be ' + RD_NEW_PERIOD);
        System.assertEquals(RD2_ChangeHistoryService.CHANGE_TYPE_UPGRADE, rdch.ChangeType__c, 
            'The Change Type should be ' + RD2_ChangeHistoryService.CHANGE_TYPE_UPGRADE);
    }

    @IsTest
    private static void changesAreShownInChangeHistoryView() {
        configureRecurringDonationChangeHistoryEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
                .withDayOfMonth('20')
                .withCalculateNextDonationDate()
                .withPaymentMethod(null)
                .build();

        insert rd;

        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        rd.PaymentMethod__c = PAYMENT_CREDIT_CARD;
        rd.InstallmentFrequency__c = RD_NEW_FREQUENCY;
        rd.npe03__Installment_Period__c = RD_NEW_PERIOD;

        Test.startTest();
        update rd;
        Test.stopTest();

        RD2_ChangeHistoryView historyView = RD2_ChangeHistoryController.getChangeHistory(rd.Id, 3, null);

        System.assertEquals(1, historyView.changes.size(), 'Unexpected number of changes.');

        RD2_ChangeView changeView = historyView.changes[0];
        System.assertEquals(5, changeView.fields.size(), 'Unexpected number of field changes.');

        // field order is important
        System.assertEquals(RD_AMOUNT, changeView.fields[0].oldValue, 'Unexpected old Amount');
        System.assertEquals(RD_NEW_AMOUNT, changeView.fields[0].newValue, 'Unexpected new Amount');

        Decimal newYearlyValue = RD_NEW_AMOUNT * (RD_Constants.PERIOD_TO_YEARLY_FREQUENCY.get(RD_NEW_PERIOD) / RD_NEW_FREQUENCY);
        Decimal previousYearlyValue = RD_AMOUNT * (RD_Constants.PERIOD_TO_YEARLY_FREQUENCY.get(RD_PERIOD) / 1);
        System.assertEquals(previousYearlyValue.setScale(2), changeView.fields[1].oldValue, 'Unexpected old Annual Value');
        System.assertEquals(newYearlyValue.setScale(2), changeView.fields[1].newValue, 'Unexpected new Annual Value');

        System.assertEquals(1, changeView.fields[2].oldValue, 'Unexpected old Installment Frequency');
        System.assertEquals(RD_NEW_FREQUENCY, changeView.fields[2].newValue, 'Unexpected new Installment Frequency');

        System.assertEquals(RD_PERIOD, changeView.fields[3].oldValue, 'Unexpected old Installment Period');
        System.assertEquals(RD_NEW_PERIOD, changeView.fields[3].newValue, 'Unexpected new Installment Period');

        System.assertEquals(Label.stgLabelNone, changeView.fields[4].oldValue, 'Unexpected old payment method value.');
        System.assertEquals(PAYMENT_CREDIT_CARD, changeView.fields[4].newValue, 'Unexpected old payment method value.');

    }

    // Helpers
    ///////////////////

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
     * @description Return Change Histories associated with the provided Recurring Donation Id
     * @param rdId Reuccring Donation Id
     * @return List<RecurringDonationChangeHistory__c>
     */
    private static List<RecurringDonationChangeHistory__c> getRecurringDonationChangeHistory(Id rdId){
        return [
            SELECT Id, EffectiveDate__c, ChangeType__c, RecurringDonation__c, NewAmount__c, 
                NewCampaign__c, NewInstallmentFrequency__c, NewInstallmentPeriod__c, NewPaymentMethod__c, 
                NewStatus__c, NewStatusReason__c, NewAnnualValue__c,
                PreviousAmount__c, PreviousCampaign__c, PreviousInstallmentFrequency__c, 
                PreviousInstallmentPeriod__c, PreviousPaymentMethod__c, PreviousStatus__c, 
                PreviousStatusReason__c, PreviousAnnualValue__c
            FROM RecurringDonationChangeHistory__c
            WHERE RecurringDonation__c =: rdId
            ORDER BY CreatedDate ASC
        ];
    }

    /***
    * @description Stubs custom settings configuration to enable enhanced Recurring Donations
    * @return none
    */
    public static void configureRecurringDonationChangeHistoryEnabled() {
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                IsRecurringDonations2Enabled__c = true,
                EnableChangeHistory__c = true
            )
        );

        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
    }

}
