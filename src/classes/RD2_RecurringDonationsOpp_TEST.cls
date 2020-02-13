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
* @group Recurring Donations
* @description Unit tests for Recurring Donation Opportunities trigger when enhanced Recurring Donations are enabled
*
*/
@IsTest(IsParallel=false)
private class RD2_RecurringDonationsOpp_TEST {

    private static final TEST_SObjectGateway.RecurringDonationGateway rdGateway = new TEST_SObjectGateway.RecurringDonationGateway();
    private static final TEST_SObjectGateway.OpportunityGateway oppGateway = new TEST_SObjectGateway.OpportunityGateway();

    private static final String CURRENCY_ISO_CODE_FIELD = UTIL_Currency.CURRENCY_ISO_CODE_FIELD;
    private static final String CURRENCY_CAD = 'CAD';
    private static final String CURRENCY_USD = 'USD';

    private static final Date START_DATE = Date.newInstance(2019, 9, 15);
    private static final Date TODAY = START_DATE.addDays(1);
    private static final Integer MONTHS_TO_YEAR_END = START_DATE.monthsBetween(Date.newInstance(2020, 1, 1));
    private static final String PAYMENT_CHECK = 'Check';
    private static final Decimal RD_AMOUNT = 100;


    /****
    * @description Creates data required for unit tests
    */
    @TestSetup
    private static void setUp() {
        Contact contact = UTIL_UnitTestData_TEST.getContact();
        insert contact;

        RD2_ScheduleService.currentDate = TODAY;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = getRecurringDonationBuilder(contact.Id)
            .withCurrencyIsoCode(CURRENCY_CAD)
            .build();
        insert rd;

        TEST_OpportunityBuilder oppBuilder = getOpportunityBuilder(rd);
        List<Opportunity> opps = new List<Opportunity>{
            oppBuilder
                .withName()
                .withCurrencyIsoCode(CURRENCY_CAD)
                .withCloseDate(START_DATE)
                .withClosedWonStage()
                .build(),
            oppBuilder
                .withName()
                .withCurrencyIsoCode(CURRENCY_CAD)
                .withCloseDate(START_DATE.addMonths(1))
                .withOpenStage()
                .build()
        };
        insert opps;
    }

    /**
     * @description Verifies Current Year Value is unchanged
     * when open Opp is updated to Closed Won stage
     */
    @IsTest
    private static void shouldNotChangeCurrentYearValueWhenOppIsUpdatedToClosedWon() {
        RD2_ScheduleService.currentDate = TODAY;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        Opportunity opp = getOpenOpportunity(rd);

        Test.startTest();
        opp.StageName = UTIL_UnitTestData_TEST.getClosedWonStage();
        update opp;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(rd.npe03__Amount__c * MONTHS_TO_YEAR_END, rd.CurrentYearValue__c,
            'Current Year Value should be unchanged');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be unchanged');
    }

    /**
     * @description Verifies Current Year Value is updated
     * when open Opportunity is set to Closed Lost stage
     */
    @IsTest
    private static void shouldUpdateCurrentYearValueWhenOppIsUpdatedToClosedLost() {
        RD2_ScheduleService.currentDate = TODAY;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        Opportunity opp = getOpenOpportunity(rd);

        Test.startTest();
        opp.StageName = UTIL_UnitTestData_TEST.getClosedLostStage();
        update opp;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(rd.npe03__Amount__c * (MONTHS_TO_YEAR_END - 1), rd.CurrentYearValue__c,
            'Current Year Value should exclude Closed Lost Opportunity');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be unchanged');
    }

    /**
     * @description Verifies Current Year Value is updated
     * when past Closed Won Opportunity is deleted
     */
    @IsTest
    private static void shouldUpdateCurrentYearValueWhenPastClosedWonOppIsDeleted() {
        RD2_ScheduleService.currentDate = TODAY;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        Opportunity opp = getClosedOpportunity(rd);

        Test.startTest();
        delete opp;
        Test.stopTest();

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(rd.npe03__Amount__c * (MONTHS_TO_YEAR_END - 1), rd.CurrentYearValue__c,
            'Current Year Value should exclude deleted Opportunity');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be unchanged');
    }

    /**
     * @description Verifies Current Year Value is updated
     * when future open Opp Amount is changed. The Current Year Value
     * takes the Opp Amount into consideration over the matching installment Amount.
     */
    @IsTest
    private static void shouldUpdateCurrentYearValueWhenOppAmountIsUpdated() {
        final Decimal oppNewAmount = RD_AMOUNT + 100;
        RD2_ScheduleService.currentDate = TODAY;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        Opportunity opp = getOpenOpportunity(rd);

        //users updates the future open Opp Amount
        Test.startTest();
        opp.Amount = oppNewAmount;
        update opp;
        Test.stopTest();

        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertEquals(oppNewAmount, oppById.get(opp.Id).Amount, 'The Opp Amount should be as user specified it');

        rd = rdGateway.getRecord(rd.Id);
        System.assertEquals(rd.npe03__Amount__c * (MONTHS_TO_YEAR_END - 1) + oppNewAmount, rd.CurrentYearValue__c,
            'Current Year Value should use the future open Opp Amount over the matching installment Amount');
        System.assertEquals(rd.npe03__Amount__c * 12, rd.NextYearValue__c,
            'Next Year Value should be unchanged');
    }

    /**
     * @description Verifies an Opportunity cannot be created if its currency is not the same
     * as the currency on related Recurring Donation
     */
    @IsTest
    private static void shouldPreventOppInsertWhenCurrencyIsOutOfSyncWithRD() {
        if (!UserInfo.isMultiCurrencyOrganization()) {
            return;
        }

        RD2_ScheduleService.currentDate = TODAY;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        
        Exception actualException;
        try {
            Test.startTest();
            insert getOpportunityBuilder(rd)
                .withCurrencyIsoCode(CURRENCY_USD)
                .withCloseDate(START_DATE)
                .withOpenStage()
                .build();
            Test.stopTest();

        } catch (Exception e) {
            actualException = e;
        }

        System.assertNotEquals(null, actualException, 'An Exception should be generated');
        System.assert(actualException.getMessage().contains(System.Label.RD2_CurrencyChangeIsRestrictedOnOpp),
            'Exception message should match, actual message: ' + actualException.getMessage());
    }

    /**
     * @description Verifies an Opportunity can be created if its currency is the same
     * as the currency on related Recurring Donation
     */
    @IsTest
    private static void shouldAllowOppInsertWhenCurrencyIsInSyncWithRD() {
        if (!UserInfo.isMultiCurrencyOrganization()) {
            return;
        }

        RD2_ScheduleService.currentDate = TODAY;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        
        Exception actualException;
        try {
            Test.startTest();
            insert getOpportunityBuilder(rd)
                .withCurrencyIsoCode(CURRENCY_CAD)
                .withCloseDate(START_DATE)
                .withOpenStage()
                .build();
            Test.stopTest();

        } catch (Exception e) {
            actualException = e;
        }

        System.assertEquals(null, actualException, 'No Exception should be generated: ' + actualException);
    }

    /**
     * @description Verifies an Opportunity cannot be updated if its currency is not the same
     * as the currency on related Recurring Donation
     */
    @IsTest
    private static void shouldPreventOppUpdateWhenCurrencyIsOutOfSyncWithRD() {
        if (!UserInfo.isMultiCurrencyOrganization()) {
            return;
        }

        RD2_ScheduleService.currentDate = TODAY;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        Opportunity opp = getOpenOpportunity(rd);

        Exception actualException = updateOpportunity(opp, opp.Amount + 10, CURRENCY_USD);

        System.assertNotEquals(null, actualException, 'An Exception should be generated');
        System.assert(actualException.getMessage().contains(System.Label.RD2_CurrencyChangeIsRestrictedOnOpp),
            'Exception message should match, actual message: ' + actualException.getMessage());
    }

    /**
     * @description Verifies an Opportunity is updated if its currency is the same
     * as the currency on related Recurring Donation
     */
    @IsTest
    private static void shouldAllowOppUpdateWhenCurrencyIsInSyncWithRD() {
        if (!UserInfo.isMultiCurrencyOrganization()) {
            return;
        }

        RD2_ScheduleService.currentDate = TODAY;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();

        npe03__Recurring_Donation__c rd = rdGateway.getRecords()[0];
        Opportunity opp = getOpenOpportunity(rd);
        Decimal oldAmount = opp.Amount;

        Exception actualException = updateOpportunity(opp, opp.Amount + 10, CURRENCY_CAD);

        System.assertEquals(null, actualException, 'No Exception should be generated: ' + actualException);
        Map<Id, Opportunity> oppById = new Map<Id, Opportunity>(oppGateway.getRecords(rd));
        System.assertNotEquals(oldAmount, oppById.get(opp.Id).Amount, 'The Opp Amount should be changed');
    }

    /**
     * @description Verifies an Opportunity can be created and updated
     * without any error when it is not related to a Recurring Donation record
     */
    @IsTest
    private static void shouldAllowOppInsertAndUpdateWhenNotRelatedToRD() {
        if (!UserInfo.isMultiCurrencyOrganization()) {
            return;
        }

        RD2_ScheduleService.currentDate = TODAY;
        RD2_EnablementService_TEST.setRecurringDonations2Enabled();
        
        Exception actualException;
        try {
            Test.startTest();
            Opportunity opp = new TEST_OpportunityBuilder()
                .withContact(getContact().Id)
                .withAmount(100)
                .withCurrencyIsoCode(CURRENCY_CAD)
                .withCloseDate(START_DATE)
                .withOpenStage()
                .build();
            insert opp;
            Test.stopTest();

            opp.Amount += 10;
            update opp;

        } catch (Exception e) {
            actualException = e;
        }

        System.assertEquals(null, actualException, 'No Exception should be generated: ' + actualException);
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

    /****
    * @description Returns closed Opportunity assigned to the Recurring Donation
    * @param rd Recurring Donation
    * @return Opportunity
    */
    private static Opportunity getClosedOpportunity(npe03__Recurring_Donation__c rd) {
        return getOpportunity(rd, true);
    }

    /****
    * @description Returns open Opportunity assigned to the Recurring Donation
    * @param rd Recurring Donation
    * @return Opportunity
    */
    private static Opportunity getOpenOpportunity(npe03__Recurring_Donation__c rd) {
        return getOpportunity(rd, false);
    }

    /****
    * @description Returns Opportunity assigned to the Recurring Donation
    * @param isClosed Specifies if the Opportunity is closed
    * @param rd Recurring Donation
    * @return Opportunity
    */
    private static Opportunity getOpportunity(npe03__Recurring_Donation__c rd, Boolean isClosed) {
        for (Opportunity opp : oppGateway.getRecords(rd)) {
            if (opp.isClosed == isClosed) {
                return opp;
            }
        }

        System.assert(false, 'The Recurring Donation should have Opportunity to return');
        return null;
    }

    /**
     * @description Instantiate an Opp builder for the specified Recurring Donation
     * @param rd Recurring Donation
     * @return TEST_OpportunityBuilder New Opp builder
     */
    private static TEST_OpportunityBuilder getOpportunityBuilder(npe03__Recurring_Donation__c rd) {
        return new TEST_OpportunityBuilder()
            .withContact(rd.npe03__Contact__c)
            .withRecurringDonation(rd.Id)
            .withAmount(rd.npe03__Amount__c)
            .withInstallmentNumber(1);
    }

    /**
     * @description Base common RecurringDonation test structure for all test methods to start from
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder() {
        return getRecurringDonationBuilder(UTIL_UnitTestData_TEST.mockId(Contact.SObjectType));
    }

    /**
     * @description Base common Recurring Donation test structure for all test methods to start from
     * @param c Contact
     * @return TEST_RecurringDonationBuilder instance
     */
    private static TEST_RecurringDonationBuilder getRecurringDonationBuilder(Contact c) {
        return getRecurringDonationBuilder(c.Id);
    }

    /**
     * @description Base common Recurring Donation test structure for all test methods to start from
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
            .withStartDate(START_DATE);
    }

    /***
    * @description Updates currency on the Opportunity record
    * @param opp An Opportunity record
    * @param newAmount New Amount value
    * @param currencyCode Curency ISO Code on the Opportunity record
    * @return Exception Returns an exception if generated during update
    */
    private static Exception updateOpportunity(Opportunity opp, Decimal newAmount, String currencyCode) {
        Exception actualException;
        try {
            Test.startTest();
            opp.put(CURRENCY_ISO_CODE_FIELD, currencyCode);
            opp.Amount = newAmount;
            update opp;
            Test.stopTest();

        } catch (Exception e) {
            actualException = e;
        }

        return actualException;
    }


}
