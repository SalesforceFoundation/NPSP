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
@IsTest(IsParallel=true)
public with sharing class RD2_ChangeHistoryService_TEST {

    private static final Date START_DATE = Date.newInstance(2019, 9, 15);
    private static final Integer MONTHS_TO_DEC = START_DATE.monthsBetween(Date.newInstance(2019, 12, 15));
    private static final Integer MONTHS_TO_YEAR_END = START_DATE.monthsBetween(Date.newInstance(2020, 1, 1));
    private static final String PAYMENT_CREDIT_CARD = 'Credit Card';
    private static final String PAYMENT_CHECK = 'Check';
    private static final Decimal RD_AMOUNT = 100;
    private static final Decimal RD_NEW_AMOUNT = 200;
    private static final String RD_NEW_PERIOD = RD_Constants.INSTALLMENT_PERIOD_WEEKLY;
    private static final Decimal RD_NEW_FREQUENCY = 2;

    /****
    * @description Creates data required for unit tests
    */
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

        Test.startTest();
        insert rd;
        Test.stopTest();

        List<RecurringDonationChangeHistory__c> rdchList = getRecurringDonationChangeHistory(rd.Id);

        System.assertEquals(0, rdchList.size(), 'There should be no Change History after RD insert');

        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        update rd;
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
        
        rd.npe03__Amount__c = RD_NEW_AMOUNT;
        
        Test.startTest();
        update rd;
        Test.stopTest();

        List<RecurringDonationChangeHistory__c> rdchList = getRecurringDonationChangeHistory(rd.Id);
        System.assertEquals(1, rdchList.size(), 'There should be 1 Change History after the update');
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
    }

    /**
     * @description Verifies that creating and updating a Recurring Donation with Change History Enabled
     * does create Change History records
     */
    @IsTest
    private static void shouldCreateSingleChangeHistoryWhenMultipleFieldsChanges() {
        configureRecurringDonationChangeHistoryEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        insert rd;

        Campaign campaign = new Campaign(Name = 'UpgradeCampaign', IsActive = true);
        insert campaign;
        
        rd.npe03__Recurring_Donation_Campaign__c = campaign.Id;
        rd.InstallmentFrequency__c = RD_NEW_FREQUENCY;
        rd.npe03__Installment_Period__c = RD_NEW_PERIOD;
        
        Test.startTest();
        update rd;
        Test.stopTest();

        List<RecurringDonationChangeHistory__c> rdchList = getRecurringDonationChangeHistory(rd.Id);
        RecurringDonationChangeHistory__c rdch = rdchList[0];
        System.assertEquals(1, rdchList.size(), 'There should be 1 Change History after the update');
        System.assertEquals(RD_NEW_FREQUENCY, rdch.NewInstallmentFrequency__c, 'New Installment Frequency should be ' + RD_NEW_FREQUENCY);
        System.assertEquals(1, rdch.PreviousInstallmentFrequency__c, 'Previous Installment Frequency should be ' + 1);
        System.assertEquals(RD_NEW_PERIOD, rdch.NewInstallmentPeriod__c, 'New Installment Period should be ' + RD_NEW_PERIOD);
        System.assertEquals(RD_Constants.INSTALLMENT_PERIOD_MONTHLY, rdch.PreviousInstallmentPeriod__c, 'Previous Installment Period should be ' + RD_Constants.INSTALLMENT_PERIOD_MONTHLY);
        System.assertEquals(null, rdch.NewCampaign__c, 'New Campaign should be ' + campaign.Id);
        System.assertEquals(campaign.Id, rdch.PreviousCampaign__c, 'Previous Campaign should be ' + null);
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

        rd.Status__c = RD2_Constants.STATUS_LAPSED;
        update rd;

        rdchList = getRecurringDonationChangeHistory(rd.Id);
        RecurringDonationChangeHistory__c rdch2 = rdchList[1];

        System.assertEquals(2, rdchList.size(), 'There should be 2 Change Histories after the update');
        System.assertEquals(RD2_Constants.STATUS_LAPSED, rdch2.NewStatus__c, 'New Status should be ' + RD2_Constants.STATUS_LAPSED);
        System.assertEquals(RD2_Constants.STATUS_ACTIVE, rdch2.PreviousStatus__c, 'Previous Status should be ' + RD2_Constants.STATUS_ACTIVE);

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
                NewStatus__c, NewStatusReason__c, NewYearlyValue__c,
                PreviousAmount__c, PreviousCampaign__c, PreviousInstallmentFrequency__c, 
                PreviousInstallmentPeriod__c, PreviousPaymentMethod__c, PreviousStatus__c, 
                PreviousStatusReason__c, PreviousYearlyValue__c
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
