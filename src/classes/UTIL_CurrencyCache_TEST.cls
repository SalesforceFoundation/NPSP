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
* @description Tests for the UTIL_CurrencyCache class
*/
@isTest
private class UTIL_CurrencyCache_TEST {

    static testMethod void test_AdvancedCurrencyConversion() {

        UtilCurrencyCacheMock mockcurrCache = new UtilCurrencyCacheMock();
        mockcurrCache.isOrgCacheAvailableReturn = false;
        // Dates list must always be in descending order
        mockcurrCache.effectiveDatesReturn = new List<Date>{
                Date.Parse('05/01/2017'), Date.Parse('03/01/2017'), Date.Parse('01/01/2017')
        };
        mockcurrCache.effectiveRatesReturn = new List<Decimal>{
                1.35, 1.25, 1.5
        };
        UTIL_CurrencyCache.instance = mockcurrCache;

        System.AssertEquals(False, UTIL_CurrencyCache.getInstance().isOrgCacheAvailable());
        System.AssertEquals(null, UTIL_CurrencyCache.orgCache);
        System.AssertEquals( 1.25, UTIL_CurrencyCache.getEffectiveExchangeRate('CAD', Date.Parse('03/15/2017')));
        UTIL_CurrencyCache.getInstance().resetCurrencyCache();

    }

    static testMethod void test_CurrencyCacheMethods() {

        // We won't really know if the client has a cache or not, so don't assume a response
        System.AssertNotEquals(null, UTIL_CurrencyCache.getInstance().isOrgCacheAvailable());
        System.AssertNotEquals(null, UTIL_CurrencyCache.getInstance().getRateMapForCurrencies(new List<String>{'CAD'}));
        UTIL_CurrencyCache.getInstance().resetCurrencyCache();
    }

    /**
     * @description Generate a set of effective dates and somewhat random exchange rates to
     * use for testing.
     * @param
     */
    private static Map<String, List<Object>> getDummyRates(Date startDt, Decimal seedValue) {
        List<Date> dts = new List<Date>();
        List<Decimal> rates = new List<Decimal>();
        Date dt = startDt;
        Decimal rtStart = seedValue;
        Decimal rt = rtStart;
        while (dt < Date.Today()) {
            dts.add(dt);
            rates.add(rt);
            dt = dt.addMonths(1);
            Decimal multiplier = (Math.random() > 0.5 ? 1 : -1);
            rt = ((rtStart + ((Math.random()/100) * multiplier))*1000000).round(System.RoundingMode.HALF_UP);
            rt = rt.divide(1000000,4);
        }
        return new Map<String, List<Object>>{
                UTIL_CurrencyCache.LIST_TYPE_EFF_DATES => dts,
                UTIL_CurrencyCache.LIST_TYPE_EXCH_RATES => rates};
    }

    /**
     * @description A mock implementation of UTIL_CurrencyCache.Interface_x that can
     * be used to provide pre-set return values from methods and store
     * parameters passed to methods.
     */
    public class UtilCurrencyCacheMock implements UTIL_CurrencyCache.Interface_x {
        public Boolean isOrgCacheAvailableReturn;
        public List<Date> effectiveDatesReturn;
        public List<Decimal> effectiveRatesReturn;

        public boolean isOrgCacheAvailable() {
            return isOrgCacheAvailableReturn;
        }

        public void resetCurrencyCache() {
            UTIL_CurrencyCache.cachedRatesByCurrency.clear();
        }

        public Map<String, Map<String, List<Object>>> getRateMapForCurrencies(List<String> currCodes) {
            Map<String, Map<String, List<Object>>> mapOfEffRatesByCurrencyCode
                    = new Map<String, Map<String, List<Object>>>();
            mapOfEffRatesByCurrencyCode.put(currCodes[0], new Map<String, List<Object>>{
                    UTIL_CurrencyCache.LIST_TYPE_EFF_DATES => effectiveDatesReturn,
                    UTIL_CurrencyCache.LIST_TYPE_EXCH_RATES => effectiveRatesReturn});
            return mapOfEffRatesByCurrencyCode;
        }

    }
}