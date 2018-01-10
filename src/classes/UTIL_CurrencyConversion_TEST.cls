/*
    Copyright (c) 2017, Salesforce.org
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
* @date 2017
* @group Utilities
* @description Tests for the UTIL_CurrencyConversion class
*/
@isTest
private class UTIL_CurrencyConversion_TEST {

    private static final Date DEFAULT_DATE = Date.newInstance(1900,1,1);
    /**
     * @description Validate proper currency conversion math when dated exchange rates are enabled in an org
     */
    static testMethod void test_CurrencyConversionWithDatedRates() {

        UtilCurrencyCacheMock mockcurrCache = new UtilCurrencyCacheMock();
        UTIL_CurrencyCache.instance = mockcurrCache;

        // Enable for standard currency management in the mock
        UTIL_Currency_TEST.UtilCurrencyMock mockCurr = new UTIL_Currency_TEST.UtilCurrencyMock();
        UTIL_Currency.instance = mockCurr;
        mockCurr.orgDefaultCurrencyReturn = 'USD';
        mockCurr.getDefaultCurrencyReturn = 'USD';
        mockCurr.isAdvancedCurrencyManagementEnabledReturn = false; // we're forcing the rates rather than attempting to query
        mockCurr.isMultiCurrencyOrganizationReturn = true;

        // Note: each time the mockCurrCache is queried for a new currency code it will use the rates
        // defined in the effectiveRatesReturn and effectiveDatesReturn properties. The actual currency
        // code does not matter as long as it changes each time we want to use a different set of rates/dates.

        Test.startTest();

        // TEST 1: Verify a simple single exchange rate
        // =====================================================
        // The default rate for CAD -> USD will be 1.25
        mockcurrCache.effectiveRatesReturn = new List<Decimal>{ 1.25 };
        mockcurrCache.effectiveDatesReturn = new List<Date>{ DEFAULT_DATE };

        System.AssertEquals( 1.25, UTIL_CurrencyCache.getEffectiveExchangeRate('CAD', Date.newInstance(2017,3,15)));
        System.AssertEquals( 800, UTIL_CurrencyConversion.convertAmount(1000, Date.Today(), 'CAD', 'USD'));

        // TEST 2: Verify converting from one non-USD currency to another non-USD currency
        // ===============================================================================

        // The default rate for EUR -> USD will be 0.85
        mockcurrCache.effectiveRatesReturn = new List<Decimal>{ 0.85 };
        System.AssertEquals( 0.85, UTIL_CurrencyCache.getEffectiveExchangeRate('EUR', Date.newInstance(2017,3,15)));
        System.AssertEquals( 1176.47, UTIL_CurrencyConversion.convertAmount(1000, Date.Today(), 'EUR', 'USD'));

        // Now figure out what the conversion rate is from Canadian Dollars to Euro's
        System.AssertEquals( 1.470588, UTIL_CurrencyConversion.getExchangeRate(Date.Today(), 'CAD', 'EUR'));

        // $1000 CAD converted to Euro's should be 1470.59 given the exchange rates above
        System.AssertEquals( 680, UTIL_CurrencyConversion.convertAmount(1000, Date.Today(), 'CAD', 'EUR'));

        // Verify that converting to/from the same currency always returns the same value
        System.AssertEquals( 1000, UTIL_CurrencyConversion.convertAmount(1000, Date.Today().addDays(95), 'CAD', 'CAD'));

        // TEST 3: Test when the UTIL_CurrencyConversion.alwaysUseStandardCurrencyRate flag is set to true
        // ===============================================================================================

        // There are two rates for XYZ->USD. The first is the current rate with an effective date of 2 years ago
        // and the second is the 'default' rate to use when alwaysUseStandardCurrencyRate is set to true.
        mockcurrCache.effectiveRatesReturn = new List<Decimal>{ 1.25, 1.75 };
        mockcurrCache.effectiveDatesReturn = new List<Date>{ Date.Today().addYears(-2), DEFAULT_DATE };
        mockcurrCache.defaultRate = 1.50;

        // The exchange rate for today should be 1.25
        System.AssertEquals( 1.25, UTIL_CurrencyConversion.getExchangeRate(null, 'XYZ', 'USD'));

        // The exchange rate for 1/1/201- should be 1.75
        System.AssertEquals( 1.75, UTIL_CurrencyConversion.getExchangeRate(Date.newInstance(2010,1,1), 'XYZ', 'USD'));

        // Convert from USD to XYZ. Should convert using the default rate of 1.50
        System.AssertEquals( 1.50, UTIL_CurrencyConversion.convertFromCorporateUsingStandardRates('XYZ', 1));
    }

    /**
     * @description Test the logic to store the effective dated exchange rate in a custom field on the Payment object
     */
    static testMethod void test_store_dated_exchange_rate_on_payment() {

        SObject defaultCurrencyType, nonDefaultCurrencyType;
        if (userInfo.isMultiCurrencyOrganization()) {
            for (sObject ct : database.query('SELECT IsoCode, ConversionRate, IsCorporate FROM CurrencyType WHERE IsActive = True')) {
                if ((boolean)ct.get('IsCorporate')) {
                    defaultCurrencyType = ct;
                } else {
                    nonDefaultCurrencyType = ct;
                }
            }
        }


        UTIL_CustomSettingsFacade.getContactsSettingsForTests(
                new npe01__Contacts_And_Orgs_Settings__c (npe01__Payments_Enabled__c= true)
        );
        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c(
                        Use_Dated_Conversion_Rates__c = True,
                        Custom_Exchange_Rate_Field__c = 'npe01__Custom_Payment_Field__c')
        );

        UtilCurrencyCacheMock mockcurrCache = new UtilCurrencyCacheMock();
        UTIL_CurrencyCache.instance = mockcurrCache;
        mockcurrCache.defaultRate = 1.23;
        mockcurrCache.effectiveRatesReturn = new List<Decimal>{ 1.25, 1.27, 1.29 };
        mockcurrCache.effectiveDatesReturn = new List<Date>{ Date.Today().addYears(-1), Date.Today().addYears(-2), Date.Today().addYears(-3) };

        // Enable for standard currency management in the mock
        UTIL_Currency_TEST.UtilCurrencyMock mockCurr = new UTIL_Currency_TEST.UtilCurrencyMock();
        UTIL_Currency.instance = mockCurr;
        mockCurr.orgDefaultCurrencyReturn = 'USD';
        mockCurr.getDefaultCurrencyReturn = 'USD';
        mockCurr.isAdvancedCurrencyManagementEnabledReturn = true;
        mockCurr.isMultiCurrencyOrganizationReturn = true;

        Account acc = new Account(Name='foo');
        insert acc;

        Test.startTest();

        Opportunity opp = new Opportunity(
                Name = 'success',
                Amount = 100,
                AccountID = acc.id,
                CloseDate = Date.Today().addYears(-2).addDays(30),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage());
        if (nonDefaultCurrencyType != null) {
            opp.put('CurrencyIsoCode', (String) nonDefaultCurrencyType.get('IsoCode'));
        }
        insert opp;

        Test.stopTest();

        // Can only test the result if multi-currency is enabled
        if (userInfo.isMultiCurrencyOrganization()) {
            npe01__OppPayment__c pmt = [SELECT Id, npe01__Custom_Payment_Field__c, npe01__Payment_Date__c FROM npe01__OppPayment__c LIMIT 1];
            system.assertEquals('1.27', pmt.npe01__Custom_Payment_Field__c,
                    'The Custom_Payment_Field__c should have a value of 1.27');

            // Update the payment date and test that the effective rate was updated accordingly
            pmt.npe01__Payment_Date__c = Date.Today();
            update pmt;

            pmt = [SELECT Id, npe01__Custom_Payment_Field__c FROM npe01__OppPayment__c LIMIT 1];
            system.assertEquals('1.25', pmt.npe01__Custom_Payment_Field__c,
                    'The Custom_Payment_Field__c should have a value of 1.25');
        }

    }

    /**
     * @description Test the logic to store the effective dated exchange rate in a custom field on the Allocation object
     * - Technically there is no available field to use on the Allocation__c object to actually store a value and
     * to assert later. As a result, this unit test method defines a non-existent field in the settings to simulate
     * what would happen if the User entered a field that doesn't exist (i.e, nothing).
     */
    static testMethod void test_store_dated_exchange_rate_on_allocation() {

        SObject defaultCurrencyType, nonDefaultCurrencyType;
        if (userInfo.isMultiCurrencyOrganization()) {
            for (sObject ct : database.query('SELECT IsoCode, ConversionRate, IsCorporate FROM CurrencyType WHERE IsActive = True')) {
                if ((boolean)ct.get('IsCorporate')) {
                    defaultCurrencyType = ct;
                } else {
                    nonDefaultCurrencyType = ct;
                }
            }
        }

        General_Accounting_Unit__c defaultGau = new General_Accounting_Unit__c(Name='General');
        insert defaultGau;

        UTIL_CustomSettingsFacade.getAllocationsSettingsForTests(
                new Allocations_Settings__c(Default_Allocations_Enabled__c = true, Default__c = defaultGau.id)
        );

        UTIL_CustomSettingsFacade.getHouseholdsSettingsForTests(
                new npo02__Households_Settings__c(
                        Use_Dated_Conversion_Rates__c = True,
                        Custom_Exchange_Rate_Field__c = 'Not_a_real_field__c')
        );

        UtilCurrencyCacheMock mockcurrCache = new UtilCurrencyCacheMock();
        UTIL_CurrencyCache.instance = mockcurrCache;
        mockcurrCache.defaultRate = 1.23;
        mockcurrCache.effectiveRatesReturn = new List<Decimal>{ 1.25, 1.27, 1.29 };
        mockcurrCache.effectiveDatesReturn = new List<Date>{ Date.Today().addYears(-1), Date.Today().addYears(-2), Date.Today().addYears(-3) };

        // Enable for standard currency management in the mock
        UTIL_Currency_TEST.UtilCurrencyMock mockCurr = new UTIL_Currency_TEST.UtilCurrencyMock();
        UTIL_Currency.instance = mockCurr;
        mockCurr.orgDefaultCurrencyReturn = 'USD';
        mockCurr.getDefaultCurrencyReturn = 'USD';
        mockCurr.isAdvancedCurrencyManagementEnabledReturn = true;
        mockCurr.isMultiCurrencyOrganizationReturn = true;

        Account acc = new Account(Name='foo');
        insert acc;

        Test.startTest();

        Opportunity opp = new Opportunity(
                Name = 'success',
                Amount = 100,
                AccountID = acc.id,
                CloseDate = system.today(),
                StageName = UTIL_UnitTestData_TEST.getClosedWonStage());
        if (nonDefaultCurrencyType != null) {
            opp.put('CurrencyIsoCode', (String) nonDefaultCurrencyType.get('IsoCode'));
        }
        insert opp;

        Test.stopTest();

        System.AssertEquals(true, ALLO_Allocations_TDTM.storeDatedConversionRate,
                'Based on the mocked settings this should still return true');

        // There's nothing to actually assert here because there is no field available on the Allocation__c
        // object to store the value in. Leaving the code below in place in case there's ever a new field
        // on the object that the value can be stored into for the test.
        /*if (userInfo.isMultiCurrencyOrganization()) {
            Allocation__c alloc = [SELECT Id, Some_Field_If_There_Was_One__c FROM Allocation__c LIMIT 1];
            system.assert(alloc.Some_Field_If_There_Was_One__c != null);
        }*/
    }

    /**
     * @description A mock implementation of UTIL_CurrencyCache.Interface_x that can
     * be used to provide pre-set return values from methods and store
     * parameters passed to methods.
     */
    public class UtilCurrencyCacheMock implements UTIL_CurrencyCache.Interface_x {
        public List<Date> effectiveDatesReturn;     // List of dates in Descending date order
        public List<Decimal> effectiveRatesReturn;  // List of rates matching to above dates
        public Decimal defaultRate;                 // Default exchange rate for this currency when not using dated rates

        public boolean isOrgCacheAvailable() {
            return false;
        }

        public void resetCurrencyCache() { }

        public Map<String, UTIL_CurrencyCache.CurrencyData> getRateMapForCurrencies(List<String> currCodes) {
            Map<String, UTIL_CurrencyCache.CurrencyData> mapOfCurrencyDataByCurrencyCode
                    = new Map<String, UTIL_CurrencyCache.CurrencyData>();

            UTIL_CurrencyCache.CurrencyData currData = new UTIL_CurrencyCache.CurrencyData();
            currData.effectiveDates = effectiveDatesReturn;
            currData.rates = effectiveRatesReturn;
            currData.defaultRate = defaultRate;

            mapOfCurrencyDataByCurrencyCode.put(currCodes[0], currData);
            return mapOfCurrencyDataByCurrencyCode;
        }
        public Integer getCurrDecimalPlaces(String currCode) {
            return 2;
        }

    }

}