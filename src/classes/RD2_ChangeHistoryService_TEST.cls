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

    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        configureRecurringDonationChangeHistoryEnabled();
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
     * @description Verifies that creating and updating a Recurring Donation with Change History Enabled
     * does create Change History records
     */
    @IsTest
    private static void shouldCreateChangeHistoryWhenAmountChanges() {
        // RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        configureRecurringDonationChangeHistoryEnabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(getContact())
            .withDayOfMonth('20')
            .withCalculateNextDonationDate()
            .build();

        Test.startTest();
        insert rd;
        Test.stopTest();

        npe03__Recurring_Donation__c rdUpdate = rd.clone();
        rdUpdate.npe03__Amount__c = RD_NEW_AMOUNT;

        // RD2_ChangeHistoryService changeHistoryService = new RD2_ChangeHistoryService();
        // changeHistoryService.handleHistoryFieldChanged(rdUpdate, rd);

        // changeHistoryService.insertChangeHistoryRecords();

        RD2_RecurringDonations_TDTM triggerHandler = new RD2_RecurringDonations_TDTM();
        List<npe03__Recurring_Donation__c> newRdList = new List<npe03__Recurring_Donation__c>{rdUpdate};
        List<npe03__Recurring_Donation__c> oldRdList = new List<npe03__Recurring_Donation__c>{rd};

        triggerHandler.createChangeHistoryOnUpdate(newRdList, oldRdList, TDTM_Runnable.Action.AfterUpdate);

        List<RecurringDonationChangeHistory__c> rdchList = getRecurringDonationChangeHistory(rd.Id);

        System.assertEquals(1, rdchList.size(), 'There should be 1 Change History after the update');
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
            SELECT Id, EffectiveDate__c
            FROM RecurringDonationChangeHistory__c
            WHERE RecurringDonation__c =: rdId
        ];
    }

    /***
    * @description Stubs custom settings configuration to enable enhanced Recurring Donations
    * @return none
    */
    public static void configureRecurringDonationChangeHistoryEnabled() {
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        UTIL_CustomSettingsFacade.reloadCustomSettingsOnRecordTypeCleanup();
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
            new npe03__Recurring_Donations_Settings__c(
                IsRecurringDonations2Enabled__c = true,
                EnableChangeHistory__c = true,
                npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name()
            )
        );
    }

    public static void setUpConfiguration(Map<String, Object> valueByField) {
        npe03__Recurring_Donations_Settings__c rdSetting = new npe03__Recurring_Donations_Settings__c(
            npe03__Add_Campaign_to_All_Opportunites__c = true,
            IsRecurringDonations2Enabled__c = true,
            npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name()
        );

        for (String field : valueByField.keySet()) {
            rdSetting.put(field, valueByField.get(field));
        }

        UTIL_CustomSettingsFacade.reloadCustomSettingsOnRecordTypeCleanup();
        UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(rdSetting);
    }

    /**
     * @description Configure RD Settings for Enhanced Recurring Donations
     */
    // private static void configureEnhancedRDSettings() {
    //     RD2_EnablementService_TEST.setRecurringDonations2Enabled();

    //     RD2_StatusMapper_TEST.Stub mapperStub = new RD2_StatusMapper_TEST.Stub()
    //         .withAllMapping();
    //     RD2_StatusMapper.statusMapper = (RD2_StatusMapper) Test.createStub(
    //         RD2_StatusMapper.Class,
    //         mapperStub
    //     );

    //     UTIL_CustomSettingsFacade.getRecurringDonationsSettingsForTest(
    //         new npe03__Recurring_Donations_Settings__c(
    //             IsRecurringDonations2Enabled__c = true,
    //             npe03__Opportunity_Forecast_Months__c = 1,
    //             npe03__Open_Opportunity_Behavior__c = RD2_Constants.CloseActions.Mark_Opportunities_Closed_Lost.name(),
    //             npe03__Record_Type__c = UTIL_RecordTypes_TEST.getDefaultRecordTypeId(Opportunity.SObjectType),
    //             InstallmentOppStageName__c = PLEDGED_STAGE
    //         )
    //     );
    // }

}
