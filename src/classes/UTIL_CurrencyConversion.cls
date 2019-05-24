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
* @description Utilities for converting amounts using the organizations currency exchange rates
*/
public class UTIL_CurrencyConversion {

    /**
     * @description Static flag to force the conversion logic to always use the standard currency rates
     * rather than dated exchange rates (if enabled). This is necessary to support the legacy roll-ups that
     * are based on aggragate queries since those only use the standard (i.e., default rate) rather than
     * the dated exchange rate.
     */
    private static Boolean forceConvertToUseOrgDefaultRate = false;

    private static final Integer RATE_DECIMAL_PLACES = 6;
    private static final Integer AMT_DECIMAL_MULTIPLIER = 1000000;    // based on the number of zeros (i.e., 2 decimal places=100)

    /**
     * @description Returns the proper effective rate to use based on the date and the from/to currencies
     * Leverages the UTIL_CurrencyCache class to handle either standard or dated exchanges as well as the
     * platform cache if it's been allocated.
     * @param dt - Effective Date to use for conversion (or null to use the current date)
     * @param fromCurr - The currency to convert from
     * @param toCurr - The currency to convert to.
     * @return Exchange Rate
     */
    public static Decimal getExchangeRate(Date dt, String fromCurr, String toCurr) {

        // If multi-currency is not enabled at all OR the from and to currencies are the same, just return 1
        if (!UTIL_Currency.getInstance().isMultiCurrencyOrganization() || fromCurr == toCurr) {
            return 1;
        }

        // Force the date to the default (1/1/1900) if this flag is set to true
        if (forceConvertToUseOrgDefaultRate == true) {
            dt = null;
        } else if (dt == null) {
            dt = Date.today();
        }

        // Retrieve the conversion rate from the "From" Currency to the Org Default Currency
        Decimal fromRate = UTIL_CurrencyCache.getEffectiveExchangeRate(fromCurr, dt);

        // If the "to" currency is the org default, just return the fromRate
        if (toCurr == UTIL_Currency.getInstance().getOrgDefaultCurrency()) {
            return fromRate;
        }

        // Otherwise we have to calculate the rate between the two currencies.
        Decimal toRate = UTIL_CurrencyCache.getEffectiveExchangeRate(toCurr, dt);
        Decimal effRate = fromRate.divide(toRate, RATE_DECIMAL_PLACES, System.RoundingMode.HALF_UP);

        return effRate;
    }

    /**
     * @description Returns the converted amount to the toCurr using the proper exchange rate.
     * @param amt - The amount to convert
     * @param dt - Effective Date to use for conversion (or null to use the current date)
     * @param fromCurr - The currency to convert from
     * @param toCurr - The currency to convert to.
     * @return Amount converted to the toCurr using the applied effective date rounded to two decimal places
     */
    public static Decimal convertAmount(Decimal amt, Date dt, String fromCurr, String toCurr) {
        if (!UTIL_Currency.getInstance().isMultiCurrencyOrganization() || fromCurr == toCurr) {
            return amt;
        } else {
            Decimal effRate = getExchangeRate(dt, fromCurr, toCurr);
            Integer decimalPlaces = UTIL_CurrencyCache.getInstance().getCurrDecimalPlaces(toCurr);
            Decimal convertedToCorp = amt.divide(effRate, RATE_DECIMAL_PLACES, System.RoundingMode.HALF_UP) * AMT_DECIMAL_MULTIPLIER;
            Decimal convertedToTarget = Decimal.ValueOf(convertedToCorp.Round( System.RoundingMode.HALF_UP));
            return convertedToTarget.divide(AMT_DECIMAL_MULTIPLIER, decimalPlaces, System.RoundingMode.HALF_UP);
        }
    }

    /*******************************************************************************************************
    * @description Converts an amount from the corporate currency to a given currency always using the
    *   non-dated exchange rate exchange rate even if ACM is enabled in the org.
    * @param ISO A string of the currency's iso code that we wish to convert the amount to.
    * @param amt A decimal of the amount to convert.
    * @return decimal The converted amount.
    ********************************************************************************************************/
    //do a conversion from amount in corporate currency to the currency specified by the ISO code
    public static decimal convertFromCorporateUsingStandardRates(String toISO, Decimal amt) {
        return convertAmountUsingStandardRates(UTIL_Currency.getInstance().getOrgDefaultCurrency(), toISO, amt);
    }

    /*******************************************************************************************************
    * @description Converts an amount from any given currency to any other currency always using the
    *   non-dated exchange rate exchange rate even if ACM is enabled in the org.
    * @param fromISO A string of the currency's iso code of the amount we wish to convert.
    * @param toISO A string of the currency's iso code that we wish to convert the amount to.
    * @param amt A decimal of the amount to convert.
    * @return decimal The converted amount.
    ********************************************************************************************************/
    public static decimal convertAmountUsingStandardRates(String fromISO, String toISO, Decimal amt) {
        forceConvertToUseOrgDefaultRate = true;
        Decimal rtn = UTIL_CurrencyConversion.convertAmount(amt, null, fromISO, toISO);
        forceConvertToUseOrgDefaultRate = false;
        return rtn;
    }

}